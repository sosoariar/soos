#!/bin/bash
# bximage 需要添加在系统 path中
# 32M大小的硬盘,对于用来理解操作系统原理足够了
# 执行 build.sh 后, 在当前目录下生成hd.img 表示硬盘
bximage -hd -mode="flat" -size=32 -q hd.img

# 执行前先安装 sudo apt-get install -y nasm
nasm -o ./MBR.bin ./MBR.asm

dd if=./MBR.bin of=./hd.img bs=512 count=1 conv=notrunc