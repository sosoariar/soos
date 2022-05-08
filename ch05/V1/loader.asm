%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

; 实模式下,表达方式是直接赋予16位寄存器的值
; 保护模式下,通过GDT封装后,需要 lgdt 指令解析
    GDT_BASE:   dd    0x00000000
           dd    0x00000000

    CODE_DESC:  dd    0x0000FFFF
           dd    DESC_CODE_HIGH4

    DATA_STACK_DESC:  dd    0x0000FFFF
             dd    DESC_DATA_HIGH4

    VIDEO_DESC: dd    0x80000007
           dd    DESC_VIDEO_HIGH4

    GDT_SIZE   equ   $ - GDT_BASE
    GDT_LIMIT   equ   GDT_SIZE -	1
    times 60 dq 0
    SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0
    SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0	 ; 同上
    SELECTOR_VIDEO equ (0x0003<<3) + TI_GDT + RPL0	 ; 同上

;用于存储获取到的内存容量
    total_men_bytes dd 0 ;4字节变量

    gdt_ptr  dw  GDT_LIMIT
        dd  GDT_BASE

;定义一个缓冲区
;人工对齐:total_mem_bytes4字节+gdt_ptr6字节+ards_buf244字节+ards_nr2,共256字节
    ards_buf times 244 db 0
    ards_nr dw 0		        ;用于记录ards结构体数量

loader_start:
;edx 的赋值,是为了初始化内存硬件的操作方式
;edx = 534D4150h ('SMAP') 获取内存布局

    xor ebx, ebx		        ;置ebx为0
    mov edx, 0x534d4150	        ;edx只赋值一次，循环体中不会改变
    mov di, ards_buf	        ;ards结构缓冲区

; 循环获取每个ARDS内存范围描述结构
    mov eax, 0x0000e820
    mov ecx, 20		      ;ARDS大小是20字节
    int 0x15
    jc .e820_failed_so_try_e801   ;若cf==1,则E820模式失效,跳转到0xe801,尝试从此处开始操作
    add di, cx		      ;使di增加20字节指向缓冲区中新的ARDS结构位置
    inc word [ards_nr]	  ;记录ARDS数量
    cmp ebx, 0		      ;若ebx为0且cf不为1,这说明ards全部返回，当前已是最后一个
    jnz .e820_mem_get_loop

; 执行到此处,说明通过BIOS中断获得了物理内存结构的数据
; 下面的代码找出最大的内存块
.find_max_mem_area:
   mov eax, [ebx]	      ;base_add_low
   add eax, [ebx+8]	      ;length_low
   add ebx, 20		      ;指向缓冲区中下一个ARDS结构
   cmp edx, eax		      ;冒泡排序，找出最大,edx寄存器始终是最大的内存容量
   jge .next_ards
   mov edx, eax		      ;edx为总内存大小
.next_ards:
   loop .find_max_mem_area
   jmp .mem_get_ok

;E801h 模式
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
   mul ecx		    ;32位乘法,默认的被乘数是eax,积为64位,高32位存入edx,低32位存入eax.
   add esi,eax		;由于此方法只能测出4G以内的内存,故32位eax足够了,edx肯定为0,只加eax便可
   mov edx,esi		;edx为总内存大小
   jmp .mem_get_ok

; 0x88 模式
.e801_failed_so_try88:
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



;----------------------------------------   准备进入保护模式   ------------------------------------------
;1 打开A20
;2 加载gdt
;3 将cr0的pe位置1
;-----------------  打开A20  ----------------
    in al,0x92
    or al,0000_0010B
    out 0x92,al

;-----------------  加载GDT  ----------------
    lgdt [gdt_ptr]

;-----------------  cr0的第0位置1  ----------------
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start

; 在32位保护模式下, 通过SELECTOR_DATA 可以得到类似实模式下寄存器的值,
; 下面这段程序类似实模式下操作段寄存器,只不过现在是通过SELECTOR来定位地址
[bits 32]
p_mode_start:
   mov ax, SELECTOR_DATA
   mov ds, ax
   mov es, ax
   mov ss, ax
   mov esp,LOADER_STACK_TOP
   mov ax, SELECTOR_VIDEO
   mov gs, ax

   mov byte [gs:320], 'P'

   jmp $