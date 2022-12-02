cmake_minimum_required(VERSION 3.16)
project(zkp-fhe LANGUAGES CXX)

# Library
# set(CMAKE_PREFIX_PATH /home/ubuntu/seal)
find_package(SEAL 4.0 REQUIRED)

# Benchmarks
add_executable(sec_agg)
target_sources(sec_agg PRIVATE ${CMAKE_CURRENT_LIST_DIR}/secure_aggregation.cpp)
#target_link_libraries(sec_agg SEAL::seal)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(sec_agg PRIVATE Threads::Threads)


add_compile_options(-pthread)

if(TARGET SEAL::seal)
	target_link_libraries(sec_agg PUBLIC SEAL::seal)
elseif(TARGET SEAL::seal_shared)
	target_link_libraries(sec_agg PUBLIC SEAL::seal_shared)
else()
    message(FATAL_ERROR "Cannot find target SEAL::seal or SEAL::seal_shared")
endif()
