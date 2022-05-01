%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
    LOADER_STACK_TOP equ LOADER_BASE_ADDR
    jmp loader_start

;构建gdt及其内部的描述符
;全局描述符表GDT是一片内存区域,每隔8个字节便是一个表现,dd 可以定义一个4字节,下面定义方式是高,低两个4字节

; 起始地址
GDT_BASE:
    dd    0x00000000
    dd    0x00000000

CODE_DESC:
    dd    0x0000FFFF
    dd    DESC_CODE_HIGH4

;数据段和栈段共同使用一个段描述符,栈是向下扩展,数据段是向上扩展
DATA_STACK_DESC:
    dd    0x0000FFFF
    dd    DESC_DATA_HIGH4

VIDEO_DESC:
    dd    0x80000007	       ;limit=(0xbffff-0xb8000)/4k=0x7
    dd    DESC_VIDEO_HIGH4

GDT_SIZE   equ   $ - GDT_BASE
GDT_LIMIT   equ   GDT_SIZE -	1
times 60 dq 0					 ; 此处预留60个描述符的slot

SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0     ; (CODE_DESC - GDT_BASE)/8 + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0	 ; 同上
SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0	 ; 同上

; 定义全局描述符表 GDT 的指针,此指针是 lgdt 加载 GDT 到 gdtr 寄存器时用的,
gdt_ptr
    dw  GDT_LIMIT
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

;----   准备进入保护模式   ----
;1 打开A20
;2 加载gdt
;3 将cr0的pe位置1

;-----------------  打开A20  ----------------
in al,0x92
or al,0000_0010B
out 0x92,al

;-----------------  加载GDT  ----------------
lgdt [gdt_ptr]


;-----------------  cr0  ----------------
mov eax, cr0
or eax, 0x00000001
mov cr0, eax

jmp  SELECTOR_CODE:p_mode_start

[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp,LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

mov byte [gs:320], 'P'

jmp $