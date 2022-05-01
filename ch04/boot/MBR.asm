%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
    LOADER_STACK_TOP equ LOADER_BASE_ADDR
    jmp loader_start

;构建gdt及其内部的描述符
   GDT_BASE:   dd    0x00000000
            dd    0x00000000

   CODE_DESC:  dd    0x0000FFFF
	       dd    DESC_CODE_HIGH4

   DATA_STACK_DESC:  dd    0x0000FFFF
		     dd    DESC_DATA_HIGH4

   VIDEO_DESC: dd    0x80000007	       ;limit=(0xbffff-0xb8000)/4k=0x7
	       dd    DESC_VIDEO_HIGH4

   GDT_SIZE   equ   $ - GDT_BASE
   GDT_LIMIT   equ   GDT_SIZE -	1
   times 60 dq 0					 ; 此处预留60个描述符的slot

   SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0     ; (CODE_DESC - GDT_BASE)/8 + TI_GDT + RPL0
   SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0	 ; 同上
   SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0	 ; 同上

   gdt_ptr  dw  GDT_LIMIT
	    dd  GDT_BASE
   loadermsg db '2 loader in real.'

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

   mov	 sp, LOADER_BASE_ADDR
   mov	 bp, loadermsg
   mov	 cx, 17
   mov	 ax, 0x1301
   mov	 bx, 0x001f
   mov	 dx, 0x1800
   int	 0x10