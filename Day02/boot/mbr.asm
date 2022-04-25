; 主引导程序
;
SECTION MBR vstart=0x7c00 ; SECTION名MBR , SECTION 起始地址 0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00