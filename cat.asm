.model tiny
.code
org 100h
.286


COLOR        equ 0bdh               ; цвет кота
EAR_COLOR    equ 0d0h               ; цвет ушей
START_MEMORY equ 0b800h             ; начало видеопамяти
CMD_LEN      equ ds:[80h]           ; длина командной строки
FRAME_X_LEN  equ ds:[82h]           ; длина рамки
FRAME_Y_LEN  equ ds:[85h]           ; ширина рамки

EAR          equ ds:[88h]           ; адрес начала размера ушей в оперативной памяти
SYMBOL_START equ ds:[8Ah]           ; адрес начала кода символа в оперативной памяти
PHRASE_START equ 08Dh               ; адрес начала фразы в оперативной памяти
EXIT_CALL    equ 4c00h

SCREEN_LEN   equ 160d


Start:
        call   SetVideoMemoryStart

        mov si, SYMBOL_START
        call   CalculateHexLen
        mov symbol, si

        mov ax, symbol

        call   CalculateEarSize

        mov si, FRAME_X_LEN                             ; кладём в si длину рамки(d)
        call   CalculateHexLen
        shr si, 1
        shl si, 1
        mov x_hex_len, si

        mov si, FRAME_Y_LEN
        call   CalculateHexLen                          ; кладём в si ширину рамки(d)
        shr si, 1
        shl si, 1
        mov y_hex_len, si

        call   SetUpperRowParams
        call   PrintUpperRow

        add sp, 2

        call   SetLeftColumnParams
        call   PrintLeftColumn

        call   SetRightColumnParams
        call   PrintRightColumn

        call   SetLowerRowParams
        call   PrintLowerRow

        call   PrintLeftEar
        call   PrintRightEar

        call   ColorInsides
        call   ColorLeftEar
        call   ColorRightEar

        call   SetPhrasePlace
        call   SetPhraseLength
        call   SetColor
        call   SetCmdStartParam

        call   PrintPhrase

        call   Exit

x_hex_len   dw ?
y_hex_len   dw ?
ear_size    dw ?
symbol      dw ?

lu_corner   dw ?
ru_corner   dw ?


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


;=================================================
; CalculateEarSize
;
; Calculates ear size and puts it to the ear_size
; variable
;
; Expected: -
; Exit:     ear_size
; Destroys: DX
;
;=================================================

CalculateEarSize    proc

                    pop bx                              ; сохраняем адрес возврата

                    xor dx, dx                          ; dx = 0
                    mov dl, EAR                         ; dl = EAR
                    sub dl, '0'                         ; dl = EAR - '0'
                    mov ear_size, dx                    ; ear_size = EAR - '0'

                    push bx                             ; возвращаем адрес возврата в стек
                    ret


