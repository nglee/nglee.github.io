---
layout: post
title: "Boost.Interprocess 객체의 인스턴스는 언제 해제되는가?"
comments: true
---

C++ 프로그램에서 프로세스 간 통신(IPC, Inter-Process Communication)을 위해 `boost::interprocess`에서 제공하는 객체(Object)들을 사용하게 되었습니다. 프로세스 간 공유 메모리(Inter-Process shared memory)나 프로세스 간 뮤텍스(Inter-Process Mutex)를 사용하려고 하다보니, 자연스럽게 다음과 같은 의문점이 생겼습니다.

"어떤 프로세스가 내부적으로 할당하여 그 프로세스만 사용하게 될 자원들은 그 프로세스가 종료되는 순간 자동으로 반환된다. 명시적으로 자원을 반환하는 코드가 없더라도 운영체제 수준에서 이것을 처리한다. 그렇다면, 프로세스 간 통신을 위해 공유 메모리에 할당된 자원은 언제 반환되는가? 다시 말해서, 공유 메모리에 생성된 객체의 인스턴스는 언제 해제되는가(destructed)?"

자원을 명시적으로 해제할 경우 당연히 그 자원은 반환될 것입니다. 그러나 자원을 명시적으로 해제하지 않는다면 어떻게 될까요? 시스템을 재부팅해야 자원이 해제가 될까요? 아니면 재부팅하지 않더라도 그 자원을 사용했던 프로세스들이 종료되면 자동으로 해제가 될까요? `boost::interprocess` 관련 문서를 뒤적인 결과 다음과 같은 [항목](https://www.boost.org/doc/libs/1_71_0/doc/html/interprocess/some_basic_explanations.html#interprocess.some_basic_explanations.persistence)을 발견할 수 있었습니다. 원문은 영어로 되어있고 의역하면 다음과 같습니다.

> **프로세스 간 통신에 사용되는 자원들은 언제까지 지속되는가**
>
> 프로세스 간 통신에 사용되는 자원들에 대한 중요한 이슈 중 하나는 그 자원들의 지속시간이다. 어떤 자원이 언제 시스템에서 사라지는지를 아는 것은 매우 중요하다. Boost.Interprocess에서 제공하는 자원들은 다음과 같이 세 가지 경우로 나뉜다:
> * 프로세스 수준 지속: 어떤 공유 자원을 사용(open)한 모든 프로세스들이 그 자원을 더 이상 사용하지 않게 되거나(close) 정상종료(exit)되거나 비정상종료(crash)될 때까지 유지된다.
> * 커널 수준 지속: 운영체제의 커널이 재시작(reboot)되거나 자원이 명시적으로 삭제(delete)될 때까지 유지된다.
> * 파일시스템 수준 지속: 자원이 명시적으로 삭제(delete)될 때까지 유지된다.

각각의 수준에 대해 매우 잘 정리되어 있음을 알 수 있습니다. 위의 내용을 토대로 제게 필요했던 기능은 **프로세스 수준 지속**을 지원하는 자원이라는 것도 명확하게 판단할 수 있었습니다. 하지만 문제는, `boost::interprocess`가 제공하는 자원들이 위 세가지 중 어디에 속하는지가 명확히 정리되어 있지 않았다는 점입니다. 그래서 테스트 코드를 직접 짜 보면서 실험을 해보기로 했습니다. `boost::interprocess`에서 제공하는 모든 종류의 자원을 테스트해보지는 못했고, 제가 확인이 필요했던 것들만 테스트해보았습니다. 이 포스트에서 테스트해보지 못한 다른 종류의 자원들도 이 포스트에서 소개하는 방식과 동일하게 테스트해볼 수 있을 것입니다.

## managed_xsi_shared_memory : 커널 수준 지속

이 공유 메모리는 리눅스에서만 사용할 수 있습니다. 리눅스에서 진행되었던 모든 테스트는 Ubuntu 18.04(g++ 7.5.0), x86_64 환경에서 진행되었습니다. Boost 버전은 1.71.0 을 사용하였고, `/usr/local/boost-1.71.0`에 설치되었다고 가정하였습니다.

<script src="https://gist.github.com/nglee/5892c346d26f9282160581e7fde4d3cf.js"></script>

위 테스트코드에서는 공유 자원을 해제하는 과정을 고의적으로 생략하였습니다. 자원을 명시적으로 해제하지 않고 프로세스를 종료시켰을 때 자원이 자동으로 해제되는지(즉, **프로세스 수준 지속**인지) 확인해보고 싶은 것입니다.

```
$ g++ bitest1.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest1
$ ./bitest1
shared memory created
$ ./bitest1
File exists
shared memory creation failed, opened instead
$
```

위와 같이 프로세스가 종료되었음에도 자원이 해제되지 않는 것을 보니 일단 프로세스 수준 지속은 아님을 알 수 있습니다. 그런데 이 상태로 재부팅하고 나면 다음과 같음을 볼 수 있습니다.

```
$ ./bitest1
shared memory created
$
```

따라서 `managed_xsi_shared_memory` 인스턴스의 경우 커널이 재시작 하고 나서 자원이 해재된 것을 보니 **커널 수준 지속**임을 알 수 있습니다.

(참고로, 생성된 공유 메모리를 파일 시스템을 통해 접근할 수 있는지 알아보려면 man shm_overview 문서의 Accessing shared memory objects via the filesystem 항목을 보면 될 것 같습니다.)

## managed_windows_shared_memory : 프로세스 수준 지속

이 공유 메모리는 윈도우에서만 사용할 수 있습니다. 다음과 같은 코드로 컴파일 후 연속적으로 실행하면 항상 `shared memory created`가 출력됩니다. 따라서 **프로세스 수준 지속**임을 알 수 있습니다. (테스트 환경: Windows 10, Visual Studio 2019, NuGet 패키지 인스톨러 이용하여 boost 1.71.0 버전 설치)

<script src="https://gist.github.com/nglee/f89b6448a05edcb9ed382a94e8aa13d5.js"></script>

## interprocess_mutex : 커널 수준 지속 (managed_xsi_shared_memory에 할당된 경우)

<script src="https://gist.github.com/nglee/a03ed8c2de387608f6d9d98ce53beb51.js"></script>
```
$ g++ bitest2.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest2
$ ./bitest2
interprocess_mutex create success
$ ./bitest2
boost::interprocess_exception::library_error
interprocess_mutex create fail
$
```

위와 같이 프로세스가 종료되어도 공유 메모리에 할당된 `interprocess_mutex`가 자동으로 해제되지 않는 것을 보니 프로세스 수준 지속은 아님을 알 수 있습니다. `interprocess_mutex`가 할당된 `managed_xsi_shared_memory`가 **커널 수준 지속**이므로 이 경우 `interprocess_mutex`도 **커널 수준 지속**임을 알 수 있습니다. (재부팅시에 `managed_xsi_shared_memory`가 사라지므로 그 안에 할당된 `interprocess_mutex`도 사라지게 됨)

뮤텍스의 경우 한 가지 더 궁금한 점이 생깁니다. 비록 자원은 해제되지 않더라도, 혹시 `unlock`은 자동으로 해줄까요? 다시 말해, 어떤 프로세스가 `interprocess_mutex`를 `lock`하고 나서 `unlock`하지 않고 프로세스가 종료된다면, 다른 프로세스가 그 `interprocess_mutex`를 `lock`할 수 있을까요?

<script src="https://gist.github.com/nglee/b9dd4d8f55010d47a48f30f4967b86d1.js"></script>
```
$ g++ bitest3.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest3
$ ./bitest3
This is the first process.
The first process locked an interprocess_mutex
and is going to exit without unlocking the mutex
$ ./bitest3
This is the second process.
The second process is going to lock an interprocess mutex,
and if it succeeds, then a message will be shown.
If it fails, it will run indefinitely.

```

위의 예제에서 볼 수 있듯이 `unlock`이 자동으로 되지 않음을 알 수 있습니다. 이런 상황을 막기 위해서는 다음과 같이 `scoped_lock`을 사용해야 합니다.

<script src="https://gist.github.com/nglee/a6eb842a92f1b44ca3d3880b255aac80.js"></script>
```
$ g++ bitest4.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest4
$ ./bitest4
This is the first process.
The first process locked an interprocess_mutex
and is going to exit without unlocking the mutex
$ ./bitest4
This is the second process.
The second process is going to lock an interprocess mutex,
and if it succeeds, then a message will be shown.
If it fails, it will run indefinitely.
The second process locked the mutex!
$
```

하지만 `scoped_lock`도 완벽한 해답이 되지는 못합니다. 만약 `scoped_lock`의 인스턴스가 해제되기 전에 프로세스가 종료된다면, 결국 `unlock`이 되지 않는 것이나 마찬가지입니다. 다음은 `gdb`를 이용해서 인위적으로 `scoped_lock`이 해제되기 전에 프로세스를 종료시킨 후에 다른 프로세스에서 `lock`을 시도하는 예제입니다.

```
$ g++ bitest4.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest4d -g
$ gdb ./bitest4d
(gdb) break 30
(gdb) run
This is the first process.

Breakpoint 1, first_process (shm=0x638c20) at bitest4.cpp:30
30	    scoped_lock<interprocess_mutex> lock(*mtx);
(gdb) n
32	    std::cout << "The first process locked an interprocess_mutex" << std::endl;
(gdb) kill
Kill the program being debugged? (y or n) y
(gdb) run
This is the second process.
The second process is going to lock an interprocess mutex,
and if it succeeds, then a message will be shown.
If it fails, it will run indefinitely.
^C
Program received signal SIGINT, Interrupt.
__lll_lock_wait () at ../sysdeps/unix/sysv/linux/x86_64/lowlevellock.S:135
135	../sysdeps/unix/sysv/linux/x86_64/lowlevellock.S: No such file or directory.
(gdb)
```

위에서 볼 수 있듯이 `unlock`이 자동으로 되지 않음을 알 수 있습니다. 이는 디버깅 과정에서 문제가 될 수 있습니다. 이럴 때 사용할 수 있는 것이 `file_lock`입니다.

## file_lock : 프로세스 수준 지속

`file_lock`은 [문서](https://www.boost.org/doc/libs/1_71_0/doc/html/interprocess/synchronization_mechanisms.html#interprocess.synchronization_mechanisms.file_lock)에도 명시되어 있듯이 **프로세스 수준 지속**입니다. 따라서 `file_lock`의 장점은 무엇보다 `lock`을 한 프로세스가 명시적으로 `unlock`을 하지 않은 상태로 종료되더라도(정상종료이든, 비정상종료이든 관계 없이) 자동으로 `unlock`이 된다는 점입니다.

<script src="https://gist.github.com/nglee/164bde324c6c03a50047648c222d0b28.js"></script>
```
$ g++ bitest5.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest5
$ ./bitest5
The process locked an file_lock,
and is going to exit without unlocking the lock.
$ ./bitest5
The process locked an file_lock,
and is going to exit without unlocking the lock.
$ g++ bitest5.cpp -I/usr/local/boost-1.71.0/include -std=c++14 -pthread -o bitest5d -g
$ gdb ./bitest5d
(gdb) break 11
(gdb) run
The process locked an file_lock,

Breakpoint 1, main() at bitest5.cpp:11
11          std::cout << "and is going to exit without unlocking the lock." << std::endl;
(gdb) kill
Kill the program being debugged? (y or n) y
(gdb) disable break
(gdb) run
The process locked an file_lock,
and is going to exit without unlocking the lock.
(gdb)
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
    <td class="td_center">2018-07-14</td>
  </tr>
  <tr>
    <td class="td_center">1.1</td>
    <td>Minor fixes</td>
    <td class="td_center">2018-07-17</td>
  </tr>
  <tr>
    <td class="td_center">1.2</td>
    <td>Change to v1.71.0</td>
    <td class="td_center">2020-04-06</td>
  </tr>
</table>
</div>
