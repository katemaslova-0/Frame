.286
.model tiny
.code
org 100h

COLOR        equ 03dh               ; цвет кота
EAR_COLOR    equ 030h               ; цвет ушей
START_MEMORY equ 0b800h             ; начало видеопамяти
EXIT_CALL    equ 4c00h

x_hex_len    equ 20h
y_hex_len    equ 14h
ear_size     equ 04h
symbol       equ 03h

lu_corner    equ 02B0h
ru_corner    equ 02F0h
ll_corner    equ 0F30h

SCREEN_LEN   equ 160d

Start:
    jmp Main

;=================================================
; KeyboardInt
;
; My keyboard interrupt handler(instead of int 09h)
;
; Expected: -
; Exit: usual int 09h if F9 isn't pressed
;       draws a frame with regs if F9 is pressed
; Destroys: -
;
;=================================================

KeyboardInt proc

            pushf
            push ax bx es

            in al, 60h
            and al, not 80h
            cmp al, 67d
            jne NO_FRAME

            pushf
            push ax bx dx si di bp
            call Frame
            pop bp di si dx bx ax
            popf

NO_FRAME:
            push 0b800h                     ; начало видеопамяти кладём в es
            pop es                          ;
            mov bx, (80d * 5 + 40d) * 2     ; в bx - середину 5й строки
            mov ah, 4eh                     ; в аh - атрибут символа

            mov es:[bx], ax                 ; для проверки выводим символ в середине 5й строки

            pop es bx ax
            popf                            ; восстанавливаем состояние системы

            db 0eah
            OldSeg      dw 0
            OldOff      dw 0

            endp

;=================================================
; TimerInt
;
; My timer interrupt handler(instead of int 08h)
;
; Expected: -
; Exit: usual int 08h if F9 isn't pressed
;       draws a frame with regs if F9 is pressed
; Destroys: -
;
;=================================================

TimerInt    proc

            pushf
            push bx

            mov bx, bp
            mov bp, sp
            push [bp + 4h]
            mov bp, bx

            push sp

            push ax cx dx si di bp ds es ss cs

            in al, 60h
            and al, not 80h
            cmp al, 67d
            jne NO_UPD

            call Frame

NO_UPD:
            pop bx                          ; bx = cs_prev
            pop bx                          ; bx = ss_prev
            pop es ds bp di si dx cx ax
            pop bx                          ; bx = sp_prev
            pop bx                          ; bx = ip_prev
            pop bx                          ; bx = bx_prev

            popf

            db 0eah
            OldTimerSeg      dw 0
            OldTimerOff      dw 0

            endp

;=================================================
; Frame
;
; Draws frame and prints regs' values inside it
;
; Expected: -
; Exit: frame with regs' values
; Destroys: ?
;
;=================================================

Frame       proc

            push START_MEMORY
            pop es

            mov ax, symbol

            call   PrintUpperRow
            call   PrintLeftColumn
            call   PrintRightColumn
            call   PrintLowerRow

            call   PrintLeftEar
            call   PrintRightEar

            call   ColorInsides
            call   ColorLeftEar
            call   ColorRightEar

            call   PrintRegs

            ret
            endp

;=================================================
; PrintRegs
;
; Prints regs' values inside the frame
;
; Expected: -
; Exit: Regs' values
; Destroys: ?
;
;=================================================

