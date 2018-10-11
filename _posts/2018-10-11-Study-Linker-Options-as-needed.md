---
layout: post
title: "링커 옵션 탐구 : --as-needed"
published: true
comments: true
---

분석에 사용되는 정적 링커 `ld(1)` 와 `g++(1)` 는 다음과 같습니다.

```
$ ld -v
GNU ld (GNU Binutils for Ubuntu) 2.26.1
$ g++ --version
g++ (Ubuntu 5.4.0-6ubuntu1~16.04.10) 5.4.0 20160609
```

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
</table>
</div>
