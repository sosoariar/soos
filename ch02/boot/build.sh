nasm -o MBR.bin MBR.nasm
dd if=MBR.bin of=hd.img bs=512 count=1 conv=notrunc