PrintRegs   proc

            mov bx, (80d * 10 + 37d) * 2
            push START_MEMORY
            pop es
            mov ah, COLOR
            mov dx, 28d     ; позиция в стеке, с которой начинаются сохраненные регистры

            mov al, 'b'
            mov es:[bx], ax
            add bx, 2
            mov al, 'x'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'i'
            mov es:[bx], ax
            add bx, 2
            mov al, 'p'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 's'
            mov es:[bx], ax
            add bx, 2
            mov al, 'p'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'a'
            mov es:[bx], ax
            add bx, 2
            mov al, 'x'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'c'
            mov es:[bx], ax
            add bx, 2
            mov al, 'x'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'd'
            mov es:[bx], ax
            add bx, 2
            mov al, 'x'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 's'
            mov es:[bx], ax
            add bx, 2
            mov al, 'i'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'd'
            mov es:[bx], ax
            add bx, 2
            mov al, 'i'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'b'
            mov es:[bx], ax
            add bx, 2
            mov al, 'p'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'd'
            mov es:[bx], ax
            add bx, 2
            mov al, 's'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'e'
            mov es:[bx], ax
            add bx, 2
            mov al, 's'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 's'
            mov es:[bx], ax
            add bx, 2
            mov al, 's'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            mov al, 'c'
            mov es:[bx], ax
            add bx, 2
            mov al, 's'
            mov es:[bx], ax
            add bx, 2

            call PrintEq
            call PrintRegVal

            ret
            endp

;=================================================
; PrintEq
;
; Prints ' = ' after the reg name
;
; Expected: -
; Exit: ' = ' line
; Destroys: ?
;
;=================================================

PrintEq     proc

            mov al, ' '
            mov es:[bx], ax
            add bx, 2
            mov al, '='
            mov es:[bx], ax
            add bx, 2
            mov al, ' '
            mov es:[bx], ax
            add bx, 2

            mov bp, sp
            add bp, dx
            add bp, 2 ; с учетом наличия адреса возврата PrintEq
            mov cx, [bp]
            sub dx, 2 ; декрементируем для след аргумента

            ret
            endp

;=================================================
; PrintRegVal
;
; Prints reg's value
;
; Expected: -
; Exit: reg's value
; Destroys: ?
;
;=================================================

PrintRegVal proc

            push cx
            shr cx, 3*4d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            add bx, 2
            pop cx

            push cx
            and cx, 3840d
            shr cx, 2*4d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            add bx, 2
            pop cx

            push cx
            and cx, 240d
            shr cx, 1*4d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            add bx, 2
            pop cx

            push cx
            and cx, 15d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            add bx, 2
            pop cx

            add bx, 160d - 2 * 9d

            ret
            endp

;=================================================
; NumOrLet
;
; Makes a letter or a num in CX a symbol
;
; Expected: let or num in cx
; Exit: ascii code in CX
; Destroys: -
;
;=================================================

NumOrLet    proc
            cmp cx, 0Ah
            jl NUM

            add cx, 'A' - 0Ah
            ret
NUM:
            add cx, '0'

            ret
            endp

;=================================================
; ColorLeftEar
;
; Colores left ear insides
;
; Expected: -
; Exit:     colored left ear
; Destroys: DX, DI, CX
;
;=================================================

ColorLeftEar        proc

                    pop bx                              ; сохраняем адрес возврата

                    mov di, lu_corner                   ; di = lu_corner
                    add di, SCREEN_LEN * 2 + 2          ; di = lu_corner + SCREEN_LEN * 2 + 2

                    mov cx, ear_size                    ; cx = ear_size
                    dec cx                              ; cx = ear_size - 1
                    xor dx, dx                          ; dx = 0
                    inc dx                              ; dx = 1

                    ColorLStairs:                       ; цикл для закрашивания всех строк
                        push cx                         ;
                        push di                         ; сохраняем cx и di(другие значения внутри след цикла)

                        mov cx, dx                      ; cx = dx

                        ColorLLine:                     ; цикл для закрашивания одной строки
                            mov ah, EAR_COLOR           ; ah = EAR_COLOR
                            stosw                       ; es:[di] = ax, di += 2
                        loop ColorLLine

                        pop di
                        pop cx                          ; возвращаем cx и di

                        inc dx                          ; dx += 1
                        add di, SCREEN_LEN              ; di += SCREEN_LEN

                    loop ColorLStairs

                    push bx                             ; возращаем адрес возврата в стек
                    ret
                    endp


