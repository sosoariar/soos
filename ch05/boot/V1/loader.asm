%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start

loadermsg db 'HELLO LOADER IN REAL'

loader_start:

; 程序成功加载的提示信息

mov byte [gs:164],'L'
mov byte [gs:165],0x04

mov byte [gs:166],'O'
mov byte [gs:167],0x04

mov byte [gs:168],'A'
mov byte [gs:169],0x04

mov byte [gs:170],'D'
mov byte [gs:171],0x04

mov byte [gs:172],'E'
mov byte [gs:173],0x04

mov byte [gs:174],'R'
mov byte [gs:175],0x04

;------------------------------------------------------------
;INT 0x10 利用中断显示
;------------------------------------------------------------
   mov	 sp, LOADER_BASE_ADDR
   mov	 bp, loadermsg           ; ES:BP = 字符串地址
   mov	 cx, 20			 ; 字符串长度
   mov	 ax, 0x1301		 ; AH = 13,  AL = 01h
   mov	 bx, 0x001f
   mov	 dx, 0x1800		 ;
   int	 0x10


; 实模式下,表达方式是直接赋予16位寄存器的值
; 保护模式下,通过GDT封装后,需要 lgdt 指令解析
  GDT_BASE:   dd    0x00000000
	       dd    0x00000000

   CODE_DESC:  dd    0x0000FFFF
	       dd    DESC_CODE_HIGH4

   DATA_STACK_DESC:  dd    0x0000FFFF
		     dd    DESC_DATA_HIGH4

   VIDEO_DESC: dd    0x80000007
	       dd    DESC_VIDEO_HIGH4

   GDT_SIZE   equ   $ - GDT_BASE
   GDT_LIMIT   equ   GDT_SIZE -	1
   times 60 dq 0
   SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0
   SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0	 ; 同上
   SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0	 ; 同上

   gdt_ptr  dw  GDT_LIMIT
	    dd  GDT_BASE
;----------------------------------------   准备进入保护模式   ------------------------------------------
;1 打开A20
;2 加载gdt
;3 将cr0的pe位置1
;
;-----------------  打开A20  ----------------
    in al,0x92
    or al,0000_0010B
    out 0x92,al

;-----------------  加载GDT  ----------------
    lgdt [gdt_ptr]

;-----------------  cr0的第0位置1  ----------------
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start

; 在32位保护模式下, 通过SELECTOR_DATA 可以得到类似实模式下寄存器的值,
; 下面这段程序类似实模式下操作段寄存器,只不过现在是通过SELECTOR来定位地址
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