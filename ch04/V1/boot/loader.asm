%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR   ;栈区的起始地址,为什么是这个地址?
jmp loader_start

;;;; 全局描述符表 (Global Descriptor Table GDT) ;;;;
; 全局描述符表GDT是一片内存区域,每隔8个字节便是一个表项,dd 可以定义一个4字节,下面定义方式是高,低两个4字节
; 在内存中开辟一个区域来存储全局描述符表,在被有关指令执行前,和普通数据没有差别,只是符合了GDT的格式
; 全局描述符GDT只有一张(一个处理器对应一个GDT),GDT 可以被放在内存的任何位置,但CPU必须知道GDT的入口
; Intel提供了一个寄存器GDTR用来存放GDT的入口,程序员将GDT设定在内存中某个位置之后,可以通过LGDT指令将GDT的入口地址装入此寄存器

; GDT的第0个描述符不可用
; GDT_BASE 只是用来表示这一内存位置的地址
GDT_BASE:
    dd    0x00000000
    dd    0x00000000

; 代码段描述符
; 代码段描述符要有可执行等属性
CODE_DESC:
    dd    0x0000FFFF        ;低4字节
    dd    DESC_CODE_HIGH4   ;高4字节

; 数据段和栈段描述符
; 数据段和栈段共同使用一个段描述符,栈是向下扩展,数据段是向上扩展
; 数据段等需要可读可写等属性
DATA_STACK_DESC:
    dd    0x0000FFFF
    dd    DESC_DATA_HIGH4

; 显存段描述符
VIDEO_DESC:
    dd    0x80000007
    dd    DESC_VIDEO_HIGH4

GDT_SIZE        equ   $ - GDT_BASE
GDT_LIMIT       equ   GDT_SIZE - 1
times 60 dq 0                   ; 预留空间,方便后续更新代码段

;;;; 选择子 (Global Descriptor Table GDT) ;;;;
; (CODE_DESC - GDT_BASE)/8 + TI_GDT + RPL0
; GDTR 只是基址，那么偏移量通过什么确认呢？
SELECTOR_CODE   equ     (0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA   equ     (0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO  equ     (0x0003<<3) + TI_GDT + RPL0

; 定义全局描述符表 GDT 的指针,此指针是 lgdt 加载 GDT 到 gdtr 寄存器时用的
; 以下两行供48位寄存器GDTR加载GDT表使用
gdt_ptr
    dw  GDT_LIMIT   ; 16 位GDT以字节的界限
    dd  GDT_BASE    ; GDT 的32位起始地址

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