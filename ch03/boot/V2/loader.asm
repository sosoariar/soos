; 为什么这个文件会在第二个扇区, 用dd指令写入的时候,在第一个扇区被MBR.bin占去了以后,顺序写到第二扇区
%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR

jmp loader_start

loadermsg db 'HELLO LOADER IN REAL'

loader_start:
; 字符串"HELLO LOADER"
mov byte [gs:0x20],'H'
mov byte [gs:0x21],0xA4

mov byte [gs:0x22],'E'
mov byte [gs:0x23],0xA4

mov byte [gs:0x24],'L'
mov byte [gs:0x25],0xA4

mov byte [gs:0x26],'L'
mov byte [gs:0x27],0xA4

mov byte [gs:0x28],'O'
mov byte [gs:0x29],0xA4

mov byte [gs:0x2a],' '
mov byte [gs:0x2b],0xA4

mov byte [gs:0x2c],'L'
mov byte [gs:0x2d],0xA4

mov byte [gs:0x2e],'O'
mov byte [gs:0x2f],0xA4

mov byte [gs:0x30],'A'
mov byte [gs:0x31],0xA4

mov byte [gs:0x32],'D'
mov byte [gs:0x33],0xA4

mov byte [gs:0x34],'E'
mov byte [gs:0x35],0xA4

mov byte [gs:0x36],'R'
mov byte [gs:0x37],0xA4

jmp $
