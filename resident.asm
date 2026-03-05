.286
.model tiny
.code
org 100h

COLOR        equ 03dh                               ; cat color
EAR_COLOR    equ 030h                               ; ear color
START_MEMORY equ 0b800h                             ; VRAM start
EXIT_CALL    equ 4c00h

x_hex_len    equ 20h                                ; length of the frame
y_hex_len    equ 14h                                ; width of the frame
ear_size     equ 04h                                ; size of ears
symbol       equ 03h                                ; sym color

lu_corner    equ 02B0h                              ; left upper corner address
ru_corner    equ 02F0h                              ; right upper corner address
ll_corner    equ 0F30h                              ; left lower corner address

w_scancode   equ 17d
q_scancode   equ 16d
e_scancode   equ 18d

SCREEN_LEN   equ 160d
SCREEN_SIZE  equ 2000d
NUM_OF_REGS  equ 13d

Start:
    jmp Main

;=================================================
; KeyboardInt
;
; My keyboard interrupt handler(instead of int 09h)
;
; Expected: -
; Exit: changes the flag for the timer int to
;       indicate if one of 'q', 'w' or 'e' has
;       been pressed
; Destroys: -
;
;=================================================

KeyboardInt proc

            pushf                                   ; save flags
            push ax bx es                           ; save ax, bx, es

            in al, 60h                              ; put the last pressed sym scancode in al
            and al, not 80h

            cmp al, w_scancode
            jne NO_W_PRESSED
            mov flag, 01h                           ; if 'w' is pressed, flag = 01h

            jmp DEFAULT

NO_W_PRESSED:
            cmp al, q_scancode
            jne NO_Q_PRESSED
            mov flag, 10h                           ; if 'q' is pressed, flag = 10h

            jmp DEFAULT

NO_Q_PRESSED:
            cmp al, e_scancode                      ; if 'e' is pressed, flag = 00h
            jne DEFAULT
            mov flag, 00h

DEFAULT:
            pop es bx ax
            popf                                    ; restore system state

            db 0eah                                 ; = jmp far
            OldSeg      dw 0                        ; (arg1)
            OldOff      dw 0                        ; (arg2)

            endp

;=================================================
; TimerInt
;
; My timer interrupt handler(instead of int 08h)
;
; Expected: -
; Exit: usual int 08h if 'q', 'w', 'e' aren't pressed
;       draws a frame with regs if 'w' is pressed
;       stops frame updates if 'e' is pressed
;       closes the frame if 'q' is pressed
; Destroys: -
;
;=================================================

TimerInt    proc

            pushf                                   ; save flags
            push bx                                 ; save bx value

            mov bx, bp                              ; bx = bp
            mov bp, sp                              ; bp = sp
            push [bp + 4h]                          ; save ip
            mov bp, bx                              ; restore bp

            push sp ax cx dx si di bp ds es ss cs

            mov ax, flag                            ; ax = flag
            cmp ax, 01h
            jne NO_FRAME                            ; if flag != 01h -> no frame

            call CompareBuffs                       ; else -> save background(in case of frame closing)
            call Frame                              ; draw frame

            jmp NO_FRAME_CLOSING

NO_FRAME:
            cmp ax, 10h
            jne NO_FRAME_CLOSING                    ; if flag != 10h -> end

            call CloseFrame
            mov flag, 00h                           ; no need to close the frame again next int 08h

NO_FRAME_CLOSING:

            add sp, 4                               ; remove cs and ss prev values
            pop es ds bp di si dx cx ax             ; restore regs
            add sp, 4                               ; remove ip and sp prev values
            pop bx                                  ; bx = bx_prev

            popf                                    ; restore flags

            db 0eah                                 ; = jmp far
            OldTimerSeg      dw 0                   ; (arg1)
            OldTimerOff      dw 0                   ; (arg2)

            endp

;=================================================
; CompareBuffs
;
; Compares draw_buffer with VRAM and changes
; symbols in save_buffer if not equal
;
; Expected: frame image in draw_buffer
;           background image in save_buffer
; Exit:     updated save_buffer
; Destroys: -
;
;=================================================

