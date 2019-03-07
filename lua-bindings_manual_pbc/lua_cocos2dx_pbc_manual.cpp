#include "scripting/lua-bindings/manual/pbc/lua_cocos2dx_pbc_manual.h"

#include "platform/CCPlatformConfig.h"
#include "base/ccConfig.h"
#include "scripting/lua-bindings/manual/tolua_fix.h"
#include "scripting/lua-bindings/manual/LuaBasicConversions.h"
#include "scripting/lua-bindings/manual/CCLuaEngine.h"

#include "scripting/lua-bindings/manual/pbc/pbc-lua.h"

#include "cocos/platform/CCFileUtils.h"

#ifdef __cplusplus
extern "C" {
#endif

int read_protobuf_file(lua_State *L) {
    const char *buff = luaL_checkstring(L, -1);
    Data data = cocos2d::FileUtils::getInstance()->getDataFromFile(buff);
    lua_pushlstring(L, (const char *) data.getBytes(), data.getSize());
    return 1;
}

TOLUA_API int register_pbc_module(lua_State *L) {
    lua_getglobal(L, "_G");
    if (lua_istable(L, -1))//stack:...,_G,
    {
        lua_register(L, "read_protobuf_file_c", read_protobuf_file);
        luaopen_protobuf_c(L);
    }
    lua_pop(L, 1);
    return 1;
}

#ifdef __cplusplus
}
#endif