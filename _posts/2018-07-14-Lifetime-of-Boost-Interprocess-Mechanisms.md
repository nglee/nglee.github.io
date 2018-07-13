---
layout: post
title: "boost::interprocess 객체의 인스턴스는 언제 해제되는가?"
comments: false
published: false
---

C++ 프로그램에서 프로세스 간 통신(이하 IPC, Inter-Process Communication)을 위해 `boost::interprocess`에서 정의된 객체(Object)들을 사용하게 되었습니다. 프로세스 간 공유 메모리(Inter-Process shared memory)나 프로세스 간 뮤텍스(Inter-Process Mutex)를 사용하려고 하다보니, 자연스럽게 다음과 같은 의문점이 생겼습니다.

"어떤 프로세스가 내부적으로 할당하여 그 프로세스만 사용하게 될 자원들은 그 프로세스가 종료되는 순간 자동으로 반환된다. 그렇다면, 프로세스 간 통신을 위해 공유 메모리에 할당된 자원은 언제 반환되는가? 다시 말해서, 공유 메모리에 생성된 객체의 인스턴스는 언제 해제되는가(destructed)?"

자원을 명시적으로 해제할 경우 당연히 그 자원은 반환될 것입니다. 그러나 자원을 명시적으로 해제하지 않는다면 어떻게 될까요? 시스템을 재부팅해야 자원이 해제가 될까요? 아니면 재부팅하지 않더라도 그 자원을 사용했던 프로세스들이 종료되면 자동으로 해제가 될까요? `boost::interprocess` 관련 문서를 뒤적인 결과 다음과 같은 [항목](https://www.boost.org/doc/libs/1_60_0/doc/html/interprocess/some_basic_explanations.html#interprocess.some_basic_explanations.persistence)을 발견할 수 있었습니다. 원문은 영어로 되어있고 의역하면 다음과 같습니다.

> ## 프로세스 간 통신에 사용되는 자원들은 언제까지 지속되는가
> 프로세스 간 통신에 사용되는 자원들에 대한 가장 중요한 이슈 중 하나는 그 자원들의 지속시간이다. 어떤 자원이 언제 시스템에서 사라지는지를 아는 것은 매우 중요하다. Boost.Interprocess에서 제공하는 자원들은 다음과 같이 세 가지 경우로 나뉜다:
> * 프로세스 수준 지속: 어떤 공유 자원을 사용(open)한 모든 프로세스들이 그 자원을 더 이상 사용하지 않게 되거나(close) 정상종료(exit)되거나 비정상종료(crash)될 때까지 유지된다.
> * 커널 수준 지속: 운영체제의 커널이 재시작(reboot)되거나 자원이 명시적으로 삭제(delete)될 때까지 유지된다.
> * 파일시스템 수준 지속: 자원이 명시적으로 삭제(delete)될 때까지 유지된다.

각각의 수준에 대해 매우 잘 정리되어 있음을 알 수 있습니다. 하지만 문제는, 제가 사용하고자 했던 `boost::interprocess`의 자원들이 위 세가지 중 어디에 속하는지가 명확히 정리되어 있지 않았다는 점입니다. 관련된 부분에 대해 스택 오버플로우에 [질문]()을 올리기도 했고 무려 50점이나 되는 현상금(bounty)을 걸었음에도 만족할 만한 답변을 얻지 못했습니다. 

그래서 테스트 코드를 직접 짜 보면서 실험을 해보기로 했습니다. `boost::interprocess`에서 제공하는 모든 종류의 자원을 테스트해보지는 못했고, 제가 확인이 필요했던 것들만 테스트해보았습니다.

## managed_xsi_shared_memory : 커널 수준 지속

이 공유 메모리는 리눅스에서만 사용할 수 있습니다. 리눅스에서 진행되었던 모든 테스트는 Ubuntu 16.04(커널 버전 4.13.0-45, g++ 5.4.0), x86_64 환경에서 진행되었습니다.

```
$ cat test.cpp
#include <boost/interprocess/managed_xsi_shared_memory.hpp>
#include <boost/interprocess/xsi_key.hpp>
#include <iostream>

using namespace boost::interprocess;
typedef managed_xsi_shared_memory   managed_xsi_shared_memory;

int main()
{
    managed_xsi_shared_memory *shm = nullptr;

    try {
        shm = new managed_xsi_shared_memory{ create_only, xsi_key("test.cpp", 239), 1024 };
        std::cout << "shared memory created" << std::endl;
    } catch (interprocess_exception& e) {
        shm = new managed_xsi_shared_memory{ open_only, xsi_key("test.cpp", 239) };
        std::cout << "shared memory creation failed, opened instead" << std::endl;
    }
}
$ g++ test.cpp -I/usr/local/boost-1.60.0/include -std=c++14 -pthread -o test
$ ./test
shared memory created
$ ./test
shared memory creation failed, opened instead
$ 
```

위와 같이 프로세스가 종료되었음에도 자원이 해제되지 않는 것을 보니 일단 프로세스 수준 지속은 아님을 알 수 있습니다. 그런데 이 상태로 재부팅하고 나면 다음과 같음을 볼 수 있습니다.

```
$ ./test
shared memory created
$
```

따라서 `managed_xsi_shared_memory` 인스턴스의 경우 커널이 재시작 하고 나서 자원이 해재된 것을 보니 **커널 수준 지속**임을 알 수 있습니다.

(참고로, 생성된 공유 메모리를 파일 시스템을 통해 접근할 수 있는지 알아보려면 `man shm_overview` 문서의 `Accessing shared memory objects via the filesystem` 항목을 보면 될 것 같습니다.)

## managed_windows_shared_memory : 프로세스 수준 지속

이 공유 메모리는 윈도우즈에서만 사용할 수 있습니다. 위와 같이 테스트하면 **프로세스 수준 지속**임을 알 수 있습니다. 

## interprocess_mutex : 커널 수준 지속

```
$ cat test.cpp
#include <boost/interprocess/managed_xsi_shared_memory.hpp>
#include <boost/interprocess/xsi_key.hpp>
#include <iostream>

using namespace boost::interprocess;

void first_process(managed_xsi_shared_memory *shm);
void second_process(managed_xsi_shared_memory *shm);

int main()
{
    managed_xsi_shared_memory *shm = nullptr;

    try {
        shm = new managed_xsi_shared_memory{ open_or_create, xsi_key("test.cpp", 230), 1024 };
        interprocess_mutex *mtx = shm->construct<interprocess_mutex>("gMutex")();
        if (mtx)
            std::cout << "interprocess_mutex create success" << std::endl;
        else
            std::cout << "interprocess_mutex create fail" << std::endl;
    } catch (interprocess_exception& e) {
        std::cout << "interprocess_mutex create fail" << std::endl;
    }
}
$ g++ test.cpp -I/usr/local/boost-1.60.0/include -std=c++14 -pthread -o test
$ ./test
interprocess_mutex create success
$ ./test
interprocess_mutex create fail
$
```

위와 같이 프로세스가 종료되어도 공유 메모리에 할당된 `interprocess_mutex`가 자동으로 해제되지 않는 것을 보니 프로세스 수준 지속은 아님을 알 수 있습니다. `interprocess_mutex`가 할당된 `managed_xsi_shared_memory`가 **커널 수준 지속**이므로 `interprocess_mutex`도 **커널 수준 지속**임을 알 수 있습니다.

뮤텍스의 경우 한 가지 궁금한 점이 더 생깁니다. 비록 자원은 해제되지 않더라도, 혹시 `unlock`은 자동으로 해주지 않을까? 즉, 어떤 프로세스가 `interprocess_mutex`를 `lock`하고 나서 `unlock`하지 않고 프로세스가 종료된다면, 다른 프로세스가 그 `interprocess_mutex`를 `lock`할 수 있을까요?

```
$ cat test.cpp
#include <boost/interprocess/managed_xsi_shared_memory.hpp>
#include <boost/interprocess/xsi_key.hpp>
#include <iostream>

using namespace boost::interprocess;

void first_process(managed_xsi_shared_memory *shm);
void second_process(managed_xsi_shared_memory *shm);

int main()
{
    managed_xsi_shared_memory *shm = nullptr;

    try {
        shm = new managed_xsi_shared_memory{ create_only, xsi_key("test.cpp", 239), 1024 };
        first_process(shm);
    } catch (interprocess_exception& e) {
        shm = new managed_xsi_shared_memory{ open_only, xsi_key("test.cpp", 239) };
        second_process(shm);
    }
}

void first_process(managed_xsi_shared_memory *shm)
{
    std::cout << "This is the first process." << std::endl;

    interprocess_mutex *mtx = shm->find_or_construct<interprocess_mutex>("gMutex")();
    mtx->lock();

    std::cout << "The first process locked an interprocess_mutex" << std::endl;
    std::cout << "and is going to exit without unlocking the mutex" << std::endl;
}

void second_process(managed_xsi_shared_memory *shm)
{
    std::cout << "This is the second process." << std::endl;

    interprocess_mutex *mtx = shm->find_or_construct<interprocess_mutex>("gMutex")();
    
    std::cout << "The second process is going to lock an interprocess mutex," << std::endl;
    std::cout << "and if it succeeds, then a message will be shown." << std::endl;

    mtx->lock();

    std::cout << "The second process locked the mutex!" << std::endl;
}
$ g++ test.cpp -I/usr/local/boost-1.60.0/include -std=c++14 -pthread -o test
$ ./test
This is the first process.
The first process locked an interprocess_mutex
and is going to exit without unlocking the mutex
$ ./test
This is the second process.
The second process is going to lock an interprocess mutex,
and if it succeeds, then a message will be shown.

```

위의 예제에서 볼 수 있듯이 `unlock`이 자동으로 되지 않음을 알 수 있습니다. 이런 상황을 막기 위해서는 다음과 같이 `scoped_lock`을 사용해야 합니다.

```
$ cat test.cpp
#include <boost/interprocess/managed_xsi_shared_memory.hpp>
#include <boost/interprocess/xsi_key.hpp>
#include <boost/interprocess/sync/scoped_lock.hpp>
#include <iostream>

using namespace boost::interprocess;

void first_process(managed_xsi_shared_memory *shm);
void second_process(managed_xsi_shared_memory *shm);

int main()
{
    managed_xsi_shared_memory *shm = nullptr;

    try {
        shm = new managed_xsi_shared_memory{ create_only, xsi_key("test.cpp", 239), 1024 };
        first_process(shm);
    } catch (interprocess_exception& e) {
        shm = new managed_xsi_shared_memory{ open_only, xsi_key("test.cpp", 239) };
        second_process(shm);
    }
}

void first_process(managed_xsi_shared_memory *shm)
{
    std::cout << "This is the first process." << std::endl;

    interprocess_mutex *mtx = shm->find_or_construct<interprocess_mutex>("gMutex")();

    scoped_lock<interprocess_mutex> lock(*mtx);

    std::cout << "The first process locked an interprocess_mutex" << std::endl;
    std::cout << "and is going to exit without unlocking the mutex" << std::endl;
}

void second_process(managed_xsi_shared_memory *shm)
{
    std::cout << "This is the second process." << std::endl;

    interprocess_mutex *mtx = shm->find_or_construct<interprocess_mutex>("gMutex")();
    
    std::cout << "The second process is going to lock an interprocess mutex," << std::endl;
    std::cout << "and if it succeeds, then a message will be shown." << std::endl;

    scoped_lock<interprocess_mutex> lock(*mtx);

    std::cout << "The second process locked the mutex!" << std::endl;
}
$ g++ test.cpp -I/usr/local/boost-1.60.0/include -std=c++14 -pthread -o test
$ ./test
This is the first process.
The first process locked an interprocess_mutex
and is going to exit without unlocking the mutex
$ ./test
This is the second process.
The second process is going to lock an interprocess mutex,
and if it succeeds, then a message will be shown.
The second process locked the mutex!
$
```

하지만 `scoped_lock`도 완벽한 해답이 되지는 못합니다. 만약 `scoped_lock`이 해제가 되기 전에 프로세스가 종료된다면, 결국 `unlock`이 되지 않는 것이나 마찬가지입니다.

```
$ cat test.cpp
#include <boost/interprocess/managed_xsi_shared_memory.hpp>
#include <boost/interprocess/xsi_key.hpp>
#include <boost/interprocess/sync/scoped_lock.hpp>
#include <iostream>

using namespace boost::interprocess;

void first_process(managed_xsi_shared_memory *shm);
void second_process(managed_xsi_shared_memory *shm);

int main()
{
    managed_xsi_shared_memory *shm = nullptr;

    try {
        shm = new managed_xsi_shared_memory{ create_only, xsi_key("test.cpp", 239), 1024 };
        first_process(shm);
    } catch (interprocess_exception& e) {
        shm = new managed_xsi_shared_memory{ open_only, xsi_key("test.cpp", 239) };
        second_process(shm);
    }
}

void first_process(managed_xsi_shared_memory *shm)
{
    std::cout << "This is the first process." << std::endl;

    interprocess_mutex *mtx = shm->find_or_construct<interprocess_mutex>("gMutex")();

    scoped_lock<interprocess_mutex> lock(*mtx);

    std::cout << "The first process locked an interprocess_mutex" << std::endl;
    std::cout << "and is going to exit without unlocking the mutex" << std::endl;
}

void second_process(managed_xsi_shared_memory *shm)
{
    std::cout << "This is the second process." << std::endl;

    interprocess_mutex *mtx = shm->find_or_construct<interprocess_mutex>("gMutex")();
    
    std::cout << "The second process is going to lock an interprocess mutex," << std::endl;
    std::cout << "and if it succeeds, then a message will be shown." << std::endl;

    scoped_lock<interprocess_mutex> lock(*mtx);

    std::cout << "The second process locked the mutex!" << std::endl;
}
$ g++ test.cpp -I/usr/local/boost-1.60.0/include -std=c++14 -pthread -o testd -g
$ gdb testd
GNU gdb (Ubuntu 7.11.1-0ubuntu1~16.5) 7.11.1
Copyright (C) 2016 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from testd...done.
(gdb) break 30
Breakpoint 1 at 0x401ac9: file test.cpp, line 30.
(gdb) run
Starting program: /home/nglee/Workspace/boost_test/testd 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
This is the first process.

Breakpoint 1, first_process (shm=0x638c20) at test.cpp:30
30	    scoped_lock<interprocess_mutex> lock(*mtx);
(gdb) n
32	    std::cout << "The first process locked an interprocess_mutex" << std::endl;
(gdb) kill
Kill the program being debugged? (y or n) y
(gdb) run
Starting program: /home/nglee/Workspace/boost_test/testd 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
This is the second process.
The second process is going to lock an interprocess mutex,
and if it succeeds, then a message will be shown.
^C
Program received signal SIGINT, Interrupt.
__lll_lock_wait () at ../sysdeps/unix/sysv/linux/x86_64/lowlevellock.S:135
135	../sysdeps/unix/sysv/linux/x86_64/lowlevellock.S: No such file or directory.
(gdb) 
```

이럴 때 사용할 수 있는 것이 `file_lock`입니다.

## file_lock : 프로세스 수준 지속

`file_lock`은 [문서](https://www.boost.org/doc/libs/1_60_0/doc/html/interprocess/synchronization_mechanisms.html#interprocess.synchronization_mechanisms.file_lock)에도 명시되어 있듯이 **프로세스 수준 지속**입니다. 따라서 `file_lock`의 장점은 무엇보다 `lock`을 한 프로세스가 명시적으로 `unlock`을 하지 않은 상태로 종료(crash)되더라도 자동으로 `unlock`이 된다는 점입니다.

```
$ cat test.cpp
#include <boost/interprocess/sync/file_lock.hpp>
#include <iostream>

using namespace boost::interprocess;

int main()
{
    file_lock flock("test.cpp");
    flock.lock();
    std::cout << "The process locked an file_lock," << std::endl;
    std::cout << "and is going to exit without unlocking the lock." << std::endl;
}
$ g++ test.cpp -I/usr/local/boost-1.60.0/include -std=c++14 -pthread -o test
$ ./test
The process locked an file_lock,
and is going to exit without unlocking the lock.
$ ./test
The process locked an file_lock,
and is going to exit without unlocking the lock.
$
```

P.S. 원하는 답변을 얻지 못했던 스택 오버플로우 질문에는 직접 [답변]()을 달았습니다.

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
</table>
</div>

