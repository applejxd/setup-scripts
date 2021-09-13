#!/bin/sh

if [ $# -eq 0 ]; then
    # Save Password
    read -sp "Password: " password
else
    password=$1
fi

################
# Dependencies #
################

# CMake
echo "$password" | sudo -S apt install -y cmake
# google-glog + gflags
echo "$password" | sudo -S apt install -y libgoogle-glog-dev libgflags-dev
# BLAS & LAPACK
echo "$password" | sudo -S apt install -y libatlas-base-dev
# Eigen3
echo "$password" | sudo -S apt install -y libeigen3-dev
# SuiteSparse and CXSparse (optional)
echo "$password" | sudo -S apt install -y libsuitesparse-dev

##########
# Eigen3 #
##########

git clone https://gitlab.com/libeigen/eigen.git
cd eigen
mkdir build
cd build
cmake ..
cd ../../

#######
# NDK #
#######

wget https://dl.google.com/android/repository/android-ndk-r23-linux.zip
unzip android-ndk-r23-linux.zip
rm android-ndk-r23-linux.zip

################
# Ceres-Solver #
################

wget https://github.com/ceres-solver/ceres-solver.git
cd ceres-solver
mkdir build
cd build
cmake \
-DBUILD_SHARED_LIBS=OFF \
-DCMAKE_TOOLCHAIN_FILE=../../android-ndk-r23/build/cmake/android.toolchain.cmake \
-DEigen3_DIR=../../eigen/build/Eigen3Config.cmake \
-DANDROID_ABI=arm64-v8a \
-DANDROID_STL=c++_shared \
-DANDROID_NATIVE_API_LEVEL=android-29 \
-DBUILD_SHARED_LIBS=OFF \
-DMINIGLOG=ON \
..
cmake \
-DBUILD_SHARED_LIBS=OFF \
-DCMAKE_TOOLCHAIN_FILE=../../android-ndk-r23/build/cmake/android.toolchain.cmake \
-DEigen3_DIR=../../eigen/build/Eigen3Config.cmake \
-DANDROID_ABI=arm64-v8a \
-DANDROID_STL=c++_shared \
-DANDROID_NATIVE_API_LEVEL=android-29 \
-DBUILD_SHARED_LIBS=OFF \
-DMINIGLOG=ON \
..
make -j3