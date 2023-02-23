#!/usr/bin/env bash

# This file is part of the microplay-hub
# Designs by Liontek1985
# for RetroPie and offshoot
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# Splashscreen for Orangepi v1.4 - 2023-02-22

rp_module_id="splashscreen-opi"
rp_module_desc="Configure Splashscreen for OrangePi"
rp_module_section="main"
rp_module_repo="git https://github.com/microplay-hub/splashscreen-opi.git master"
rp_module_flags="noinstclean !rpi"

function _update_hook_splashscreen-opi() {
    # make sure splashscreen is always up to date if updating just RetroPie-Setup
    if rp_isInstalled "$md_id"; then
        install_bin_splashscreen-opi
        configure_splashscreen-opi
    fi
}

function sources_splashscreen-opi() {
    if [[ -d "$md_inst" ]]; then
        git -C "$md_inst" reset --hard  # ensure that no local changes exist
    fi
    gitPullOrClone "$md_inst"
}

function _image_exts_splashscreen-opi() {
    echo '\.bmp\|\.jpg\|\.jpeg\|\.gif\|\.png\|\.ppm\|\.tiff\|\.webp'
}

function _video_exts_splashscreen-opi() {
    echo '\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac'
}

function depends_splashscreen-opi() {
    local params=(fbi vorbis-tools mpv insserv)
    getDepends "${params[@]}"
}

function install_splashscreen-opi() {
    cat > "/etc/systemd/system/asplashscreen-opi.service" << _EOF_
[Unit]
Description=Show custom splashscreen
DefaultDependencies=no
Before=local-fs-pre.target
Wants=local-fs-pre.target
ConditionPathExists=$md_inst/asplashscreen-opi.sh

[Service]
Type=oneshot
ExecStart=$md_inst/asplashscreen-opi.sh
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
_EOF_

    rp_installModule "omxiv" "_autoupdate_"

	gitPullOrClone "$md_inst" "https://github.com/microplay-hub/mpcore-splashscreens.git master"

    iniConfig "=" '"' "$md_inst/asplashscreen-opi.sh"
    iniSet "ROOTDIR" "$rootdir"
    iniSet "DATADIR" "$datadir"
    iniSet "REGEX_IMAGE" "$(_image_exts_splashscreen-opi)"
    iniSet "REGEX_VIDEO" "$(_video_exts_splashscreen-opi)"

    if [[ ! -f "$configdir/all/$md_id.cfg" ]]; then
        iniConfig "=" '"' "$configdir/all/$md_id.cfg"
        iniSet "RANDOMIZE" "disabled"
    fi
    chown $user:$user "$configdir/all/$md_id.cfg"

    mkUserDir "$datadir/splashscreens-opi"
    echo "Place your own splashscreens in here." >"$datadir/splashscreens-opi/README.txt"
    chown $user:$user "$datadir/splashscreens-opi/README.txt"

    local splsetup="$scriptdir/scriptmodules/supplementary"	
    cd "$md_inst"
#	cp -r "splashscreen-opi.sh" "$splsetup/splashscreen-opi.sh"
    chown -R $user:$user "$splsetup/splashscreen-opi.sh"
	chmod 755 "$splsetup/splashscreen-opi.sh"
	rm -r "splashscreen-opi.sh"
}

function enable_plymouth_splashscreen-opi() {
    local config="/boot/cmdline.txt"
    if [[ -f "$config" ]]; then
        sed -i "s/ *plymouth.enable=0//" "$config"
    fi
}

function disable_plymouth_splashscreen-opi() {
    local config="/boot/cmdline.txt"
    if [[ -f "$config" ]] && ! grep -q "plymouth.enable" "$config"; then
        sed -i '1 s/ *$/ plymouth.enable=0/' "$config"
    fi
}

function default_splashscreen-opi() {
    echo "$md_inst/mpnxt-splashscreen.png" >>/etc/splashscreen-opi.list
    echo "$md_inst/mpnxt-splashload.png" >>/etc/splashscreen-opi.list
}

function enable_splashscreen-opi() {
    systemctl enable asplashscreen-opi
}

