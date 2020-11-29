cmake_minimum_required(VERSION 3.18)
project(MyProject VERSION 1.0.0)

include_directories(include)
file(GLOB_RECURSE SOURCES "src/*".cpp)

add_executable(main ${SOURCES})
