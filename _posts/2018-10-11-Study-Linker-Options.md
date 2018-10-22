---
layout: post
title: "링커 옵션 분석"
published: true
comments: true
---

이 포스트에서는 링커 `ld(1)` 가 제공하는 수많은 옵션들 중 라이브러리 배포 과정에서 참고하면 좋을 몇 가지 옵션들에 대해 분석해보겠습니다.

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
</table>
</div>
