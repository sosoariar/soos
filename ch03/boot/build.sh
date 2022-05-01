#!/bin/bash
# 在boot路径下执行
#----------------step-1 init-----------------
if [ ! -d "./out" ];
then mkdir out
echo "mkdir out"
fi

if [ -e "hd.img" ];
then
     rm -rf hd.img
     ehco "rm hd.img"
fi

#----------------step-2 disk image-----------------
echo "creat hd.img 64M"
bximage -mode="create" -hd=64M -imgmode="flat" -q hd.img

#----------------step-3 MBR asm -----------------
nasm -I include/ -o ./out/MBR.bin MBR.asm

#----------------step-4 write bin into .img -----------------
dd if=./out/MBR.bin of=./hd.img bs=512 count=1  conv=notrunc

#----------------step-5 asm -----------------
nasm -I include/ -o ./out/loader.bin loader.S

#----------------step-6 write bin into .img -----------------
dd if=./out/loader.bin of=./hd.img bs=512 count=1 seek=2 conv=notrunc