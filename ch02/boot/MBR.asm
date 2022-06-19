;;;; 在屏幕上显示字符 ;;;;
; 0x7c00 是一种规范,BIOS功能包含了加载MBR中代码代码到ox7c00, CS:IP 会被BIOS设置为0X7C00
; MBR 的可执行代码逻辑在内存地址使用上需要以 0X7C00 为基础
SECTION MBR vstart=0x7c00
   mov ax,cs                            ; CS被BIOS设置为0, 下列的代码是初始化为0的操作
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

; 功能号: 0x03 光标相关
   mov ah, 3
   mov bh, 0
   int 0x10

; 功能号: 0x13 打印字符串
   mov ax, message
   mov bp, ax		; 对应功能号中断触发时,显示的数据从 ES:BP获得

   mov cx, 10		; 显示的字符数
   mov ax, 0x1301
   mov bx, 0x2
   int 0x10

   jmp $	;程序悬停

   message db "Hello MBR!"
   times 510-($-$$) db 0
   db 0x55,0xaa
