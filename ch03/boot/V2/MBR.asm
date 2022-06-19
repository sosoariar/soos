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
    mov byte [gs:0x00],'H'
    mov byte [gs:0x01],0XA4

    mov byte [gs:0x02],'E'
    mov byte [gs:0x03],0XA4

    mov byte [gs:0x04],'L'
    mov byte [gs:0x05],0XA4

    mov byte [gs:0x06],'L'
    mov byte [gs:0X07],0XA4

    mov byte [gs:0x08],'O'
    mov byte [gs:0x09],0XA4

    mov byte [gs:0x0A],'M'
    mov byte [gs:0x0B],0XA4

    mov byte [gs:0x0C],'B'
    mov byte [gs:0x0D],0XA4

    mov byte [gs:0x0E],'R'
    mov byte [gs:0x0F],0XA4

; 以上的内容相当于一个路标,表示程序正常运行到此处了
; dd 指令将 loader.bin 写入 hd.img 的第二扇区

; MBR 程序决定了读取的第二扇区 0x200
   mov eax,LOADER_START_SECTOR
; MBR 程序决定了读取扇区放到内存的0x900
   mov bx,LOADER_BASE_ADDR
   mov cx,4
   call rd_disk_m_16

   jmp LOADER_BASE_ADDR

rd_disk_m_16:
      mov esi,eax

      mov di,cx		  ; 硬盘端口会从约定的该位置读取涉及的扇区数

      mov dx,0x1f2         ; 初始化硬件接口的地址,改地址和bochsrc.disk 的配置有关, 指定位置需要什么参数,可以互联网检索得到
      mov al,cl
      out dx,al

      mov eax,esi

      mov dx,0x1f3         ; 初始化硬件接口的地址,改地址和bochsrc.disk 的配置有关, 指定位置需要什么参数,可以互联网检索得到
      out dx,al

      mov cl,8
      shr eax,cl
      mov dx,0x1f4          ; 初始化硬件接口的地址,改地址和bochsrc.disk 的配置有关, 指定位置需要什么参数,可以互联网检索得到
      out dx,al

      shr eax,cl
      mov dx,0x1f5          ; 初始化硬件接口的地址,改地址和bochsrc.disk 的配置有关, 指定位置需要什么参数,可以互联网检索得到
      out dx,al

      shr eax,cl
      and al,0x0f
      or al,0xe0
      mov dx,0x1f6
      out dx,al

      mov dx,0x1f7          ; 改地址可以设置端口的读写方向
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
