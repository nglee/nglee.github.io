---
layout: post
title: "Jetson TX1에 Swap 공간 설정하기"
comments: true
---

이 포스트에서는 **JetPack 3.1이 설치된 TX1에** swap 공간을 설정하는 방법을 설명하겠습니다. 리눅스 기반 시스템에 swap 공간을 설정하는 방법은 [여기](http://www.jetsonhacks.com/2016/12/21/jetson-tx1-swap-file-and-development-preparation/) [저기](https://jkjung-avt.github.io/swap-on-tx1/)서 쉽게 찾아볼 수 있습니다. 그런데 JetPack 3.1이 설치된 TX1에서 위 링크에서 소개하는 방법을 따라하다보면 `swapon` 명령어를 입력하는 단계에서 다음과 같은 에러 메시지를 볼 수 있습니다.

```
swapon failed: Function not implemented
```

JetPack 3.1을 설치하면 L4T(Linux for Tegra) 28.1이 설치되는데 여기에 포함된 커널이 swap 기능 없이 빌드되었기 때문에 위와 같은 에러가 발생하는 것입니다. 따라서 우리는 먼저 [swap 기능을 포함하여 커널을 다시 빌드하여야 합니다](https://devtalk.nvidia.com/default/topic/901380/tx1-swapon-failed-function-not-implemented/).

# 커널 빌드

먼저 JetPack 3.1을 설치합니다. [여기](https://github.com/jetsonhacks/buildJetsonTX1Kernel)에 커널 빌드 과정을 자동화한 스크립트가 공개되어 있는데 TX1에서 커널을 직접 빌드할 수 있게 만들어놓은 스크립트입니다. 이 스크립트를 작성한 분은 이 작업을 JetPack 3.1 설치 직후에, 시스템에 다른 조작을 하기 전에 먼저 진행할 것을 추천하고 있습니다.

**커널 빌드 과정에서 필요한 저장 공간은 2.5GB** 정도입니다. 기본으로 설치되어 있는 eMMC 이외에 다른 저장장치가 설치되어 있지 않은 경우 커널 빌드 과정에서 저장 공간 부족으로 에러가 발생할 수 있습니다. eMMC의 전체 용량이 16GB 뿐이기 때문입니다. 이 문제를 해결하기 위해 SD카드 또는 SSD 같은 추가 저장장치를 이용하거나 필요없는 파일들을 지워서 eMMC에 공간을 확보해야 합니다. JetPack 설치과정에서 복사되는 `.deb` 파일이나 CUDA 샘플과 같이 개인에 따라 필요하지 않은 파일들을 삭제하면 되겠습니다.

그럼 본격적으로 커널을 빌드해보겠습니다. 일단 위에서 소개한 깃헙 저장소를 복제(`git clone`)한 후 `getKernelSources.sh` 스크립트를 실행하겠습니다. 이 스크립트는 커널 소스를 다운 받고 qt 기반의 커널 configuration 창을 띄워주는 것까지 자동화 해줍니다.

```shell
$ git clone https://github.com/jetsonhacks/buildJetsonTX1Kernel
$ cd buildJetsonTX1Kernel/
$ sudo ./getKernelSources.sh
```

스크립트의 동작이 완료되면 `Linux/arm64 4.4.38 Kernel Configuration` 이라는 타이틀을 가진 창이 뜹니다.
여기서 `General setup` 항목의 하위 항목인 `Support for paging of anonymous memory (swap)` 항목을 활성화한 후 저장 버튼을 누릅니다. 이제 swap 기능을 포함하여 커널을 빌드하게 됩니다.

커널 configuration 창을 종료한 후 `makeKernel.sh` 스크립트를 실행하겠습니다. 이 스크립트는 TX1에서 커널 빌드가 가능하도록 `Makefile`에 `patch` 명령어를 이용하여 수정을 가한 후 커널 이미지를 빌드합니다. 소요시간은 약 17분 정도입니다.

```shell
$ sudo ./makeKernel.sh
```

빌드가 완료되면 빌드된 이미지를 `/boot` 디렉토리에 복사해야 합니다. 한 가지 주의해야 할 점은, 만약 [이 가이드](http://www.jetsonhacks.com/2017/01/28/install-samsung-ssd-on-nvidia-jetson-tx1/)를 참고하여 SSD를 설치했고 `/` 파일시스템을 SSD로 설정해 놓았다면, SSD의 `/boot` 디렉토리가 아니라 eMMC의 `/boot` 디렉토리에 복사해야 한다는 점입니다.

```shell
$ sudo cp /usr/src/kernel/kernel-4.4/arch/arm64/boot/Image /boot/Image
```

이제 TX1을 재시작하면 새로 빌드된 커널 이미지로 시스템이 동작하게 됩니다.

# Swap 공간 설정

[여기](https://github.com/jetsonhacks/postFlashTX1)에 swap 공간을 설정하는 스크립트가 공개되어 있습니다. 먼저 다음과 같이 스크립트를 다운로드 받습니다.

```shell
$ git clone https://github.com/jetsonhacks/postFlashTX1
$ cd postFlashTX1
```

다음의 명령어는 `$HOME` 디렉토리에 8GB 용량의 `swapfile`을 만들고 이 파일을 시스템의 swap 공간으로 등록합니다. `-a` 옵션은 automount를 의미하는데 시스템이 부팅할 때마다 자동으로 이 swap 공간을 사용하도록 `/etc/fstab`에 `swapfile`을 등록하는 옵션입니다.

```shell
$ sudo ./createSwapfile.sh -d $HOME -s 8 -a
```

이제 우분투의 `System Monitor` 어플리케이션을 실행하면 8GB 크기의 swap 공간이 만들어진 것을 볼 수 있을 것입니다. 혹은 JetPack 설치 과정에서 `$HOME` 디렉토리에 복사되는 `tegrastats` 파일을 실행해도 됩니다.

```shell
$ $HOME/tegrastats
```
---------------------------------------------------------------------------
#### ChangeLog
<table>
  <tr>
    <th>Version</th>
    <th>Description</th>
    <th>Date</th>
  </tr>
  <tr>
    <td class="td_center">0.1</td>
    <td>Draft</td>
    <td class="td_center">2017-12-15</td>
  </tr>
  <tr>
    <td class="td_center">1.0</td>
    <td>Publish</td>
    <td class="td_center">2017-12-18</td>
  </tr>
  <tr>
    <td class="td_center">1.1</td>
    <td>Refined</td>
    <td class="td_center">2017-12-22</td>
  </tr>
</table>
