---
layout: post
title: "여러가지 DL 라이브러리를 도커(Docker)에서 세팅해보기"
published: true
comments: true
---


## Build MXNet 1.4.1 with C++ API on Ubuntu 16.04 with CUDA 10.1 & cuDNN7.5.1

##### 1. Run a New Docker Container

```
docker run --runtime=nvidia -dit --name mxnet nvidia/cuda:10.1-cudnn7-devel-ubuntu16.04 bash
docker exec -it mxnet bash
```

##### 2. Install Dependencies via apt

```
apt update && apt install -y vim git cmake cpio libopenblas-dev liblapack-dev graphviz
```

##### 3. Install OpenCV 3.4.6

```
cd
git clone https://github.com/opencv/opencv
cd opencv
git checkout 3.4.6
mkdir build && cd build
cmake -DBUILD_TESTS=Off -DBUILD_PERF_TESTS=Off ../
make -j$(nproc) install
```

##### 4. Install Python

```
# We'll just install Anaconda, downloadable from
# https://www.anaconda.com/distribution/#download-section
# with following options "Linux, Python3.7, Anaconda3-2019.03-Linux-x86_64.sh"
docker cp Anaconda3-2019.03-Linux-x86_64.sh mxnet:/root
bash Anaconda3-2019.03-Linux-x86_64.sh
```

##### 5. Build MXNet

```
cd
git clone https://github.com/apache/incubator-mxnet mxnet
cd mxnet
git checkout 1.4.1
git submodule update --recursive --init
mkdir build && cd build
cmake -DUSE_CUDA=1 -DUSE_CUDNN=1 -DUSE_MKLDNN=1 -DUSE_CPP_PACKAGE=1 ../
make -j$(nproc)
```

##### Reference

```
https://mxnet.apache.org/versions/master/install/build_from_source.html
https://mxnet.apache.org/versions/master/install/c_plus_plus.html
```


## Convert CNTK Model to ONNX Model
Going to build `CNTK 2.7` CPU only version. `CNTK 2.7` supports `ONNX 1.4.1`.

##### Download Anaconda

```
https://www.anaconda.com/distribution/#download-section
Linux, Python3.7, Anaconda3-2019.03-Linux-x86_64.sh
```

##### Run a New Docker Container and Install Anaconda

```
docker run -dit --name cntk2onnx ubuntu:16.04 bash
docker cp Anaconda3-2019.03-Linux-x86_64.sh cntk2onnx:/root
docker exec -it cntk2onnx bash

apt update && apt install -y openmpi-bin bzip2
cd && bash Anaconda3-2019.03-Linux-x86_64.sh

exit
docker exec -it cntk2onnx bash
```

#### Create Anaconda Environment and Install CNTK via pip

```
conda create --name cntk-py36 python=3.6
conda activate cntk-py36
pip install https://cntk.ai/PythonWheel/CPU-Only/cntk-2.7-cp36-cp36m-linux_x86_64.whl
```

To confirm that `CNTK 2.7` is properly installed, run:

```
LD_LIBRARY_PATH=/root/anaconda3/envs/cntk-py36/lib python -c "import cntk; print(cntk.__version__)"
```

#### Convert a CNTK Model to ONNX Model

```
LD_LIBRARY_PATH=/root/anaconda3/envs/cntk-py36/lib python -c "import cntk; cntk.Function.load('model0.model').save('model0.onnx',format=cntk.ModelFormat.ONNX)"
```


## Install "tensorflow-onnx"

##### Download Anaconda

```
https://www.anaconda.com/distribution/#download-section
Linux, Python3.7, Anaconda3-2019.03-Linux-x86_64.sh
```

##### Run a New Docker Container and Install Anaconda

```
docker run -dit --name onnx2tf ubuntu:16.04 bash
docker cp Anaconda3-2019.03-Linux-x86_64.sh onnx2tf:/root
docker exec -it onnx2tf bash

apt update && apt install -y bzip2
cd && bash Anaconda3-2019.03-Linux-x86_64.sh

exit
docker exec -it onnx2tf bash
```

##### Install TensorFlow via pip

```
pip install tensorflow==1.13.1
```

##### Install ONNX

```
apt install -y git cmake g++ protobuf-compiler libprotoc-dev
git clone https://github.com/onnx/onnx.git
cd onnx
git checkout v1.4.1
git submodule update --init --recursive
export ONNX_ML=1
python setup.py install
```

##### Install tensorflow-onnx

```
cd 
git clone https://github.com/onnx/tensorflow-onnx
cd tensorflow-onnx
git checkout v1.4.1
python setup.py install
```

----------
<a href="javascript:showChangeLog();">Show ChangeLog</a>
<div id="post_changelog" style="display:none;">
<table>
  <tr>
    <th>Version</th>
    <th>Description</th>
    <th>Date</th>
  </tr>
  <tr>
    <td class="td_center">1.0</td>
    <td>Publish</td>
    <td class="td_center">2019-05-21</td>
  </tr>
</table>
</div>