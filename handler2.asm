;;
;; handler2 - commented source of the c2t2 handler
;;
;; Copyright 2000-2015 Joergen Ibsen
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;; http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.
;;

org 100h
        ; on entry, CS=DS=ES=SS, IP=0100, SP=FFFE,
        ; BX = 0, there is a zero word at SS:SP

        pop     ax                      ; ax = 0x0000

        xor     ax, 0x3230
        xor     ax, 0x3330              ; ax = 0x0100

        push    ax
        pop     di                      ; di = 0x0100

        xor     ax, 0x503a
        sub     [di + 0x6e], ax         ; change fixup to 'call dx'

        ; write decoder by pushing words on stack
        sub     ax, 0x6877
        push    ax
        sub     al, 0x51
        push    ax
        xor     ax, 0x4872
        xor     ax, 0x543b
        push    ax
        sub     ax, 0x497b
        push    ax
        sub     ax, 0x426b
        sub     ax, 0x546b
        push    ax
        sub     ax, 0x422a
        push    ax
        sub     ax, 0x6368
        sub     ax, 0x5a69
        push    ax
        xor     ax, 0x334f
        xor     ax, 0x544a
        push    ax
        sub     ax, 0x617a
        sub     ax, 0x4265
        or      ax, 0x510a
        push    ax
        sub     ax, 0x587b
        sub     al, 0x7d
        push    ax
        sub     ax, 0x735f
        and     al, 0x44
        push    ax
        push    word 0x793b
        sub     ax, 0x6d30
        sub     ax, 0x6a28
        push    ax
        sub     ax, 0x5c21
        push    ax
        sub     ax, 0x4f35
        sub     ax, 0x414a
        push    ax
        push    word 0x245e

        push    sp
        pop     dx                      ; dx -> stack_ffe0

        push    bx
        pop     ax                      ; ax = 0x0000

        push    bx                      ; push zero word

        push    di                      ; push 0x0100, decoder return address
fixup:
        db      0x39, 0x24              ; turns into 'call dx'

encoded_data:
        ; ...

        ; this decoder is written on the stack by the handler
stack_ffe0:
        pop     si                      ; si -> encoded_data

        ; the 'jz new_tag' below, jumps into the middle of the next two
        ; instruction which turns them into 'or al, 0x40', which sets the
        ; sentinel bit used to check if all 6 tag bits have been used
        and     al, 0x0c
        inc     ax                      ; ax = 0x0001

        mov     dx, ax                  ; dx = tag

convert_next:
        lodsb

        sub     al, 0x3b                ; 'A' - 6
        jns     got_value
        add     al, 0x13                ; 'A' - 6 - '('
        js      check_end

got_value:
        shr     dx, 1
        jz      new_tag                 ; get new tag if empty, see note
        adc     ax, ax                  ; add bit to value
        shr     dx, 1
        adc     ax, ax                  ; add bit to value

        stosb

check_end:
        cmp     si, sp
        jb      convert_next

        ret
