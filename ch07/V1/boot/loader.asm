%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR

; --------------------------------- GDT 构建 ---------------------------------
GDT_BASE:
    dd    0x00000000
    dd    0x00000000

CODE_DESC:
    dd    0x0000FFFF
    dd    DESC_CODE_HIGH4

DATA_STACK_DESC:
    dd    0x0000FFFF
    dd    DESC_DATA_HIGH4

VIDEO_DESC:
    dd    0x80000007
    dd    DESC_VIDEO_HIGH4

GDT_SIZE        equ   $-GDT_BASE
GDT_LIMIT       equ   GDT_SIZE-1
times 60 dq 0

SELECTOR_CODE   equ     (0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA   equ     (0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO  equ     (0x0003<<3) + TI_GDT + RPL0

total_mem_bytes dd 0

gdt_ptr
    dw  GDT_LIMIT
    dd  GDT_BASE

ards_buf times 244 db 0
ards_nr dw 0

loader_start:

   xor ebx, ebx
   mov edx, 0x534d4150
   mov di, ards_buf

.e820_mem_get_loop:
   mov eax, 0x0000e820
   mov ecx, 20
   int 0x15
   jc .e820_failed_so_try_e801
   add di, cx
   inc word [ards_nr]
   cmp ebx, 0
   jnz .e820_mem_get_loop


   mov cx, [ards_nr]
   mov ebx, ards_buf
   xor edx, edx
.find_max_mem_area:
   mov eax, [ebx]
   add eax, [ebx+8]
   add ebx, 20
   cmp edx, eax
   jge .next_ards
   mov edx, eax
.next_ards:
   loop .find_max_mem_area
   jmp .mem_get_ok

; ------  int 15h ax = E801h 获取内存大小,最大支持4G  ------
; 返回后, ax cx 值一样,以KB为单位,bx dx值一样,以64KB为单位
; 在ax和cx寄存器中为低16M,在bx和dx寄存器中为16MB到4G。
.e820_failed_so_try_e801:
   mov ax,0xe801
   int 0x15
   jc .e801_failed_so_try88   ;若当前e801方法失败,就尝试0x88方法

;1 先算出低15M的内存,ax和cx中是以KB为单位的内存数量,将其转换为以byte为单位
   mov cx,0x400	     ;cx和ax值一样,cx用做乘数
   mul cx
   shl edx,16
   and eax,0x0000FFFF
   or edx,eax
   add edx, 0x100000 ;ax只是15MB,故要加1MB
   mov esi,edx	     ;先把低15MB的内存容量存入esi寄存器备份

;2 再将16MB以上的内存转换为byte为单位,寄存器bx和dx中是以64KB为单位的内存数量
   xor eax,eax
   mov ax,bx
   mov ecx, 0x10000	;0x10000十进制为64KB
   mul ecx		;32位乘法,默认的被乘数是eax,积为64位,高32位存入edx,低32位存入eax.
   add esi,eax		;由于此方法只能测出4G以内的内存,故32位eax足够了,edx肯定为0,只加eax便可
   mov edx,esi		;edx为总内存大小
   jmp .mem_get_ok

;-----------------  int 15h ah = 0x88 获取内存大小,只能获取64M之内  ----------
.e801_failed_so_try88:
   ;int 15后，ax存入的是以kb为单位的内存容量
   mov  ah, 0x88
   int  0x15
   jc .error_hlt
   and eax,0x0000FFFF

   ;16位乘法，被乘数是ax,积为32位.积的高16位在dx中，积的低16位在ax中
   mov cx, 0x400     ;0x400等于1024,将ax中的内存容量换为以byte为单位
   mul cx
   shl edx, 16	     ;把dx移到高16位
   or edx, eax	     ;把积的低16位组合到edx,为32位的积
   add edx,0x100000  ;0x88子功能只会返回1MB以上的内存,故实际内存大小要加上1MB

.mem_get_ok:
   mov [total_mem_bytes], edx	 ;将内存换为byte单位后存入total_mem_bytes处。

;----   准备进入保护模式   ----
;1 打开A20
;2 加载gdt
;3 将cr0的pe位置1

    ;-----------------  打开A20  ----------------
    in al,0x92
    or al,0000_0010B
    out 0x92,al

    ;-----------------  加载GDT  ----------------
    lgdt [gdt_ptr]

    ;-----------------  cr0  ----------------
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start

.error_hlt:		      ;出错则挂起
   hlt

[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp,LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

; -------------------------   加载kernel  ----------------------
   mov eax, KERNEL_START_SECTOR        ; kernel.bin所在的扇区号
   mov ebx, KERNEL_BIN_BASE_ADDR       ; 从磁盘读出后，写入到ebx指定的地址
   mov ecx, 200			       ; 读入的扇区数

   call rd_disk_m_32

; 创建页目录及页表并初始化页内存位图
    call setup_page

;要将描述符表地址及偏移量写入内存gdt_ptr,一会用新地址重新加载
   sgdt [gdt_ptr]	      ; 存储到原来gdt所有的位置

;将gdt描述符中视频段描述符中的段基址+0xc0000000
   mov ebx, [gdt_ptr + 2]
   or dword [ebx + 0x18 + 4], 0xc0000000

;将gdt的基址加上0xc0000000使其成为内核所在的高地址
   add dword [gdt_ptr + 2], 0xc0000000

   add esp, 0xc0000000

   mov eax, PAGE_DIR_TABLE_POS
   mov cr3, eax

   mov eax, cr0
   or eax, 0x80000000
   mov cr0, eax

   lgdt [gdt_ptr]

   jmp SELECTOR_CODE:enter_kernel

enter_kernel:

   call kernel_init

   mov esp, 0xc009f000
   jmp KERNEL_ENTRY_POINT                 ; 用地址0x1500访问测试，结果ok

;-----------------   将kernel.bin中的segment拷贝到编译的地址   -----------
kernel_init:
   xor eax, eax
   xor ebx, ebx
   xor ecx, ecx
   xor edx, edx

   mov dx, [KERNEL_BIN_BASE_ADDR + 42]
   mov ebx, [KERNEL_BIN_BASE_ADDR + 28]
   add ebx, KERNEL_BIN_BASE_ADDR
   mov cx, [KERNEL_BIN_BASE_ADDR + 44]

.each_segment:
   cmp byte [ebx + 0], PT_NULL
   je .PTNULL

   push dword [ebx + 16]
   mov eax, [ebx + 4]
   add eax, KERNEL_BIN_BASE_ADDR
   push eax
   push dword [ebx + 8]
   call mem_cpy
   add esp,12
.PTNULL:
   add ebx, edx
   loop .each_segment
   ret

mem_cpy:
   cld
   push ebp
   mov ebp, esp
   push ecx
   mov edi, [ebp + 8]	   ; dst
   mov esi, [ebp + 12]	   ; src
   mov ecx, [ebp + 16]	   ; size
   rep movsb		   ; 逐字节拷贝

   ;恢复环境
   pop ecx
   pop ebp
   ret

   jmp $

;-------------   创建页目录及页表   ---------------
setup_page:
;先把页目录占用的空间逐字节清0
   mov ecx, 4096    ;页目录表大小4KB,循环执行4096次清零操作
   mov esi, 0
.clear_page_dir:
   mov byte [PAGE_DIR_TABLE_POS + esi], 0
   inc esi
   loop .clear_page_dir

;开始创建页目录项(Page Directory Entry PDE)
.create_pde:
   mov eax, PAGE_DIR_TABLE_POS
   add eax, 0x1000 			     ; 此时eax为第一个页表(PTE)的位置及属性
   mov ebx, eax				     ; 此处为ebx赋值，是为.create_pte做准备，ebx为基址。

;   两个页目录项, 页目录项0, 页目录项0xc00
   or eax, PG_US_U | PG_RW_W | PG_P	         ; 页目录项的属性RW和P位为1,US为1,表示用户属性,所有特权级别都可以访问.
   mov [PAGE_DIR_TABLE_POS + 0x0], eax       ; 第1个目录项,在页目录表中的第1个目录项写入第一个页表的位置(0x101000)及属性(7)
   mov [PAGE_DIR_TABLE_POS + 0xc00], eax     ; 一个页表项占用4字节,0xc00表示第768个页表占用的目录项,0xc00以上的目录项用于内核空间,
					                         ; 也就是页表的0xc0000000~0xffffffff共计1G属于内核,0x0~0xbfffffff共计3G属于用户进程.
   sub eax, 0x1000
   mov [PAGE_DIR_TABLE_POS + 4092], eax	     ; 使最后一个目录项指向页目录表自己的地址

;下面创建页表项(PTE)
   mov ecx, 256				                 ; 1M低端内存 / 每页大小4k = 256
   mov esi, 0
   mov edx, PG_US_U | PG_RW_W | PG_P	     ; 属性为7,US=1,RW=1,P=1

.create_pte:				     ; 创建Page Table Entry
   mov [ebx+esi*4],edx			     ; 此时的ebx已经在上面通过eax赋值为0x101000,也就是第一个页表的地址
   add edx,4096      ; edx
   inc esi
   loop .create_pte

;创建内核其它页表的PDE
   mov eax, PAGE_DIR_TABLE_POS
   add eax, 0x2000 		     ; 此时eax为第二个页表的位置
   or eax, PG_US_U | PG_RW_W | PG_P  ; 页目录项的属性US,RW和P位都为1
   mov ebx, PAGE_DIR_TABLE_POS
   mov ecx, 254			     ; 范围为第769~1022的所有目录项数量
   mov esi, 769
.create_kernel_pde:
   mov [ebx+esi*4], eax
   inc esi
   add eax, 0x1000
   loop .create_kernel_pde
   ret

;-------------------------------------------------------------------------------
;功能:读取硬盘n个扇区
rd_disk_m_32:
;-------------------------------------------------------------------------------
; eax=LBA扇区号
; ebx=将数据写入的内存地址
; ecx=读入的扇区数
  mov esi,eax	   ; 备份eax
  mov di,cx		   ; 备份扇区数到di
;读写硬盘:
;第1步：设置要读取的扇区数
  mov dx,0x1f2
  mov al,cl
  out dx,al        ;读取的扇区数
  mov eax,esi	   ;恢复ax

;第2步：将LBA地址存入0x1f3 ~ 0x1f6
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
  and al,0x0f	   ;lba第24~27位
  or al,0xe0	   ; 设置7～4位为1110,表示lba模式
  mov dx,0x1f6
  out dx,al

;第3步：向0x1f7端口写入读命令，0x20
  mov dx,0x1f7
  mov al,0x20
  out dx,al

;;;;;;; 至此,硬盘控制器便从指定的lba地址(eax)处,读出连续的cx个扇区,下面检查硬盘状态,不忙就能把这cx个扇区的数据读出来

;第4步：检测硬盘状态
.not_ready:		   ;测试0x1f7端口(status寄存器)的的BSY位
  ;同一端口,写时表示写入命令字,读时表示读入硬盘状态
  nop
  in al,dx
  and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输,第7位为1表示硬盘忙
  cmp al,0x08
  jnz .not_ready	   ;若未准备好,继续等。

;第5步：从0x1f0端口读数据
  mov ax, di

  mov dx, 256	   ;di为要读取的扇区数,一个扇区有512字节,每次读入一个字,共需di*512/2次,所以di*256
  mul dx
  mov cx, ax
  mov dx, 0x1f0

.go_on_read:
  in ax,dx
  mov [ebx], ax
  add ebx, 2

  loop .go_on_read
  ret