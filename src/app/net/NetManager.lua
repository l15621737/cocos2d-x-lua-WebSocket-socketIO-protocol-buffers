local _M = class("NetManager")

require "app.net.init"
local socket = require "socket"

local CONNECT_AGAIN = true						-- 是否支持重连
local TimePerHeart = 5                       	-- 心跳间隔
local TimeToOff = TimePerHeart * 100         	-- 心跳超时
local ErrorTimeOff = 200                      	-- 错误超时 网络异常(断网，切换网络...)后的超时退出时间
local ErrorReconnectMaxTimes = 20 				-- 网络错误尝试重连次数

local scheduler = cc.Director:getInstance():getScheduler()
local stringFormat = string.format

function _M:ctor(url)
	print('NetManager:ctor')
	
	self.url = url	
   	self.socketManager = require("app.net.SocketManager").new(url)
	self.socketManager:setPBMapping(PBMapping)
	
	self.isSendProgress = false
	self.needReconnect = false
	self.reconnectTimes = 0
	self.lastSendHeartTime = os.time()
	self.heartPrevTime = os.time()
	self:initMessageEvent()
end

-- socket 是否已连接
function _M:isSocketConnected()
	if self.socketManager then
		return self:getSocketState() == cc.WEBSOCKET_STATE_OPEN
	end
end

-- socket 是否已关闭
function _M:isSocketClosed()
	if self.socketManager then
		return self:getSocketState() == cc.WEBSOCKET_STATE_CLOSED
	end
end

-- socket当前状态
function _M:getSocketState()
	if self.socketManager then
		return self.socketManager:getSocketState()
	end
end

function _M:initMessageEvent()
	MessageEventExtend.extend(self)
	self:ListenMessage(MsgID_Network)
end

function _M:OnMessage(msgSID, ...)
	local arg = {...}
	if msgSID == MsgID_Net_Connected then
		local data = arg[1]
		self:onWebsocketOpen(data)
	elseif msgSID == MsgID_Net_Recived then
		local szEvent = arg[1]
		local tData = arg[2]
		self:onWebsocketMessage(szEvent, tData) 
	elseif msgSID == MsgID_Net_Closed then
		local data = arg[1]
		self:onWebsocketClose(data)
	elseif msgSID == MsgID_Net_Error then
		local data = arg[1]
		self:onWebsocketError(data)
	end
end


function _M:onWebsocketOpen(data)
	if not self.firstConnected then 
		-- 首次连接成功
		print("Net onWebsocketOpen")
		self.firstConnected = true
	else
		-- 重连成功
		print("Net onWebsocketReOpen")
	end

	self.reconnectTimes = 0
	self.isSendProgress = false
	self.heartPrevTime = os.time()
	self:stopErrorSch()
	self:starHeart()
end

function _M:onWebsocketClose(data)
	print("Net onWebsocketClose")
	if self.closeByMyself then 
		if self.needReconnect then
			self:connectAagin()
		end
		return 
	end
	self:handNetError()
end

function _M:onWebsocketError(data)
	print("Net onWebsocketError")
	self:handNetError()
end

function _M:onWebsocketMessage(szProtocalName, tData)
	dump(tData, stringFormat("onWebsocketMessage:%s", szProtocalName))
end

function _M:handNetError()
	print("handNetError")
	if CONNECT_AGAIN then
		self:beginErrorSch()
	else
		self:stopErrorSch()
		self:errorExit()
	end
end

function _M:beginErrorSch()
	self:stopErrorSch()
	print("beginErrorSch")
	self.reconnectTimes = self.reconnectTimes + 1
	if self.reconnectTimes >= ErrorReconnectMaxTimes then
		print("error reconnect times:"..self.reconnectTimes)
		self:errorExit()
		return
	end
	self.errorSch = scheduler:scheduleScriptFunc(function ()
		if self:isSocketConnected() then -- 安全保护
			return
		end
		print('error time update')
		self:stopErrorSch()
		self:errorExit()
	end, ErrorTimeOff, false)
end

function _M:stopErrorSch()
	if self.errorSch then
		print("stopErrorSch")
		scheduler:unscheduleScriptEntry(self.errorSch)
		self.errorSch = nil
	end
end

function _M:sendHeart()
	self:sendData(NetProtocal.HEART_REQ, {reqTimestamp = socket.gettime()})
	self.lastSendHeartTime = os.time()
end

function _M:starHeart()
	self:stopHeart()
	self:sendHeart()
	self.heartScheduler = scheduler:scheduleScriptFunc(function()		
		local costTime = os.time() - self.heartPrevTime
		local timeDelay = os.time() - self.lastSendHeartTime
		local isSendTime = timeDelay >= TimePerHeart

		if  costTime > TimeToOff and isSendTime then
			print('heart break time out')
			self:errorExit()
		elseif costTime >= TimePerHeart and isSendTime then
			-- print(self.msgID..':costTime = '..costTime.." send hear time = "..os.time())
			self:sendHeart()
		end
	end, 0, false)
end

function _M:stopHeart()
	if self.heartScheduler then
		scheduler:unscheduleScriptEntry(self.heartScheduler)
		self.heartScheduler = nil	
	end
end

function _M:errorExit()
	if self.errorExited then return end
	print("errorExit")
	self.errorExited = true
	self:closeSocket()
end

function _M:closeSocket()
	self.closeByMyself = true
	print("closeSocket")
	self:stopHeart()
	if self.socketManager then
		self.socketManager:closeSocket()
	end
end

function _M:connectAagin()
	print("connectAagin:"..os.date())

	self.socketManager = SocketManager.new(self.url)
	self.socketManager:setPBMapping(PBMapping)
	self.isSendProgress = false
	self.errorExited = false
	self.firstConnected = false
	self.closeByMyself = false
	self.needReconnect = false
	self.reconnectTimes = 0
	self.lastSendHeartTime = os.time()
	self.heartPrevTime = os.time()
	self:starHeart()
end

-- 重新建立socket并连接
function _M:reConnectSocket()
	print("reConnectSocket time = ".. os.date())
	
	if self:isSocketClosed() then
		self:connectAagin()
	else
		self.needReconnect = true
		self:closeSocket()
	end
end

--[[
	发送协议
	@param protocal 协议
	@param data 发送数据格式为lua table
--]]
function _M:sendData(protocal, data)	
	if self.socketManager then
		self.socketManager:sendBinaryData(protocal, data)
	end
end

return _M