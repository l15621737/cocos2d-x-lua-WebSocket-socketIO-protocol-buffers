
local _M = class('SocketManager')

local WS_DATA_FORMAT_TEXT 	= 0
local WS_DATA_FORMAT_BINARY = 1

local _sbyteFunc = string.byte
local _ssubFunc = string.sub
local _tconcatFunc = table.concat
local _schar = string.char
local _strFind = string.find

local _frame_open_key = _sbyteFunc("0")
local _frame_close_key = _sbyteFunc("1")
local _frame_ping_key = _sbyteFunc("2")
local _frame_pong_key = _sbyteFunc("3")
local _frame_message_key = _sbyteFunc("4")
local _frame_upgrade_key = _sbyteFunc("5")
local _frame_noop_key = _sbyteFunc("6")

local _binary_message_key = 4

local _type_min = _sbyteFunc("0")
local _type_connect = _sbyteFunc("0")
local _type_disconnect = _sbyteFunc("1")
local _type_event = _sbyteFunc("2")
local _type_ack = _sbyteFunc("3")
local _type_error = _sbyteFunc("4")
local _type_binary_event = _sbyteFunc("5")
local _type_binary_ack = _sbyteFunc("6")
local _type_max = _sbyteFunc("6")
local _type_undetermined = _sbyteFunc("16") --undetermined mask bit

function _M:ctor(url)

	self.iBinaryPendingBuffers = 0
    self.szBinaryEventName = nil
    -- 查找event Name 和pb Name 的对应关系，可以是function或table, 参数返回如同__index
    self.__pbNameMapping  = nil

 	self.webSocket = cc.WebSocket:create(url)
	self.webSocket:registerScriptHandler(handler(self, self.onWebsocketOpen), cc.WEBSOCKET_OPEN)
	self.webSocket:registerScriptHandler(handler(self, self.onWebsocketMessage), cc.WEBSOCKET_MESSAGE)
	self.webSocket:registerScriptHandler(handler(self, self.onWebsocketClose), cc.WEBSOCKET_CLOSE)
	self.webSocket:registerScriptHandler(handler(self, self.onWebsocketError), cc.WEBSOCKET_ERROR)
end
------------  wbsocket handler start ----------------------

function _M:onWebsocketOpen(strBuff )
	-- dump(strBuff, "onWebsocketOpen")
	SendMessage(MsgID_Net_Connected, strbuff)
end

function _M:onWebsocketMessage(strBuff )	
	-- dump(strBuff, "onWebsocketMessage")
	if type(strBuff) == "string" then
	    local frameKey = _sbyteFunc(strBuff, 1)
	    if frameKey == _frame_open_key then

	    elseif frameKey == _frame_close_key then

	    elseif frameKey == _frame_ping_key then

	    elseif frameKey == _frame_pong_key then

	    elseif frameKey == _frame_message_key then
	        -- msg
	        local typeKey = _sbyteFunc(strBuff,2)
	        if typeKey == _type_event then

	            -- objSocketIO:PraseMsg(strBuff,3)
	        elseif typeKey == _type_binary_event then
	            -- find "-" cal conut
	            -- 先获取协议名称
	            local iPosEnd = _strFind(strBuff,"-",3)
	            local szCount = _ssubFunc(strBuff, 3 , iPosEnd - 1)
	            local iCount = tonumber(szCount)
	            local szJsonHead = _ssubFunc(strBuff, iPosEnd + 1, -1)
	            local tJsonHead = json.decode(szJsonHead)           
	            -- print("iPosEnd szCount", iPosEnd ,szCount, iCount, szJsonHead, tJsonHead)
	            self:PraseBinaryMsg(iCount, tJsonHead)
	        end

	    elseif frameKey == _frame_upgrade_key then
	    
	    elseif frameKey == _frame_noop_key then

	    elseif frameKey == _binary_message_key then
	        -- 获取二进制数据
	        self:putBinaryBuffer(strBuff, 2)
	    else

	    end
	end
end

function _M:onWebsocketClose(strBuff )
	-- dump(strBuff, "onWebsocketClose")
	SendMessage(MsgID_Net_Closed, strBuff)
end

function _M:onWebsocketError(strBuff )
	-- dump(strBuff, "onWebsocketError")
	SendMessage(MsgID_Net_Error, strBuff)
end

-- 设置PB协议对应表
function _M:setPBMapping(PBMapping)
	self.__pbNameMapping = PBMapping
end

------------  wbsocket handler end ----------------------

