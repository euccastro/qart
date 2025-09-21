#!/bin/bash
# Build SDL3 from source for static linking

set -e

SDL_VERSION="3.2.22"
SDL_DIR="third_party/SDL-release-${SDL_VERSION}"
SDL_BUILD_DIR="${SDL_DIR}/build"

# Create third_party directory if it doesn't exist
mkdir -p third_party

# Download SDL3 source if not already present
if [ ! -d "${SDL_DIR}" ]; then
    echo "Downloading SDL3 ${SDL_VERSION}..."
    cd third_party
    wget "https://github.com/libsdl-org/SDL/archive/refs/tags/release-${SDL_VERSION}.tar.gz"
    tar -xzf "release-${SDL_VERSION}.tar.gz"
    rm "release-${SDL_VERSION}.tar.gz"
    cd ..
fi

# Create build directory
mkdir -p "${SDL_BUILD_DIR}"

# Configure SDL3 with CMake for static linking
echo "Configuring SDL3 build..."
cd "${SDL_BUILD_DIR}"
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DSDL_SHARED=OFF \
    -DSDL_STATIC=ON \
    -DSDL_TEST=OFF \
    -DSDL_EXAMPLES=OFF

# Build SDL3
echo "Building SDL3..."
make -j$(nproc)

echo "SDL3 build complete!"
echo "Static library available at: ${SDL_BUILD_DIR}/libSDL3.a"
ls -lh "${SDL_BUILD_DIR}/libSDL3.a"