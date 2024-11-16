#include <iostream>
#include <fstream>
#include <optional>
#include <string>
#include <vector>

#include "lua.h"
#include "lualib.h"
#include "luacode.h"

using namespace std;

// This file contains modified code from
//
// - https://github.com/luau-lang/luau/blob/1cda8304bf085b955109f9cc32cd51b581cdff54/CLI/Repl.cpp
// - https://github.com/luau-lang/luau/blob/e905e305702388543dac9040667968c0b856506d/CLI/FileUtils.cpp
//
// MIT License
//
// Copyright (c) 2019-2024 Roblox Corporation
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

bool isAbsolutePath(string_view path)
{
    // Must begin with '/'
    return path.size() >= 1 && path[0] == '/';
}

vector<string_view> splitPath(string_view path)
{
    vector<string_view> components;

    size_t pos = 0;
    size_t nextPos = path.find_first_of("\\/", pos);

    while (nextPos != string::npos)
    {
        components.push_back(path.substr(pos, nextPos - pos));
        pos = nextPos + 1;
        nextPos = path.find_first_of("\\/", pos);
    }
    components.push_back(path.substr(pos));

    return components;
}

// Takes a path that is relative to the file at baseFilePath and returns the path explicitly rebased onto baseFilePath.
// For absolute paths, baseFilePath will be ignored, and this function will resolve the path to a canonical path:
// (e.g. "/Users/.././Users/johndoe" -> "/Users/johndoe").
string resolvePath(string_view path, string_view baseFilePath)
{
    vector<string_view> pathComponents;
    vector<string_view> baseFilePathComponents;

    // Dependent on whether the final resolved path is absolute or relative
    // - if relative (when path and baseFilePath are both relative), resolvedPathPrefix remains empty
    // - if absolute (if either path or baseFilePath are absolute), resolvedPathPrefix is "C:\", "/", etc.
    string resolvedPathPrefix;
    bool isResolvedPathRelative = false;

    if (isAbsolutePath(path))
    {
        // path is absolute, we use path's prefix and ignore baseFilePath
        size_t afterPrefix = path.find_first_of("\\/") + 1;
        resolvedPathPrefix = path.substr(0, afterPrefix);
        pathComponents = splitPath(path.substr(afterPrefix));
    }
    else
    {
        size_t afterPrefix = baseFilePath.find_first_of("\\/") + 1;
        baseFilePathComponents = splitPath(baseFilePath.substr(afterPrefix));
        if (isAbsolutePath(baseFilePath))
        {
            // path is relative and baseFilePath is absolute, we use baseFilePath's prefix
            resolvedPathPrefix = baseFilePath.substr(0, afterPrefix);
        }
        else
        {
            // path and baseFilePath are both relative, we do not set a prefix (resolved path will be relative)
            isResolvedPathRelative = true;
        }
        pathComponents = splitPath(path);
    }

    // Remove filename from components
    if (!baseFilePathComponents.empty())
        baseFilePathComponents.pop_back();

    // Resolve the path by applying pathComponents to baseFilePathComponents
    int numPrependedParents = 0;
    for (string_view component : pathComponents)
    {
        if (component == "..")
        {
            if (baseFilePathComponents.empty())
            {
                if (isResolvedPathRelative)
                    numPrependedParents++;      // "../" will later be added to the beginning of the resolved path
            }
            else if (baseFilePathComponents.back() != "..")
            {
                baseFilePathComponents.pop_back(); // Resolve cases like "folder/subfolder/../../file" to "file"
            }
        }
        else if (component != "." && !component.empty())
        {
            baseFilePathComponents.push_back(component);
        }
    }

    // Create resolved path prefix for relative paths
    if (isResolvedPathRelative)
    {
        if (numPrependedParents > 0)
        {
            resolvedPathPrefix.reserve(numPrependedParents * 3);
            for (int i = 0; i < numPrependedParents; i++)
            {
                resolvedPathPrefix += "../";
            }
        }
        else
        {
            resolvedPathPrefix = "./";
        }
    }

    // Join baseFilePathComponents to form the resolved path
    string resolvedPath = resolvedPathPrefix;
    for (auto iter = baseFilePathComponents.begin(); iter != baseFilePathComponents.end(); ++iter)
    {
        if (iter != baseFilePathComponents.begin())
            resolvedPath += "/";

        resolvedPath += *iter;
    }
    if (resolvedPath.size() > resolvedPathPrefix.size() && resolvedPath.back() == '/')
    {
        // Remove trailing '/' if present
        resolvedPath.pop_back();
    }
    return resolvedPath;
}

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

static string get_error_message(lua_State* L, int status)
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

    return error;
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

static string run_file(lua_State* GL, string file)
{
    file = resolvePath(file, "");
    optional<string> source = read_file(file);
    if (!source)
        return "Could not open " + file;

    lua_State* L = lua_newthread(GL);
    luaL_sandboxthread(L);

    char* bytecode;
    size_t bytecodeSize = 0;
    bytecode = luau_compile(source->c_str(), source->length(), nullptr, &bytecodeSize);
    string chunkname = "=" + file;
    int result = luau_load(L, chunkname.c_str(), bytecode, bytecodeSize, 0);
    free(bytecode);

    // lua_pop(GL, 1);

    int status = 0;
    if (result == 0)
        status = lua_resume(L, nullptr, 0);
    else
        status = LUA_ERRSYNTAX;

    if (status != 0)
        return get_error_message(L, status);

    if (!lua_isfunction(L, -1))
        return "Luau script does not return a function";

    lua_pushcfunction(L, lua_lines, "lines");

    if ((status = lua_resume(L, nullptr, 1)) != 0)
        return get_error_message(L, status);

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

    lua_Debug ar;
    lua_getinfo(L, 1, "s", &ar);
    string sourcePath = ar.source;
    if (sourcePath.length() > 1 && sourcePath.at(0) == '=')
    {
        sourcePath.erase(0, 1);
        sourcePath = resolvePath(sourcePath, "");
        sourcePath = sourcePath.substr(0, sourcePath.find_last_of('/'));
        sourcePath += "/";
    }
    else
    {
        sourcePath = "";
    }
    // TODO: sourcePath needs to be normalized ("dir1/dir2/../dir3" -> "dir1/dir3")
    name = sourcePath + name + ".luau";
    name = resolvePath(name, "");

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

static const luaL_Reg global_funcs[] = {
    {"loadstring", lua_loadstring},
    {"require", lua_require},
    {nullptr, nullptr},
};

int main(int argc, char* argv[])
{
    if (argc < 2)
    {
        cerr << "Usage: " << argv[0] << " <script> <input>" << endl;
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

    lua_close(L);

    return 0;
}