function disable_splashscreen-opi() {
    systemctl disable asplashscreen-opi
}

function configure_splashscreen-opi() {
    [[ "$md_mode" == "remove" ]] && return

    # remove legacy service
    [[ -f "/etc/init.d/asplashscreen-opi" ]] && insserv -r asplashscreen-opi && rm -f /etc/init.d/asplashscreen-opi

    disable_plymouth_splashscreen-opi
    enable_splashscreen-opi
    [[ ! -f /etc/splashscreen-opi.list ]] && default_splashscreen-opi
}

function remove_splashscreen-opi() {
    enable_plymouth_splashscreen-opi
    disable_splashscreen-opi
    rp_callModule "omxiv" remove
    rm -f /etc/splashscreen-opi.list /etc/systemd/system/asplashscreen-opi.service
    systemctl daemon-reload
}

function choose_path_splashscreen-opi() {
    local options=(
        1 "RetroPie splashscreens"
        2 "Own/Extra splashscreens (from $datadir/splashscreens-opi)"
    )
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ "$choice" -eq 1 ]] && echo "$md_inst"
    [[ "$choice" -eq 2 ]] && echo "$datadir/splashscreens-opi"
}

function set_append_splashscreen-opi() {
    local mode="$1"
    [[ -z "$mode" ]] && mode="set"
    local path
    local file
    while true; do
        path="$(choose_path_splashscreen-opi)"
        [[ -z "$path" ]] && break
        file=$(choose_splashscreen-opi "$path")
        if [[ -n "$file" ]]; then
            if [[ "$mode" == "set" ]]; then
                echo "$file" >/etc/splashscreen-opi.list
                printMsgs "dialog" "Splashscreen set to '$file'"
                break
            fi
            if [[ "$mode" == "append" ]]; then
                echo "$file" >>/etc/splashscreen-opi.list
                printMsgs "dialog" "Splashscreen '$file' appended to /etc/splashscreen-opi.list"
            fi
        fi
    done
}

function choose_splashscreen-opi() {
    local path="$1"
    local type="$2"

    local regex
    [[ "$type" == "image" ]] && regex=$(_image_exts_splashscreen-opi)
    [[ "$type" == "video" ]] && regex=$(_video_exts_splashscreen-opi)

    local options=()
    local i=0
    while read splashdir; do
        splashdir=${splashdir/$path\//}
        if echo "$splashdir" | grep -q "$regex"; then
            options+=("$i" "$splashdir")
            ((i++))
        fi
    done < <(find "$path" -type f ! -regex ".*/\..*" ! -regex ".*LICENSE" ! -regex ".*README.*" ! -regex ".*\.sh"  ! -regex ".*\.pkg" | sort)
    if [[ "${#options[@]}" -eq 0 ]]; then
        printMsgs "dialog" "There are no splashscreens installed in $path"
        return
    fi
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose splashscreen." 22 76 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -n "$choice" ]] && echo "$path/${options[choice*2+1]}"
}

function randomize_splashscreen-opi() {
    options=(
        0 "Disable splashscreen randomizer"
        1 "Randomize RetroPie splashscreens"
        2 "Randomize own splashscreens (from $datadir/splashscreens-opi)"
        3 "Randomize all splashscreens"
        4 "Randomize /etc/splashscreen-opi.list"
    )
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    iniConfig "=" '"' "$configdir/all/$md_id.cfg"
    chown $user:$user "$configdir/all/$md_id.cfg"

    case "$choice" in
        0)
            iniSet "RANDOMIZE" "disabled"
            printMsgs "dialog" "Splashscreen randomizer disabled."
            ;;
        1)
            iniSet "RANDOMIZE" "retropie"
            printMsgs "dialog" "Splashscreen randomizer enabled in directory $rootdir/supplementary/$md_id"
            ;;
        2)
            iniSet "RANDOMIZE" "custom"
            printMsgs "dialog" "Splashscreen randomizer enabled in directory $datadir/splashscreens-opi"
            ;;
        3)
            iniSet "RANDOMIZE" "all"
            printMsgs "dialog" "Splashscreen randomizer enabled for both splashscreen directories."
            ;;
        4)
            iniSet "RANDOMIZE" "list"
            printMsgs "dialog" "Splashscreen randomizer enabled for entries in /etc/splashscreen-opi.list"
            ;;
    esac
}

