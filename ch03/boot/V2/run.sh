#!/bin/bash
echo "check........"
if [ ! -e  /root/proc/bochs/keymaps/x11-pc-us.map ];then
    echo "/root/proc/bochs/keymaps/x11-pc-us.map does not exist..."
    exit 1
else
    file /root/proc/bochs/keymaps/x11-pc-us.map
fi

if [ ! -e  /root/proc/bochs/BIOS-bochs-latest ];then
    echo " /root/proc/bochs/BIOS-bochs-latest does not exist..."
    exit 1
else 
    file /root/proc/bochs/BIOS-bochs-latest
fi

echo "check over ...."
sleep 1
echo "run........"

/root/proc/bochs/bin/bochs -f /root/projects/OrangeOS/bochsrc.disk
