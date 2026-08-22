cmake_minimum_required(VERSION 3.16)

include(cmake/cable/bootstrap.cmake)

include(CableBuildInfo)
include(CableBuildType)
include(CableToolchains)

cable_configure_toolchain(DEFAULT cxx11)
cable_set_build_type(DEFAULT Release CONFIGURATION_TYPES Release RelWithDebInfo)

project(veilminer)
set(PROJECT_VERSION 1.1.3)

option(ETHASHCL "Build with OpenCL mining" ON)
option(ETHASHCUDA "Build with CUDA mining" ON)
# On Apple Silicon, CUDA/OpenCL are unavailable; default to CPU mining
if (APPLE AND (CMAKE_SYSTEM_PROCESSOR MATCHES "arm64" OR CMAKE_OSX_ARCHITECTURES MATCHES "arm64"))
    set(ETHASHCL OFF CACHE BOOL "Build with OpenCL mining" FORCE)
    set(ETHASHCUDA OFF CACHE BOOL "Build with CUDA mining" FORCE)
    option(ETHASHCPU "Build with CPU mining" ON)
else()
    option(ETHASHCPU "Build with CPU mining (only for development)" OFF)
endif()
option(ETHDBUS "Build with D-Bus support" OFF)
option(APICORE "Build with API Server support" ON)
option(DEVBUILD "Log developer metrics" OFF)
# Vendor jsoncpp and link it statically so a binary keeps working after the
# system copy bumps its soname. Turn this off to link the system jsoncpp
# through pkg-config instead.
option(SYSTEM_JSONCPP "Link the system jsoncpp instead of the vendored copy" OFF)

# propagates CMake configuration options to the compiler
function(configureProject)
	if (ETHASHCL)
		add_definitions(-DETH_ETHASHCL)
	endif()
	if (ETHASHCUDA)
		add_definitions(-DETH_ETHASHCUDA)
	endif()
	if (ETHASHCPU)
		add_definitions(-DETH_ETHASHCPU)
	endif()
	if (ETHDBUS)
		add_definitions(-DETH_DBUS)
	endif()
	if (APICORE)
		add_definitions(-DAPI_CORE)
	endif()
	if (DEVBUILD)
		add_definitions(-DDEV_BUILD)
	endif()
endfunction()

