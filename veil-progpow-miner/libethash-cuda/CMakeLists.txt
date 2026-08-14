# A custom command and target to turn the CUDA kernel into a byte array header
# The normal build depends on it properly and if the kernel file is changed, then
# a rebuild of libethash-cuda should be triggered

add_custom_command(
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/CUDAMiner_kernel.h
	COMMAND ${CMAKE_COMMAND} ARGS
	-DTXT2STR_SOURCE_FILE="${CMAKE_CURRENT_SOURCE_DIR}/CUDAMiner_kernel.cu"
	-DTXT2STR_VARIABLE_NAME=CUDAMiner_kernel
	-DTXT2STR_HEADER_FILE="${CMAKE_CURRENT_BINARY_DIR}/CUDAMiner_kernel.h"
	-P "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/txt2str.cmake"
	COMMENT "Generating CUDA Kernel"
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/CUDAMiner_kernel.cu
)
add_custom_target(cuda_kernel DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/CUDAMiner_kernel.h ${CMAKE_CURRENT_SOURCE_DIR}/CUDAMiner_kernel.cu)

# CUDA is enabled as a first-class language by the root CMakeLists. The old
# find_package(CUDA)/cuda_add_library pair was removed in CMake 4.
find_package(CUDAToolkit REQUIRED)

if (CUDAToolkit_VERSION VERSION_LESS 11.0)
	message(FATAL_ERROR "CUDA 11.0 or newer is required (found ${CUDAToolkit_VERSION}). "
		"Blackwell (RTX 50-series, sm_120) additionally needs CUDA 12.8 or newer.")
endif()

# Which SASS to bake in. -DCOMPUTE=<nn> still pins a single arch.
#
# The list is trimmed to what the detected toolkit actually accepts: nvcc hard
# errors on an arch it has dropped, so an unfiltered list breaks the build
# rather than degrading. CUDA 13 removed Maxwell through Volta offline
# compilation; 12.8 is the first release that knows sm_120.
if (COMPUTE AND (COMPUTE GREATER 0))
	set(VEIL_CUDA_ARCHS ${COMPUTE})
else()
	set(VEIL_CUDA_ARCHS "")
	if (CUDAToolkit_VERSION VERSION_LESS 13.0)
		# Maxwell/Pascal/Volta. Still plenty of GTX 900/10-series on small-coin
		# networks, which is why CI pins 12.x rather than moving to 13.
		list(APPEND VEIL_CUDA_ARCHS 50 52 60 61 70)
	endif()
	list(APPEND VEIL_CUDA_ARCHS 75 80 86)          # Turing, Ampere
	if (NOT CUDAToolkit_VERSION VERSION_LESS 11.8)
		list(APPEND VEIL_CUDA_ARCHS 89 90)         # Ada, Hopper
	endif()
	if (NOT CUDAToolkit_VERSION VERSION_LESS 12.8)
		# Blackwell consumer (RTX 50-series). The -virtual entry keeps PTX in
		# the binary so anything newer can still JIT.
		list(APPEND VEIL_CUDA_ARCHS 120 120-virtual)
	endif()
endif()

message("-- CUDA Toolkit     ${CUDAToolkit_VERSION}")
message("-- CUDA archs       ${VEIL_CUDA_ARCHS}")
if (CUDAToolkit_VERSION VERSION_LESS 12.8 AND NOT COMPUTE)
	message(WARNING "CUDA ${CUDAToolkit_VERSION} cannot target Blackwell. "
		"RTX 50-series cards will fall back to runtime NVRTC compilation, which "
		"also needs 12.8+. Install CUDA 12.8 or newer to support them.")
endif()

file(GLOB sources CUDAMiner.cpp CUDAMiner_cuda.cu)
file(GLOB headers CUDAMiner.h CUDAMiner_cuda.h ${CMAKE_CURRENT_BINARY_DIR}/CUDAMiner_kernel.h)

add_library(ethash-cuda STATIC ${sources} ${headers})
add_dependencies(ethash-cuda cuda_kernel)

set_target_properties(ethash-cuda PROPERTIES
	CUDA_ARCHITECTURES "${VEIL_CUDA_ARCHS}"
	CUDA_STANDARD 17
	CUDA_STANDARD_REQUIRED ON)

target_compile_options(ethash-cuda PRIVATE
	$<$<COMPILE_LANGUAGE:CUDA>:--ptxas-options=-v>
	$<$<COMPILE_LANGUAGE:CUDA>:-lineinfo>
	$<$<COMPILE_LANGUAGE:CUDA>:-use_fast_math>
	# sm_50..sm_70 are deprecated on 12.x and say so on every file.
	$<$<COMPILE_LANGUAGE:CUDA>:-Wno-deprecated-gpu-targets>
	$<$<CONFIG:Release>:$<$<COMPILE_LANGUAGE:CUDA>:-O3>>
	$<$<CONFIG:Debug>:$<$<COMPILE_LANGUAGE:CUDA>:-G>>)

if (NOT MSVC)
	target_compile_options(ethash-cuda PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:--disable-warnings>)
endif()

target_link_libraries(ethash-cuda ethcore ethash::ethash progpow Boost::thread)
# The search kernel is compiled at runtime, so nvrtc and the driver API are
# both hard requirements rather than build-time conveniences.
target_link_libraries(ethash-cuda CUDA::nvrtc CUDA::cuda_driver)
target_include_directories(ethash-cuda PUBLIC ${CUDAToolkit_INCLUDE_DIRS})
target_include_directories(ethash-cuda PRIVATE .. ${CMAKE_CURRENT_BINARY_DIR})
