#define LUA_LIB
#include<lua.h>
#include<lualib.h>
#include<lauxlib.h>

static int currentstate(lua_State * L){
  lua_pushthread(L);
  return 1;
}

static const luaL_Reg cext[] = {
  {"currentstate", currentstate},
  {NULL, NULL}
};

LUALIB_API int luaopen_everlooping_cext(lua_State * L){
  luaL_register(L, "everlooping.cext", cext);
  return 1;
}
