
local _M = class("MainScene", cc.load("mvc").ViewBase)
require "app.msg.init"

local url = 'ws://183.3.211.167:9116/yemanrendazuozhan_yn_dl/test11111111975/?post_data=%7B%22roomid%22%3A%22test11111111975%22%2C%22gameid%22%3A%22yemanrendazuozhan%5Fyn%5Fdl%22%2C%22player%22%3A%7B%22opt%22%3A%22%22%2C%22uid%22%3A%2257675622%22%2C%22name%22%3A%2257675622%22%2C%22avatarurl%22%3A%22http%3A%5C%2F%5C%2Fres.yy.com%5C%2Fguild%5C%2Fheader%5C%2F10001.jpg%22%7D%2C%22channelid%22%3A%22yy%22%7D&timestamp=1509710152&nonstr=jg4g3b0i-7pb0-92y5-mu0a-e997nmb6gg3p&sign=c7961cc7357f8a991edf5a93daf1e69b2d7c30ab&EIO=3&transport=websocket'
-- local url = 'ws://172.27.38.26:8889/yemanrendazuozhan_yn_dl/test11111111988/?post_data=%7B%22roomid%22%3A%22test11111111988%22%2C%22gameid%22%3A%22yemanrendazuozhan%5Fyn%5Fdl%22%2C%22channelid%22%3A%22yy%22%2C%22player%22%3A%7B%22avatarurl%22%3A%22http%3A%5C%2F%5C%2Fres.yy.com%5C%2Fguild%5C%2Fheader%5C%2F10001.jpg%22%2C%22opt%22%3A%22%22%2C%22name%22%3A%2243742921%22%2C%22uid%22%3A%221090122%22%7D%7D&timestamp=1509710152&nonstr=jg4g3b0i-7pb0-92y5-mu0a-e997nmb6gg3p&sign=c7961cc7357f8a991edf5a93daf1e69b2d7c30ab&EIO=3&transport=websocket'

function _M:onCreate()
   NetManager = require("app.net.NetManager").new(url)
end



return _M