-- 获取协议头文件以便解析二进制
function _M:PraseBinaryMsg(iPendingCount, tHead)
    self.iBinaryPendingBuffers = iPendingCount
    local szBinaryEventName = tHead[1]
    if type(szBinaryEventName) ~= "string" then
        szBinaryEventName = nil
        for k,v in pairs(tHead) do
            if type(v) == "string" then
                szBinaryEventName = v
            end
        end
    end

    if szBinaryEventName == nil then
        print("Binary EventName is nil socketIO:SetBinaryHead") 
    end
    self.szBinaryEventName = szBinaryEventName
   -- print("................PraseBinaryMsg"..":::"..self.szBinaryEventName..":::"..self.iBinaryPendingBuffers)

end

-- 解析二进制数据
function _M:putBinaryBuffer(strBuff, ioffset)
    if self.iBinaryPendingBuffers > 0 then
        local szPBName = nil
        if self.__pbNameMapping ~= nil then
            local szType = type(self.__pbNameMapping)
            if szType == "table" then
                szPBName = self.__pbNameMapping[self.szBinaryEventName]
            elseif szType == "function" then
                szPBName = self.__pbNameMapping(self.szBinaryEventName)
            end
        end
		assert(szPBName ~= nil, "get pb.xxx 出错")

        local tPb = protobuf.decode(szPBName, strBuff, ioffset)
 		
 		SendMessage(MsgID_Net_Recived, self.szBinaryEventName, tPb)

        self.iBinaryPendingBuffers = self.iBinaryPendingBuffers - 1
    end
end

-- 发送二进制数据
-- param szEvent 协议名
-- param strBuffData 数据表
local _oneBinaryHead = _tconcatFunc({_schar(_frame_message_key), _schar(_type_binary_event),"1-"})
function _M:sendBinaryData(szEvent, strBuffData)
    local strBinarybuff = nil
    -- socket.io 要求发送协议必须先发送一条 451带协议名的text 然后再发送二进制，同接收消息一样
    local szHead = _tconcatFunc({_oneBinaryHead, json.encode({szEvent, {_placeholder = true,num = 0 }})})
    self:sendText(szHead, szEvent)

    if strBuffData == nil then
        strBinarybuff = _schar(_binary_message_key)
    elseif type(strBuffData) == "string" then
        strBinarybuff =_tconcatFunc( {_schar(_binary_message_key), strBuffData})
    -- table pb
    elseif type(strBuffData) == "table" then
        local szPBName = nil
        if self.__pbNameMapping ~= nil then
            local szType = type(self.__pbNameMapping)
            if szType == "table" then
                szPBName = self.__pbNameMapping[szEvent]
            elseif szType == "function" then
                szPBName = self.__pbNameMapping(szEvent)
            end
        end

		assert(szPBName ~= nil, "get pb.xxx 出错")

        local strbuff = protobuf.encode(szPBName, strBuffData)
        strBinarybuff =_tconcatFunc({_schar(_binary_message_key), strbuff})
    else
        strBinarybuff = _schar(_binary_message_key)
    end

    self:sendBinary(strBinarybuff, szEvent)
end

-- 发送文本
function _M:sendText(sendStr, szEvent)
	if self.webSocket and self:getSocketState() == cc.WEBSOCKET_STATE_OPEN then
		-- print("sendText:", szEvent, sendStr)
		self.webSocket:setDataType(WS_DATA_FORMAT_TEXT)
		self.webSocket:sendString(sendStr)
		else
		if self.webSocket ~= nil then
		    print(':error webSocket state = ', objWebSocket:getReadyState())
		else
		    print(':error webSocket is nil')
		end
	end
end

-- 发送二进制
function _M:sendBinary(sendStr, szEvent)
	if self.webSocket and self:getSocketState() == cc.WEBSOCKET_STATE_OPEN then
		-- print("sendBinary:", szEvent, sendStr)
		self.webSocket:setDataType(WS_DATA_FORMAT_BINARY)
	    self.webSocket:sendString(sendStr)
	else
	    if self.webSocket ~= nil then
	        print(':error webSocket state = ', objWebSocket:getReadyState())
	    else
	        print(':error webSocket is nil')
	    end
	end
end


-- socket当前状态
function _M:getSocketState()
	if self.webSocket then
		return self.webSocket:getReadyState()
	end
end

-- 关闭socket
function _M:closeSocket()
	if self.webSocket then
		if self:getSocketState() == cc.WEBSOCKET_STATE_OPEN or self:getSocketState() == cc.WEBSOCKET_STATE_CONNECTING then
            self.webSocket:close()
        end
	end
end


return _M