function preview_splashscreen-opi() {
    local options=(
        1 "View single splashscreen"
        2 "View slideshow of all splashscreens"
        3 "Play video splash"
    )

    local path
    local file
    while true; do
        local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        path="$(choose_path_splashscreen-opi)"
        [[ -z "$path" ]] && break
        while true; do
            case "$choice" in
                1)
                    file=$(choose_splashscreen-opi "$path" "image")
                    [[ -z "$file" ]] && break
                    fbi --noverbose --autozoom "$file"
                    ;;
                2)
                    file=$(mktemp)
                    find "$path" -type f ! -regex ".*/\..*" ! -regex ".*LICENSE" ! -regex ".*README.*" ! -regex ".*\.sh" | sort > "$file"
                    if [[ -s "$file" ]]; then
                        fbi --timeout 6 --once --autozoom --list "$file"
                    else
                        printMsgs "dialog" "There are no splashscreens installed in $path"
                    fi
                    rm -f "$file"
                    break
                    ;;
                3)
                    file=$(choose_splashscreen-opi "$path" "video")
                    [[ -z "$file" ]] && break
                    mpv -vo sdl -fs "$file"
                    ;;
            esac
        done
    done
}


function gui_splashscreen-opi() {
    if [[ ! -d "$md_inst" ]]; then
        rp_callModule splashscreen-opi depends
        rp_callModule splashscreen-opi install
    fi
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
    while true; do
        local enabled=0
        [[ -n "$(find "/etc/systemd/system/"*".wants" -type l -name "asplashscreen-opi.service")" ]] && enabled=1
        local options=(1 "Choose splashscreen")
        if [[ "$enabled" -eq 1 ]]; then
            options+=(2 "Show splashscreen on boot (currently: Enabled)")
            iniConfig "=" '"' "$configdir/all/$md_id.cfg"
            iniGet "RANDOMIZE"
            options+=(3 "Randomizer options (currently: ${ini_value^})")
        else
            options+=(2 "Show splashscreen on boot (currently: Disabled)")
        fi
        options+=(
            4 "Use default splashscreen"
            5 "Manually edit splashscreen list"
            6 "Append splashscreen to list (for multiple entries)"
            7 "Preview splashscreens"
            8 "Update RetroPie splashscreens"
        )

        iniConfig "=" '"' "$configdir/all/$md_id.cfg"
        iniGet "DURATION"
        # default splashscreen duration is 12 seconds
        local duration=${ini_value:-12}

        options+=(
            A "Configure image splashscreen duration ($duration sec)"
            )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    set_append_splashscreen-opi set
                    ;;
                2)
                    if [[ "$enabled" -eq 1 ]]; then
                        disable_splashscreen-opi
                        printMsgs "dialog" "Disabled splashscreen on boot."
                    else
                        [[ ! -f /etc/splashscreen-opi.list ]] && rp_callModule splashscreen-opi default
                        enable_splashscreen-opi
                        printMsgs "dialog" "Enabled splashscreen on boot."
                    fi
                    ;;
                3)
                    randomize_splashscreen-opi
                    ;;
                4)
                    iniSet "RANDOMIZE" "disabled"
                    default_splashscreen-opi
                    enable_splashscreen-opi
                    printMsgs "dialog" "Splashscreen set to RetroPie default."
                    ;;
                5)
                    editFile /etc/splashscreen-opi.list
                    ;;
                6)
                    set_append_splashscreen-opi append
                    ;;
                7)
                    preview_splashscreen-opi
                    ;;
                8)
                    rp_callModule splashscreen-opi install
                    ;;
                A)  
                    duration=$(dialog --title "Splashscreen duration" --clear --rangebox "Configure how many seconds the splashscreen is active" 0 60 5 100 $duration 2>&1 >/dev/tty)
                    if [[ -n "$duration" ]]; then
                        iniSet "DURATION" "${duration//[^[:digit:]]/}"
                    fi
                    ;;
            esac
        else
            break
        fi
    done
}
