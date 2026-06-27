cmake_minimum_required(VERSION 3.20)
project(hello_service CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find the userver package installed by the userver-nix wrapper.
# Only the core feature is required for this service.
find_package(userver COMPONENTS core REQUIRED)

# Shared object library used by the service (and tests, if added later).
add_library(${PROJECT_NAME}_objs OBJECT
    src/say_hello.hpp
    src/say_hello.cpp
    src/hello_handler.hpp
    src/hello_handler.cpp
)
target_link_libraries(${PROJECT_NAME}_objs PUBLIC userver::core)
target_include_directories(${PROJECT_NAME}_objs PUBLIC src)

# The service executable.
add_executable(${PROJECT_NAME} src/main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_objs)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
install(FILES configs/static_config.yaml
        DESTINATION share/${PROJECT_NAME})
