MAKEFLAGS = -sR

MKDIR = mkdir
RMDIR = rmdir
CP = cp
CD = cd
DD = dd
RM = rm

BUILD_PATH = ./build
MAKE = make
INITLDRMFLGS = -C $(BUILD_PATH) -f initldr.mk
INITLDRLINKMFLGS = -C $(BUILD_PATH) -f ldrlink.mk
DSTPATH = ../exckrnl
RELEDSTPATH = ../release

.PHONY : build print clean all

build: clean print all

all:
	$(MAKE) $(INITLDRMFLGS)
	$(MAKE) $(INITLDRLINKMFLGS)
	@echo '系统编译构建完成'
clean:
	$(CD) $(BUILD_PATH); $(RM) -f *.o *.bin *.i *.krnl *.s *.map *.lib *.btoj *.vdi *vmdk *.eki *.elf
	@echo '清理全部已构建文件'

print:
	@echo '*********正在开始编译构建系统*************'




