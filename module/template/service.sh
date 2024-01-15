#!/system/bin/sh

MODDIR="${0%/*}"

alias resetprop="/data/adb/ap/bin/resetprop"

# First try Android 11's new init.rc since some devices use the new path but still have the legacy init.rc file
# https://github.com/topjohnwu/Magisk/pull/4836
INITRC_NAME="system/etc/init/hw/init.rc"
# legacy init.rc (Android 10 and older)
[ -f "/$INITRC_NAME" ] || INITRC_NAME="init.rc"

INITRC="/$INITRC_NAME"

trim() {
  trimmed=$1
  trimmed=${trimmed%% }
  trimmed=${trimmed## }
  echo $trimmed
}

# https://github.com/topjohnwu/Magisk/blob/v23.0/native/jni/init/rootdir.cpp#L24
grep_flash_recovery() {
  # Some devices don't have the flash_recovery service
  # (like Samsung renamed it to "ota_cleanup" but Magisk won't remove it, so we don't need to do anything for this)
  LINE=$(grep "service flash_recovery " "$INITRC") || return 1
  LINE=${LINE#*"service flash_recovery "}
  trim "$LINE"
}

reset_flash_recovery() {
  FLASH_RECOVERY=$(grep_flash_recovery) || return

  # Skip if the flash_recovery service is not removed by Magisk
  grep -qxF "service flash_recovery /system/bin/xxxxx" "$MAGISKRC" || return

  # Skip if the install-recovery.sh does not exist
  [ -f "$FLASH_RECOVERY" ] || return

  # Skip if there is the state set for the service
  [ "$(getprop 'init.svc.flash_recovery' 2>/dev/null)" = "" ] || return

  # Set a "fake" state for the service
  resetprop -n 'init.svc.flash_recovery' 'stopped'
}

grep_service_name() {
  ARG=$1
  LINE=$(grep "service .* $MAGISK_TMP/magisk --$ARG" "$MAGISKRC")
  LINE=${LINE#*"service "}
  LINE=${LINE%" $MAGISK_TMP"*}
  trim "$LINE"
}

del_service_name() {
  resetprop --delete "init.svc.$1"
}

delete_services() {
  # Remove Magisk's services' names from system properties
  POST_FS_DATA=$(grep_service_name "post-fs-data")
  LATE_START_SERVICE=$(grep_service_name "service")
  BOOT_COMPLETED=$(grep_service_name "boot-complete")
  del_service_name "$POST_FS_DATA"
  del_service_name "$LATE_START_SERVICE"
  del_service_name "$BOOT_COMPLETED"
}

{
  # Reset props after boot completed to avoid breaking some weird devices/ROMs...
  while [ "$(getprop sys.boot_completed)" != "1" ]
  do
    sleep 1
  done

  # Xiaomi cross region flash...
  # See https://github.com/topjohnwu/Magisk/pull/2470
  resetprop_if_match ro.boot.hwc CN GLOBAL
  resetprop_if_match ro.boot.hwcountry China GLOBAL

  # some stupid banking apps check this prop
  resetprop_if_diff sys.oem_unlock_allowed 0

  # Load MagiskHide props
  resetprop -n --file "$MODDIR/hide.prop"

  # Hide that we booted from recovery when magisk is in recovery mode
  resetprop_if_match "ro.bootmode" "recovery" "unknown"
  resetprop_if_match "ro.boot.bootmode" "recovery" "unknown"
  resetprop_if_match "vendor.boot.bootmode" "recovery" "unknown"

  resetprop --delete ro.build.selinux

  reset_flash_recovery
  delete_services
}&