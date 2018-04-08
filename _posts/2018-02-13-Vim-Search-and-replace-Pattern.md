---
layout: post
title: "Vim Search and Replace 패턴"
comments: true
---

Vim은 search and replace 기능을 위해 `:s`(substitute) 명령을 제공한다. 검색하고자 하는 패턴, 바꾸고자 하는 패턴이 복잡할 때는 `:s` 명령어도 복잡해진다. 이 포스트에서는 예제를 활용해 패턴을 활용하는 방식을 알아본다. [Vim Tips Wiki](http://vim.wikia.com/wiki/Search_and_replace)에서 도움을 받았다.

------

다음의 명령어를 분석해보자.

```
:1039,1080s/\(\s\+\)\(.\+DeviceKind_CPU);\)$/\1\/\/\2/g
```

구분자 `/`를 기준으로 하나씩 나눠서 살펴보자. 아래서 `^`로 표시된 문자가 구분자다. 구분자를 기준으로 앞에서부터 각각 범위, 검색 패턴, 바꾸기 패턴, 플래그를 지정한다.

```
:1039,1080s/\(\s\+\)\(.\+DeviceKind_CPU);\)$/\1\/\/\2/g
           ^                                ^        ^
```

### 범위 `1039,1080`

1039번째 줄과 1080번째 줄을 포함하여 그 사이에서 찾아바꾸기 명령을 수행한다.

### 검색 패턴 `\(\s\+\)\(.\+DeviceKind_CPU);\)$`

검색 패턴이다. 세 부분으로 더 잘게 나눠서 볼 필요가 있다.
```
\(\s\+\)\(.\+DeviceKind_CPU);\)$
^^^^^^^^
```
이 부분은 하나 이상의(`\+`) 연속된 whitespace(`\s`, 탭이나 공백)를 찾고 이 패턴을 바꾸기 패턴에서 참조할 수 있게 한다(`\(`, `\)`). 이 패턴은 `\1`로 참조할 수 있다.
```
\(\s\+\)\(.\+DeviceKind_CPU);\)$
        ^^^^^^^^^^^^^^^^^^^^^^^
```
이 부분은 하나 이상의(`\+`) 문자 혹은 공백(`.`)에 이어 `DeviceKind_CPU);`라는 문자열이 있는 패턴을 찾고 이 패턴을 바꾸기 패턴에서 참조할 수 있게 한다(`\(`, `\)`). 이 패턴은 `\2`로 참조할 수 있다.
```
\(\s\+\)\(.\+DeviceKind_CPU);\)$
                               ^
```
검색 패턴에서 찾은 문자열로 반드시 줄이 끝나야 한다는 의미이다.

### 바꾸기 패턴 `\1\/\/\2`

검색 패턴에서 찾은 `\1` 패턴과 `\2` 패턴 사이에 `//`를 추가한다.

### 플래그 `g`

존재하는 모든 패턴에 대해서 search and replace 를 수행한다.

------

정리하면,

```
:1039,1080s/\(\s\+\)\(.\+DeviceKind_CPU);\)$/\1\/\/\2/g
```

**이 명령어는 1039 번째 줄과 1080 줄 사이에서 끝에 "DeviceKind_CPU);"라는 문자열이 존재하는 줄을 찾아서 주석처리하는 명령어다.**

예컨대 다음과 같은 문서는
```
    launch(data1, DeviceKind_CPU);
    launch(data1, DeviceKind_GPU);
    launch(data2, DeviceKind_CPU);
    launch(data2, DeviceKind_GPU);
```
아래와 같이 변한다.
```
    //launch(data1, DeviceKind_CPU);
    launch(data1, DeviceKind_GPU);
    //launch(data2, DeviceKind_CPU);
    launch(data2, DeviceKind_GPU);
```
