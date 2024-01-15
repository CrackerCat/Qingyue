#!/system/bin/sh

MODDIR=${0%/*}

chmod 755 /data/adb/modules/qingyue/xia/libqingyue.so
chmod +x /data/adb/modules/qingyue/xia/libqingyue.so
./data/adb/modules/qingyue/xia/libqingyue.so

[ -f "$MODDIR/sepolicy.rule" ] && exit 0

magiskpolicy --live "allow zygote * filesystem { unmount }" \
"allow zygote zygote capability { sys_ptrace sys_chroot }" \
"allow zygote unlabeled file { open read }"

