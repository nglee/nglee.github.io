---
layout: post
title: "ARMv8-A 아키텍쳐 레퍼런스 매뉴얼을 읽어보자"
comments: true
published: false
---

<small class="post_intro">
이 포스트는 ARMv8-A 아키텍쳐 레퍼런스 매뉴얼을 번역하는 포스트입니다. 앞으로 시간이 날 때마다 조금씩 번역하려고 합니다. 중요하지 않다고 생각하는 부분은 번역하지 않았습니다. 모든 번역은 직역이 아니라 의역이며, 해석이 어려운 부분은 _(역자 주)_ 표시와 함께 간단한 주석을 덧붙였습니다.
</small>

----------------------------------------------------

## A1.1 About the ARM architecture

> (A1-32) The ARM architecture described in this Architecture Reference Manual defines the behavior of an abstract machine,
referred to as a processing element, often abbreviated to PE. Implementations compliant with the ARM architecture
must conform to the described behavior of the processing element. It is not intended to describe how to build an
implementation of the PE, nor to limit the scope of such implementations beyond the defined behaviors.

이 매뉴얼에서 기술하는 아키텍처는 **processing element**, 혹은 __PE__ 라고 불리는 머신(machine)이 어떻게 작동하는지 정의한다. 이 머신은 실제 존재하는 머신이 아닌 논리적 머신이다. 이 아키텍처를 기반으로 만든 프로세서는 이 PE와 동일하게 동작해야 한다. 이 메뉴얼은 그러한 프로세서를 실제로 어떻게 제작할 수 있는지에 대해서는 설명하지 않는다. 또한 여기에 기술되지 않은 부분들에 대해서는 특별히 제한을 두지 않는다.

> (A1-32) Except where the architecture specifies differently, the programmer-visible behavior of an implementation that is
compliant with the ARM architecture must be the same as a simple sequential execution of the program on the
processing element. This programmer-visible behavior does not include the execution time of the program.

프로그래머가 볼 때 이 아키텍처를 구현한 프로세서는 PE에서 순차적으로 명령어가 실행되는 경우와 똑같이 동작해야 한다. (_역자 주_ - 프로세서에 out-of-order execution 기능을 넣어도 된다는 뜻이라고 생각합니다.) 단, 특별히 언급하는 경우에는 다를 수 있다. 여기서 프로그램 수행시간은 고려하지 않는다. (_역자 주_ - Out-of-order execution 기능을 구현해서 특정 명령어 집합의 수행속도를 빠르게 해도 상관없다는 뜻이라고 생각합니다.)

> (A1-32) The ARM architecture is a Reduced Instruction Set Computer (RISC) architecture with the following RISC
architecture features:
* A large uniform register file.
* A load/store architecture, where data-processing operations only operate on register contents, not directly on
memory contents.
* Simple addressing modes, with all load/store addresses determined from register contents and instruction
fields only.

ARM 아키텍처는 RISC(Reduced Instruction Set Computer) 아키텍처다. RISC 아키텍처는 다음과 같은 특징을 갖는다.
* 레지스터 수가 많고 크기가 동일하다.
* 데이터가 처리되려면 반드시 먼저 레지스터에 적재되어야 한다. 메모리에 있는 데이터를 직접 처리하는 경우는 없다.
* Load/Store 명령어의 메모리 주소는 레지스터와 명령어의 내용을 통해서만 계산된다. (_역자 주_ - Memory indirect mode가 없다, 즉 메모리에 있는 값을 가지고 주소를 계산하는 경우는 없다는 뜻이라고 생각합니다.)

> (A1-32) An important feature of the ARMv8 architecture is backwards compatibility, combined with the freedom for optimal
implementation in a wide range of standard and more specialized use cases. The ARMv8 architecture supports:
* A 64-bit Execution state, AArch64.
* A 32-bit Execution state, AArch32, that is compatible with previous versions of the ARM architecture.
>
>---- NOTE ----
* The AArch32 Execution state is compatible with the ARMv7-A architecture profile, and enhances that
profile to support some features included in the AArch64 Execution state.

ARMv8의 중요한 특징은 하위 호완성(backward compatibility)을 가진다는 것이다. ARMv8은 다음의 두 가지 상태를 가질 수 있다:
* 64비트 상태인 AArch64.
* 32비트 상태인 AArch32. 이 상태는 이전 아키텍처 버전과 호환된다.

---- 참고 ----

* AArch32 상태는 ARMv7-A 아키텍처와 호환되며, AArch64 상태에서의 기능을 지원하기 위해 ARMv7-A 아키텍처를 발전시켰다. (_역자 주_ - 결국 AArch32 모드에서 ARMv7-A 아키텍처를 대상으로 짠 코드를 수정 없이 돌릴 수 있을 것 같습니다.)

