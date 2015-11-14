;;
;; c2t1  --  converts a .com file into an executable text file
;;
;; Optimized with respect to the decoder size
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

        mov     dx, di                  ; initialize counter

convert_next:
        lodsb
        aam     10h
        add     ax, 6b6bh
        stosw

        inc     dx
        inc     dx

        test    dl, 3fh
        jnz     break_ok

        mov     ax, 0a0dh
        stosw

break_ok:
        loop    convert_next

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

; ===================================================================
;  error handling
; ===================================================================
intro:
        db      '-------------------------------------------------------------------------------',0dh,0ah
        db      'c2t1 (just for fun ;-)                        Copyright 2000-2015 Joergen Ibsen',0dh,0ah
        db      '                                 Licensed under the Apache License, Version 2.0',0dh,0ah
        db      '-------------------------------------------------------------------------------',0dh,0ah
        db      0dh,0ah,'$'

_syntax:
        call    _error
        db      ' Syntax:   c2t1 <filename>',0dh,0ah
        db      0dh,0ah
        db      'c2t1 is optimized with respect to the decoder size.',0dh,0ah
        db      0dh,0ah
        db      'c2t1 will convert the .com file into an executable text file. The new size will',0dh,0ah
        db      'be twize the size of the original. The original file is overwritten.',0dh,0ah
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
   db 03Ah, 053h, 029h, 045h, 038h, 02Ch, 077h, 050h, 02Dh, 051h
   db 05Fh, 050h, 035h, 072h, 033h, 035h, 03Bh, 034h, 050h, 02Dh
   db 02Bh, 04Ah, 050h, 035h, 04Ah, 053h, 02Dh, 057h, 024h, 050h
   db 068h, 06Bh, 078h, 068h, 02Dh, 06Bh, 02Dh, 024h, 027h, 024h
   db 05Eh, 050h, 054h, 058h, 053h, 057h, 039h, 023h

HANDLER_SIZE equ $ - handler

buffer:
