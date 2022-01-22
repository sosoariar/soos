# 软件安装

安装 oracle vm virtualbox 版本 6.0.24

一路确认到底的ubuntu20.04安装

![image-20220122192740518](https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/image-20220122192740518.png)

# Ubuntu20.04 系统配置

安装nasm

```shell
sudo apt-get install nasm
```

安装gcc，以下这个命令会一次性安装包括gcc在内的一系列编译软件

```shell
sudo apt install build-essential
```

以上nasm和gcc的安装都是为之后make完成编译和链接工作做准备 

构建工作空间

```shell
mkdir /home/soso/soso/soos -p
```

![image-20220122195321409](G:/Downloads/Pic/image-20220122195321409.png)

![image-20220122195417913](https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/image-20220122195417913.png)

```shell
cd /home/soso/soso/soos
git clone https://gitee.com/lmos/cosmos.git
cd cosmos/lesson02/HelloOS
ls -lrt
```



编译

```shell
make -f Makefile
```

将生成的HelloOS.bin文件拷贝到/boot文件夹下。

其实不是一定强制要HellOS.bin放在/boot文件夹下才能够完成启动，这只是遵循惯例而已。将HellOS放在其他文件夹下，然后之后在grub.cfg文件中设置相应的HellOS.bin的地址即可。

拷贝可以使用"mv"命令，我以自己的情况举例。在HelloOS.bin所在的文件夹打开terminal，使用以下命令进行文件移动

```
sudo mv HelloOS.bin /boot 
```

修改/etc/default/grub文件，将GRUB_TIMEOUT修改为30，设置进入默认启动项的等候时间，默认值为10秒，我们将其延长。使用一下命令打开并编辑grub文件

```
sudo gedit /etc/default/grub 
```

编辑完成后，使用以下命令更新文件设置

```
sudo update-grub
```



在/boot/grub/grub.cfg中添加menuentry，这一步有非常多的坑，老师在文章中的讲解比较简单，但是在具体实现的时候有很多细节要注意。首先打开grub.cfg这个文件，使用以下命令

```
sudo gedit /boot/grub/grub.cfg
```

然后将下面这段专栏中已经给出的配置粘贴到grub.cfg文件中，并保存

```
menuentry 'HelloOS' {

     insmod part_msdos #GRUB加载分区模块识别分区
    
     insmod ext2 #GRUB加载ext文件系统模块识别ext文件系统
    
     set root='hd0,msdos5' #注意boot目录挂载的分区，这是我机器上的情况
    
     multiboot2 /boot/HelloOS.bin #GRUB以multiboot2协议加载HelloOS.bin
    
     boot #GRUB启动HelloOS.bin

} 
```

在虚拟机测试的时候，如果发现一直进不去选择系统的界面，可以在重启虚拟机系统后多次按ESC键，之后就可以出现选择系统的界面了，如无意外，可以看到Hello OS！！

如果前期操作都正确，代码也是clone老师的，那么不出现黑色字符界面，大概率是因为UEFI启动导致的，可以试下改传统启动。

hello.lds 是什么作用的？

这是链接脚本，ld链接器需要根据这个文件内容进行链接elf格式文件的





main.c 最终由 nasm 和 GCC 编译成可链接模块，由LD链接器链接在一起,形成可执行文件;

计算机屏幕显示往往是显卡的输出

显卡在 VESA 标准下的两种工作模式：字符模式 和 图形模式, 为了兼容这种标准，提供 VGABIOS 的固件程序;

一个成熟的商业操作系统更是多达几万个代码模块文件，几千万行的代码量，是这世间最复杂的软件工程之一。所以需要一个牛逼的工具来控制这个巨大的编译过程。

make 是一个工具程序，它读取一个叫“makefile”的文件，也是一种文本文件，这个文件中写好了构建软件的规则，它能根据这些规则自动化构建软件

makefile 案例
```c
CC = gcc #定义一个宏CC 等于gcc
CFLAGS = -c #定义一个宏 CFLAGS 等于-c
OBJS_FILE = file.o file1.o file2.o file3.o file4.o #定义一个宏
.PHONY : all everything #定义两个伪目标all、everything
all:everything #伪目标all依赖于伪目标everything
everything :$(OBJS_FILE) #伪目标everything依赖于OBJS_FILE，而OBJS_FILE是宏会被
#替换成file.o file1.o file2.o file3.o file4.o
%.o : %.c
   $(CC) $(CFLAGS) -o $@ $<
```

![img](https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/cbd634cd5256e372bcbebd4b95f21b34.jpg)

到 Hello OS.bin 文件，但是我们还要让 GRUB 能够找到它，才能在计算机启动时加载它。这个过程我们称为安装

GRUB 在启动时会加载一个 grub.cfg 的文本文件，根据其中的内容执行相应的操作，其中一部分内容就是启动项。

GRUB 首先会显示启动项到屏幕，然后让我们选择启动项，最后 GRUB 根据启动项对应的信息，加载 OS 文件到内存。