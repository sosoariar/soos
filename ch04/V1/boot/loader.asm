%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR   ;栈区的起始地址,为什么是这个地址?
jmp loader_start

;;;; 全局描述符表 (Global Descriptor Table GDT) ;;;;
;全局描述符表GDT是一片内存区域,每隔8个字节便是一个表现,dd 可以定义一个4字节,下面定义方式是高,低两个4字节
; GDT的第0个描述符不可用
GDT_BASE:
    dd    0x00000000
    dd    0x00000000

; 代码段描述符
CODE_DESC:
    dd    0x0000FFFF        ;低4字节
    dd    DESC_CODE_HIGH4   ;高4字节

; 数据段和栈段描述符
; 数据段和栈段共同使用一个段描述符,栈是向下扩展,数据段是向上扩展
DATA_STACK_DESC:
    dd    0x0000FFFF
    dd    DESC_DATA_HIGH4

; 显存段描述符
VIDEO_DESC:
    dd    0x80000007	       ;limit=(0xbffff-0xb8000)/4k=0x7
    dd    DESC_VIDEO_HIGH4

GDT_SIZE        equ   $ - GDT_BASE
GDT_LIMIT       equ   GDT_SIZE - 1
times 60 dq 0                   ; 预留空间,方便后续更新代码段

; --------------------------------- GDT 构建 ---------------------------------
; selector 的宏功能参数初始化
SELECTOR_CODE   equ     (0x0001<<3) + TI_GDT + RPL0     ; (CODE_DESC - GDT_BASE)/8 + TI_GDT + RPL0
SELECTOR_DATA   equ     (0x0002<<3) + TI_GDT + RPL0	 ; 同上
SELECTOR_VIDEO  equ     (0x0003<<3) + TI_GDT + RPL0	 ; 同上

; 定义全局描述符表 GDT 的指针,此指针是 lgdt 加载 GDT 到 gdtr 寄存器时用的,
gdt_ptr
    dw  GDT_LIMIT
    dd  GDT_BASE

loadermsg db '2 loader in real.'

loader_start:

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

jmp dword SELECTOR_CODE:p_mode_start

[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp,LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

mov byte [gs:160], 'P'

jmp $