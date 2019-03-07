--[[
	消息系统
--]]


local MsgSystem = class("MsgSystem", function(  )
	return display.newNode()
end)


--[[
	为了使用 CCNotificationCenter
--]]
function MsgSystem:ctor( oldIns )
	self:retain()  -- 加1保持句柄
	self.m_Listeners = {}  --{eventtype:{handle}}

	if oldIns ~= nil then
		-- 合并
		self.m_Listeners = clone(oldIns.m_Listeners)
		-- 释放
		oldIns:Release()
	end
end

--[[
	@brief 注册消息句柄
	@param msgFID, 一级消息ID 
	@param listener，消息 func(msgFID, msgSID, params)
	@return handle,用于取消注册的句柄
--]]
function MsgSystem:RegisterMessageEvent( msgFID, listener )
	local msgIDKey = tostring(msgFID)
    if self.m_Listeners[msgIDKey] == nil then
        self.m_Listeners[msgIDKey] = {}
    end
    local handle = "_LISTENER_HANDLE_" .. tostring(listener)
    self.m_Listeners[msgIDKey][handle] = listener
    return handle
end

--[[
	@brief 取消注册消息句柄
	@param msgFID, 一级消息ID 
	@param key RegisterMessageEvent 返回值
--]]
function MsgSystem:UnRegisterMessageEvent( msgFID, key )
	local msgIDKey = tostring(msgFID)
    if self.m_Listeners[msgIDKey] ~= nil then
	    self.m_Listeners[msgIDKey][key] = nil
    end
end

--[[
	@brief 获取一级消息ID
	@param msgSID，二级消息ID
	@param 以及消息ID
--]]
function MsgSystem:GetFID( msgSID )
	local fid = msgSID
	while fid >= 100 do
		fid = fid * 0.1
	end
	return math.floor(fid)
end

--[[
	@brief 发送消息
	@param msgFID, 一级消息ID
	@param msgSID, 二级消息ID
--]]
function MsgSystem:SendMessage( msgSID, ... )
	local msgFID = self:GetFID(msgSID)
	local msgIDKey = tostring(msgFID)
	local listenerTable = self.m_Listeners[msgIDKey]
	if listenerTable == nil then
		return
	end
	local listeners = {}
	for _, listener in pairs(listenerTable) do
		listeners[#listeners + 1] = listener
	end
	for i, listener in ipairs(listeners) do
		listener(msgSID, ...)
	end
end

--[[
	@brief 释放
--]]
function MsgSystem:Release(  )
	self:release()
end

local oldIns = g_MsgSystem 
g_MsgSystem = MsgSystem.new( oldIns )

---------------------------> 外部
--[[
    @brief 释放
--]]
function MsgSystemRelease()
    g_MsgSystem:Release()
end

--[[
	@brief 发送消息
	@param msgFID, 一级消息ID  delete
	@param msgSID, 二级消息ID
	@param ... 参数,自定义
--]]
function SendMessage( msgSID, ... )
	g_MsgSystem:SendMessage(msgSID, ...)
end


--[[
	消息监听扩展

	使用
	1、MessageEventExtend.extend 扩展对象
	2、self:ListenMessage(msgFID), 监听一个类型的消息
	3、实现 OnMessage(msgSID, ...)  处理消息
	4、self:RemoveMessageListener(msgFID)  取消监听某一类消息
	5、self:RemoveAllMessageListener()    取消所有监听
--]]

MessageEventExtend = {}
function MessageEventExtend.extend( object )

	object.msgevent_msgid_hanlder_table = {}
	
	--[[
		@brief 根据 sid 获取 fid
	--]]
	function object:GetFIDWithSID( msgSID )
		return g_MsgSystem:GetFID(msgSID)
	end

	--[[
		@brief 注册消息监听
	--]]
	function object:ListenMessage( msgFID )
		if object.msgevent_msgid_hanlder_table[msgFID] ~= nil then
			return
		end
		local handler = g_MsgSystem:RegisterMessageEvent(msgFID, function( msgSID, ... )
			if object.OnMessage then
				object:OnMessage(msgSID, ...)
			end
		end)
		object.msgevent_msgid_hanlder_table[msgFID] = handler
	end

	--[[
		@取消注册
	--]]
	function object:RemoveMessageListener( msgFID )
		g_MsgSystem:UnRegisterMessageEvent(msgFID, object.msgevent_msgid_hanlder_table[msgFID])
	end

	--[[
		@取消所有注册
	--]]
	function object:RemoveAllMessageListener( )
		for k,v in pairs(object.msgevent_msgid_hanlder_table) do
			g_MsgSystem:UnRegisterMessageEvent(k, v)
		end
	end

end






























