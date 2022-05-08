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