/root/proc/bochs/bin/bximage -hd -mode="flat" -size=32 -q hd.img
nasm -o ./MBR.bin ./MBR.asm
dd if=./MBR.bin of=./hd.img bs=512 count=1 conv=notrunc