CompareBuffs    proc

                push ax bx es di cx                 ; save regs' values

                push START_MEMORY
                pop es                              ; es = START_MEMORY

                mov cx, SCREEN_SIZE                 ; cx = 2000d
                xor di, di                          ; di = 0

                CmpWord:
                    mov ax, es:[di]
                    mov bx, cs:draw_buffer[di]
                    cmp bx, ax
                    je NEXT_LOOP

                    mov cs:save_buffer[di], ax
                    mov cs:draw_buffer[di], ax

                NEXT_LOOP:
                    add di, 2
                loop CmpWord

                pop cx di es bx ax

                ret
                endp


;=================================================
; CloseFrame
;
; Closes frame
;
; Expected: background image in save_buffer
; Exit:     closed frame
; Destroys: -
;
;=================================================

CloseFrame      proc

                push cx di es ax                    ; save regs' values

                push START_MEMORY
                pop es                              ; es = START_MEMORY

                mov cx, SCREEN_SIZE                 ; cx = 2000d
                xor di, di                          ; di = 0

                OutputSym:
                    mov ax, cs:save_buffer[di]      ; ax = save_buffer[di]
                    stosw                           ; es:[di] = ax, di += 2
                loop OutputSym

                pop ax es di cx                     ; restore regs' values

                ret
                endp

;=================================================
; Frame
;
; Draws frame with regs' values inside in VRAM
; and draw_buffer
;
; Expected: -
; Exit:     frame with regs' values in VRAM and
;           draw_buffer
; Destroys: AX, ES
;
;=================================================

Frame       proc

            push START_MEMORY
            pop es                                  ; es = START_MEMORY

            mov ax, symbol                          ; ax = symbol

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
; Expected: regs' values in stack
; Exit: Regs' values
; Destroys: ?
;
;=================================================

PrintRegs   proc

            mov bx, (80d * 10 + 37d) * 2            ; put start address for printing regs to bx
            push START_MEMORY
            pop es                                  ; es = START_MEMORY
            mov ah, COLOR                           ; ah = COLOR
            mov dx, 28d                             ; position in stack from which reg values start
            mov cx, NUM_OF_REGS                     ; num of regs
            xor di, di                              ; di = 0

            PrintOneReg:
                mov al, cs:[regs_line + di]         ; mov first letter from the string to al
                mov es:[bx], ax                     ; draw this letter in VRAM
                mov cs:draw_buffer[bx], ax          ; draw this letter in draw_buffer
                add bx, 2                           ; move to the next sym
                inc di                              ; move to the next letter in string
                mov al, cs:[regs_line + di]
                mov es:[bx], ax
                mov cs:draw_buffer[bx], ax
                add bx, 2
                inc di

                push cx                             ; save the counter
                call PrintEq                        ; print ' = '
                call PrintRegVal                    ; print reg val
                pop cx                              ; restore the counter

            loop PrintOneReg

            ret
            endp

;=================================================
; PrintEq
;
; Prints ' = ' after the reg name
;
; Expected: adress of the eq start in BX
;           offset of the reg value
; Exit: ' = ' line
; Destroys: ?
;
;=================================================

PrintEq     proc

            mov al, ' '                             ; al = ' '
            mov es:[bx], ax                         ; print space
            mov cs:draw_buffer[bx], ax              ; both in VRAM and draw_buffer
            add bx, 2

            mov al, '='
            mov es:[bx], ax
            mov cs:draw_buffer[bx], ax
            add bx, 2

            mov al, ' '
            mov es:[bx], ax
            mov cs:draw_buffer[bx], ax
            add bx, 2

            mov bp, sp                              ; bp = sp
            add bp, dx                              ; [bp] = reg_value
            add bp, 4                               ; skip PrintEq return address and push cx
            mov cx, [bp]                            ; cx = reg_value(to print after '= ')
            sub dx, 2                               ; offset in stack for the next argument

            ret
            endp

;=================================================
; PrintRegVal
;
; Prints reg's value
;
; Expected: reg's value in CX
; Exit: reg's value printed
; Destroys: AX, BX
;
;=================================================

