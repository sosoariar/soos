	org	07c00h			    ; 汇编伪指令ORG作用是定义程序或数据块的起始地址
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	call	DispStr			; 调用显示字符串例程
	jmp	$			        ; 无限循环
    ;显示字符串子程序
DispStr:
	mov	ax, BootMessage ;任何不被方括号[]括起来的标签或变量名都被认为是地址
	mov	bp, ax			; ES:BP = 串地址
	mov	cx, 16			; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 000ch		; 页号为0(BH = 0) 黑底红字(BL = 0Ch,高亮)
	mov	dl, 0
	int	10h			; 10h 号中断
	ret

BootMessage:		db	"Hello, OS world!"  ;访问该标签中的内容，需要使用[]

times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 以word的方式写入 AA55, 作为第一扇区的结束标志