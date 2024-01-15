SKIPUNZIP=1

DEBUG=@DEBUG@
SONAME=@SONAME@

if [ "$BOOTMODE" ] && [ "$APATCH" ]; then
  ui_print "- Installing from APatch app"
else
  ui_print "*********************************************************"
  ui_print "! Install from recovery is not supported"
  ui_print "! Please install from APatch app"
  abort    "*********************************************************"
fi

VERSION=$(grep_prop version "${TMPDIR}/module.prop")
ui_print "- Installing $SONAME $VERSION"

ui_print "- Extracting verify.sh"
unzip -o "$ZIPFILE" 'verify.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/verify.sh" ]; then
  ui_print "*********************************************************"
  ui_print "! Unable to extract verify.sh!"
  ui_print "! This zip may be corrupted, please try downloading again"
  abort    "*********************************************************"
fi
. "$TMPDIR/verify.sh"
extract "$ZIPFILE" 'customize.sh'  "$TMPDIR/.vunzip"
extract "$ZIPFILE" 'verify.sh'     "$TMPDIR/.vunzip"

ui_print "- Extracting module files"
extract "$ZIPFILE" 'module.prop'     "$MODPATH"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" "common.sh" "$MODPATH"
extract "$ZIPFILE" "credits" "$MODPATH"
extract "$ZIPFILE" "service.sh" "$MODPATH"
extract "$ZIPFILE" "sepolicy.rule" "$MODPATH"
extract "$ZIPFILE" "boot-completed.sh" "$MODPATH"
extract "$ZIPFILE" "hide.prop" "$MODPATH"

chmod +x "$MODPATH/*"

mkdir "$MODPATH/xia"

  ui_print "- Extracting arm64 libraries"
  extract "$ZIPFILE" "lib/arm64-v8a/lib$SONAME.so" "$MODPATH/xia" true

chmod 777 "$MODPATH/xia/libqingyue.so"