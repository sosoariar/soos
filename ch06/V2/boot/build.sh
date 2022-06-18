#!/bin/bash
# 在boot路径下执行
#----------------step-1 init-----------------
if [ ! -d "./out" ]; then
  mkdir out
  echo "mkdir out"
fi

if [ -e "hd.img" ]; then
  rm -rf hd.img
  echo "rm -rf hd.img"
fi

if [ ! -d "./out/kernel" ];then
    mkdir out/kernel
fi

#----------------step-2 disk image-----------------
echo "create image"
bximage -hd -mode="flat" -size=32 -q hd.img

#----------------step-3 MBR asm -----------------
echo "build asm"
nasm -I include/ -o ./out/MBR.bin MBR.asm

#----------------step-4 write bin into .img -----------------
dd if=./out/MBR.bin of=./hd.img bs=512 count=1  conv=notrunc

#----------------step-5 asm -----------------
nasm -I include/ -o ./out/loader.bin loader.asm
dd if=./out/loader.bin of=./hd.img bs=512 count=4 seek=2 conv=notrunc

nasm -f elf -o ./out/kernel/print.o ./lib/kernel/print.asm

gcc -m32 -I ./lib/kernel/ -c -o ./out/kernel/main.o ./kernel/main.c

# 最终生产的可执行文件的起始虚拟地址，可以用-Ttext参数来指定
ld -melf_i386  -Ttext 0xc0001500 -e main -o ./out/kernel/kernel.bin out/kernel/main.o out/kernel/print.o

#----------------step-6 write bin into .img -----------------
dd if=./out/kernel/kernel.bin of=./hd.img bs=512 count=200 seek=9 conv=notrunc