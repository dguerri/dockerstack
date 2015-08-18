## Build

    # Build "latest"  (docker caches FS layers, so don't use parallel builds)
    make all

    # Build version 1.0
    make all BUILD_VERSION=1.0

## Clean

    # Clean version 1.0 with 5 parallel processes
    make clean -j5 BUILD_VERSION=1.0

## Test

    # Test version 1.0 with 5 parallel processes
    make test -j5 BUILD_VERSION=1.0
