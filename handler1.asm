;;
;; handler1 - commented source of the c2t1 handler
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

        xor     ax, 0x533a
        sub     [di + 0x38], ax         ; change fixup to 'call ax'

        ; write decoder by pushing words on stack
        sub     al, 0x77
        push    ax
        sub     ax, 0x5f51
        push    ax
        xor     ax, 0x3372
        xor     ax, 0x343b
        push    ax
        sub     ax, 0x4a2b
        push    ax
        xor     ax, 0x534a
        sub     ax, 0x2457
        push    ax
        push    word 0x786b
        push    word 0x6b2d
        sub     ax, 0x2724
        and     al, 0x5e
        push    ax

        push    sp
        pop     ax                      ; ax -> stack_fff0

        push    bx                      ; push zero word

        push    di                      ; push 0x0100, decoder return address
fixup:
        db      0x39, 0x23              ; turns into 'call ax'

encoded_data:
        ; ...

        ; this decoder is written on the stack by the handler
stack_fff0:
        pop     si                      ; si -> encoded_data

convert_next:
        lodsw

        sub     ax, 0x6b6b              ; 'kk'
        js      check_end

        aad     0x10

        stosb

check_end:
        cmp     si, sp
        jb      convert_next

        ret
