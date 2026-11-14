/* Local test harness for the exact Lua sources bundled by the examined extender. */
#include <stdio.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
/* Offline harness supplies the embedding callbacks, not a CoE5 API. Constant float
   hashes are valid (collisions are resolved by Lua); entropy is irrelevant here. */
unsigned coe5seMakeLuaSeed(void) { return 12345; }
unsigned coe5seHashLuaFloat(lua_Number n) { (void)n; return 0; }
void coe5seChargeLuaSteps(lua_State *L,size_t steps) { (void)L;(void)steps; }
int main(int argc,char **argv) {
    if(argc!=2)return 2;
    lua_State *L=luaL_newstate();if(!L)return 2;
    luaL_requiref(L,"_G",luaopen_base,1);lua_pop(L,1);
    luaL_requiref(L,"table",luaopen_table,1);lua_pop(L,1);
    luaL_requiref(L,"string",luaopen_string,1);lua_pop(L,1);
    luaL_requiref(L,"math",luaopen_math,1);lua_pop(L,1);
    luaL_requiref(L,"utf8",luaopen_utf8,1);lua_pop(L,1);
    int status=luaL_loadfile(L,argv[1]);if(!status)status=lua_pcall(L,0,LUA_MULTRET,0);
    if(status)fprintf(stderr,"%s\n",lua_tostring(L,-1));lua_close(L);return status?1:0;
}
