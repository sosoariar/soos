;;;; 在屏幕上显示字符 ;;;;
; 0x7c00 是一种规范,BIOS功能包含了加载MBR中代码到ox7c00, CS:IP 会被BIOS设置为0X7C00
; MBR 的可执行代码逻辑在内存地址使用上需要以 0X7C00 为基础
SECTION MBR vstart=0x7c00
   mov ax,cs                            ; CS被BIOS设置为0, 下列的代码是初始化为0的操作
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov sp,0x7c00
   mov ax,0xb800                        ; 与VGA显示有关
   mov gs,ax

;;;; BIOS中断处理程序,与显示字符有关 ;;;;
; BIOS 0x10 中断
; 中断处理程序功能的执行需要参数,而参数约定从寄存器AX,BX,CX,DX中得到
; 功能号0x60 清屏+初始化屏幕大小,具体数据代表的内容可以help
   mov ax, 0x0600
   mov bx, 0x0700
   mov cx, 0
   mov dx, 0x184f
   int 0x10            ; int 0x10

; 功能号: 0x03 光标相关
   mov ah, 3
   mov bh, 0
   int 0x10

; 功能号: 0x13 打印字符串
   mov ax, message
   mov bp, ax		; 对应功能号中断触发时,显示的数据从 ES:BP获得

   mov cx, 10
   mov ax, 0x1301
   mov bx, 0x2
   int 0x10

;;;; 程序悬停 ;;;;
; CS,IP重复指向该地址,无法往下执行,
; 即在寄存器和内存数据保持不变时
   jmp $

   message db "Hello MBR!"


   times 510-($-$$) db 0
   db 0x55,0xaa
