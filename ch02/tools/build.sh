bximage -mode="create" -hd=16M -imgmode="flat" -q hd.img
nasm boot.asm -o  boot.bin
dd if=boot.bin of=hd.img bs=512 count=1 conv=notrunc
