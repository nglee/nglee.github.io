---
layout: post
title: "The Linux Programming Interface 42장 연습문제 풀이"
published: true
comments: true
---

> 42-1. Write a program to verify that if a library is closed with `dlclose()`, it is not unloaded if any of its symbols are used by another library.

In the following example, `main` opens `libfoo.so` and `libbar.so` with `dlopen()`, and `libbar.so` itself opens `libfoo.so` with `dlopen()`. The example tries to verify that `libfoo.so` is not unloaded even if `main` closes `libfoo.so` with `dlclose()` if the symbol `foo` of `libfoo.so` is used by `libbar.so`.

```
$ cat foo.c
#include <stdio.h>

void foo()
{
        printf("foo\n");
}
$ cat bar.c
#include <dlfcn.h>
#include "tlpi_hdr.h"

extern void foo();

void *bar(void *arg)
{
        void *fooHandle;
        void (*foo)(void);
        const char *err;

        fooHandle = dlopen("libfoo.so", RTLD_LAZY);
        if (fooHandle == NULL)
                fatal("dlopen: %s", dlerror());

        (void) dlerror();
        *(void **) (&foo) = dlsym(fooHandle, "foo");
        err = dlerror();
        if (err != NULL)
                fatal("dlsym: %s", err);

        for (int i = 0; i >= 0; i++)
                if (0 == i % 100000000)
                        (*foo)();

        return NULL;
}
$ cat main.c
#include <dlfcn.h>
#include <pthread.h>
#include "tlpi_hdr.h"

int main()
{
        void *fooHandle, *barHandle;
        void (*foo)(void);
        void *(*bar)(void *);
        const char *err;

        fooHandle = dlopen("libfoo.so", RTLD_LAZY);
        if (fooHandle == NULL)
                fatal("dlopen: %s", dlerror());

        barHandle = dlopen("libbar.so", RTLD_LAZY);
        if (fooHandle == NULL)
                fatal("dlopen: %s", dlerror());

        (void) dlerror();
        *(void **) (&foo) = dlsym(fooHandle, "foo");
        err = dlerror();
        if (err != NULL)
                fatal("dlsym: %s", err);

        (void) dlerror();
        *(void **) (&bar) = dlsym(barHandle, "bar");
        err = dlerror();
        if (err != NULL)
                fatal("dlsym: %s", err);

        printf("Calling foo of libfoo.so from main\n");
        (*foo)();

        pthread_t t;
        void *res;
        int s;

        printf("Creating a thread that calls bar of libbar.so from main\n");
        s = pthread_create(&t, NULL, *bar, NULL);
        if (s != 0)
                errExitEN(s, "pthread_create");

        sleep(2);

        printf("Closing libfoo.so with dlclose()\n");
        dlclose(fooHandle);

        s = pthread_join(t, &res);
        if (s != 0)
                errExitEN(s, "pthread_join");

        exit(EXIT_SUCCESS);
}
$
```

Possible output is:
```
$ ./main
Calling foo of libfoo.so from main
foo
Creating a thread that calls bar of libbar.so from main
foo
foo
foo
foo
foo
foo
foo
foo
foo
foo
foo
foo
foo
Closing libfoo.so with dlclose()
foo
foo
foo
foo
foo
foo
foo
foo
foo
$
```

> 42-2. Add a `dladdr()` call to the program in Listing 42-1 (dynload.c) in order to retrieve information about the address returned by `dlsym()`. Print out the values of the fields of the returned Dl_info structure, and verify that they are as expected.

```
$ cat dynload.c
#define _GNU_SOURCE
#include <dlfcn.h>
#include "tlpi_hdr.h"

int
main(int argc, char *argv[])
{
    void *libHandle;            /* Handle for shared library */
    void (*funcp)(void);        /* Pointer to function with no arguments */
    const char *err;

    if (argc != 3 || strcmp(argv[1], "--help") == 0)
        usageErr("%s lib-path func-name\n", argv[0]);

    /* Load the shared library and get a handle for later use */

    libHandle = dlopen(argv[1], RTLD_LAZY);
    if (libHandle == NULL)
        fatal("dlopen: %s", dlerror());

    /* Search library for symbol named in argv[2] */

    (void) dlerror();                           /* Clear dlerror() */
    *(void **) (&funcp) = dlsym(libHandle, argv[2]);
    err = dlerror();
    if (err != NULL)
        fatal("dlsym: %s", err);

    /* Try calling the address returned by dlsym() as a function
       that takes no arguments */

    (*funcp)();

    Dl_info info;
    dladdr(funcp, &info);
    printf("dli_fname: %s\n", info.dli_fname);
    printf("dli_fbase: %p\n", info.dli_fbase);
    printf("dli_sname: %s\n", info.dli_sname);
    printf("dli_saddr: %p\n", info.dli_saddr);

    dlclose(libHandle);                         /* Close the library */

    exit(EXIT_SUCCESS);
}
$
```

Possible output is:
```
$ ./dynload ./libdemo.so x1
Called mod1-x1
dli_fname: ./libdemo.so
dli_fbase: 0x7f6186645000
dli_sname: x1
dli_saddr: 0x7f6186645750
$ ./dynload ./libdemo.so x1
Called mod1-x1
dli_fname: ./libdemo.so
dli_fbase: 0x7efe54752000
dli_sname: x1
dli_saddr: 0x7efe54752750
$ ./dynload ./libdemo.so x1
Called mod1-x1
dli_fname: ./libdemo.so
dli_fbase: 0x7fd98f5ef000
dli_sname: x1
dli_saddr: 0x7fd98f5ef750
$ ./dynload ./libdemo.so x2
Called mod2-x2
dli_fname: ./libdemo.so
dli_fbase: 0x7f37d4d11000
dli_sname: x2
dli_saddr: 0x7f37d4d11763
$ ./dynload ./libdemo.so x2
Called mod2-x2
dli_fname: ./libdemo.so
dli_fbase: 0x7f1b80664000
dli_sname: x2
dli_saddr: 0x7f1b80664763
$ ./dynload ./libdemo.so x2
Called mod2-x2
dli_fname: ./libdemo.so
dli_fbase: 0x7ff67d03a000
dli_sname: x2
dli_saddr: 0x7ff67d03a763
$ ./dynload ./libdemo.so x3
Called mod3-x3
dli_fname: ./libdemo.so
dli_fbase: 0x7f8f9f696000
dli_sname: x3
dli_saddr: 0x7f8f9f696776
$ ./dynload ./libdemo.so x3
Called mod3-x3
dli_fname: ./libdemo.so
dli_fbase: 0x7fbbee261000
dli_sname: x3
dli_saddr: 0x7fbbee261776
$ ./dynload ./libdemo.so x3
Called mod3-x3
dli_fname: ./libdemo.so
dli_fbase: 0x7fc6d51cc000
dli_sname: x3
dli_saddr: 0x7fc6d51cc776
$
```

Although `dli_fbase` and `dli_saddr` values differ each time even for same symbol, it can be checked that the difference between them is equal for same symbol.

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
    <td class="td_center">2018-12-28</td>
  </tr>
</table>
</div>