# On macOS, boost@1.85 is keg-only and not on the default search path.
# Auto-detect the Homebrew prefix so brew patch bumps don't break the build,
# and leave BOOST_ROOT unset elsewhere (Linux/Windows use system/vcpkg Boost).
if (APPLE)
    execute_process(
        COMMAND brew --prefix boost@1.85
        OUTPUT_VARIABLE BREW_BOOST_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
    if (BREW_BOOST_PREFIX AND EXISTS "${BREW_BOOST_PREFIX}")
        set(BOOST_ROOT "${BREW_BOOST_PREFIX}")
    endif()
    # Homebrew ships .a alongside .dylib for both of these. Prefer the archives
    # so the binary survives a brew upgrade that bumps a soname.
    set(Boost_USE_STATIC_LIBS ON)
    set(OPENSSL_USE_STATIC_LIBS ON)
endif()
find_package(Boost REQUIRED COMPONENTS system filesystem thread)

if (SYSTEM_JSONCPP)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(JSONCPP REQUIRED jsoncpp)
    add_library(veil_jsoncpp INTERFACE)
    target_include_directories(veil_jsoncpp INTERFACE ${JSONCPP_INCLUDE_DIRS})
    target_link_libraries(veil_jsoncpp INTERFACE ${JSONCPP_LINK_LIBRARIES})
    # Make <json/json.h> resolvable globally (jsoncpp installs under include/json/)
    include_directories(${JSONCPP_INCLUDE_DIRS})
else()
    include(FetchContent)
    set(JSONCPP_WITH_TESTS OFF CACHE BOOL "" FORCE)
    set(JSONCPP_WITH_POST_BUILD_UNITTEST OFF CACHE BOOL "" FORCE)
    set(JSONCPP_WITH_PKGCONFIG_SUPPORT OFF CACHE BOOL "" FORCE)
    set(JSONCPP_WITH_CMAKE_PACKAGE OFF CACHE BOOL "" FORCE)
    set(JSONCPP_WITH_EXAMPLE OFF CACHE BOOL "" FORCE)
    set(JSONCPP_STATIC_WINDOWS_RUNTIME OFF CACHE BOOL "" FORCE)
    set(BUILD_OBJECT_LIBS OFF CACHE BOOL "" FORCE)
    set(BUILD_STATIC_LIBS ON CACHE BOOL "" FORCE)
    # jsoncpp keys its library type off BUILD_SHARED_LIBS. Force it off for the
    # subproject only, then put the caller's value back.
    set(VEIL_SAVED_BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS})
    set(BUILD_SHARED_LIBS OFF)
    # jsoncpp 1.9.x declares a cmake_minimum_required below what CMake 4 accepts.
    set(CMAKE_POLICY_VERSION_MINIMUM 3.16)
    FetchContent_Declare(jsoncpp
        GIT_REPOSITORY https://github.com/open-source-parsers/jsoncpp.git
        GIT_TAG 1.9.6
        GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(jsoncpp)
    unset(CMAKE_POLICY_VERSION_MINIMUM)
    set(BUILD_SHARED_LIBS ${VEIL_SAVED_BUILD_SHARED_LIBS})
    add_library(veil_jsoncpp INTERFACE)
    target_link_libraries(veil_jsoncpp INTERFACE jsoncpp_static)
    include_directories(${jsoncpp_SOURCE_DIR}/include)
endif()

find_package(OpenSSL REQUIRED)
include_directories(${OPENSSL_INCLUDE_DIR})

configureProject()

# CUDA has to be a real language for CMake to drive nvcc. FindCUDA and
# cuda_add_library, which this used to rely on, are gone as of CMake 4.
if (ETHASHCUDA)
	enable_language(CUDA)
endif()

message("----------------------------------------------------------------------------")
message("-- CMake ${CMAKE_VERSION}")
message("-- Build ${CMAKE_BUILD_TYPE} / ${CMAKE_SYSTEM_NAME}")
message("----------------------------------------------------------------- components")
message("-- ETHASHCL         Build OpenCL components                      ${ETHASHCL}")
message("-- ETHASHCUDA       Build CUDA components                        ${ETHASHCUDA}")
message("-- ETHASHCPU        Build CPU components                         ${ETHASHCPU}")
message("-- ETHDBUS          Build D-Bus components                       ${ETHDBUS}")
message("-- APICORE          Build API Server components                  ${APICORE}")
message("-- DEVBUILD         Build with dev logging                       ${DEVBUILD}")
message("-- SYSTEM_JSONCPP   Link system jsoncpp (else vendored static)   ${SYSTEM_JSONCPP}")
message("----------------------------------------------------------------------------")
message("")

include(EthCompilerSettings)
if(UNIX AND NOT APPLE)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++")
endif()


cable_add_buildinfo_library(PROJECT_NAME ${PROJECT_NAME})

add_subdirectory(libethash-veil)
add_subdirectory(libprogpow)
add_subdirectory(libdevcore)
add_subdirectory(libethcore)
add_subdirectory(libhwmon)
add_subdirectory(libpoolprotocols)

if (ETHASHCL)
	add_subdirectory(libethash-cl)
endif ()
if (ETHASHCUDA)
	add_subdirectory(libethash-cuda)
endif ()
if (ETHASHCPU)
	add_subdirectory(libethash-cpu)
endif ()
if (APICORE)
	add_subdirectory(libapicore)
endif()

add_subdirectory(veilminer)


if(WIN32)
	set(CPACK_GENERATOR ZIP)
else()
	set(CPACK_GENERATOR TGZ)
endif()
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_CHECKSUM SHA256)
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY FALSE)
include(CPack)