PrintRegVal proc

            push cx                                 ; save cx value
            shr cx, 3*4d                            ;
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            mov cs:draw_buffer[bx], ax
            add bx, 2
            pop cx

            push cx
            and cx, 3840d
            shr cx, 2*4d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            mov cs:draw_buffer[bx], ax
            add bx, 2
            pop cx

            push cx
            and cx, 240d
            shr cx, 1*4d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            mov cs:draw_buffer[bx], ax
            add bx, 2
            pop cx

            push cx
            and cx, 15d
            call NumOrLet

            mov al, cl
            mov es:[bx], ax
            mov cs:draw_buffer[bx], ax
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

                    pop bx                          ; save return address

                    mov di, lu_corner               ; di = lu_corner
                    add di, SCREEN_LEN * 2 + 2      ; di = lu_corner + SCREEN_LEN * 2 + 2

                    mov cx, ear_size                ; cx = ear_size
                    dec cx                          ; cx = ear_size - 1
                    xor dx, dx                      ; dx = 0
                    inc dx                          ; dx = 1

                    ColorLStairs:                   ; cycle for coloring all the lines
                        push cx                     ;
                        push di                     ; save di and cx

                        mov cx, dx                  ; cx = dx

                        ColorLLine:                 ; cycle for coloring one line
                            mov ah, EAR_COLOR       ; ah = EAR_COLOR
                            stosw                   ; es:[di] = ax, di += 2
                        loop ColorLLine

                        pop di
                        pop cx                      ; restore cx and di

                        inc dx                      ; dx += 1
                        add di, SCREEN_LEN          ; di += SCREEN_LEN

                    loop ColorLStairs

                    mov di, lu_corner               ; di = lu_corner
                    add di, SCREEN_LEN * 2 + 2      ; di = lu_corner + SCREEN_LEN * 2 + 2

                    mov cx, ear_size                ; cx = ear_size
                    dec cx                          ; cx = ear_size - 1
                    xor dx, dx                      ; dx = 0
                    inc dx                          ; dx = 1

                    ColorLStairsInBuff:             ; cycle for coloring all the lines in buffer
                        push cx                     ;
                        push di                     ; save di and cx

                        mov cx, dx                  ; cx = dx
                        mov ah, EAR_COLOR           ; ah = EAR_COLOR

                        ColorLLineInBuff:           ; cycle for coloring one line in buffer
                            mov cs:draw_buffer[di], ax
                            add di, 2
                        loop ColorLLineInBuff

                        pop di
                        pop cx                      ; restore cx and di

                        inc dx                      ; dx += 1
                        add di, SCREEN_LEN          ; di += SCREEN_LEN

                    loop ColorLStairsInBuff

                    push bx                         ; restore return address
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

                    pop bx                          ; save return address

                    mov di, ru_corner               ; di = ru_corner
                    add di, SCREEN_LEN * 2 - 2      ; di = ru_corner + SCREEN_LEN * 2 - 2

                    mov cx, ear_size                ; cx = ear_size
                    dec cx                          ; cx = ear_size - 1
                    xor dx, dx                      ; dx = 0
                    inc dx                          ; dx = 1

                    ColorRStairs:                   ; cycle for coloring all of the lines
                        push cx                     ;
                        push di                     ; save cx and di

                        mov cx, dx                  ; cx = dx

                        ColorRLine:                 ; cycle for coloring one line
                            mov ah, EAR_COLOR       ; ah = EAR_COLOR
                            stosw                   ; es:[di] = ax, di += 2
                            sub di, 4               ; di -= 4
                        loop ColorRLine

                        pop di                      ;
                        pop cx                      ; restore cx and di

                        inc dx                      ; dx += 1
                        add di, SCREEN_LEN          ; di += SCREEN_LEN

                    loop ColorRStairs

                    mov di, ru_corner               ; di = ru_corner
                    add di, SCREEN_LEN * 2 - 2      ; di = ru_corner + SCREEN_LEN * 2 - 2

                    mov cx, ear_size                ; cx = ear_size
                    dec cx                          ; cx = ear_size - 1
                    xor dx, dx                      ; dx = 0
                    inc dx                          ; dx = 1

                    ColorRStairsInBuff:             ; cycle for coloring all of the lines in buffer
                        push cx                     ;
                        push di                     ; save cx and di

                        mov cx, dx                  ; cx = dx
                        mov ah, EAR_COLOR           ; ah = EAR_COLOR

                        ColorRLineInBuff:           ; cycle for coloring one line in buffer
                            mov cs:draw_buffer[di], ax
                            sub di, 2
                        loop ColorRLineInBuff

                        pop di                      ;
                        pop cx                      ; restore cx and di

                        inc dx                      ; dx += 1
                        add di, SCREEN_LEN          ; di += SCREEN_LEN

                    loop ColorRStairsInBuff

                    push bx                         ; restore return address
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

                    pop bx                          ; save return address

                    mov di, 05D2h                   ; start address for coloring
                    mov cx, 000Fh                   ; num of rows to color
                    xor ax, ax                      ; ax = 0

                    ColorRow:
                        push di                     ; save di and cx
                        push cx

                        mov cx, x_hex_len           ; cx = x_hex_len
                        dec cx                      ; cx = x_hex_len - 1
                        mov ah, COLOR               ; ah = COLOR

                        ColorSym:
                            stosw                   ; es:[di] = ax, di += 2
                        loop ColorSym

                        pop cx                      ; restore cx and di
                        pop di

                        add di, SCREEN_LEN          ; di += SCREEN_LEN

                    loop ColorRow

                    mov di, 05D2h                   ; start address for coloring
                    mov cx, 000Fh                   ; num of rows to color
                    xor ax, ax                      ; ax = 0

                    ColorRowInBuff:
                        push di                     ; save di and cx
                        push cx

                        mov cx, x_hex_len           ; cx = x_hex_len
                        dec cx                      ; cx = x_hex_len - 1
                        mov ah, COLOR               ; ah = COLOR

                        ColorSymInBuff:
                            mov cs:draw_buffer[di], ax
                            add di, 2
                        loop ColorSymInBuff

                        pop cx                      ; restore cx and di
                        pop di

                        add di, SCREEN_LEN          ; di += SCREEN_LEN

                    loop ColorRowInBuff

                    push bx                         ; restore return address
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

                        mov di, 0538h               ; start adress for printing
                        mov cx, 0019h               ; length of row(less than lower one because of ears)
                        mov ah, COLOR               ; ah = COLOR

                        UpperRow:
                            stosw                   ; es:[di] = ax, di += 2
                        loop UpperRow

                        mov di, 0538h               ; the same for draw_buffer
                        mov cx, 0019h

                        UpperRowInBuf:
                            mov cs:draw_buffer[di], ax
                            add di, 2
                        loop UpperRowInBuf

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

                        mov cx, y_hex_len           ; cx = y_hex_len
                        mov di, lu_corner           ; di = lu_corner
                        mov ah, COLOR               ; ah = COLOR

                        LeftColumn:
                            stosw                   ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN - 2d ; +2d included in stosw
                        loop LeftColumn

                        mov cx, y_hex_len           ; the same for draw_buffer
                        mov di, lu_corner

                        LeftColumnInBuff:
                            mov cs:draw_buffer[di], ax
                            add di, SCREEN_LEN
                        loop LeftColumnInBuff

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

                        mov cx, y_hex_len           ; cx = y_hex_len
                        mov di, ru_corner           ; di = ru_corner
                        mov ah, COLOR               ; ah = COLOR

                        RightColumn:
                            stosw                   ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN - 2d ; +2 included in stosw
                        loop RightColumn

                        mov cx, y_hex_len           ; the same for draw_buffer
                        mov di, ru_corner

                        RightColumnInBuff:
                            mov cs:draw_buffer[di], ax
                            add di, SCREEN_LEN
                        loop RightColumnInBuff

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
                        mov di, ll_corner           ; di = ll_corner
                        mov cx, x_hex_len           ; cx = x_hex_len

                        LowerRow:
                            stosw                   ; es:[di] = ax, di += 2
                        loop LowerRow

                        mov di, ll_corner           ; the same for draw_buffer
                        mov cx, x_hex_len

                        LowerRowInBuff:
                            mov cs:draw_buffer[di], ax
                            add di, 2
                        loop LowerRowInBuff

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

                        mov di, lu_corner           ; di = lu_corner
                        mov cx, ear_size            ; cx = ear_size
                        mov ah, COLOR               ; ah = COLOR

                        LeftEar:
                            stosw                   ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN      ; di += SCREEN_LEN
                        loop LeftEar

                        mov di, lu_corner           ; di = lu_corner
                        mov cx, ear_size            ; cx = ear_size

                        LeftEarInBuff:
                            mov cs:draw_buffer[di], ax
                            add di, SCREEN_LEN + 2d
                        loop LeftEarInBuff

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

                        mov di, ru_corner           ; di = lu_corner
                        mov cx, ear_size            ; cx = ear_size
                        mov ah, COLOR               ; ah = COLOR

                        RightEar:
                            stosw                   ; es:[di] = ax, di += 2
                            add di, SCREEN_LEN - 4d ; di += (SCREEN_LEN - 4d)
                        loop RightEar

                        mov di, ru_corner           ; di = lu_corner
                        mov cx, ear_size            ; cx = ear_size

                        RightEarInBuff:
                            mov cs:draw_buffer[di], ax
                            add di, SCREEN_LEN - 2d
                        loop RightEarInBuff

                        ret
                        endp

