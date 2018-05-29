---
layout: post
title: "Hacking OpenCV (Eng)"
comments: true
---

This post will show a subtle bug in OpenCV. In this post, version 3.4.1, which is the latest released version at the time of writing, is used.

<script src="https://gist.github.com/nglee/1c5a6f0ff711915dd47a6fb96c1a5ae0.js"></script>

Let's look at the code above. Between line 23 and line 29, there are no codes that modify the value of `GpuMat d2`. Therefore, two identical images should be displayed on windows `out1` and `out2`. However, different images are displayed on those windows as shown below.

![2018-05-29-Hacking-OpenCV.png]({{ "/assets/2018-05-29-Hacking-OpenCV.png" | absolute_url }})

This is a bug [reported](https://github.com/opencv/opencv/issues/11606) to the upstream OpenCV repository.

Try out yourself:

```shell
$ wget https://github.com/nglee/opencv_test/releases/download/hacking-opencv/hacking-opencv.tar.gz
$ tar xzf hacking-opencv.tar.gz
$ cd hacking-opencv
$ make
$ ./opencv_hack
```

The OpenCV 3.4.1 library used in the source was built on Ubuntu 16.04:

```shell
$ wget https://github.com/opencv/opencv/archive/3.4.1.tar.gz
$ tar -xzf 3.4.1.tar.gz
$ cd opencv-3.4.1
$ mkdir build/install -p && cd build
$ cmake ../ -DCMAKE_INSTALL_PREFIX=/home/nglee/Workspace/opencv-3.4.1/build/install -DWITH_CUDA=on -DCUDA_ARCH_BIN=5.0 -DBUILD_JAVA=off -DBUILD_PERF_TESTS=off -DBUILD_TESTS=off -DBUILD_PACKAGE=off -DBUILD_opencv_cudaarithm=off -DBUILD_opencv_cudabgsegm=off -DBUILD_opencv_cudacodec=off -DBUILD_opencv_cudafeatures2d=off -DBUILD_opencv_cudafilters=off -DBUILD_opencv_cudaimgproc=off -DBUILD_opencv_cudalegacy=off -DBUILD_opencv_cudastereo=off -DBUILD_opencv_cudawarping=off -DBUILD_opencv_java_bindings_generator=off -DBUILD_opencv_python_bindings_generator=off
$ make -j 7 && make install
```

The original test image is from Pixabay.

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
    <td class="td_center">2018-05-29</td>
  </tr>
</table>
</div>

