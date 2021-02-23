cmake_minimum_required(VERSION 3.18)
set (CMAKE_CXX_STANDARD 17)

file(GLOB SOURCE
     "*.hpp"
     "*.cpp"
)

add_executable(timetable ${SOURCE})

