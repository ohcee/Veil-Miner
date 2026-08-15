set(SOURCES
	PoolURI.cpp PoolURI.h
	PoolClient.h
	PoolManager.h PoolManager.cpp
	testing/SimulateClient.h testing/SimulateClient.cpp
	stratum/EthStratumClient.h stratum/EthStratumClient.cpp
	stratum/utilstrencodings.h stratum/utilstrencodings.cpp
	stratum/uint256.h stratum/uint256.cpp
	stratum/arith_uint256.h stratum/arith_uint256.cpp
	getwork/EthGetworkClient.h getwork/EthGetworkClient.cpp
)

find_package(OpenSSL REQUIRED)

add_library(poolprotocols ${SOURCES})
target_link_libraries(poolprotocols PRIVATE devcore veilminer-buildinfo ethash::ethash Boost::system veil_jsoncpp OpenSSL::SSL OpenSSL::Crypto)
if(WIN32)
	# EthStratumClient reads the Windows certificate store for TLS root CAs
	target_link_libraries(poolprotocols PRIVATE crypt32)
endif()
target_include_directories(poolprotocols PRIVATE ..)