;=================================================
; ColorRightEar
;
; Colores right ear insides
;
; Expected: -
; Exit:     colored right ear
; Destroys: DX, DI, CX
;
;=================================================

ColorRightEar       proc

                    pop bx                              ; сохраняем адрес возврата

                    mov di, ru_corner                   ; di = ru_corner
                    add di, SCREEN_LEN * 2 - 2          ; di = ru_corner + SCREEN_LEN * 2 - 2

                    mov cx, ear_size                    ; cx = ear_size
                    dec cx                              ; cx = ear_size - 1
                    xor dx, dx                          ; dx = 0
                    inc dx                              ; dx = 1

                    ColorRStairs:                       ; цикл для закрашивания всех строк
                        push cx                         ;
                        push di                         ; сохраняем cx и di(другие значения внутри след цикла)

                        mov cx, dx                      ; cx = dx

                        ColorRLine:                     ; цикл для закрашивания одной строки
                            mov ah, EAR_COLOR           ; ah = EAR_COLOR
                            stosw                       ; es:[di] = ax, di += 2
                            sub di, 4                   ; di -= 4
                        loop ColorRLine

                        pop di                          ;
                        pop cx                          ; возвращаем cx и di

                        inc dx                          ; dx += 1
                        add di, SCREEN_LEN              ; di += SCREEN_LEN

                    loop ColorRStairs

                    push bx                             ; возвращаем адрес возврата в стек
                    ret
                    endp

;=================================================
; ColorInsides
;
; Colores the cat(except ears)
;
; Expected: -
; Exit:     colored ear
; Destroys: AX, DX, DI, CX
;
;=================================================

ColorInsides        proc

                    pop bx                              ; сохраняем адрес возврата

                    mov di, ear_size                    ; di = ear_size
                    mov ax, SCREEN_LEN                  ; ax = SCREEN_LEN
                    xor dx, dx                          ; dx = 0
                    mul di                              ; ax = SCREEN_LEN * ear_size
                    mov di, ax                          ; di = SCREEN_LEN * ear_size
                    add di, lu_corner                   ; di = SCREEN_LEN * ear_size + lu_corner
                    add di, SCREEN_LEN                  ; di = SCREEN_LEN * (ear_size + 1) + lu_corner
                    inc di                              ;
                    inc di                              ; di = SCREEN_LEN * (ear_size + 1) + lu_corner + 2

                    mov cx, y_hex_len                   ; cx = y_hex_len
                    sub cx, ear_size                    ; cx = y_hex_len - ear_size
                    dec cx                              ; cx = y_hex_len - ear_size - 1
                    xor ax, ax                          ; ax = 0

                    ColorRow:
                        push di
                        push cx

                        mov cx, x_hex_len               ; cx = x_hex_len
                        dec cx                          ; cx = x_hex_len - 1

                        ColorSym:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                        loop ColorSym

                        pop cx
                        pop di

                        add di, SCREEN_LEN              ; di += SCREEN_LEN

                    loop ColorRow

                    push bx                             ; возвращаем адрес возврата в стек
                    ret
                    endp

;==================================================
; PrintUpperRow
;
; Prints upper row of frame
;
; Expected:     ES offset(where row starts) in [SP + 02h]
;               row lentgh in [SP + 04h]
;               symbol code in AL
; Exit:         printed row
; Destroys:     DI, CX, BP
;
;==================================================

PrintUpperRow           proc

                        mov di, 0538h
                        mov cx, 0019h

                        UpperRow:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                        loop UpperRow

                        ret
                        endp

;==================================================
; PrintLeftColumn
;
; Prints left column of frame
;
; Expected:     ES offset(where the row starts) in [SP + 02h]
;               row lentgh in [SP + 04h]
;               symbol code in AL
; Exit:         printed left column
; Destroys:     DI, CX, BP
;
;==================================================

