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

   ; 在寄存器中定义了几个参数,参数有什么作用,还是要看具体逻辑
   mov eax,LOADER_START_SECTOR  ;
   mov bx,LOADER_BASE_ADDR
   mov cx,1

   call rd_disk_m_16
   jmp LOADER_BASE_ADDR ;程序悬停后,内存中数据不被清理,不断在显示器上刷新

;读取硬盘N扇区
rd_disk_m_16:
    mov esi,eax
    mov di,cx

;从硬盘中读数据:
;向硬盘发送要读数据的请求

;第1步：bochsrc.disk 中硬盘设置
;ata0: enabled=true, ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14
;即起始地址为 0x1f0
    mov dx,0x1f2         ;该位置可以指定读取的扇区数
    mov al,cl
    out dx,al            ;读取的扇区数
    mov eax,esi	   ;恢复ax

; 往下列地址写入数据,可以初始化硬盘的读数据状态
    ;LBA地址7~0位写入端口0x1f3
    mov dx,0x1f3
    out dx,al
    ;LBA地址15~8位写入端口0x1f4
    mov cl,8
    shr eax,cl
    mov dx,0x1f4
    out dx,al
    ;LBA地址23~16位写入端口0x1f5
    shr eax,cl
    mov dx,0x1f5
    out dx,al

    ; 往device 寄存器中写入LBA 地址的24～27 位，并置第6 位为l ，使其为LBA 模式，设置第4
    ;位，选择操作的硬盘（ master 硬盘或slave 硬盘）。
    shr eax,cl
    and al,0x07	   ;lba第24~27位
    or al,0xe0	   ; 设置7～4位为1110,表示lba模式
    mov dx,0x1f6
    out dx,al

;第3步：向硬盘发出读命令，0x20
    mov dx,0x1f7
    mov al,0x20
    out dx,al

;第4步：检测硬盘状态
  .not_ready:
      ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
      nop
      in al,dx
      and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输，第7位为1表示硬盘忙
      cmp al,0x08
      jnz .not_ready	   ;若未准备好，继续等。

;第5步：硬盘状态准备好后,开始从指定端口读取数据
;0x1f0~0x1f2 只有16位,即2字节的data缓冲,即每次in操作只读入2字节
;di为要读取的扇区数，一个扇区有512字节，每次读入2字节
; 共需di*512/2次，所以di*256
      mov ax, di
      mov dx, 256
      mul dx
      mov cx, ax
;初始化数据读回地址
      mov dx, 0x1f0
;通过ox1f0端口读的数据顺序写入到指定地址0x900为起始地址的内存
  .go_on_read:
      in ax,dx
      mov [bx],ax
      add bx,2
      loop .go_on_read
      ret

   times 510-($-$$) db 0
   db 0x55,0xaa

