---
layout: post
title: "The Linux Programming Interface(TLPI) 42장 연습문제 풀이"
published: true
comments: true
---

> 42-1. Write a program to verify that if a library is closed with `dlclose()`, it is not unloaded if any of its symbols are used by another library.

In the following example, `main` opens `libfoo.so` and `libbar.so` with `dlopen()`, and `libbar.so` itself opens `libfoo.so` with `dlopen()`. The example tries to verify that `libfoo.so` is not unloaded even if `main` closes `libfoo.so` with `dlclose()` if the symbol `foo` of `libfoo.so` is used by `libbar.so`.

<script src="http://gist-it.appspot.com/https://github.com/nglee/TLPI/blob/master/42-1/foo.c"></script>
<script src="http://gist-it.appspot.com/https://github.com/nglee/TLPI/blob/master/42-1/bar.c"></script>
<script src="http://gist-it.appspot.com/https://github.com/nglee/TLPI/blob/master/42-1/main.c"></script>

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

<script src="http://gist-it.appspot.com/https://github.com/nglee/TLPI/blob/master/42-2/dynload.c></script>

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
