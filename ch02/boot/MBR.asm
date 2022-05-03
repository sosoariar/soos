; 功能: 在屏幕上显示字符
SECTION MBR vstart=0x7c00 ; 源代码编译后在内存中的起始地址
   mov ax,cs              ; CS:IP 默认是顺序执行的,同样这条指令也会顺序存储在0x7c00向上扩展的地址中
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov sp,0x7c00
   mov ax,0xb800
   mov gs,ax

; BIOS 0x10 中断
; 从寄存器AX,BX,CX,DX中得到需要执行什么功能

; 功能号0x60 清屏+初始化屏幕大小,具体数据代表的内容可以help
   mov ax, 0x0600
   mov bx, 0x0700
   mov cx, 0           ;
   mov dx, 0x184f	     ;
   int 0x10            ; int 0x10

; 直接操作显存地址
    mov byte [gs:0x00],'H'
    mov byte [gs:0x01],0xA4

    mov byte [gs:0x02],'E'
    mov byte [gs:0x03],0xA4

    mov byte [gs:0x04],'L'
    mov byte [gs:0x05],0xA4

    mov byte [gs:0x06],'L'
    mov byte [gs:0x07],0xA4

    mov byte [gs:0x08],'O'
    mov byte [gs:0x09],0xA4

    mov byte [gs:0x0A],'M'
    mov byte [gs:0x0B],0xA4

    mov byte [gs:0x0C],'B'
    mov byte [gs:0x0D],0xA4

    mov byte [gs:0x0E],'R'
    mov byte [gs:0x0F],0xA4

   jmp $	;程序悬停

   times 510-($-$$) db 0
   db 0x55,0xaa