;=================================================
; CalculateHexLen
;
; Translates decimal number in SI to hex(and makes
; it even if it's not)
;
; Expected: decimal number in SI(as symbols)
; Exit:     SI
; Destroys: -
;
;=================================================

CalculateHexLen     proc

                    pop bx                              ; сохраняем адрес возврата

                    push cx
                    push dx
                    push ax

                    xor ax, ax                          ; ax = 0
                    sub si, '0'                         ; si = arg - '0'
                    sub si, 3000h                       ; si = arg - '0' - 3000h
                    mov ax, si                          ; ax = arg - '0' - 3000h
                    shl ax, 8                           ;
                    shr ax, 8                           ; ax чётный
                    mov cx, 10d                         ; cx = 10d
                    mul cx                              ; dx:ax = ax * 10d
                    shr si, 8                           ; si \= 8
                    add si, ax                          ; si = (arg - '0' - 3000h) \ 8 + ax

                    pop ax
                    pop dx
                    pop cx                              ; в si лежит длина рамки(h)

                    push bx                             ; возвращаем адрес возврата в стек
                    ret


;=================================================
; SetVideoMemoryStart
;
; Puts start video memory address to ES
;
; Expected:     -
; Exit:         ES
; Destroys:     AX
;
;=================================================

SetVideoMemoryStart     proc

                        mov ax, START_MEMORY            ; загружаем в es адрес начала видеопамяти
                        mov es, ax                      ;

                        ret

;==================================================
; SetPhrasePlace
;
; Counts where the start of line should be placed
; and puts the result to DI
;
; Expected:     -
; Exit:         DI
; Destroys:     AX
;
;==================================================

SetPhrasePlace          proc

                        xor ax, ax                      ; зануляем ax

                        mov al, CMD_LEN                 ; кладём длину командной строки в al
                        sub ax, 000Ch                   ; уменьшаем длину с учетом наличия других аргументов
                        shr ax, 1                       ; ax >> 1
                        shl ax, 1                       ; если ax нечётно, то делаем чётным

                        mov di, SCREEN_LEN * 10 + 80d   ; сдвиг на середину экрана
                        sub di, ax                      ; отнимаем длину слова(размещаем слово посередине)

                        ret

;==================================================
; SetColor
;
; Puts symbol color to AH
;
; Expected:     -
; Exit:         AH
; Destroys:     -
;
;==================================================

SetColor                proc

                        mov ah, COLOR                   ; кладём атрибут символа в ah

                        ret

;==================================================
; SetPhraseLength
;
; Calculates command line length and puts it to CL
;
; Expected:     -
; Exit:         CL
; Destroys:     -
;
;==================================================

SetPhraseLength         proc

                        mov cl, CMD_LEN                 ; кладём длину командной строки в cl
                        sub cx, 000Ch                   ; cut off cmd line

                        ret

;==================================================
; SetCmdStartParam
;
; Puts phrase offset to SI
;
; Expected:     -
; Exit:         SI
; Destroys:     -
;
;==================================================

SetCmdStartParam        proc

                        mov si, PHRASE_START            ; кладём адрес начала командной строки в si

                        ret

;==================================================
; PrintPhrase
;
; Prints phrase from command line
;
; Expected:     phrase start offset in DI
;               phrase length in CX
;               symbol atribute in AH
; Exit:         printed phrase
; Destroys:     AL, DI, SI
;
;==================================================

PrintPhrase             proc

                        Phrase:                         ; печать фразы
                            lodsb                       ; al = ds:[di], si++
                            stosw                       ; es:[di] = ax, di += 2
                        loop Phrase

                        ret

;==================================================
; SetUpperRowParams
;
; Puts arguments for printing upper row to stack
; in reverse order
;
; Expected:     symbol atribute in AH
; Exit:         args pushed in stack in reverse order
; Destroys:     SI, DX
;
;==================================================

SetUpperRowParams       proc

                        pop bx                          ; сохраняем адрес возврата

                        mov si, x_hex_len               ; si = FRAME_X_LEN(h)

                        mov dx, ear_size
                        shl dx, 1                       ; dx = EAR_SIZE * 2

                        sub si, dx                      ; si = FRAME_X_LEN(h) - EAR_SIZE * 2
                        inc si
                        push si                         ; кладём в стек длину рамки(для верха - с учетом ушей)
                        dec si                          ;

                        shl si, 1                       ; si = (FRAME_X_LEN(h) - EAR_SIZE * 2) * 2

                        push ax
                        mov ax, SCREEN_LEN              ; ax = 160d
                        sub ax, si                      ; ax = 160d - si
                        mov si, ax                      ; si = 160d - (FRAME_X_LEN(h) - EAR_SIZE * 2)*2
                        pop ax

                        shr si, 2                       ; если нечетное число при делении на 2, делаем четным
                        shl si, 1                       ; si = (160d - (FRAME_X_LEN(h) - EAR_SIZE * 2)*2) / 2
                        add si, SCREEN_LEN * 8          ; si = 160d * 8 + (160d - (FRAME_X_LEN(h) - EAR_SIZE * 2)*2) / 2

                        push si                         ; кладём в стек адрес верхнего левого угла
                        push bx                         ; возвращаем адрес возврата в стек

                        ret

;==================================================
; SetLeftColumnParams
;
; Puts arguments for printing left column to stack
; in direct order
;
; Expected:     -
; Exit:         args pushed in stack in direct order
; Destroys:     CX, SI
;
;==================================================

SetLeftColumnParams     proc

                        pop bx                          ; сохраняем адрес возврата

                        mov cx, 8d                      ; cx = 8d
                        sub cx, ear_size                ; cx = 8d - EAR_SIZE

                        push ax                         ;
                        mov ax, SCREEN_LEN              ; ax = 160d
                        push dx                         ;
                        mul cx                          ;
                        pop dx
                        mov cx, ax                      ; cx = 160d * (8d - EAR_SIZE)
                        mov ax, SCREEN_LEN              ; ax = 160d

                        mov si, x_hex_len               ; si = FRAME_X_LENGTH(H)
                        shl si, 1                       ; si = FRAME_X_LENGTH(H)*2
                        sub ax, si                      ; ax = 160d - FRAME_X_LENGTH(H)*2
                        shl ax, 1
                        shr ax, 2                       ; ax = (160d - FRAME_X_LENGTH(H)*2) / 2
                        add cx, ax                      ; cx = 160d * (8d - EAR_SIZE) + (160d - FRAME_X_LENGTH(H)*2) / 2
                        pop ax

                        mov lu_corner, cx               ; сохраняем адрес верхнего левого угла
                        push cx                         ; кладём в стек аргументы(прямой порядок) - адрес верхнего левого угла

                        push y_hex_len                  ; кладём в стек длину рамки

                        push bx                         ; возвращаем адрес возврата в стек

                        ret

;==================================================
; SetRightColumnParams
;
; Puts arguments for printing left column to stack
; in direct order
;
; Expected:     -
; Exit:         args pushed in stack in direct order
; Destroys:     CX, SI
;
;==================================================

SetRightColumnParams    proc

                        pop bx                          ; сохраняем адрес возврата

                        mov cx, 8d                      ; cx = 8d
                        mov dx, ear_size                ; dx = ear_size
                        sub cx, dx                      ; cx = 8d - EAR_SIZE

                        push ax                         ;
                        mov ax, SCREEN_LEN              ; ax = 160d
                        push dx
                        mul cx
                        pop dx
                        mov cx, ax                      ; cx = 160d * (8d - EAR_SIZE)
                        mov ax, 80d                     ; ax = 80d
                        mov si, x_hex_len               ; si = FRAME_X_LENGTH(H)
                        add ax, si                      ; ax = 80d + FRAME_X_LENGTH(H)
                        shl ax, 1
                        shr ax, 1                       ; ax чётный
                        add cx, ax                      ; cx = 160d * (8d - EAR_SIZE) + 80d + FRAME_X_LENGTH(H)
                        pop ax

                        mov ru_corner, cx               ; сохраняем адрес верхнего левого угла
                        push cx                         ; кладём в стек аргументы(прямой порядок) - адрес верхнего левого угла

                        push y_hex_len                  ; кладём в стек длину рамки

                        push bx                         ; возвращаем адрес возврата в стек

                        ret

;==================================================
; SetLowerRowParams
;
; Puts arguments for printing lower row to DI
; and CX
;
; Expected:     -
; Exit:         DI, CX
; Destroys:     -
;
;==================================================

SetLowerRowParams       proc

                        push ax
                        push dx
                        mov ax, SCREEN_LEN              ; ax = 160d
                        mov cx, y_hex_len               ; cx = y_hex_len
                        mul cx
                        mov cx, ax                      ; cx = 160d * y_hex_len
                        pop dx
                        pop ax

                        add cx, lu_corner               ; cx = 160d * y_hex_len + lu_corner

                        mov di, cx                      ; di = 160d * y_hex_len + lu_corner
                        mov cx, x_hex_len               ; cx = FRAME_X_LENGTH(H)
                        inc cx                          ; cx = FRAME_X_LENGTH(H) + 1

                        ret

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

                        mov bp, sp
                        mov di, [bp + 02h]              ; di = [bp + 02h]
                        mov cx, [bp + 04h]              ; cx = [bp + 04h]

                        UpperRow:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                        loop UpperRow

                        ret

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

                        pop bx                          ; достаём адрес возврата из стека

                        pop cx                          ; достаём аргументы
                        pop di                          ;

                        push bx                         ; возвращаем адрес возврата в стек

                        LeftColumn:
                            mov ah, COLOR
                            stosw
                            add di, SCREEN_LEN - 2d     ; +2d включается в stosw
                        loop LeftColumn

                        ret

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

                        pop bx                          ; достаём адрес возврата из стека

                        pop cx                          ; достаём аргументы
                        pop di

                        push bx                         ; возвращаем адрес возврата в стек

                        RightColumn:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN  - 2d    ; увеличиваем di на 160d (переход на следующую строку)
                        loop RightColumn

                        ret

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

                        LowerRow:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                        loop LowerRow


                        ret

;==================================================
; PrintLeftEar
;
; Prints left ear
;
; Expected:     -
; Exit:         printed left ear
; Destroys:     DI, CX
;
;==================================================

PrintLeftEar            proc

                        mov di, lu_corner               ; di = lu_corner
                        mov cx, ear_size                ; cx = ear_size

                        LeftEar:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN          ; di += SCREEN_LEN
                        loop LeftEar

                        ret

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

                        RightEar:
                            mov ah, COLOR               ; ah = COLOR
                            stosw                       ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN - 4d     ; di += (SCREEN_LEN - 4d)
                        loop RightEar

                        ret

;==================================================
; Exit
;
; Finishes the programm
;
; Expected:     -
; Exit:         end of the programm
; Destroys:     AX
;
;==================================================

Exit                    proc

                        mov ax, EXIT_CALL               ; завершение программы
                        int 21h

                        ret
end         Start
