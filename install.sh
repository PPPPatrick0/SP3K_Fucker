# akfucker

# skip mount system
SKIPMOUNT=true

# getkey volume 
keyvolume(){ 
keyvl=''; keyvl=`getevent -qlc 1 | awk '{print $3}'`
if [ "$keyvl" == "KEY_VOLUMEDOWN" ] || [ "$keyvl" == "ABS_MT_TRACKING_ID" ];then
    echo 1
elif [ "$keyvl" == "KEY_VOLUMEUP" ];then
    echo 2
elif [ "$keyvl" == "KEY_POWER" ];then
    echo 3
else
    keyvolume
fi; }

print_modname() {
ui_print " "
ui_print "  Name: $(grep_prop name $TMPDIR/module.prop), V$(grep_prop version $TMPDIR/module.prop), ($(grep_prop versionCode $TMPDIR/module.prop))"
ui_print "  $(grep_prop description $TMPDIR/module.prop)"
ui_print "  Author: $(grep_prop author $TMPDIR/module.prop)"
ui_print " "
}

# main process
on_install() {
ui_print "! Use volume keys to select"
ui_print "! Cancel, press power key"
ui_print " "
ui_print "- Touch or Volume key to continue ?"
getevent -qlc 1 >&2 && ui_print "  Check OK" || abort "! Check getevent failed"
sleep 0.5
ui_print "  Checking modelconf block"
if [ -b "/dev/block/bootdevice/by-name/modelconf" ];then
    ui_print "  Found modelconf block at /dev/block/bootdevice/by-name/modelconf"
    current_modelconf=$(cat /dev/block/bootdevice/by-name/modelconf 2>/dev/null)
    ui_print "  Current modelconf:"
    ui_print "    $current_modelconf"
else
    abort "! modelconf block not found"
fi

ui_print "  Dumping file list"
for XZ in $(ls "$TMPDIR"); do
ui_print "    $XZ"
done

ui_print "  Fucking modelconf:"
ui_print "    Skip flash modelconf with Next->Next->Skip"
ui_print "- Flash modelconf_ufs_CN ?"
ui_print "  Vol+ Yes"
ui_print "  Vol- Next"
ui_print " "

if [ "$(keyvolume)" == 1 ];then
    ui_print "- Flash modelconf_ufs_CNGD ?"
    ui_print "  Vol+ Yes"
    ui_print "  Vol- Next"
    ui_print " "
    if [ "$(keyvolume)" == 1 ];then
        ui_print "- Flash modelconf_ufs_CNWG ?"
        ui_print "  Vol+ Yes"
        ui_print "  Vol- Skip"
        ui_print " "
        if [ "$(keyvolume)" == 1 ];then
            ui_print "  Skip modelconf change"
        elif [ "$(keyvolume)" == 2 ];then
            # flash CNWG_SP3000.bin
            if [ ! -f "$TMPDIR/modelconf_ufs_CNWG_SP3000.bin" ];then
                abort "! modelconf_ufs_CNWG_SP3000.bin not found"
            else
                dd if="$TMPDIR/modelconf_ufs_CNWG_SP3000.bin" of="/dev/block/bootdevice/by-name/modelconf"
                ui_print "  Done"
            fi
        else
            abort "! Canceled"
        fi
    elif [ "$(keyvolume)" == 2 ];then
        # flash CNGD_SP3000.bin
        if [ ! -f "$TMPDIR/modelconf_ufs_CNGD_SP3000.bin" ];then
            abort "! modelconf_ufs_CNGD_SP3000.bin not found"
        else
            dd if="$TMPDIR/modelconf_ufs_CNGD_SP3000.bin" of="/dev/block/bootdevice/by-name/modelconf"
            ui_print "  Done"
        fi
    else
        abort "! Canceled"
    fi
elif [ "$(keyvolume)" == 2 ];then
    # flash CN_SP3000.bin
    if [ ! -f "$TMPDIR/modelconf_ufs_CN_SP3000.bin" ];then
        abort "! modelconf_ufs_CN_SP3000.bin not found"
    else
        dd if="$TMPDIR/modelconf_ufs_CN_SP3000.bin" of="/dev/block/bootdevice/by-name/modelconf"
        ui_print "  Done"
    fi
else
    abort "! Canceled"
fi

sleep 0.5

ui_print "  Setup bootctl binary with 0755"
if [ ! -f "$TMPDIR/bootctl" ];then
    abort "! modelconf_ufs_CN_SP3000.bin not found"
else
    set_perm $TMPDIR/bootctl 0 2000 0755
    ui_print "  Done"
fi

sleep 0.5

current_slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
current_version=$(getprop ro.build.version.incremental 2>/dev/null)
ui_print "- Switch boot slot ?"
ui_print "  Current boot slot $current_slot"
ui_print "  Current firmware version $current_version"
ui_print "  Vol+ Yes"
ui_print "  Vol- Skip"
ui_print " "

if [ "$(keyvolume)" == 2 ];then
    if [ "$current_slot" == "_a" ];then
        ui_print "  Switch to slot _b"
        $TMPDIR/bootctl set-active-boot-slot 1
    else
        ui_print "  Switch to slot _a"
        $TMPDIR/bootctl set-active-boot-slot 0
    fi
elif [ "$(keyvolume)" == 1 ];then
    ui_print "  Skip boot slot switch"
else
    abort "! Canceled"
fi

# set flag to remove module in next boot
ui_print "  Cleaning module context"
set_perm_recursive $MODPATH 0 0 0755 0644
touch $MODPATH/remove
touch $MODPATH/disable

# reboot system
ui_print "- Reboot system ?"
ui_print "  Vol+ Yes"
ui_print "  Vol- Reboot manually later"
ui_print " "

if [ "$(keyvolume)" == 2 ];then
    reboot
elif [ "$(keyvolume)" == 1 ];then
    ui_print "  You need reboot the device manually to apply changes"
else
    abort "! Canceled"
fi
}
