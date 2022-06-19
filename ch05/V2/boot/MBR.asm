;;;; MBR 功能: 从后续扇区中加载 ;;;;
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
    mov ax, 0x0600
    mov bx, 0x0700
    mov cx, 0
    mov dx, 0x184f
    int 0x10

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
      mov esi,eax
      mov di,cx

 ; 初始化硬件接口的地址,改地址和bochsrc.disk 的配置有关
 ; ata0:enabled=1,ioaddr1=0x1f0, ioaddr2=0x3f0, irq=14
 ; 与IO接口之间如何传参,根据实际的硬件要求送数, 在该程序中即如何往 0x1f2 ~ 0x1f7

 ; 设置硬盘读取的扇区数
      mov dx,0x1f2
      mov al,cl
      out dx,al

; 通知hd.img用LBA方式及哪些个内存地址交换数据
      mov eax,esi
      mov dx,0x1f3
      out dx,al

      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f
      or al,0xe0
      mov dx,0x1f6
      out dx,al

; 向hd.img发出读命令
      mov dx,0x1f7
      mov al,0x20
      out dx,al

; 从约定的状态位中,查看硬盘的数据是否准备完成
  .not_ready:
      nop
      in al,dx
      and al,0x88
      cmp al,0x08
      jnz .not_ready

; 从哪里开始读数据
      mov ax, di
      mov dx, 256
      mul dx
      mov cx, ax
      mov dx, 0x1f0 ;读数据的起始地址,这个地址是配置，也是和硬件的约定

; 循环读数,当数据读写完成,硬件会改变CPU寄存器的状态位
  .go_on_read:
      in ax,dx
      mov [bx],ax   ; 程序开始定义的读取得数据存放在内存的哪个地方
      add bx,2
      loop .go_on_read
      ret

   times 510-($-$$) db 0
   db 0x55,0xaa
