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

gcc -c -o out/kernel/main.o kernel/main.c

/usr/bin/ld out/kernel/main.o -Ttext 0xc0001500 -e main -o out/kernel/kernel.bin


#----------------step-6 write bin into .img -----------------
dd if=./out/kernel/kernel.bin of=./hd.img bs=512 count=200 seek=9 conv=notrunc