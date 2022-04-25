cmake_minimum_required(VERSION 3.17)
project(soos C)

set(CMAKE_C_STANDARD 99)

add_executable(soos main.c Day01/HelloWorld.c Day01/main.c)