> (A1-33) Both Execution states support SIMD and floating-point instructions:
* AArch32 state provides:
  * SIMD instructions in the base instruction sets that operate on the 32-bit general-purpose registers.
  * Advanced SIMD instructions that operate on registers in the SIMD and floating-point register
(SIMD&FP register) file.
  * Floating-point instructions that operate on registers in the SIMD&FP register file.
* AArch64 state provides:
  * Advanced SIMD instructions that operate on registers in the SIMD&FP register file.
  * Floating-point instructions that operate on registers in the SIMD&FP register file.

두 상태 모두 SIMD와 부동소수점 연산을 지원한다.
* AArch32는 다음을 제공한다.
  * 32비트 범용 레지스터를 이용하는 SIMD 명령어.
  * SIMD&FP 레지스터 파일을 이용하는 Advanced SIMD 명령어.
  * SIMD&FP 레지스터 파일을 이용하는 부동소숫점 명령어.
* AArch64는 다음을 제공한다.
  * SIMD&FP 레지스터 파일을 이용하는 Advanced SIMD 명령어.
  * SIMD&FP 레지스터 파일을 이용하는 부동소숫점 명령어.

## A1.2 Architecture profiles

> (A1-34) **AArch64** : Is the 64-bit Execution state, meaning addresses are held in 64-bit registers, and instructions in the
base instruction set can use 64-bit registers for their processing. AArch64 state supports the A64
instruction set.
>
> **AArch32** : Is the 32-bit Execution state, meaning addresses are held in 32-bit registers, and instructions in the
base instruction sets use 32-bit registers for their processing. AArch32 state supports the T32 and
A32 instruction sets.
>
> ---- NOTE ----  
The Base instruction set comprises the supported instructions other than the Advanced SIMD and floating-point
instructions.

64비트 상태인 **AArch64**에서 메모리 주소는 64비트 레지스터에 저장되며 기본 명령어 집합은 64비트 레지스터**를** 사용할 수 있다. AArch64 상태는 A64 명령어 집합을 지원한다.

32비트 상태인 **AArch32**에서 메모리 주소는 32비트 레지스터에 저장되며 기본 명령어 집합은 32비트 레지스터**만** 사용할 수 있다. AArch32 상태는 T32와 A32 명령어 집합을 지원한다.

---- 참고 ----  
기본 명령어 집합은 Advanced SIMD와 부동소숫점 명령어를 제외한 명령어들을 의미한다.

> **A** : Application profile, described in this manual:
* Supports a Virtual Memory System Architecture (VMSA) based on a Memory Management
Unit (MMU).
* Supports the A64, A32, and T32 instruction sets.
>
> **R** :  Real-time profile:
* Supports a Protected Memory System Architecture (PMSA) based on a Memory Protection
Unit (MPU).
* Supports the A32 and T32 instruction sets.

**A** : 어플리케이션(Application) 프로필. 이 문서는 이 프로필에 대해서 설명한다.
* MMU(Memory Management Unit) 기반 VMSA(Virtual Memory System Architecture)를 지원한다.
* A64, A32, T32 명령어 집합을 지원한다.

**R** : 실시간(Real-time) 프로필.
* MPU(Memory Protection Unit) 기반 PMSA(Protected Memory System Architecture)를 지원한다.
* A32, T32 명령어 집합을 지원한다.

## A1.3 ARMv8 architectural concepts

### A1.3.1 Execution state

> (A1-36) The Execution state defines the PE execution environment, including:
* The supported register widths.
* The supported instruction sets.
* Significant aspects of:
  * The exception model.
  * The Virtual Memory System Architecture (VMSA).
  * The programmers’ model.

실행상태(Execution state)는 PE가 실행되는 환경을 정의한다. 여기에는 다음이 포함된다:
* 지원하는 레지스터 크기
* 지원하는 명령어 집합
* 예외 처리(exception) 모델, VMSA(Virtual Memory System Architecture), 프로그래머 모델의 여러 부분들

> The Execution states are:
>
> **AArch64** The 64-bit Execution state. This Execution state:
* Provides 31 64-bit general-purpose registers, of which X30 is used as the procedure link
register.
* Provides a 64-bit program counter (PC), stack pointers (SPs), and exception link registers
(ELRs).
* Provides 32 128-bit registers for SIMD vector and scalar floating-point support.
* Provides a single instruction set, A64.
* Defines the ARMv8 Exception model, with up to four Exception levels, EL0 - EL3, that
provide an execution privilege hierarchy.
* Provides support for 64-bit virtual addressing.
* Defines a number of Process state (PSTATE) elements that hold PE state. The A64
instruction set includes instructions that operate directly on various PSTATE elements.
* Names each System register using a suffix that indicates the lowest Exception level at which
the register can be accessed.
>
> **AArch32** The 32-bit Execution state. This Execution state:
* Provides 13 32-bit general-purpose registers, and a 32-bit PC, SP, and link register (LR). The
LR is used as both an ELR and a procedure link register.
Some of these registers have multiple banked instances for use in different PE modes.
* Provides a single ELR, for exception returns from Hyp mode.
* Provides 32 64-bit registers for Advanced SIMD vector and scalar floating-point support.
* Provides two instruction sets, A32 and T32.
* Supports the ARMv7-A exception model, based on PE modes, and maps this onto the
ARMv8 Exception model, that is based on the Exception levels.
* Provides support for 32-bit virtual addressing.
* Defines a number of Process state (PSTATE) elements that hold PE state. The A32 and T32
instruction sets include instructions that operate directly on various PSTATE elements, and
instructions that access PSTATE by using the Application Program Status Register (APSR)
or the Current Program Status Register (CPSR).

