;;
;; c2t2  --  converts a .com file into an executable text file
;;
;; Optimized with respect to the encoding
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

; Note: Yes, I know this code is realy ugly -- it was just hacked
;       together to do the job :-)

org 100h

start:
        mov     ah, 9
        mov     dx, intro
        int     21h

        mov     ah, 4ah
        mov     bh, 32
        int     21h                     ; resize mem block to 128k
        jc      _mem_error              ; mem error?

; ===================================================================
;  get filename
; ===================================================================
        mov     si, 0081h
skipspaces:
        lodsb
        cmp     al, " "
        je      short skipspaces
        jb      _syntax                 ; no filename given

        lea     dx, [si - 1]            ; ds:dx -> filename
findend:
        lodsb
        cmp     al, " "
        ja      short findend

        mov     ax, 3d02h
        xor     cx, cx
        mov     [si - 1], cl            ; zero terminate filename

        int     21h                     ; open file (read/write)
        jc      _open_error             ; open error?

        xchg    ax, bx                  ; bx = handle

; ===================================================================
;  read file
; ===================================================================
        mov     dx, buffer
        mov     di, dx

        mov     cx, 07f00h
        mov     ah, 3fh
        int     21h                     ; read from file
        jc      _read_error             ; read error?

        cmp     ax, cx
        je      _format_error           ; format error?

        cmp     word [di], 'MZ'
        je      _format_error           ; format error?

        cmp     word [di], 'ZM'
        je      _format_error           ; format error?

; ===================================================================
;  convert file
; ===================================================================
        mov     dx, cs
        add     dh, 10h
        mov     es, dx                  ; es -> next segment

        mov     si, handler
        mov     cx, HANDLER_SIZE
        xor     di, di
        rep     movsb                   ; copy handler

        mov     si, buffer
        xchg    ax, cx                  ; cx = filesize

        lea     dx, [di-2]              ; initialize counter

        mov     bp, di                  ; bp -> first 'dx'
        inc     di
        inc     dx
        mov     byte [es:bp], 00100000b

convert_next:
        xor     ax, ax
        lodsb

        push    bx
        mov     bx, ax
        shr     ax, 2
        call    convert_to_ascii

        stosb
        inc     dx

        test    dl, 3fh
        jnz     break_ok_1

        xor     dx, dx
        mov     ax, 0a0dh
        stosw

break_ok_1:

        shr     bx, 1
        pushf
        shr     bx, 1
        rcr     byte [es:bp], 1
        popf
        rcr     byte [es:bp], 1
        jnc     bp_ok

        movzx   ax, byte [es:bp]
        shr     ax, 2
        call    convert_to_ascii
        mov     [es:bp], al

        mov     bp, di
        inc     di
        inc     dx
        mov     byte [es:bp], 00100000b

bp_ok:
        pop     bx

        test    dl, 3fh
        jnz     break_ok_2

        test    dx, dx
        jz      break_ok_2

        mov     ax, 0a0dh
        stosw

break_ok_2:
        loop    convert_next

        cmp     byte [es:bp], 00100000b
        jne     rotate_into_place
        mov     byte [es:bp], '.'
        jmp     conversion_done

rotate_into_place:
        shr     byte [es:bp], 1
        jnc     rotate_into_place

        movzx   ax, byte [es:bp]
        shr     ax, 2
        call    convert_to_ascii
        mov     [es:bp], al

conversion_done:

; ===================================================================
;  write converted file
; ===================================================================
        xor     cx, cx                  ;
        xor     dx, dx                  ;
        mov     ax, 4200h               ;
        int     21h                     ; lseek to begin of file
        jc      _write_error            ; seek error?

        push    es                      ; dx = 0 from lseek
        pop     ds                      ; ds:dx -> converted file

        mov     cx, di                  ; cx = converted size

        mov     ah, 40h
        int     21h                     ; write to file
        jc      _write_error            ; write error?

_ok:
        call    _error
        db      'File conversion successfull!$'

convert_to_ascii:
        cmp     al, 5
        ja      not_0_5
        add     al, '('
        jmp     c_done
not_0_5:
        add     al, 'A' - 6
c_done:
        ret

; ===================================================================
;  error handling
; ===================================================================
intro:
        db      '-------------------------------------------------------------------------------',0dh,0ah
        db      'c2t2 (just for fun ;-)                        Copyright 2000-2015 Joergen Ibsen',0dh,0ah
        db      '                                 Licensed under the Apache License, Version 2.0',0dh,0ah
        db      '-------------------------------------------------------------------------------',0dh,0ah
        db      0dh,0ah,'$'

_syntax:
        call    _error
        db      ' Syntax:   c2t2 <filename>',0dh,0ah
        db      0dh,0ah
        db      'c2t2 is optimized with respect to the encoding.',0dh,0ah
        db      0dh,0ah
        db      'c2t2 will convert the .com file into an executable text file. The new size',0dh,0ah
        db      'will be one third larger than the original. The original file is overwritten.',0dh,0ah
        db      '$'

_mem_error:
        call    _error
        db      'ERR: mem error!$'

_open_error:
        call    _error
        db      'ERR: could not open file!$'

_read_error:
        call    _error
        db      'ERR: could not read from file!$'

_format_error:
        call    _error
        db      'ERR: file is not a .com file or too big!$'

_write_error:
        call    _error
        db      'ERR: could not write to file!$'

_error:
        pop     dx                      ;
        push    cs                      ; ds:dx -> error message
        pop     ds                      ;
        mov     ah, 09h
        int     21h                     ; print error message
        int     20h                     ; exit to DOS

; ===================================================================
;  decoder
; ===================================================================
handler:
   db 058h, 035h, 030h, 032h, 035h, 030h, 033h, 050h, 05Fh, 035h
   db 03Ah, 050h, 029h, 045h, 06Eh, 02Dh, 077h, 068h, 050h, 02Ch
   db 051h, 050h, 035h, 072h, 048h, 035h, 03Bh, 054h, 050h, 02Dh
   db 07Bh, 049h, 050h, 02Dh, 06Bh, 042h, 02Dh, 06Bh, 054h, 050h
   db 02Dh, 02Ah, 042h, 050h, 02Dh, 068h, 063h, 02Dh, 069h, 05Ah
   db 050h, 035h, 04Fh, 033h, 035h, 04Ah, 054h, 050h, 02Dh, 07Ah
   db 061h, 02Dh, 065h, 042h, 00Dh, 00Ah, 051h, 050h, 02Dh, 07Bh
   db 058h, 02Ch, 07Dh, 050h, 02Dh, 05Fh, 073h, 024h, 044h, 050h
   db 068h, 03Bh, 079h, 02Dh, 030h, 06Dh, 02Dh, 028h, 06Ah, 050h
   db 02Dh, 021h, 05Ch, 050h, 02Dh, 035h, 04Fh, 02Dh, 04Ah, 041h
   db 050h, 068h, 05Eh, 024h, 054h, 05Ah, 053h, 058h, 053h, 057h
   db 039h, 024h

HANDLER_SIZE equ $ - handler

buffer:
