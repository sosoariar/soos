%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
    LOADER_STACK_TOP equ LOADER_BASE_ADDR
    jmp loader_start

loader_start:
    mov byte [gs:160],'2'
    mov byte [gs:161],0xA4

    mov byte [gs:162],' '
    mov byte [gs:163],0xA4

    mov byte [gs:164],'L'
    mov byte [gs:165],0xA4

    mov byte [gs:166],'O'
    mov byte [gs:167],0xA4

    mov byte [gs:168],'A'
    mov byte [gs:169],0xA4

    mov byte [gs:170],'D'
    mov byte [gs:171],0xA4

    mov byte [gs:172],'E'
    mov byte [gs:173],0xA4

    mov byte [gs:174],'R'
    mov byte [gs:175],0xA4