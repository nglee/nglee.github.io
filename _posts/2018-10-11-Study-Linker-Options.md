---
layout: post
title: "링커 옵션 분석"
published: true
comments: true
---

이 포스트에서는 정적 링커 `ld(1)` 가 제공하는 수많은 옵션들 중 라이브러리 배포 과정에서 참고하면 좋을 몇 가지 옵션들에 대해 분석해보겠습니다.

분석을 진행할 옵션들은 다음과 같습니다.

```
--as-needed
--no-as-needed

--no-undefined
--allow-shlib-undefined
--no-allow-shlib-undefined
```

분석에 사용되는 정적 링커 `ld(1)` 와 컴파일러 드라이버(compiler driver) `g++(1)` 의 버전은 다음과 같습니다.

```
$ ld -v
GNU ld (GNU Binutils for Ubuntu) 2.26.1
$ g++ --version
g++ (Ubuntu 5.4.0-6ubuntu1~16.04.10) 5.4.0 20160609
```

## --as-needed, --no-as-needed

`--as-needed` 옵션에 대한 `man page` 의 설명은 다음과 같습니다.

>This option affects ELF DT_NEEDED tags for dynamic libraries mentioned on the command line after the --as-needed option. Normally the linker will add a DT_NEEDED tag for each dynamic library mentioned on the command line, regardless of whether the library is actually needed or not. --as-needed causes a DT_NEEDED tag to only be emitted for a library that satisfies an undefined symbol reference from a regular object file or, if the library is not found in the DT_NEEDED lists of other libraries linked up to that point, an undefined symbol reference from another dynamic library. --no-as-needed restores the default behaviour.

즉, `-l` 옵션으로 명시된 라이브러리들은 실제 참조되지 않더라도 `DT_NEEDED` 태그로 명시하는 것이 `ld(1)` 의 기본 동작입니다. 만약 `--as-needed` 옵션을 사용하면 `-l` 옵션으로 명시된 라이브러리라도 실제 참조되지 않으면 `DT_NEEDED` 태그로 명시되지 않습니다.

그런데 다음 예제를 한 번 살펴봅시다. `sample1.cpp` 는 `pthread` 라이브러리를 사용하지 않지만 `g++(1)` 로 컴파일 시 `-Wl,--as-needed` 옵션 없이 `-lpthread` 옵션을 넘겨주기 때문에 `pthread` 라이브러리가 `DT_NEEDED` 태그로 명시되어야 할 것 같습니다.

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

`-Wl,--as-needed` 옵션이 없기 때문에 `-lpthread` 로 명시된 `pthread` 라이브러리가 `DT_NEEDED` 태그로 명시되어야 할 것 같은데 놀랍게도 누락되어 있습니다. 이유는 다음과 같이 컴파일 시 `-v` 옵션을 주면 알 수 있습니다.

