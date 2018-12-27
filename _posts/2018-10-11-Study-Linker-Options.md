---
layout: post
title: "라이브러리 배포 과정에서 알아두면 좋을 링커 옵션"
published: true
comments: true
---

이 포스트에서는 링커 `ld(1)` 가 제공하는 수많은 옵션들 중 라이브러리 배포 과정에서 요긴하게 활용할 수 있는 몇 가지 옵션들에 대해 알아보겠습니다.

다음은 분석을 진행할 옵션들의 목록입니다.

**링커 명령(linker command line)에 입력으로 주어진 모든 shared object(.so) 를 `DT_NEEDED` 태그로 명시할지, 아니면 실제 사용되는 shared object(.so) 만 명시할지 지정하는 옵션들:**
```
--as-needed
--no-as-needed
```

**링커 명령(linker command line)에 입력으로 주어진 object file(.o) 이나 shared object(.so) 에 unresolved symbol 이 있을 경우 오류 발생 여부를 지정하는 옵션들:**
```
--no-undefined
--allow-shlib-undefined
--no-allow-shlib-undefined
```

**라이브러리 이차 종속 문제, 다시 말해 링커 명령(linker command line)에 입력으로 주어진 shared object(.so) 가 의존하는 라이브러리의 위치를 명시할 때 사용하는 옵션들:**
```
--rpath-link
--rpath
--enable-new-dtags
```

분석에 사용되는 링커 `ld(1)` 와 컴파일러 드라이버(compiler driver) `g++(1)` 의 버전은 다음과 같습니다.

```
$ ld -v
GNU ld (GNU Binutils for Ubuntu) 2.26.1
$ g++ --version
g++ (Ubuntu 5.4.0-6ubuntu1~16.04.10) 5.4.0 20160609
```

----------------------------------------------------------

## 첫 번째

**링커 명령(linker command line)에 입력으로 주어진 모든 shared object(.so) 를 `DT_NEEDED` 태그로 명시할지, 아니면 실제 사용되는 shared object(.so) 만 명시할지 지정하는 옵션들:**
```
--as-needed
--no-as-needed
```

