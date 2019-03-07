#pragma once

#ifdef __cplusplus
extern "C" {
#endif
#include "tolua++.h"

TOLUA_API int  register_pbc_module(lua_State* L);

#ifdef __cplusplus
}
#endif