> $ g++ -o sample1 sample1.cpp -lpthread -v
>
>    ...(중간 생략)...
>
> /usr/lib/gcc/x86_64-linux-gnu/5/**collect2** -plugin /usr/lib/gcc/x86_64-linux-gnu/5/liblto_plugin.so -plugin-opt=/usr/lib/gcc/x86_64-linux-gnu/5/lto-wrapper -plugin-opt=-fresolution=/tmp/ccEhEmXo.res -plugin-opt=-pass-through=-lgcc_s -plugin-opt=-pass-through=-lgcc -plugin-opt=-pass-through=-lc -plugin-opt=-pass-through=-lgcc_s -plugin-opt=-pass-through=-lgcc --sysroot=/ --build-id --eh-frame-hdr -m elf_x86_64 --hash-style=gnu ***--as-needed*** -dynamic-linker /lib64/ld-linux-x86-64.so.2 -z relro -o sample1 /usr/lib/gcc/x86_64-linux-gnu/5/../../../x86_64-linux-gnu/crt1.o /usr/lib/gcc/x86_64-linux-gnu/5/../../../x86_64-linux-gnu/crti.o /usr/lib/gcc/x86_64-linux-gnu/5/crtbegin.o -L/usr/lib/gcc/x86_64-linux-gnu/5 -L/usr/lib/gcc/x86_64-linux-gnu/5/../../../x86_64-linux-gnu -L/usr/lib/gcc/x86_64-linux-gnu/5/../../../../lib -L/lib/x86_64-linux-gnu -L/lib/../lib -L/usr/lib/x86_64-linux-gnu -L/usr/lib/../lib -L/usr/lib/gcc/x86_64-linux-gnu/5/../../.. /tmp/ccbK9uM1.o ***-lpthread*** -lstdc++ -lm -lgcc_s -lgcc -lc -lgcc_s -lgcc /usr/lib/gcc/x86_64-linux-gnu/5/crtend.o /usr/lib/gcc/x86_64-linux-gnu/5/../../../x86_64-linux-gnu/crtn.o


`collect2` 는 `GCC(GNU Compile Collection)` 에서 사용하는 링커에 대한 일종의 래퍼입니다. 여기서 `--as-needed` 옵션을 넘겨줌을 알 수 있습니다. 다음과 같이 컴파일 시 명시적으로 `--no-as-needed` 옵션을 넘겨주면, `pthread` 라이브러리 뿐만 아니라 `collect2` 가 기본으로 명시해주는 `stdc++`, `m`, `gcc_s` 등도 `DT_NEEDED` 로 명시되는 것을 알 수 있습니다.

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

정리하면, `ld(1)` 에 대한 `man page` 문서에는 `--no-as-needed` 옵션이 기본값이라고 설명되어 있지만 `g++(1)` 가 `collect2` 를 사용하게 되면서 `--as-needed` 옵션이 기본값이 되어버렸다고 할 수 있겠습니다.

## --no-undefined, --allow-shlib-undefined, --no-allow-shlib-undefined

이 옵션들은 링커의 입력으로 들어오는 object file(.o) 이나 shared object(.so) 에 unresolved symbol 이 있는 경우 링커가 어떻게 동작하는지 결정한다.

결론부터 얘기하면 링커가 생성해내는(= 링커가 출력하는) 파일이 executable 이냐, shared object(.so) 냐에 따라 다르다.

아무 옵션도 주어지지 않았을 때의 기본 동작은 다음과 같다.

|    linker output   | unresolved symbol in an object file(.o) | unresolved symbol in an shared object(.so) |
|:------------------:|:---------------------------------------:|:------------------------------------------:|
|     executable     |                 disallow                |                 disallow\*\*               |
| shared object(.so) |                  allow\*                |                   allow\*\*                |

`--no-undefined` 옵션을 사용하게 되면, 위의 표에서 \* 표시된 부분의 동작이 disallow 로 바뀌게 된다.

`--allow-shlib-undefined` 옵션을 사용하게 되면, 위의 표에서 \*\* 표시된 부분의 동작이 allow 로 바뀌게 된다.

`--no-allow-shlib-undefined` 옵션을 사용하게 되면, 위의 표에서 \*\* 표시된 부분의 동작이 disallow 로 바뀌게 된다.

먼저, object file (.o) 을 링커의 입력으로 받을 때 unresolved symbol 이 있을 경우, 링커가 executable 을 출력하는 경우와 shared object (.so) 를 출력하는 경우에 어떻게 동작하는지 비교해보자.

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

`main.cpp` 에는 함수 `f1` 에 대한 정의가 없다. 이 경우 `main` 이라는 executable 을 만들려고 할 경우 `undefined reference to 'f1()'` 라는 에러가 발생한다.

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

`f2.cpp` 에도 `main.cpp` 처럼 함수 `f1` 에 대한 정의가 없다. 그러나 `libf2.so` 라는 shared object (.so) 를 만들려고 할 경우 에러가 발생하지 않는다.

이 때 다음과 같이 `--no-undefined` 옵션을 넘겨주면, `undefined reference to 'f1()'` 라는 에러가 발생한다.

```
$ g++ -shared -o libf2.so -Wl,--no-undefined f2.o
f2.o: In function `f2()':
f2.cpp:(.text+0x5): undefined reference to `f1()'
collect2: error: ld returned 1 exit status
$
```

다음으로, shared object (.so) 를 링커의 입력으로 받을 때 unresolved symbol 이 있을 경우, 링커가 executable 을 출력하는 경우와 shared object (.so) 를 출력하는 경우에 어떻게 동작하는지 비교해보자.

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

먼저 위와 같이 shared object (.so) `libf2.so` 를 생성한다. 앞에서 보았듯이 obejct file `f2.o` 에 unresolved symbol 인 함수 `f1` 이 있지만 링커가 shared object 를 출력하는 경우 오류를 발생시키지 않는다.

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

위를 보면 `main2` 라는 executable 을 만드는데 unresolved symbol 을 포함하는 `libf2.so` 를 사용할 경우 `undefined reference to 'f1()'` 이라는 에러가 발생한다.

이 때 다음과 같이 `--allow-shlib-undefined` 옵션을 넘겨주면, 에러가 발생하지 않는다.

```
$ g++ -o main2 main2.o -L. -Wl,--allow-shlib-undefined -lf2
$
```

물론 이런 식으로 만들어진 executable 인 `main2` 를 다음과 같이 실행하려고 할 경우, `f1` 에 대한 unresolved reference 를 해결하기 전에는 다음과 같은 에러가 발생한다.

```
$ ./main2
./main2: symbol lookup error: libf2.so: undefined symbol: _Z2f1v
$
```

이번에는 shared object (.so) `libf2.so` 를 입력으로 받아서 또 다른 shared object (.so) 를 출력하는 경우를 생각해보자.

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

위와 같이 `libf2.so` 에 unresolved symbol 이 있지만 에러가 발생하지 않는다.

이 때 다음과 같이 `--no-allow-shlib-undefined` 옵션을 넘겨주면, 에러가 발생한다.

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
</table>
</div>
