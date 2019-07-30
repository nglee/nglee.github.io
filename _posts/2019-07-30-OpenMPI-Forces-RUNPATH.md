---
layout: post
title: "OpenMPI는 RUNPATH 사용을 강제한다"
published: true
comments: true
---

```
$ cat foo.cpp
void foo()
{
}
$ cat main.cpp
void foo();
int main()
{
    foo();
}
$ g++ -shared -o libfoo.so -fPIC foo.cpp
$ g++ -o main main.cpp -L. -lfoo -Wl,-rpath,'$ORIGIN'
$ readelf -d main | egrep "RPATH|RUNPATH"
 0x000000000000000f (RPATH)              Library rpath: [$ORIGIN]
$
```

여기까지는 예상대로다. `--enable-new-dtags` 없으면 `RUNPATH`가 아니라 `RPATH`가 사용된다.

이제 `g++` 대신 `mpic++`를 사용해보자.

```
$ mpic++ -o main main.cpp -L. -lfoo -Wl,-rpath,'$ORIGIN'
$ readelf -d main | egrep "RPATH|RUNPATH"
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN:/usr/local/mpi/lib]
$
```

놀랍게도 `--enable-new-dtags`를 사용하지 않아도 `RPATH`가 아니라 `RUNPATH`가 사용되고 있다. 이는 `--disable-new-dtags` 옵션을 주어도 마찬가지다. 다음을 보자.

```
$ mpic++ -o main main.cpp -L. -lfoo -Wl,-rpath,'$ORIGIN' -Wl,--disable-new-dtags
$ readelf -d main | egrep "RPATH|RUNPATH"
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN:/usr/local/mpi/lib]
$
```

[이 포스트](https://github.com/open-mpi/ompi/issues/6539)를 통해 `mpic++`에 `--showme` 라는 옵션이 있다는 것을 알게 되었다.

```
$ mpic++ --showme
g++ -I/usr/local/mpi/include -pthread -Wl,-rpath -Wl,/usr/local/mpi/lib -Wl,--enable-new-dtags -L/usr/local/mpi/lib -lmpi_cxx -lmpi
$
```

`mpic++`이 `--enable-new-dtags`를 기본으로 넘겨줌을 알 수 있다. 다음과 같이 `--disable-new-dtags`를 명시해도 `--enable-new-dtags`가  사용된다.

```
$ mpic++ -o main main.cpp -L. -lfoo -Wl,-rpath,'$ORIGIN' -Wl,--disable-new-dtags --showme
g++ -o main main.cpp -L. -lfoo -Wl,-rpath,$ORIGIN -Wl,--disable-new-dtags -I/usr/local/mpi/include -pthread -Wl,-rpath -Wl,/usr/local/mpi/lib -Wl,--enable-new-dtags -L/usr/local/mpi/lib -lmpi_cxx -lmpi
$
```

이건 추측이지만, `RUNPATH`가 있으면 `RPATH`가 무용지물이기 때문에 `--disable-new-dtags`와 `--enable-new-dtags`가 동시에 명시되면 `--disable-new-dtags`는 무시되는 것이 아닐까 한다.

사용한 프로그램과 OS 버전은 다음과 같다.

```
OpenMPI : 1.10.3
g++     : 5.4.0
Ubuntu  : 16.04
```

해결책은 `OpenMPI`를 빌드할 때 `configure`에 `--disable-wrapper-runpath`를 넘기는 것이다.

그러나 이 옵션은 [이 커밋](https://github.com/open-mpi/ompi/commit/ebb30c15f2a3808a51c94bf7e0f382ba096ade2f)에서 추가가 된 것으로 보이고, 이 커밋은 1.10.3 버전에 반영되지 않은 것 같다. (1.10.3 버전의 `README`에 해당 내용이 언급되지 않았다.) 3.1.0 버전부터 도입된 듯 하다.

[여기](https://www.bountysource.com/issues/27909090-need-ability-to-not-use-enable-new-dtags-option-in-linker-scripts)에 따르면 다음과 같은 해법도 있는 듯 하다.

>Removing all references of --enable-new-dtags in the /share/openmpi/share/openmpi/*-wrapper-data.txt files solves the issue in that rpathing is still possible and --enable-new-dtags is no longer used when linking, but that has to be done after make install. It would be nice to be able to specify this at Open MPI's build time.


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
    <td class="td_center">2019-07-30</td>
  </tr>
</table>
</div>
