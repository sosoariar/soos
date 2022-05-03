; 为什么这个文件会在第二个扇区, 用dd指令写入的时候,在第一个扇区被MBR.bin占去了以后,顺序写到第二扇区
%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR

; 输出背景色绿色，前景色红色，并且跳动的字符串"1 MBR"
mov byte [gs:0x20],'H'
mov byte [gs:0x21],0x07

mov byte [gs:0x22],'E'
mov byte [gs:0x23],0x07

mov byte [gs:0x24],'L'
mov byte [gs:0x25],0x07

mov byte [gs:0x26],'L'
mov byte [gs:0x27],0x07

mov byte [gs:0x28],'O'
mov byte [gs:0x29],0x07

mov byte [gs:0x2a],' '
mov byte [gs:0x2b],0x07

mov byte [gs:0x2c],'L'
mov byte [gs:0x2d],0x07

mov byte [gs:0x2e],'O'
mov byte [gs:0x2f],0x07

mov byte [gs:0x30],'A'
mov byte [gs:0x31],0x07

mov byte [gs:0x32],'D'
mov byte [gs:0x33],0x07

mov byte [gs:0x34],'E'
mov byte [gs:0x35],0x07

mov byte [gs:0x36],'R'
mov byte [gs:0x37],0x07

jmp $		       ; 通过死循环使程序悬停在此
