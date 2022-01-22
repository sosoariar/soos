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

