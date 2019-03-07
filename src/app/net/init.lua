require "app.net.pbc.protobuf"
require "app.net.NetProtocal"
require "app.net.PBMapping"

local basePBFilePath = cc.FileUtils:getInstance():fullPathForFilename("res/pb/base.pb")
local gamePBFilePath = cc.FileUtils:getInstance():fullPathForFilename("res/pb/game.pb")
local lobbyPBFilePath = cc.FileUtils:getInstance():fullPathForFilename("res/pb/lobby.pb")

protobuf.readnil_ignore_assert() 

local basebuffer = read_protobuf_file_c(basePBFilePath)
protobuf.register(basebuffer)

local gamebuffer = read_protobuf_file_c(gamePBFilePath)
protobuf.register(gamebuffer)

local lobbybuffer = read_protobuf_file_c(lobbyPBFilePath)
protobuf.register(lobbybuffer)
