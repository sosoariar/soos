; 全局参数配置

;---- loader ----
LOADER_BASE_ADDR equ 0x900  ;实模式下一块可用的内存地址
LOADER_START_SECTOR equ 0x2 ;LBA定义的逻辑地址,表示在第二扇区

PAGE_DIR_TABLE_POS equ 0x100000 ;二级页目录表，页表放在内存中1M起始位置连续存放

;---- GDT 宏参数 ----
; 段描述符属性
; 符号名命名规则 DESC_字段名_字段相关信息
; 例如 DESC_G_4K 表示段描述符的第55位G标号,也就是高32位的第23位 G=1时表示4K粒度
DESC_G_4K               equ        0x01<<23                      ;4K粒度
DESC_D_32               equ        0x01<<22                      ;表示32位操作位
DESC_L	                equ        0x00<<21
DESC_AVL                equ        0_00000000000000000000b       ; 这个位没有实际意义
DESC_LIMIT_CODE2        equ        1111_0000000000000000b
DESC_LIMIT_DATA2        equ        DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2       equ        0000_000000000000000b
DESC_P	                equ        1_000000000000000b

; 执行下列标记的内存段,当前进程的特权级要高于内存的特权级,进程的特权级绑定在哪个数据结构中？
DESC_DPL_0              equ		   00_0000000000000b    ;对应的内存段特权级是0
DESC_DPL_1              equ		   01_0000000000000b    ;对应的内存段特权级是1
DESC_DPL_2              equ		   10_0000000000000b    ;对应的内存段特权级是2
DESC_DPL_3              equ		   11_0000000000000b    ;对应的内存段特权级是3

DESC_S_CODE             equ		   1_000000000000b
DESC_S_DATA             equ		   DESC_S_CODE
DESC_S_sys              equ		   0_000000000000b
DESC_TYPE_CODE          equ		   1000_00000000b	;x=1,c=0,r=0,a=0 代码段是可执行的,非依从的,不可读的,已访问位a清0.
DESC_TYPE_DATA          equ		   0010_00000000b	;x=0,e=0,w=1,a=0 数据段是不可执行的,向上扩展的,可写的,已访问位a清0.

; 0x00<<24 表示第24位到31位,2个字节，平坦模式段基址是0,所以高32位中 24~31位是0
DESC_CODE_HIGH4         equ     (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
DESC_DATA_HIGH4         equ     (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
DESC_VIDEO_HIGH4        equ     (0x00 << 24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b

;---- 选择子属性 ----
RPL0        equ   00b
RPL1        equ   01b
RPL2        equ   10b
RPL3        equ   11b
TI_GDT	    equ   000b
TI_LDT	    equ   100b

;---- 页表相关属性 ----
PG_P     equ  1b  ;段是否在内存
PG_RW_R	 equ  00b
PG_RW_W	 equ  10b
PG_US_S	 equ  000b
PG_US_U	 equ  100b