;===================================================
; SaveBackground
;
; Puts background image to a buffer
;
; Expected: -
; Exit: save_buffer
; Destroys: -
;
;===================================================

SaveBackground          proc

                        push ax si es cx

                        mov cx, SCREEN_SIZE         ; cx = 2000d
                        push START_MEMORY
                        pop es
                        xor si, si                  ; si = 0

                        SaveWord:
                            mov ax, es:[si]             ; ax = es:[si]
                            mov cs:save_buffer[si], ax  ; cs:save_buffer[si] = es:[si]
                            add si, 2                   ; si += 2
                        loop SaveWord

                        pop cx es si ax

                        ret
                        endp

;===================================================
; FillDrawBuffer
;
; Puts VRAM image to draw_buffer
;
; Expected: -
; Exit: save_buffer
; Destroys: -
;
;===================================================

FillDrawBuffer          proc

                        push ax si es cx

                        mov cx, SCREEN_SIZE         ; cx = 2000d
                        push START_MEMORY
                        pop es
                        xor si, si                  ; si = 0

                        SaveDrawWord:
                            mov ax, es:[si]             ; ax = es:[si]
                            mov cs:draw_buffer[si], ax  ; cs:draw_buffer[si] = es:[si]
                            add si, 2                   ; si += 2
                        loop SaveDrawWord

                        pop cx es si ax

                        ret
                        endp


