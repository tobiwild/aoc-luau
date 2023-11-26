cmake_minimum_required(VERSION 3.13)
project(AocLuau)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include_directories(
    ./luau/VM/include
    ./luau/Compiler/include
)

link_directories(
    ./luau/build/release
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(solve solve.cpp)

target_link_libraries(solve PRIVATE luauvm luaucompiler luauast)
