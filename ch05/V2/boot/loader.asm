%include "boot.inc"

section loader vstart=LOADER_BASE_ADDR
jmp loader_start

; --------------------------------- GDT 构建 ---------------------------------
; 构建gdt及其内部的描述符
; 全局描述符表GDT是一片内存区域,每隔8个字节便是一个表现,dd 可以定义一个4字节,下面定义方式是高,低两个4字节
; GDT的第0个描述符不可用

GDT_BASE:
    dd    0x00000000
    dd    0x00000000

; 代码段描述符
CODE_DESC:
    dd    0x0000FFFF
    dd    DESC_CODE_HIGH4

; 数据段和栈段描述符
; 数据段和栈段共同使用一个段描述符,栈是向下扩展,数据段是向上扩展
DATA_STACK_DESC:
    dd    0x0000FFFF
    dd    DESC_DATA_HIGH4

; 显存段描述符
VIDEO_DESC:
    dd    0x80000007	       ; limit=(0xbffff-0xb8000)/4k=0x7
    dd    DESC_VIDEO_HIGH4     ; 此时dpl为0

GDT_SIZE        equ   $-GDT_BASE
GDT_LIMIT       equ   GDT_SIZE-1
times 60 dq 0

; --------------------------------- GDT 构建 ---------------------------------
; selector 的宏功能参数初始化
SELECTOR_CODE   equ     (0x0001<<3) + TI_GDT + RPL0     ; (CODE_DESC - GDT_BASE)/8 + TI_GDT + RPL0
SELECTOR_DATA   equ     (0x0002<<3) + TI_GDT + RPL0	    ; 同上
SELECTOR_VIDEO  equ     (0x0003<<3) + TI_GDT + RPL0	    ; 同上

; total_mem_bytes用于保存内存容量
total_mem_bytes dd 0

; 定义全局描述符表 GDT 的指针,此指针是 lgdt 加载 GDT 到 gdtr 寄存器时用的
; 以下两行供48位寄存器GDTR加载GDT表使用
gdt_ptr
    dw  GDT_LIMIT   ; 16 位GDT以字节的界限
    dd  GDT_BASE    ; GDT 的32位起始地址

;定义一个缓冲区
ards_buf times 244 db 0
ards_nr dw 0		      ;用于记录ards结构体数量

loader_start:

;;;; 内存获取并缓存到 total_mem_bytes ;;;;
;检测功能的强弱 0xe820 0xe801 0x88
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
.e820_failed_so_try_e801:
   mov ax,0xe801
   int 0x15
   jc .e801_failed_so_try88

   mov cx,0x400
   mul cx
   shl edx,16
   and eax,0x0000FFFF
   or edx,eax
   add edx, 0x100000
   mov esi,edx

   xor eax,eax
   mov ax,bx
   mov ecx, 0x10000
   mul ecx
   add esi,eax
   mov edx,esi
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

    jmp dword SELECTOR_CODE:loader_print_32

.error_hlt:		      ;出错则挂起
   hlt

[bits 32]
loader_print_32:

    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp,LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

; 创建页目录及页表并初始化页内存位图
   call setup_page

; 要将描述符表地址及偏移量写入内存gdt_ptr,一会用新地址重新加载
   sgdt [gdt_ptr]

; 将gdt描述符中视频段描述符中的段基址+0xc0000000
   mov ebx, [gdt_ptr + 2]
   or dword [ebx + 0x18 + 4], 0xc0000000

;将gdt的基址加上0xc0000000使其成为内核所在的高地址
    add dword [gdt_ptr + 2], 0xc0000000

    add esp, 0xc0000000
    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax

; 打开cr0的pg位(第31位)
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

;在开启分页后,用gdt新的地址重新加载
    lgdt [gdt_ptr]             ; 重新加载

    mov byte [gs:0x0C],' '
    mov byte [gs:0x0D],0X07

    mov byte [gs:0x0E],' '
    mov byte [gs:0x0F],0X07

    mov byte [gs:0x10],'P'
    mov byte [gs:0x11],0X07

    mov byte [gs:0x12],'R'
    mov byte [gs:0X13],0X07

    mov byte [gs:0x14],'O'
    mov byte [gs:0x15],0X07

   jmp $

;-------------   创建页目录及页表   ---------------
setup_page:
    ;先把页目录占用的空间逐字节清0
    mov ecx, 4096
    mov esi, 0
.clear_page_dir:
   mov byte [PAGE_DIR_TABLE_POS + esi], 0
   inc esi
   loop .clear_page_dir

;开始创建页目录项(PDE)
.create_pde:
   mov eax, PAGE_DIR_TABLE_POS
   add eax, 0x1000 			     ; 此时eax为第一个页表的位置及属性
   mov ebx, eax

;   下面将页目录项0和0xc00都存为第一个页表的地址，
;   一个页表可表示4MB内存,这样0xc03fffff以下的地址和0x003fffff以下的地址都指向相同的页表，
;   这是为将地址映射为内核地址做准备
   or eax, PG_US_U | PG_RW_W | PG_P	            ; 页目录项的属性RW和P位为1,US为1,表示用户属性,所有特权级别都可以访问.
   mov [PAGE_DIR_TABLE_POS + 0x0], eax          ; 第1个目录项,在页目录表中的第1个目录项写入第一个页表的位置(0x101000)及属性(7)
   mov [PAGE_DIR_TABLE_POS + 0xc00], eax        ; 一个页表项占用4字节,0xc00表示第768个页表占用的目录项,0xc00以上的目录项用于内核空间,
                                                ; 也就是页表的0xc0000000~0xffffffff共计1G属于内核,0x0~0xbfffffff共计3G属于用户进程.
   sub eax, 0x1000
   mov [PAGE_DIR_TABLE_POS + 4092], eax	     ; 使最后一个目录项指向页目录表自己的地址

;下面创建页表项(PTE)
   mov ecx, 256				     ; 1M低端内存 / 每页大小4k = 256
   mov esi, 0
   mov edx, PG_US_U | PG_RW_W | PG_P	     ; 属性为7,US=1,RW=1,P=1
.create_pte:				     ; 创建Page Table Entry
   mov [ebx+esi*4],edx			     ; 此时的ebx已经在上面通过eax赋值为0x101000,也就是第一个页表的地址
   add edx,4096      ; edx
   inc esi
   loop .create_pte

;创建内核其它页表的PDE
   mov eax, PAGE_DIR_TABLE_POS
   add eax, 0x2000
   or  eax, PG_US_U | PG_RW_W | PG_P
   mov ebx, PAGE_DIR_TABLE_POS
   mov ecx, 254			     ; 范围为第769~1022的所有目录项数量
   mov esi, 769
.create_kernel_pde:
   mov [ebx+esi*4], eax
   inc esi
   add eax, 0x1000
   loop .create_kernel_pde
   ret

