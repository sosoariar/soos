;主引导程序
%include "boot.inc"

SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

;;;; 利用BIOS中断清屏 ;;;;
    mov     ax, 0600h
    mov     bx, 0700h
    mov     cx, 0
    mov     dx, 184fh
    int     10h

; 在与显示有关的实地址上,直接写入数据的方式,显示数据
    mov byte [gs:0x00],'M'
    mov byte [gs:0x01],0X07

    mov byte [gs:0x02],'B'
    mov byte [gs:0x03],0X07

    mov byte [gs:0x04],'R'
    mov byte [gs:0x05],0X07

    mov byte [gs:0x06],'!'
    mov byte [gs:0x07],0X07

; 以上的内容相当于一个路标,表示程序正常运行到此处了
; dd 指令将 loader.bin 写入 hd.img 的第二扇区

; MBR 程序决定了读取的起始扇区 0x200
    mov eax,LOADER_START_SECTOR
; MBR 程序决定了读取扇区放到内存的0x900
    mov bx,LOADER_BASE_ADDR
; MBR 程序决定了读取扇区数量
    mov cx,4

    call rd_disk_m_16

    jmp LOADER_BASE_ADDR + 0x300

rd_disk_m_16:
; 初始化硬件接口的地址,改地址和bochsrc.disk 的配置有关
; ata0:enabled=1,ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14
; 与IO接口之间如何传参,根据实际的硬件要求送数, 在该程序中即如何往 0x1f2 ~ 0x1f7

; 设置硬盘读取的扇区数
    mov esi,eax	        ;备份eax
    mov di,cx		    ;备份cx
;读写硬盘:
;第1步：设置要读取的扇区数
    mov dx,0x1f2
    mov al,cl
    out dx,al        ;读取的扇区数
    mov eax,esi	   ;恢复ax

;第2步:将LBA地址存入0x1f3 ~ 0x1f6
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

    shr eax,cl
    and al,0x0f	   ; lba第24~27位
    or al,0xe0	   ; 设置7～4位为1110,表示lba模式
    mov dx,0x1f6
    out dx,al

;第3步：向0x1f7端口写入读命令，0x20
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

;第5步：从0x1f0端口读数据
    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax	   ; di为要读取的扇区数，一个扇区有512字节，每次读入一个字，共需di*512/2次，所以di*256
    mov dx, 0x1f0
.go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2
    loop .go_on_read
    ret

    times 510-($-$$) db 0
    db 0x55,0xaa
