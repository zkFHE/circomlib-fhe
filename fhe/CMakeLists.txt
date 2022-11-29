cmake_minimum_required(VERSION 3.20)

project(zkp-fhe LANGUAGES CXX)

# Library
find_package(SEAL 4.0 REQUIRED)

# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/depends")

# Benchmarks
add_executable(sec_agg)
target_sources(sec_agg PRIVATE ${CMAKE_CURRENT_LIST_DIR}/secure_aggregation.cpp)
target_link_libraries(sec_agg SEAL::seal)