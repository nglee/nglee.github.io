FROM ubuntu:18.04
LABEL maintainer "Namgoo Lee <devnglee@gmail.com>"

RUN apt update && apt install -y git g++ gfortran cmake curl wget unzip autoconf automake libtool libbz2-dev zlib1g-dev libzip-dev python-dev

ENV OPENBLAS_VERSION 0.3.6
ENV OPENBLAS_INSTALL_DIR /usr/local/openblas-$OPENBLAS_VERSION

RUN git clone -q --depth 1 -b v$OPENBLAS_VERSION https://github.com/xianyi/OpenBLAS.git && \
cd OpenBLAS && \
make TARGET=ARMV8 -j$(nproc) && \
make install TARGET=ARMV8 PREFIX=$OPENBLAS_INSTALL_DIR && \
cd ../ && \
rm -rf OpenBLAS

ENV CUB_VERSION 1.8.0
ENV CUB_INSTALL_DIR /usr/local/cub-$CUB_VERSION

RUN wget -q https://github.com/NVlabs/cub/archive/$CUB_VERSION.zip && \
unzip -q ./$CUB_VERSION.zip && \
cp -r cub-$CUB_VERSION $CUB_INSTALL_DIR && \
rm -rf $CUB_VERSION.zip && \
rm -rf cub-$CUB_VERSION

ENV PROTOBUF_VERSION 3.1.0
ENV PROTOBUF_INSTALL_DIR /usr/local/protobuf-$PROTOBUF_VERSION

RUN wget -q -O - https://github.com/google/protobuf/archive/v$PROTOBUF_VERSION.tar.gz | tar -xzf - && \
cd protobuf-$PROTOBUF_VERSION && \
./autogen.sh && \
./configure CFLAGS=-fPIC CXXFLAGS=-fPIC --disable-shared --prefix=$PROTOBUF_INSTALL_DIR && \
make install -j$(nproc) && \
cd ../ && \
rm -rf protobuf-$PROTOBUF_VERSION

ENV OPENCV_VERSION 3.4.6
ENV OPENCV_INSTALL_DIR /usr/local/opencv-$OPENCV_VERSION

RUN wget -q -O - https://github.com/opencv/opencv/archive/$OPENCV_VERSION.tar.gz | tar -xzf - && \
cd opencv-$OPENCV_VERSION && \
mkdir build/release -p && \
cd build/release && \
cmake -DWITH_CUDA=Off -DCMAKE_INSTALL_PREFIX=$OPENCV_INSTALL_DIR -DBUILD_TESTS=Off -DBUILD_PERF_TESTS=Off ../../ && \
make install -j$(nproc) && \
cd ../../../ && \
rm -rf opencv-$OPENCV_VERSION

ENV BOOST_VERSION 1.70.0
ENV BOOST_INSTALL_DIR /usr/local/boost-$BOOST_VERSION

RUN git clone -q --depth 1 -b boost-$BOOST_VERSION --recursive -j $(nproc) https://github.com/boostorg/boost.git && \
cd boost && \
./bootstrap.sh --prefix=$BOOST_INSTALL_DIR && \
./b2 -d0 -j$(nproc) cxxflags="-std=c++14 -fPIC" linkflags="-Wl,-rpath,'\$ORIGIN'" install && \
cd ../ && \
rm -rf boost

ENV OPENMPI_VERSION 1.10.3
ENV OPENMPI_INSTALL_DIR /usr/local/openmpi-$OPENMPI_VERSION

RUN wget -q -O - https://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-$OPENMPI_VERSION.tar.gz | tar -xzf - && \
cd openmpi-$OPENMPI_VERSION && \
./configure --prefix=$OPENMPI_INSTALL_DIR && \
make install -j$(nproc) && \
cd ../ && \
rm -rf openmpi-$OPENMPI_VERSION && \
export PATH=$OPENMPI_INSTALL_DIR/bin:\$PATH && \
export LD_LIBRARY_PATH=$OPENMPI_INSTALL_DIR/lib:\$LD_LIBRARY_PATH

RUN git clone -q -b v2.7 --recursive -j $(nproc) https://github.com/Microsoft/CNTK.git && \
cd CNTK && \
mkdir build/release -p && \
cd build/release && \
../../configure --asgd=no \
                --with-openblas=$OPENBLAS_INSTALL_DIR \
                --with-protobuf=$PROTOBUF_INSTALL_DIR \
                --with-opencv=$OPENCV_INSTALL_DIR \
                --with-boost=$BOOST_INSTALL_DIR \
                --with-mpi=$OPENMPI_INSTALL_DIR && \
make -C ../../ \
	BUILD_TOP=$PWD \
	SSE_FLAGS='' \
        all \
	-j$(nproc)

ENV CNTK_INSTALL_DIR /root/CNTK_2.7_CPU
ENV CNTK_INSTALL_BIN_DIR $CNTK_INSTALL_DIR/bin
ENV CNTK_INSTALL_LIB_DIR $CNTK_INSTALL_DIR/lib
ENV CNTK_INSTALL_INC_DIR $CNTK_INSTALL_DIR/include

RUN mkdir $CNTK_INSTALL_DIR && \
ln -s /CNTK/build/release/bin $CNTK_INSTALL_BIN_DIR && \
ln -s /CNTK/build/release/lib $CNTK_INSTALL_LIB_DIR && \
ln -s /CNTK/Source/CNTKv2LibraryDll/API $CNTK_INSTALL_INC_DIR && \
echo "export PATH=$CNTK_INSTALL_BIN_DIR:\$PATH" >> ~/.bashrc && \
echo $CNTK_INSTALL_LIB_DIR >> /etc/ld.so.conf.d/cntk.conf && \
ldconfig
