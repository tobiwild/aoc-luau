#include <iostream>
#include <fstream>

#include "lua.h"
#include "lualib.h"
#include "luacode.h"

using namespace std;

// This file contains modified code from https://github.com/luau-lang/luau/blob/1cda8304bf085b955109f9cc32cd51b581cdff54/CLI/Repl.cpp
// which was released under the following license:
//
// MIT License
//
// Copyright (c) 2019-2023 Roblox Corporation
// Copyright (c) 1994–2019 Lua.org, PUC-Rio.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

static ifstream inputFile;
static bool useStdin;

optional<string> read_file(string file)
{
    ifstream sourceFile;
    string source;

    sourceFile.open(file, ifstream::in);
    if (sourceFile.fail())
    {
        return nullopt;
    }

    source.assign(istreambuf_iterator<char>(sourceFile), istreambuf_iterator<char>());
    sourceFile.close();

    // Skip first line if it's a shebang
    if (source.length() > 2 && source.at(0) == '#' && source.at(1) == '!')
        source.erase(0, source.find('\n'));

    return source;
}

static string run_file(lua_State* GL, string file)
{
    optional<string> source = read_file(file);
    if (!source)
    {
        return "Could not open " + file;
    }

    lua_State* L = lua_newthread(GL);
    luaL_sandboxthread(L);

    char* bytecode;
    size_t bytecodeSize = 0;
    bytecode = luau_compile(source->c_str(), source->length(), nullptr, &bytecodeSize);
    string chunkname = "=" + file;
    int result = luau_load(L, chunkname.c_str(), bytecode, bytecodeSize, 0);
    free(bytecode);

    int status = 0;
    if (result == 0)
    {
        status = lua_resume(L, nullptr, 0);
    }
    else
    {
        status = LUA_ERRSYNTAX;
    }

    if (status != 0)
    {
        string error;

        if (status == LUA_YIELD)
        {
            error = "thread yielded unexpectedly";
        }
        else if (const char* str = lua_tostring(L, -1))
        {
            error = str;
        }

        error += "\nstacktrace:\n";
        error += lua_debugtrace(L);

        lua_pop(GL, 1);
        return error;
    }

    lua_pop(GL, 1);
    lua_xmove(L, GL, 1);

    return "";
}

static int finishrequire(lua_State* L)
{
    if (lua_isstring(L, -1))
        lua_error(L);

    return 1;
}

static int lua_loadstring(lua_State* L)
{
    size_t l = 0;
    const char* s = luaL_checklstring(L, 1, &l);
    const char* chunkname = luaL_optstring(L, 2, s);

    lua_setsafeenv(L, LUA_ENVIRONINDEX, false);

    char* bytecode;
    size_t bytecodeSize = 0;
    bytecode = luau_compile(s, l, nullptr, &bytecodeSize);
    int result = luau_load(L, chunkname, bytecode, bytecodeSize, 0);
    free(bytecode);

    if (result == 0)
    {
        return 1;
    }

    lua_pushnil(L);
    lua_insert(L, -2); // put before error message
    return 2;          // return nil plus error message
}

static int lua_require(lua_State* L)
{
    string name = luaL_checkstring(L, 1);
    string chunkname = "=" + name;

    luaL_findtable(L, LUA_REGISTRYINDEX, "_MODULES", 1);

    // return the module from the cache
    lua_getfield(L, -1, name.c_str());
    if (!lua_isnil(L, -1))
    {
        // L stack: _MODULES result
        return finishrequire(L);
    }

    lua_pop(L, 1);

    optional<string> source = read_file(name);
    if (!source)
    {
        luaL_argerrorL(L, 1, ("error loading " + name).c_str());
    }

    // module needs to run in a new thread, isolated from the rest
    // note: we create ML on main thread so that it doesn't inherit environment of L
    lua_State* GL = lua_mainthread(L);
    lua_State* ML = lua_newthread(GL);
    lua_xmove(GL, L, 1);

    // new thread needs to have the globals sandboxed
    luaL_sandboxthread(ML);

    char* bytecode;
    size_t bytecodeSize = 0;
    bytecode = luau_compile(source->c_str(), source->length(), nullptr, &bytecodeSize);
    int result = luau_load(ML, chunkname.c_str(), bytecode, bytecodeSize, 0);
    free(bytecode);

    if (result == 0)
    {
        int status = lua_resume(ML, L, 0);

        if (status == 0)
        {
            if (lua_gettop(ML) == 0)
                lua_pushstring(ML, "module must return a value");
            else if (!lua_istable(ML, -1) && !lua_isfunction(ML, -1))
                lua_pushstring(ML, "module must return a table or function");
        }
        else if (status == LUA_YIELD)
        {
            lua_pushstring(ML, "module can not yield");
        }
        else if (!lua_isstring(ML, -1))
        {
            lua_pushstring(ML, "unknown error while running module");
        }
    }

    // there's now a return value on top of ML; L stack: _MODULES ML
    lua_xmove(ML, L, 1);
    lua_pushvalue(L, -1);
    lua_setfield(L, -4, name.c_str());

    // L stack: _MODULES ML result
    return finishrequire(L);
}

static int lua_lines(lua_State* L)
{
    istream& input = useStdin ? cin : inputFile;
    string line;

    if (getline(input, line))
        lua_pushstring(L, line.c_str());
    else
        lua_pushnil(L);

    return 1;
}

static const luaL_Reg global_funcs[] = {
    {"loadstring", lua_loadstring},
    {"require", lua_require},
    {nullptr, nullptr},
};

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        cerr << "Usage: " << argv[0] << " [Luau script] [Input file]" << endl;
        return 1;
    }

    lua_State* L = luaL_newstate();
    luaL_openlibs(L);
    luaL_register(L, "_G", global_funcs);
    luaL_sandbox(L);

    string error = run_file(L, argv[1]);
    if (!error.empty())
    {
        cerr << error << endl;
        return 1;
    }

    if (!lua_isfunction(L, -1))
    {
        cerr << "Luau script does not return a function" << endl;
        return 1;
    }

    if (argc >= 3)
    {
        inputFile.open(argv[2]);
        if (inputFile.fail())
        {
            cerr << "Could not open " << argv[2] << endl;
            return 1;
        }
    }
    else
        useStdin = true;

    lua_pushcfunction(L, lua_lines, "lines");

    if (lua_pcall(L, 1, 0, 0))
    {
        cerr << "Error on calling function: " << lua_tostring(L, -1) << endl;
        return 1;
    }

    lua_close(L);

    return 0;
}
