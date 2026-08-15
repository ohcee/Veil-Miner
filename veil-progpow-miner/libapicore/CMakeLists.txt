set(SOURCES
    ApiServer.h ApiServer.cpp
)

add_library(apicore ${SOURCES})
target_link_libraries(apicore PRIVATE ethcore devcore veilminer-buildinfo Boost::filesystem veil_jsoncpp)
target_include_directories(apicore PRIVATE ..)
