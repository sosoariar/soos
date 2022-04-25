; 主引导程序
;
SECTION MBR vstart=0x7c00 ; SECTION名MBR , SECTION 起始地址 0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    ;显示器内存操作地址
    mov ax,0xb800
    mov gs,ax

; 打印字符串
; -----------------------------------------------------------
; INT 0x10   功能号:0x13	   功能描述:打印字符串
; AH 功能号= 0x13
;------------------------------------------------------
   mov     ax, 0600h
   mov     bx, 0700h
   mov     cx, 0
   mov     dx, 184fh
   int     10h

   ; 输出背景色绿色，前景色红色，并且跳动的字符串"1 MBR"
   mov byte [gs:0x00],'1'
   mov byte [gs:0x01],0xA4     ; A表示绿色背景闪烁，4表示前景色为红色

   mov byte [gs:0x02],' '
   mov byte [gs:0x03],0xA4

   mov byte [gs:0x04],'M'
   mov byte [gs:0x05],0xA4

   mov byte [gs:0x06],'B'
   mov byte [gs:0x07],0xA4

   mov byte [gs:0x08],'R'
   mov byte [gs:0x09],0xA4

   jmp $ ;程序悬停后,内存中数据不被清理,不断在显示器上刷新

   times 510-($-$$) db 0
   db 0x55,0xaa
