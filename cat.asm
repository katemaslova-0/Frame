.model tiny
.code
org 100h
.286

Start:

COLOR       equ 0bdh            ; цвет
LEN         equ ds:[80h]        ; длина командной строки
CMD_START   equ 082h            ; адрес начала командной строки
SYMBOL      equ 03h             ; символ


            call   SetVideoMemoryStart
            call   SetPhrasePlace
            call   SetPhraseLength
            call   SetSymbol
            call   SetCmdStartParam

            call   PrintPhrase

            call   SetUpperRowParams
            call   PrintUpperRow

            pop bx  ; очистка стека от аргументов
            pop bx  ;

            call   SetLeftColumnParams
            call   PrintLeftColumn

            call   SetRightColumnParams
            call   PrintRightColumn

            call   SetLowerRowParams
            call   PrintLowerRow

            call   PrintLeftEar
            call   PrintRightEar

            call   Exit


SetVideoMemoryStart     proc

                        mov ax, 0b800h              ; загружаем в es адрес начала видеопамяти
                        mov es, ax                  ;

                        ret

SetPhrasePlace          proc

                        xor ax, ax                  ; зануляем ax
                        mov al, LEN                 ; кладём длину командной строки в al
                        dec al                      ; уменьшаем длину(не считаем первый пробел)
                        shr ax, 1                   ;
                        shl ax, 1                   ; если ax нечётно, то делаем чётным
                        mov di, 160d * 10 + 80d     ; сдвиг на середину экрана
                        sub di, ax                  ; отнимаем длину слова(размещаем слово посередине)

                        ret

SetSymbol               proc

                        mov ah, COLOR               ; кладём атрибут символа в ah

                        ret

SetPhraseLength         proc

                        mov cl, LEN                 ; кладём длину командной строки в cl
                        dec cl                      ; уменьшаем длину(не считаем первый пробел)

                        ret

SetCmdStartParam        proc

                        mov si, CMD_START           ; кладём адрес начала командной строки в si

                        ret

PrintPhrase             proc

                        Phrase:                     ; печать фразы
                            lodsb
                            stosw
                        loop Phrase

                        ret

SetUpperRowParams       proc

                        pop bx                           ; сохраняем адрес возврата

                        push 34d                         ; кладём в стек длину рамки
                        push 160d * 8 + 40d              ; кладём в стек адрес верхнего левого угла

                        push bx                          ; возвращаем адрес возврата в стек

                        ret

SetLeftColumnParams     proc

                        pop bx              ; сохраняем адрес возврата

                        push 160d * 5 + 40d ; кладём в стек аргументы(прямой порядок)
                        push 7h             ;

                        push bx             ; возвращаем адрес возврата в стек

                        ret

SetRightColumnParams    proc

                        mov di, 160d * 5 + 120d - 2     ; кладём в di адрес правого верхнего угла
                        mov cx, 7h                      ; кладём в сх ширину рамки

                        ret

SetLowerRowParams       proc

                        mov di, 160d * 12 + 40d         ; кладём в di адрес левого нижнего угла
                        mov cx, 40d                     ; кладём в cx длину рамки

                        ret

PrintUpperRow           proc

                        mov bp, sp
                        mov di, [bp+02h]
                        mov cx, [bp+04h]

                        UpperRow:
                            mov al, SYMBOL
                            mov byte ptr es:[di+06h], al    ; загружаем нужный символ в es:[di]
                            mov byte ptr es:[di+07h], COLOR ; загружаем атрибут символа в соседний байт
                            inc di                          ; дважды инкрементируем di
                            inc di                          ;
                        loop UpperRow

                        ret

PrintLeftColumn         proc

                        pop bx                              ; кладем адрес возврата в стек

                        pop cx                              ; достаём аргументы
                        pop di                              ;

                        push bx                             ; возвращаем адрес возврата в стек

                        LeftColumn:
                            mov al, SYMBOL
                            mov byte ptr es:[di], al        ; загружаем нужный символ в es:[di]
                            mov byte ptr es:[di+01h], COLOR ; загружаем атрибут символа в соседний байт
                            add di, 160d                    ; увеличиваем di на 160d (переход на следующую строку)
                        loop LeftColumn

                        ret

PrintRightColumn        proc

                        RightColumn:
                            mov al, SYMBOL
                            mov byte ptr es:[di], al        ; загружаем нужный символ в es:[di]
                            mov byte ptr es:[di+01h], COLOR ; загружаем атрибут символа в соседний байт
                            add di, 160d                    ; увеличиваем di на 160d (переход на следующую строку)
                        loop RightColumn

                        ret

PrintLowerRow           proc

                        LowerRow:
                            mov al, SYMBOL
                            mov byte ptr es:[di], al        ; загружаем нужный символ в es:[di]
                            mov byte ptr es:[di+01h], COLOR ; загружаем атрибут символа в соседний байт
                            inc di                          ; дважды инкрементируем di
                            inc di                          ;
                        loop LowerRow

                        ret

PrintLeftEar            proc

                        mov di, 160d * 6 + 40d + 2d     ; дорисовать левый край
                        mov al, SYMBOL
                        mov byte ptr es:[di], al
                        mov byte ptr es:[di+01h], COLOR ; stosw - переделать

                        mov di, 160d * 7 + 40d + 4d
                        mov al, SYMBOL
                        mov byte ptr es:[di], al
                        mov byte ptr es:[di+01h], COLOR

                        ret

PrintRightEar           proc

                        mov di, 160d * 6 + 120d - 4d     ; дорисовать правый край
                        mov al, SYMBOL
                        mov byte ptr es:[di], al
                        mov byte ptr es:[di+01h], COLOR

                        mov di, 160d * 7 + 120d - 6d
                        mov al, SYMBOL
                        mov byte ptr es:[di], al
                        mov byte ptr es:[di+01h], COLOR

                        ret

Exit                    proc

                        mov ax, 4c00h       ; завершение программы
                        int 21h             ;

                        ret

end         Start
