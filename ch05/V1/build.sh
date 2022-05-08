#!/bin/bash
if [ ! -d "./out" ]; then
      mkdir out
fi

if [ -e "hd.img" ]; then
     rm -rf hd.img
fi

/root/proc/bochs/bin/bximage -hd -mode="flat" -size=32 -q hd.img
nasm -I include/ -o ./out/MBR.bin MBR.asm && dd if=./out/MBR.bin of=./hd.img bs=512 count=1  conv=notrunc
nasm -I include/ -o ./out/loader.bin loader.asm && dd if=./out/loader.bin of=./hd.img bs=512 count=1 seek=2 conv=notrunc