[`--as-needed` 옵션에 대한 `man page` 의 설명](http://man7.org/linux/man-pages/man1/ld.1.html)에 따르면 `-l` 옵션으로 명시된 라이브러리들은 실제 참조되지 않더라도 `DT_NEEDED` 태그로 명시하는 것이 `ld(1)` 의 기본 동작입니다. 이 때 만약 `--as-needed` 옵션을 사용하면 `-l` 옵션으로 명시된 라이브러리라도 실제 참조되지 않을 경우 `DT_NEEDED` 태그로 명시되지 않습니다.

그런데 다음 예제를 한 번 살펴봅시다. `sample1.cpp` 는 `pthread` 라이브러리를 사용하지 않지만 `g++(1)` 로 컴파일 시 `-Wl,--as-needed` 옵션 없이 `-lpthread` 옵션을 넘겨주기 때문에 `libpthread.so` 가 `DT_NEEDED` 태그로 명시되어야 할 것 같습니다.

```
$ cat sample1.cpp
int main()
{
  return 0;
}
$ g++ -o sample1 sample1.cpp -lpthread
$ readelf -d sample1 | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
$
```

`DT_NEEDED` 태그로 명시되어야 할 것 같았던 `libpthread.so` 가 놀랍게도 누락되어 있습니다. 이유는 다음과 같이 `-v` 옵션을 주어서 컴파일 명령을 실행해보면 알 수 있습니다.

```
$ g++ -o sample1 sample1.cpp -lpthread -v

   ...(중간 생략)...

/usr/lib/gcc/x86_64-linux-gnu/5/collect2

   ...(중간 생략)...

   --as-needed

   ...(중간 생략)...

   -lpthread -lstdc++ -lm -lgcc_s -lgcc -lc

   ...(이하 생략)...
$
```

[`collect2` 는 `GCC(GNU Compile Collection)` 에서 링커를 직접 부르는 대신에 사용하는 일종의 래퍼](https://gcc.gnu.org/onlinedocs/gccint/Collect2.html)입니다. 여기서 `--as-needed` 옵션을 자동으로 넘겨줌을 알 수 있습니다.

반대로, 다음과 같이 컴파일 시 명시적으로 `--no-as-needed` 옵션을 넘겨주면, `libpthread.so` 뿐만 아니라 `collect2` 가 기본으로 넘겨주는 `libstdc++.so`, `libm.so`, `libgcc_s.so` 등도 `DT_NEEDED` 로 명시되는 것을 알 수 있습니다.

```
$ g++ -o sample1 sample1.cpp -Wl,--no-as-needed -lpthread
$ readelf -d sample1 | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libpthread.so.0]
 0x0000000000000001 (NEEDED)             Shared library: [libstdc++.so.6]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so.6]
 0x0000000000000001 (NEEDED)             Shared library: [libgcc_s.so.1]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
$
```

정리하면, `ld(1)` 에 대한 `man page` 문서에는 `--no-as-needed` 옵션이 기본값이라고 설명되어 있지만 `g++(1)` 가 `collect2` 를 사용하면서 `--as-needed` 옵션이 기본값이 되어버렸다고 할 수 있겠습니다.

----------------------------------------------------------

## 두 번째

**링커 명령(linker command line)에 입력으로 주어진 object file(.o) 이나 shared object(.so) 에 unresolved symbol 이 있을 경우 오류 발생 여부를 지정하는 옵션들:**
```
--no-undefined
--allow-shlib-undefined
--no-allow-shlib-undefined
```

입력에 unresolved symbol 이 있을 경우 링커가 생성해내는(= 링커가 출력하는) 파일이 executable 이냐, 아니면 shared object(.so) 냐에 따라 오류 발생 여부가 다릅니다.

먼저 아무 옵션도 주어지지 않았을 때의 기본 동작은 다음과 같습니다.

|    linker output   | unresolved symbol in an object file(.o) | unresolved symbol in an shared object(.so) |
|:------------------:|:---------------------------------------:|:------------------------------------------:|
|     executable     |                 disallow                |                 disallow\*\*               |
| shared object(.so) |                  allow\*                |                   allow\*\*                |

`--no-undefined` 옵션을 사용하게 되면, 위의 표에서 \* 표시된 부분의 동작이 disallow 로 바뀌게 됩니다.

`--allow-shlib-undefined` 옵션을 사용하게 되면, 위의 표에서 \*\* 표시된 부분의 동작이 allow 로 바뀌게 됩니다.

`--no-allow-shlib-undefined` 옵션을 사용하게 되면, 위의 표에서 \*\* 표시된 부분의 동작이 disallow 로 바뀌게 됩니다.

먼저, object file(.o) 을 링커의 입력으로 받을 때 unresolved symbol 이 있을 경우, 링커가 executable 을 출력하는 경우와 shared object(.so) 를 출력하는 경우에 각각 어떻게 동작하는지 비교해보겠습니다.

```
$ cat main.cpp
extern void f1();

int main()
{
    f1();
}
$ g++ -c main.cpp
$ g++ -o main main.o
main.o: In function `main':
main.cpp:(.text+0x5): undefined reference to `f1()'
collect2: error: ld returned 1 exit status
$
```

`main.cpp` 에는 함수 `f1` 에 대한 정의가 없습니다. 이 경우 `main` 이라는 executable 을 만들려고 할 경우 위와 같이 `undefined reference to 'f1()'` 이라는 에러가 발생합니다.

```
$ cat f2.cpp
extern void f1();

void f2()
{
    f1();
}
$ g++ -c -fPIC f2.cpp
$ g++ -shared -o libf2.so f2.o
$
```

`f2.cpp` 에도 `main.cpp` 처럼 함수 `f1` 에 대한 정의가 없습니다. 그러나 `libf2.so` 라는 shared object(.so) 를 만들려고 할 경우 위와 같이 에러가 발생하지 않습니다.

여기서 다음과 같이 `--no-undefined` 옵션을 넘겨주면, executable 을 만들려고 할 때와 같이 `undefined reference to 'f1()'` 이라는 에러가 발생합니다.

```
$ g++ -shared -o libf2.so -Wl,--no-undefined f2.o
f2.o: In function `f2()':
f2.cpp:(.text+0x5): undefined reference to `f1()'
collect2: error: ld returned 1 exit status
$
```

다음으로, shared object(.so) 를 링커의 입력으로 받을 때 unresolved symbol 이 있을 경우, 링커가 executable 을 출력하는 경우와 shared object(.so) 를 출력하는 경우에 각각 어떻게 동작하는지 비교해보겠습니다.

```
$ cat f2.cpp
extern void f1();

void f2()
{
    f1();
}
$ g++ -c -fPIC f2.cpp
$ g++ -shared -o libf2.so f2.o
```

먼저 위와 같이 shared object(.so) `libf2.so` 를 생성합니다. 앞에서 보았듯이 object file `f2.o` 에 unresolved symbol 인 함수 `f1` 이 있지만 링커가 shared object 를 출력하는 경우 오류를 발생시키지 않습니다.

```
$ cat main2.cpp
extern void f2();

int main()
{
    f2();
}
$ g++ -c main2.cpp
$ g++ -o main2 main2.o -L. -lf2
./libf2.so: undefined reference to `f1()'
collect2: error: ld returned 1 exit status
$
```

위를 보면 `main2` 라는 executable 을 만드는데 unresolved symbol 을 포함하는 `libf2.so` 를 링커 입력으로 넘겨줄 경우 `undefined reference to 'f1()'` 이라는 에러가 발생합니다.

여기서 다음과 같이 `--allow-shlib-undefined` 옵션을 넘겨주면, 에러가 발생하지 않습니다.

```
$ g++ -o main2 main2.o -L. -Wl,--allow-shlib-undefined -lf2
$
```

물론 이런 식으로 만들어진 executable 인 `main2` 를 실행하려고 할 경우, `f1` 에 대한 unresolved reference 를 해결하기 전에는 다음과 같은 에러가 발생합니다.

```
$ ./main2
./main2: symbol lookup error: libf2.so: undefined symbol: _Z2f1v
$
```

`f1` 에 대한 unresolved reference 를 해결하려면 다음과 같이 `LD_PRELOAD` 환경변수를 사용하는 방법이 있습니다.

```
$ cat f1.cpp
void f1() { }
$ g++ -shared -o libf1.so -fPIC f1.cpp
$ LD_PRELOAD=libf1.so ./main2
$
```

이번에는 shared object(.so) `libf2.so` 를 입력으로 받아서 또 다른 shared object(.so) 를 출력하는 경우를 살펴보겠습니다.

```
$ cat f3.cpp
extern void f2();

void f3()
{
    f2();
}
$ g++ -c -fPIC f3.cpp
$ g++ -shared -o libf3.so f3.o -L. -lf2
$
```

위와 같이 `libf2.so` 에 unresolved symbol 이 있지만 에러가 발생하지 않습니다.

여기서 다음과 같이 `--no-allow-shlib-undefined` 옵션을 넘겨주면, `undefined reference to 'f1()'` 이라는 에러가 발생합니다.

```
$ g++ -shared -o libf3.so f3.o -L. -Wl,--no-allow-shlib-undefined -lf2
./libf2.so: undefined reference to `f1()'
collect2: error: ld returned 1 exit status
$
```
----------------------------------------------------------

## 세 번째

**라이브러리 이차 종속 문제, 다시 말해 링커 명령(linker command line)에 입력으로 주어진 shared object(.so) 가 의존하는 라이브러리의 위치를 명시할 때 사용하는 옵션들:**
```
--rpath-link
--rpath
--enable-new-dtags
```

이차 종속 라이브러리란 일차 종속 라이브러리가 참조하는 라이브러리입니다. 일차 종속 라이브러리는 링커가 생성해내는 파일(executable, 혹은 shared object)이 직접 참조하는 라이브러리를 가리킵니다.

일차 종속 라이브러리들은 `-l` 옵션이나 실제 라이브러리 이름으로 링커 명령에 명시되어야 합니다.

이차 종속 라이브러리들의 경우, 그 라이브러리들을 참조하는 일차 종속 라이브러리들이 `DT_RPATH` 나 `DT_RUNPATH` 를 통해 이차 종속 라이브러리들이 위치한 곳을 잘 명시해 놓았기를 바라는 것이 좋지만, 그렇지 않을 경우 `--rpath-link` 옵션이나 `--rpath` 옵션으로 이차 종속 라이브러리가 위치한 디렉토리를 명시하는 것이 좋습니다.

`--rpath-link` 옵션과 `--rpath` 옵션은 이차 종속 라이브러리가 위치한 디렉토리를 명시한다는 점에서 공통된 기능을 갖고 있습니다. 두 옵션의 차이점으로는 두 가지가 있습니다. 첫 번째 차이점은 `--rpath-link` 옵션과 `--rpath` 옵션이 둘 다 사용되었을 때, `--rpath-link` 옵션에 명시된 디렉토리가 `--rpath` 옵션에 명시된 디렉토리보다 더 높은 우선순위로 탐색된다는 것입니다. 두 번째 차이점은 `--rpath` 의 경우 링커가 출력하는 executable 이나 shared object 의 `DT_RPATH` 에 `--rpath` 옵션으로 명시된 디렉토리가 추가된다는 것입니다. `--rpath-link` 옵션은 `DT_RPATH` 에 디렉토리를 추가하지 않습니다. 또한, 이 때 `--enable-new-dtags` 옵션을 사용하면 `DT_RPATH` 가 아닌 `DT_RUNPATH` 를 사용하여 명시하게 됩니다. `DT_RPATH` 와 `DT_RUNPATH` 의 차이점은 [`ld.so(8)` 에 대한 `man page` 의 설명](http://man7.org/linux/man-pages/man8/ld.so.8.html)에 자세히 설명되어 있고 잠시 후에 다시 정리하겠습니다.

그런데 2.28 이전 버전의 `ld(1)` 에 버그가 하나 있습니다. `DT_RPATH` 에 명시된 `$ORIGIN` 키워드를 해석하지 못하는 버그입니다.

```
$ ls -F
f1/  f2/  main.cpp                            # f1 과 f2 는 디렉토리임을 알 수 있습니다
$ ls f1
f1.cpp                                        # f1 디렉토리 밑에 f1.cpp 가 있습니다
$ ls f2
f2.cpp                                        # f2 디렉토리 밑에 f2.cpp 가 있습니다
$ cat main.cpp
extern void f1();

int main()
{
        f1();                                 # main.cpp 는 외부에서 정의된 함수 f1 을 참조합니다
}
$ cat f1/f1.cpp
extern void f2();

void f1()                                     # 함수 f1 은 f1/f1.cpp 에 정의되어 있습니다
{
        f2();                                 # f1/f1.cpp 는 외부에서 정의된 함수 f2 를 참조합니다
}
$ cat f2/f2.cpp
void f2() {}                                  # 함수 f2 는 f2/f2.cpp 에 정의되어 있습니다.
$ g++ -shared -o f2/libf2.so -fPIC f2/f2.cpp  # f2.cpp 가 포함된 libf2.so 를 f2 디렉토리 밑에 생성합니다.
$ g++ -shared -o f1/libf1.so -fPIC f1/f1.cpp -Lf2 -lf2 -Wl,--rpath,'$ORIGIN/../f2'                  # f1.cpp 가 포함된 libf1.so 를 f1 디렉토리 밑에 생성합니다
                                                                                                    # 이 때 --rpath 옵션을 이용하여 libf1.so 의 DT_RPATH 에
                                                                                                    # libf2.so 가 위치한 f2 디렉토리가 명시될 수 있도록 합니다
                                                                                                    # f2 디렉토리를 명시할 때 $ORIGIN 키워드를 이용합니다
$ readelf -d f1/libf1.so | egrep "(NEEDED)|(RPATH)"
 0x0000000000000001 (NEEDED)             Shared library: [libf2.so]                                 # DT_NEEDED 에 libf1.so 가 참조하는 libf2.so 가 명시되어 있고
 0x000000000000000f (RPATH)              Library rpath: [$ORIGIN/../f2]                             # DT_RPATH 에 libf2.so 가 위치한 f2 디렉토리가 명시되어 있습니다
$ g++ -o main main.cpp -Lf1 -lf1 -Wl,--rpath,f1                                                     # ld 가 libf1.so 의 DT_RPATH 를 참고하여 libf2.so 를 찾기를 기대합니다
/usr/bin/ld: warning: libf2.so, needed by f1/libf1.so, not found (try using -rpath or -rpath-link)  # 하지만 libf2.so 를 찾을 수 없다고 불평을 합니다
f1/libf1.so: undefined reference to `f2()'
collect2: error: ld returned 1 exit status
$ ld -v                                       # ld 버전을 출력해봅니다
GNU ld (GNU Binutils for Ubuntu) 2.26.1       # 2.26.1 버전을 사용함을 알 수 있는데 2.28 이전 버전을 사용하고 있으므로 해당 버그가 존재함을 알 수 있습니다
$
```

이 버그는 알려진 버그로 이미 [여기](https://sourceware.org/bugzilla/show_bug.cgi?id=16936)와 [여기](https://sourceware.org/bugzilla/show_bug.cgi?id=20535)에 보고가 되어 있고 2.28 버전에서 픽스되었습니다.

우분투 16.04 의 경우 `g++ 5.4.0`, `ld 2.26.1` 이 기본 버전입니다.  
우분투 17.04 의 경우 `g++ 6.3.0`, `ld 2.28` 이 기본 버전입니다.  
우분투 18.04 의 경우 `g++ 7.3.0`, `ld 2.30` 이 기본 버전입니다.  
테스트 환경이 우분투 16.04 여서 버그가 존재하는 링커 버전이 이용되었던 것입니다.

버그가 픽스된 2.28 버전을 다운 받아서 위의 경우에 적용해보도록 하겠습니다. 먼저 2.28 버전을 다운 받아 컴파일한 후 `g++(1)` 이 새 버전의 `ld(1)` 를 이용하도록 설정하는 방법을 소개하겠습니다.

```
$ wget http://ftp.gnu.org/gnu/binutils/binutils-2.28.tar.gz
$ tar xzf binutils-2.28.tar.gz
$ cd binutils-2.28
$ ./configure
$ make -j12
$ ./ld/ld-new -v                            # ld-new 라는 이름으로 빌드됩니다
GNU ld (GNU Binutils) 2.28
$ which ld
/usr/bin/ld                                 # 현재 사용하는 ld 가 /usr/bin 디렉토리에 위치함을 알 수 있습니다
$ ls -F /usr/bin/ld
/usr/bin/ld@                                # /usr/bin/ld 는 링크 파일임을 알 수 있습니다
$ sudo ln -sf ${PWD}/ld/ld-new /usr/bin/ld  # /usr/bin/ld 가 새로 빌드한 링커를 가리키도록 합니다
$ ld -v                                     # ld 버전을 출력해서 제대로 설정되었는지 확인합니다
GNU ld (GNU Binutils) 2.28                  # 2.28 버전의 ld 를 사용하고 있음을 알 수 있습니다
$ cd ../
$
```

이제 다음과 같이 오류가 해결되었음을 알 수 있습니다.

```
$ g++ -o main main.cpp -Lf1 -lf1 -Wl,--rpath,f1
$ ./main
$
```

참고로 [`ld(1)` 에 대한 `man page` 의 설명](http://man7.org/linux/man-pages/man1/ld.1.html)에 따르면 `ld(1)` 는 다음의 순서로 이차 종속 라이브러리를 탐색합니다.

1. `--rpath-link` 로 명시된 디렉토리
2. `--rpath` 로 명시된 디렉토리
3. ELF 시스템에서 크로스 컴파일을 하는 경우가 아닐 때, `--rpath-link` 와 `--rpath` 옵션이 사옹되지 않았다면, `LD_RUN_PATH` 환경변수에 명시된 디렉토리
4. SunOS 에서, `--rpath` 옵션이 사용되지 않았다면, `-L` 옵션에 명시된 디렉토리
5. 크로스 컴파일을 하는 경우가 아닐 때, `LD_LIBRARY_PATH` 환경변수에 명시된 디렉토리
6. ELF 시스템에서 크로스 컴파일을 하는 경우가 아닐 때, 일차 종속 라이브러리의 `DT_RPATH` 나 `DT_RUNPATH` 에 명시된 디렉토리 (`DT_RUNPATH` 항목이 존재하면 `DT_RPATH` 항목은 무시됨)
7. `/lib`, `/usr/lib`
8. ELF 시스템에서 크로스 컴파일을 하는 경우가 아닐 때, `/etc/ld.so.conf` 에 명시된 디렉토리

마지막으로 [`ld.so(8)` 에 대한 `man page` 의 설명](http://man7.org/linux/man-pages/man8/ld.so.8.html)에 설명되어 있는 `ld.so(8)` 의 라이브러리 탐색 순서를 설명합니다. `DT_RPATH` 와 `DT_RUNPATH` 의 차이점에 대한 설명도 포함되어 있습니다.

1. `DT_RPATH` 에 명시된 디렉토리. 단, `DT_RUNPATH` 가 없어야 한다.
2. `LD_LIBRARY_PATH` 환경 변수에 명시된 디렉토리. 단, secure-execution 모드에서는 무시된다.
3. `DT_RUNPATH` 에 명시된 디렉토리. `DT_RUNPATH` 는 `DT_NEEDED` 에 명시된 라이브러리(= 직접적으로 종속된 라이브러리)를 찾는 데만 이용되고 그 라이브러리의 이차 종속 라이브러리를 찾는 데는 이용되지 않는다. 이와는 다르게 `DT_RPATH` 의 경우 n차 종속 라이브러리를 찾는 데 모두 이용될 수 있다.
4. `/etc/ld.so.cache`. 단, `-z nodeflib` 옵션이 포함되어 만들어진 실행파일이라면 `/lib` 와 `/usr/lib` 에 있는 라이브러리들은 무시된다.
5. `/lib`, `/usr/lib`. 단, `-z nodeflib` 옵션이 포함되어 만들어진 실행파일이라면 무시된다.

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
    <td class="td_center">2018-10-11</td>
  </tr>
  <tr>
    <td class="td_center">1.1</td>
    <td>Added --no-undefined, --allow-shlib-undefined, --no-allow-shlib-undefined</td>
    <td class="td_center">2018-10-22</td>
  </tr>
  <tr>
    <td class="td_center">1.2</td>
    <td>Mentioned LD_PRELOAD</td>
    <td class="td_center">2018-10-22</td>
  </tr>
  <tr>
    <td class="td_center">1.3</td>
    <td>Added --rpath-link, --rpath, --enable-new-dtags</td>
    <td class="td_center">2018-12-21</td>
  </tr>
  <tr>
    <td class="td_center">1.4</td>
    <td>More writings on --rpath-link, --rpath, --enable-new-dtags</td>
    <td class="td_center">2018-12-27</td>
  </tr>
</table>
</div>
