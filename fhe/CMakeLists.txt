cmake_minimum_required(VERSION 3.20)

project(zkp-fhe LANGUAGES CXX)

# Library
find_package(SEAL 4.0 REQUIRED)

# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/depends")

# Benchmarks
add_executable(benchSmall)
target_sources(benchSmall PRIVATE ${CMAKE_CURRENT_LIST_DIR}/bench_small.cpp)
target_link_libraries(benchSmall SEAL::seal)

add_executable(benchMedium)
target_sources(benchMedium PRIVATE ${CMAKE_CURRENT_LIST_DIR}/bench_medium.cpp)
target_link_libraries(benchMedium SEAL::seal)

add_executable(microBenchRinocchio)
target_sources(microBenchRinocchio PRIVATE ${CMAKE_CURRENT_LIST_DIR}/microbench_rinocchio.cpp)
target_link_libraries(microBenchRinocchio SEAL::seal)