PrintLeftColumn         proc

                        mov cx, y_hex_len
                        mov di, lu_corner

                        mov ah, COLOR

                        LeftColumn:
                            stosw
                            add di, SCREEN_LEN - 2d     ; +2d включается в stosw
                        loop LeftColumn

                        ret
                        endp

;==================================================
; PrintRightColumn
;
; Prints right column of frame
;
; Expected:     ES offset(where the row starts) in [SP + 02h]
;               row lentgh in [SP + 04h]
;               symbol code in AL
; Exit:         printed right column
; Destroys:     DI, CX
;
;==================================================

PrintRightColumn        proc

                        mov cx, y_hex_len
                        mov di, ru_corner

                        mov ah, COLOR                   ; ah = COLOR

                        RightColumn:
                            stosw                       ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN  - 2d    ; увеличиваем di на 160d (переход на следующую строку)
                        loop RightColumn

                        ret
                        endp

;==================================================
; PrintLowerRow
;
; Prints lower row of frame
;
; Expected:     ES offset(where the row starts) in DI
;               row lentgh in CX
;               symbol code in AL
; Exit:         printed lower row
; Destroys:     DI, CX
;
;==================================================

PrintLowerRow           proc

                        mov ah, COLOR               ; ah = COLOR
                        mov di, ll_corner
                        mov cx, x_hex_len

                        LowerRow:
                            stosw                       ; es:[di] = ax, di += 2
                        loop LowerRow

                        ret
                        endp

;==================================================
; PrintLeftEar
;
; Prints left ear
;
; Expected:     -
; Exit:         printed left ear
; Destroys:     DI, CX, AX
;
;==================================================

PrintLeftEar            proc

                        mov di, lu_corner               ; di = lu_corner
                        mov cx, ear_size                ; cx = ear_size
                        mov ah, COLOR                   ; ah = COLOR

                        LeftEar:
                            stosw                       ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN          ; di += SCREEN_LEN
                        loop LeftEar

                        ret
                        endp

;==================================================
; PrintRightEar
;
; Prints right ear
;
; Expected:     -
; Exit:         printed right ear
; Destroys:     DI, CX, SI
;
;==================================================

PrintRightEar           proc

                        mov di, ru_corner               ; di = lu_corner
                        mov cx, ear_size                ; cx = ear_size
                        mov ah, COLOR                   ; ah = COLOR

                        RightEar:
                            stosw                       ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN - 4d     ; di += (SCREEN_LEN - 4d)
                        loop RightEar

                        ret
                        endp

EOP:
Main:
            mov ax, 3509h                   ;
            int 21h                         ;
            mov OldSeg, bx                  ;
            mov bx, es                      ;
            mov OldOff, bx                  ; сохраняем адрес старого обработчика(int 09h)

            push 0                          ;
            pop es                          ; es = 0

            cli                             ;
            mov bx, 09h * 4                 ;
            mov es:[bx], offset KeyboardInt ;
            mov ax, cs                      ;
            mov es:[bx+2], ax               ;
            sti                             ; записываем свой адрес(KeyboardInt) на место адреса
                                            ; старого обработчика

            mov ax, 3508h                   ;
            int 21h                         ;
            mov OldTimerSeg, bx             ;
            mov bx, es                      ;
            mov OldTimerOff, bx             ; сохраняем адрес старого обработчика(int 08h)

            int 09h ; для отладки

            push 0                          ;
            pop es                          ; es = 0

            cli                             ;
            mov bx, 08h * 4                 ;
            mov es:[bx], offset TimerInt    ;
            mov ax, cs                      ;
            mov es:[bx+2], ax               ;
            sti                             ; записываем свой адрес(TimerInt) на место адреса
                                            ; старого обработчика

            mov ax, 3100h                   ;
            mov dx, offset EOP              ; выделяем память для сохранения
            shr dx, 4                       ; резидентного кода
            inc dx                          ;
            int 21h                         ;

end         Start
