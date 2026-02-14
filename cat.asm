.model tiny
.code
org 100h
.286

Start:      mov ax, 0b800h              ; загружаем в es адрес начала видеопамяти
            mov es, ax                  ;

            xor ax, ax                  ; зануляем ax
            mov al, len                 ; кладём длину командной строки в al
            dec al                      ; уменьшаем длину(не считаем первый пробел)
            shr ax, 1                   ;
            shl ax, 1                   ; если ax нечётно, то делаем чётным
            mov di, 160d * 10 + 80d     ; сдвиг на середину экрана
            sub di, ax ;                ; отнимаем длину слова(размещаем слово посередине)

            mov cl, len                 ; кладём длину командной строки в cl
            dec cl                      ; уменьшаем длину(не считаем первый пробел)
            mov ah, color               ; кладём атрибут символа в ah
            mov si, cmd_start           ; кладём адрес начала командной строки в si

Phrase:                                 ; печать фразы
            lodsb
            stosw
LOOP Phrase

            mov di, 160d * 8 + 40d          ; кладём в di адрес левого верхнего угла
            mov cx, 34d                     ; кладём в cx длину рамки


FrameUpperRow:
            mov al, symbol
            mov byte ptr es:[di+06h], al    ; загружаем нужный символ в es:[di]
            mov byte ptr es:[di+07h], color ; загружаем атрибут символа в соседний байт
            inc di                          ; дважды инкрементируем di
            inc di                          ;
LOOP FrameUpperRow

            mov di, 160d * 5 + 40d          ; кладём в di адрес левого верхнего угла
            mov cx, 7h                      ; кладём в сх ширину рамки


FrameLeftColumn:
            mov al, symbol
            mov byte ptr es:[di], al        ; загружаем нужный символ в es:[di]
            mov byte ptr es:[di+01h], color ; загружаем атрибут символа в соседний байт
            add di, 160d                    ; увеличиваем di на 160d (переход на следующую строку)
LOOP FrameLeftColumn

            mov di, 160d * 5 + 120d - 2     ; кладём в di адрес правого верхнего угла
            mov cx, 7h                      ; кладём в сх ширину рамки


FrameRightColumn:
            mov al, symbol
            mov byte ptr es:[di], al        ; загружаем нужный символ в es:[di]
            mov byte ptr es:[di+01h], color ; загружаем атрибут символа в соседний байт
            add di, 160d                    ; увеличиваем di на 160d (переход на следующую строку)
LOOP FrameRightColumn

            mov di, 160d * 12 + 40d         ; кладём в di адрес левого нижнего угла
            mov cx, 40d                     ; кладём в cx длину рамки


FrameLowerRow:
            mov al, symbol
            mov byte ptr es:[di], al        ; загружаем нужный символ в es:[di]
            mov byte ptr es:[di+01h], color ; загружаем атрибут символа в соседний байт
            inc di                          ; дважды инкрементируем di
            inc di                          ;
LOOP FrameLowerRow

            mov di, 160d * 6 + 40d + 2d     ; дорисовать левый край
            mov al, symbol
            mov byte ptr es:[di], al
            mov byte ptr es:[di+01h], color ; stosw - переделать

            mov di, 160d * 7 + 40d + 4d
            mov al, symbol
            mov byte ptr es:[di], al
            mov byte ptr es:[di+01h], color

            mov di, 160d * 6 + 120d - 4d     ; дорисовать правый край
            mov al, symbol
            mov byte ptr es:[di], al
            mov byte ptr es:[di+01h], color

            mov di, 160d * 7 + 120d - 6d
            mov al, symbol
            mov byte ptr es:[di], al
            mov byte ptr es:[di+01h], color

PrintRow:
        ;


        ;

            mov ax, 4c00h       ; завершение программы
            int 21h             ;

color       equ 0bdh            ; цвет
len         equ ds:[80h]        ; длина командной строки
cmd_start   equ 082h            ; адрес начала командной строки
symbol      equ 03h             ; символ


end         Start
