# Veil-specific ethash/progpow implementation copied from Veil core.
# DAG constants match the core:
#   full_dataset_init_size = 2 GB  (1<<31)
#   full_dataset_growth    = 12 MB (1<<23 | 1<<22) per epoch
#   ETHASH_EPOCH_LENGTH    = 5525  (before DAG-size-reduction height)
#   ETHASH_EPOCH_LENGTH_750MB_PER_YEAR = 8175 (after reduction height)

set(sources
    lib/ethash/ethash.cpp
    lib/ethash/managed.cpp
    lib/ethash/progpow.cpp
    lib/ethash/primes.c
    lib/keccak/keccak.c
    lib/keccak/keccakf1600.c
    lib/keccak/keccakf800.c
)

add_library(ethash-veil STATIC ${sources})

target_include_directories(ethash-veil
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/ethash
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/keccak
        ${CMAKE_CURRENT_SOURCE_DIR}/lib/support
)

set_target_properties(ethash-veil PROPERTIES
    C_STANDARD   11
    CXX_STANDARD 14
)

# Alias matching the Hunter package name so existing target_link_libraries
# calls (ethash::ethash) work without modification.
add_library(ethash::ethash ALIAS ethash-veil)
