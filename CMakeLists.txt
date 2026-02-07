cmake_minimum_required(VERSION 3.13)
project(ash)

# Force static linking for llama.cpp libraries
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)

include(CheckLanguage)
check_language(CUDA)

if(CMAKE_CUDA_COMPILER)
    message(STATUS "CUDA detected, enabling GGML_CUDA")
    set(GGML_CUDA ON CACHE BOOL "Use CUDA" FORCE)
else()
    message(STATUS "CUDA not detected, disabling GGML_CUDA")
    set(GGML_CUDA OFF CACHE BOOL "Use CUDA" FORCE)
endif()

set(LLAMA_CURL ON CACHE BOOL "Use cURL" FORCE)
set(LLAMA_BUILD_SERVER ON CACHE BOOL "Build server" FORCE)
set(LLAMA_BUILD_COMMON ON CACHE BOOL "Build common" FORCE)
add_subdirectory(llama.cpp)

find_package(CURL REQUIRED)

add_executable(ash src/main.cpp)

target_include_directories(ash PRIVATE llama.cpp)

target_link_libraries(ash llama CURL::libcurl)
