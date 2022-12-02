cmake_minimum_required(VERSION 3.16)
project(zkp-fhe LANGUAGES CXX)

# Library
# set(CMAKE_PREFIX_PATH /home/ubuntu/seal)
find_package(SEAL 4.0 REQUIRED)

# Benchmarks
add_executable(benchTiny)
target_sources(benchTiny PRIVATE ${CMAKE_CURRENT_LIST_DIR}/bench_tiny.cpp)

add_executable(benchSmall)
target_sources(benchSmall PRIVATE ${CMAKE_CURRENT_LIST_DIR}/bench_small.cpp)

add_executable(benchMedium)
target_sources(benchMedium PRIVATE ${CMAKE_CURRENT_LIST_DIR}/bench_medium.cpp)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(benchMedium PRIVATE Threads::Threads)
target_link_libraries(benchSmall PRIVATE Threads::Threads)

add_compile_options(-pthread)

if (TARGET SEAL::seal)
    target_link_libraries(benchTiny PUBLIC SEAL::seal)
    target_link_libraries(benchSmall PUBLIC SEAL::seal)
    target_link_libraries(benchMedium PUBLIC SEAL::seal)
elseif (TARGET SEAL::seal_shared)
    target_link_libraries(benchTiny PUBLIC SEAL::seal_shared)
    target_link_libraries(benchSmall PUBLIC SEAL::seal_shared)
    target_link_libraries(benchMedium PUBLIC SEAL::seal_shared)
else ()
    message(FATAL_ERROR "Cannot find target SEAL::seal or SEAL::seal_shared")
endif ()

add_executable(microBenchRinocchio)
target_sources(microBenchRinocchio PRIVATE ${CMAKE_CURRENT_LIST_DIR}/microbench_rinocchio.cpp)
target_link_libraries(microBenchRinocchio SEAL::seal)

