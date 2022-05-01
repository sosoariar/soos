%include "boot.inc" ; nasm编译器提供的预处理指令
SECTION MBR vstart=0x7c00 ; 该SECTION在内存的起始地址 0x7c00
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

   mov eax,LOADER_START_SECTOR
   mov bx,LOADER_BASE_ADDR
   mov cx,1

   call rd_disk_m_16
   jmp LOADER_BASE_ADDR ;程序悬停后,内存中数据不被清理,不断在显示器上刷新

;读取硬盘N扇区
rd_disk_m_16:
    mov esi,eax
    mov di,cx

;读写硬盘:
;第1步：设置要读取的扇区数, 即将扇区数量通过IO端口输出
    mov dx,0x172         ;选择通道,往该通道的sector count寄存器中写入待操作的扇区数,bochsrc.disk 中配置了硬盘的端口
    mov al,cl
    out dx,al            ;读取的扇区数
    mov eax,esi	   ;恢复ax
; 往该通道上的三个LBA寄存器写入扇区起始地址的低24位
    ;LBA地址7~0位写入端口0x1f3
    mov dx,0x173
    out dx,al

    ;LBA地址15~8位写入端口0x1f4
    mov cl,8
    shr eax,cl
    mov dx,0x174
    out dx,al

    ;LBA地址23~16位写入端口0x1f5
    shr eax,cl
    mov dx,0x175
    out dx,al
    ; 往device 寄存器中写入LBA 地址的24～27 位，并置第6 位为l ，使其为LBA 模式，设置第4
    ;位，选择操作的硬盘（ master 硬盘或slave 硬盘）。
    shr eax,cl
    and al,0x07	   ;lba第24~27位
    or al,0xe0	   ; 设置7～4位为1110,表示lba模式
    mov dx,0x176
    out dx,al

;第3步：向硬盘发出读命令，0x20
    mov dx,0x177
    mov al,0x20
    out dx,al

   times 510-($-$$) db 0
   db 0x55,0xaa

