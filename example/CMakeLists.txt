cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

# Normally you would add the cmake subdirectory here
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")
include(ResourceLibrary)

project(Example)

add_executable(Example example.cpp)

# You can add as many files as you want. File names should either be relative
# to the current list dir, but can also be absolute paths. The name for the
# resource library must be a valid name for a directory and a C++ namespace.
add_resource_library(ExampleResourceLibrary STATIC example.txt)
target_link_libraries(Example ExampleResourceLibrary)