flag        dw 0
save_buffer dw SCREEN_SIZE DUP(0) ;
draw_buffer dw SCREEN_SIZE DUP(0) ;
regs_line   db 'bxipaxcxdxsidibpspdsessscs'

EOP:
Main:
            mov ax, 3509h                           ; to call 09h func of int 21h
            int 21h                                 ;
            mov OldSeg, bx                          ; save standart int 09h segment
            mov bx, es                              ; bx = es
            mov OldOff, bx                          ; save standart int 09h offset

            push 0                                  ;
            pop es                                  ; es = 0

            cli                                     ;
            mov bx, 09h * 4                         ; bx = 09h * 4
            mov es:[bx], offset KeyboardInt         ;
            mov ax, cs                              ;
            mov es:[bx+2], ax                       ;
            sti                                     ; change int 09h address to KeyboardInt function


            mov ax, 3508h                           ; the same for int 08h
            int 21h
            mov OldTimerSeg, bx
            mov bx, es
            mov OldTimerOff, bx

            push 0
            pop es                                  ; es = 0

            cli
            mov bx, 08h * 4
            mov es:[bx], offset TimerInt
            mov ax, cs
            mov es:[bx+2], ax
            sti


            call SaveBackground
            call Frame
            call FillDrawBuffer
            call CloseFrame

            mov ax, 3100h
            mov dx, offset EOP                      ; allocate memory to save resident programm
            shr dx, 4                               ; dx /= 4
            inc dx                                  ; dx += 1
            int 21h

end         Start
