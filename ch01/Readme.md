计算机硬件无法直接运行.c文件，计算机运行的是二进制文件，.c文件到二进制文件需要通过编译器转换； 

编译过程 

硬件执行程序过程

```
cd /usr/local/soos
gcc HelloWorld.c -o HelloWorld 或者 gcc ./HelloWorld.c -o ./HelloWorld
```



gcc 只是完成编译工作的驱动程序，即把几个工具串成一个执行流程，分别调用了 预处理程序，编译程序，汇编程序，链接程序；

<img src="https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/image-20220122115215954.png" alt="image-20220122115215954" style="zoom: 50%;" />

手动控制  GCC 过程

```shell
gcc HelloWorld.c -E -o HelloWorld.i # 预处理:加入头文件,替换宏
gcc HelloWorld.c -S -c -o HelloWorld.s # 编译,包含预处理,将源文件转换为汇编
gcc HelloWorld.c -c -o HelloWorld.o # 汇编,将汇编转换成可链接的二进制程序
gcc HelloWorld.c -o HelloWorld # 链接,
```

冯诺依曼体系：

1. 将程序和数据装入到计算机中；
2. 必须具有长期存储程序代码，数据及中间结果，或最终运算结果
3. 完成数据运算，数据传输
4. 控制程序执行方式
5. 数据人类可读

<img src="https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/image-20220122122344757.png" alt="image-20220122122344757" style="zoom:50%;" />

数据在内存中的什么位置，通过【地址总线】来寻找对应的位置；

数据在【数据总线 】这种物理介质上传输；

读数据，写数据的控制指令由【控制总线】复制；

获取可执行文件的"汇编反编译"

```shell
objdump -d HelloWorld
```

在云服务器上获得的具体数据

```assembly
000000000040052d <main>:
# 地址       hex 真正装入机器的代码数据   汇编    代码的相关注释
  40052d:       55                      push   %rbp
  40052e:       48 89 e5                mov    %rsp,%rbp
  400531:       48 83 ec 10             sub    $0x10,%rsp
  400535:       89 7d fc                mov    %edi,-0x4(%rbp)
  400538:       48 89 75 f0             mov    %rsi,-0x10(%rbp)
  40053c:       bf e0 05 40 00          mov    $0x4005e0,%edi
  400541:       e8 ca fe ff ff          callq  400410 <puts@plt>
  400546:       b8 00 00 00 00          mov    $0x0,%eax
  40054b:       c9                      leaveq 
  40054c:       c3                      retq   
  40054d:       0f 1f 00                nopl   (%rax)
```

下图优化为后期单字节排列方式

![img](https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/5d4889e7bf20e670ee71cc9b6285c96e.jpg)

函数的调用和返回，使用的是汇编代码的 call ret 指令, call 和 ret 指令在逻辑上执行的操作是什么样？

1. call 调用函数的内存地址在哪，即代码块的第一条指令内存地址
2. 被调用的函数执行完之后，返回哪个位置继续执行？

针对第一个问题，在gcc编译完成之后，函数对应的指令序列所在的位置就已经确定了，因此这是编译阶段需要考虑的问题

至于第二个问题，在执行完call指令的同时，需要将call指令下面一条指令的地址保存到栈内存中，同时更新%rsp寄存器指向的位置，然后就可以开始执行被调函数的指令序列，执行完毕后，由ret指令从rsp中获取栈顶的returnadress地址，然后跳转到call的下一条指令继续执行。



PC的引导程序



GRUB引导程序



**BIOS**

固化在 PC机主板上的ROM芯片中：

负责检测和初始化CPU，内存及主板平台；

加载引导设备中的第一扇区数据到 0x7c00 地址开始的内存空间；

跳转到 0x7c00 处执行指令；



**Hello OS 引导汇编代码**

C作为通用的高级语言，不能直接操作特定的硬件；





# 开发环境

安装 nasm

```shell
sudo apt-get install nasm 
```

安装 gcc

```shell
sudo apt install build-essential
```























