#!/bin/sh

ROOTDIR="/opt/retropie"
DATADIR="/home/pi/RetroPie"
REGEX_VIDEO="\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"
REGEX_IMAGE="\.bmp\|\.jpg\|\.jpeg\|\.gif\|\.png\|\.ppm\|\.tiff\|\.webp"

# Load user settings
. /opt/retropie/configs/all/splashscreen-nxt.cfg

is_fkms() {
    if grep -q okay /proc/device-tree/soc/v3d@7ec00000/status 2> /dev/null || grep -q okay /proc/device-tree/soc/firmwarekms@7e600000/status 2> /dev/null ; then
        return 0
    else
        return 1
    fi
}

do_start () {
    local config="/etc/splashscreen-nxt.list"
    local line
    local re="$REGEX_VIDEO\|$REGEX_IMAGE"
    local bootsndstatus="$AVPLAYER $AVPLAYERO1 $BOOTSNDFOLDER2/$BOODSND"
    local bootimg1="$IMGVIEWER $IMGVIEWERO3"
    local bootimg2="$IMGVIEWERO4"
    local bootimg3="$IMGVIEWERO5"
    local omxiv="/opt/retropie/supplementary/omxiv/omxiv"
    case "$RANDOMIZE" in
        disabled)
            line="$(head -1 "$config")"
            ;;
        retropie)
            line="$(find "$ROOTDIR/supplementary/splashscreen-nxt" -type f | grep "$re" | shuf -n1)"
            ;;
        custom)
            line="$(find "$DATADIR/splashscreens-nxt" -type f | grep "$re" | shuf -n1)"
            ;;
        all)
            line="$(find "$ROOTDIR/supplementary/splashscreen-nxt" "$DATADIR/splashscreens-nxt" -type f | grep "$re" | shuf -n1)"
            ;;
        list)
            line="$(cat "$config" | shuf -n1)"
            ;;
    esac
    if $(echo "$line" | grep -q "$REGEX_VIDEO"); then
        # wait for dbus
        while ! pgrep "dbus" >/dev/null; do
            sleep 1
        done
        mpv -vo value -fs "$line"
    elif $(echo "$line" | grep -q "$REGEX_IMAGE"); then
        if [ "$RANDOMIZE" = "disabled" ]; then
            local count=$(wc -l <"$config")
        else
            local count=1
        fi
        [ $count -eq 0 ] && count=1
        [ $count -gt 12 ] && count=12

        # Default duration is 12 seconds, check if configured otherwise
        [ -z "$DURATION" ] && DURATION=12
        local delay=$((DURATION/count))
		local bootsndstatus="$AVPLAYER $AVPLAYERO1 $BOOTSNDFOLDER2/$BOODSND"
        if [ "$RANDOMIZE" = "disabled" ]; then
            $bootimg1 $delay $bootimg2 "$config" >/dev/null 2>&1
	    $bootsndstatus &
        else
            $bootimg2 $delay $bootimg3 "$line" >/dev/null 2>&1
	    $bootsndstatus &
        fi
    fi
    exit 0
}

case "$1" in
    start|"")
        do_start &
        ;;
    restart|reload|force-reload)
        echo "Error: argument '$1' not supported" >&2
        exit 3
       ;;
    stop)
        # No-op
        ;;
    status)
        exit 0
        ;;
    *)
        echo "Usage: asplashscreen-nxt [start|stop]" >&2
        exit 3
        ;;
esac
