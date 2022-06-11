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
;2 加载 GDT
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

; 创建页目录及页表并初始化页内存位图
   call setup_page

;要将描述符表地址及偏移量写入内存gdt_ptr,一会用新地址重新加载
sgdt [gdt_ptr]	      ; 存储到原来gdt所有的位置

 ;将gdt描述符中视频段描述符中的段基址+0xc0000000
   mov ebx, [gdt_ptr + 2]
   or dword [ebx + 0x18 + 4], 0xc0000000      ;视频段是第3个段描述符,每个描述符是8字节,故0x18。
					      ;段描述符的高4字节的最高位是段基址的31~24位

   ;将gdt的基址加上0xc0000000使其成为内核所在的高地址
   add dword [gdt_ptr + 2], 0xc0000000

   add esp, 0xc0000000        ; 将栈指针同样映射到内核地址

   ; 把页目录地址赋给cr3
   mov eax, PAGE_DIR_TABLE_POS
   mov cr3, eax

   ; 打开cr0的pg位(第31位)
   mov eax, cr0
   or eax, 0x80000000
   mov cr0, eax

   ;在开启分页后,用gdt新的地址重新加载
   lgdt [gdt_ptr]             ; 重新加载

   mov byte [gs:160], 'V'     ;视频段段基址已经被更新,用字符v表示virtual addr
   mov byte [gs:162], 'i'     ;视频段段基址已经被更新,用字符v表示virtual addr
   mov byte [gs:164], 'r'     ;视频段段基址已经被更新,用字符v表示virtual addr
   mov byte [gs:166], 't'     ;视频段段基址已经被更新,用字符v表示virtual addr
   mov byte [gs:168], 'u'     ;视频段段基址已经被更新,用字符v表示virtual addr
   mov byte [gs:170], 'a'     ;视频段段基址已经被更新,用字符v表示virtual addr
   mov byte [gs:172], 'l'     ;视频段段基址已经被更新,用字符v表示virtual addr

   jmp $


;-------------   创建页目录及页表   ---------------
; 先建立个页目录表
; 建立个页表
setup_page:
;先把页目录占用的空间逐字节清0
   mov ecx, 4096
   mov esi, 0
.clear_page_dir:
   mov byte [PAGE_DIR_TABLE_POS + esi], 0
   inc esi
   loop .clear_page_dir

;开始创建页目录项(PDE)
.create_pde:				     ; 创建Page Directory Entry
   mov eax, PAGE_DIR_TABLE_POS
   add eax, 0x1000 			     ; 此时eax为第一个页表的位置及属性
   mov ebx, eax				     ; 此处为ebx赋值，是为.create_pte做准备，ebx为基址。

;   下面将页目录项0和0xc00都存为第一个页表的地址，
;   一个页表可表示4MB内存,这样0xc03fffff以下的地址和0x003fffff以下的地址都指向相同的页表，
;   这是为将地址映射为内核地址做准备
   or eax, PG_US_U | PG_RW_W | PG_P	     ; 页目录项的属性RW和P位为1,US为1,表示用户属性,所有特权级别都可以访问.
   mov [PAGE_DIR_TABLE_POS + 0x0], eax       ; 第1个目录项,在页目录表中的第1个目录项写入第一个页表的位置(0x101000)及属性(7)
   mov [PAGE_DIR_TABLE_POS + 0xc00], eax     ; 一个页表项占用4字节,0xc00表示第768个页表占用的目录项,0xc00以上的目录项用于内核空间,
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