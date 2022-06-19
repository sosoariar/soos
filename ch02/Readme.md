执行过程:
1. 构建硬盘 hd.img
2. 编译 MBR 得到可执行代码,指令 dd 写入 hd.img
3. BIOS 从 hd.img 找到MBR可执行代码, 加载到 0x7c00
4. 按 CS:IP 顺序往下执行