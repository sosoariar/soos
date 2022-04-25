; 主引导程序
;
SECTION MBR vstart=0x7c00 ; SECTION名MBR , SECTION 起始地址 0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00

; 清屏 利用0x06号功能，上卷全部行，则可清屏。
; -----------------------------------------------------------
;INT 0x10   功能号:0x06	   功能描述:上卷窗口
;------------------------------------------------------
; VGA文本模式中,一行只能容纳80个字符,共25行。
; 下标从0开始,所以0x18=24,0x4f=79
   mov     ax, 0x600
   mov     bx, 0x700
   mov     cx, 0           ; 左上角: (0, 0)
   mov     dx, 0x184f	   ; 右下角: (80,25),

   int     0x10            ; int 0x10