실행상태는 두 가지가 있다.

**AArch64** 64비트 실행상태다. 이 실행상태는:
* 31개의 64비트 범용 레지스터를 제공한다. 이들 중 X30은 (_역자 주_ 함수의 복귀 주소가 담겨 있는) 프로시져 링크 레지스터(procedure link register)다.
* 1개의 프로그램 카운터, 여러 개의 스택 포인터(SP), 여러 개의 예외처리 링크 레지스터(exception link register, ELR)를 제공한다. 모두 64비트이다.
* SIMD 벡터 연산과 부동소숫점 스칼라 연산을 위해 32개의 128비트 레지스터를 제공한다.
* A64 명령어 집합을 제공한다.
* ARMv8 예외처리 모델을 정의한다. 이 모델은 EL0부터 EL3까지 최대 4개의 예외처리 수준(exception level)을 정의하고 이들은 실행 권한 체계를 제공한다.
* 64비트 가상 주소를 지원한다.
* PE의 상태를 담고 있는 프로세스 상태(PSTATE)를 정의한다. A64 명령어 집합은 다양한 PSTATE에 직접 동작하는 명령어를 갖고있다.
* 시스템 레지스터에 접미사를 붙여서 그 레지스터를 사용할 수 있는 가장 낮은 예외처리 수준을 표시한다.

**AArch32** 32비트 실행상태다. 이 실행상태는:
* 13개의 32비트 범용 레지스터를 제공한다. 그리고 각각 1개의 32비트 PC, SP, 그리고 LR을 제공한다. LR은 ELR 용도로도 사용되고 프로시져 링크 레지스터로도 사용된다. 이 레지스터 중 일부는 서로 다른 PE 모드에서 사용되기 위해 중첩되어 있다.
* Hyp 모드에서 복귀하기 위해 1개의 ELR을 제고앟ㄴ다.
* Advanced SIMD 벡터 연산과 부동소숫점 스칼라 연산을 위해 32개의 64비트 레지스터를 제공한다.
* A32와 T32 명령어 집합을 제공한다.
* PE 모드에 기반하는 ARMv7-A 예외처리 모델을 지원한다. 그리고 PE 모드와 ARMv8의 예외처리 수준(exception level) 사이의 관계를 정의한다. ARMv8의 예외처리 모델은 예외처리 수준을 기반으로 작동한다.
* 32비트 가상 주소를 지원한다.
* PE의 상태를 담고 있는 프로세스 상태(PSTATE)를 정의한다. A32와 T32 명령어 집합은 다양한 PSTATE에 직접 동작하는 명령어를 갖고 있고 또한 APSR과 CPSR을 이용해서 PSTATE에 접근하는 명령어도 갖고 있다. APSR은 Application Program Status Register를 의미하고 CPSR은 Current Program Status Register를 의미한다.

> (A1-37) Transferring control between the AArch64 and AArch32 Execution states is known as interprocessing. The PE can
move between Execution states only on a change of Exception level, and subject to the rules given in
Interprocessing on page D1-1962. This means different software layers, such as an application, an operating system
kernel, and a hypervisor, executing at different Exception levels, can execute in different Execution states.

실행상태를 바꾸는 것을 인터프로세싱(interprocessing)이라고 부른다. PE는 예외처리 수준이 변경될 때에만 실행상태를 변경할 수 있다. 이에 대한 규칙은 D1-1962에 기술되어 있다. 응용프로그램, 운영체제, 커널, 하이퍼바이저 등과 같이 서로 다른 예외처리 수준에서 실행되는 소프트웨어들은 서로 다른 실행상태를 가질 수 있다.

---------------------------------------------------------------------------
#### ChangeLog
<table>
  <tr>
    <th>Version</th>
    <th>Description</th>
    <th>Date</th>
  </tr>
  <tr>
    <td class="td_center">0.1</td>
    <td>Draft</td>
    <td class="td_center">2017-12-29</td>
  </tr>
  <tr>
    <td class="td_center">0.2</td>
    <td>~ A1.3.1</td>
    <td class="td_center">2017-01-09</td>
  </tr>
</table>
