cmake_policy(SET CMP0015 NEW)

aux_source_directory(. SRC_LIST)

include_directories(BEFORE ..)

set(EXECUTABLE veilminer)

file(GLOB HEADERS "*.h")

add_executable(${EXECUTABLE} ${SRC_LIST} ${HEADERS})
if(MSVC)
	# Windows resource: the icon plus a VERSIONINFO block, configured from
	# veilminer.rc.in so the version tracks PROJECT_VERSION on its own.
	# FILEVERSION wants four plain numbers, so 1.1.3 becomes 1,1,3,0 and a
	# suffix such as rc1 is dropped from the numeric part.
	string(REGEX MATCH "^[0-9]+(\\.[0-9]+)*" _rc_version "${PROJECT_VERSION}")
	string(REPLACE "." ";" _rc_version "${_rc_version}")
	list(LENGTH _rc_version _rc_len)
	while(_rc_len LESS 4)
		list(APPEND _rc_version 0)
		list(LENGTH _rc_version _rc_len)
	endwhile()
	list(SUBLIST _rc_version 0 4 _rc_version)
	string(REPLACE ";" "," VEILMINER_RC_VERSION "${_rc_version}")
	configure_file(veilminer.rc.in ${CMAKE_CURRENT_BINARY_DIR}/veilminer.rc @ONLY)
	# rc.exe resolves the icon relative to the .rc it is compiling, and that
	# now lives in the build tree, so the icon goes next to it.
	configure_file(veilminer.ico ${CMAKE_CURRENT_BINARY_DIR}/veilminer.ico COPYONLY)
	target_sources(${EXECUTABLE} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/veilminer.rc)
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
