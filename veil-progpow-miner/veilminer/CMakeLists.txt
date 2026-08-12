cmake_policy(SET CMP0015 NEW)

aux_source_directory(. SRC_LIST)

include_directories(BEFORE ..)

set(EXECUTABLE veilminer)

file(GLOB HEADERS "*.h")

add_executable(${EXECUTABLE} ${SRC_LIST} ${HEADERS})
if(MSVC)
	target_sources(${EXECUTABLE} PRIVATE veilminer.rc)
endif()

# Use bundled CLI11 v1.9.1 header — system CLI11 is v2.x with incompatible API
add_library(CLI11_bundled INTERFACE)
target_include_directories(CLI11_bundled INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(veilminer PRIVATE ethcore poolprotocols devcore veilminer-buildinfo CLI11_bundled Boost::system)

if(ETHDBUS)
	find_package(PkgConfig)
	set( ENV{PKG_CONFIG_PATH} "$ENV{PKG_CONFIG_PATH}:/usr/lib/x86_64-linux-gnu/pkgconfig" )
	pkg_check_modules(DBUS dbus-1)
	include_directories(${DBUS_INCLUDE_DIRS})
	link_directories(${DBUS_LIBRARY_DIRS})
	target_link_libraries(veilminer PRIVATE ${DBUS_LIBRARIES})
endif()

if(APICORE)
	target_link_libraries(veilminer PRIVATE apicore)
endif()

include(GNUInstallDirs)
install(TARGETS veilminer DESTINATION ${CMAKE_INSTALL_BINDIR})
if(MSVC)
    install(FILES $<TARGET_PDB_FILE:veilminer> DESTINATION ${CMAKE_INSTALL_BINDIR} OPTIONAL)
endif()
