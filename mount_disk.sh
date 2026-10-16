#!/bin/bash

tmpfiledir="${HOME}/.cache/disk_mounter"

# create tempfiledir if not there already
mkdir -p "${HOME}/.cache/disk_mounter"

image_file=""
use_cdemu="false"
name=""
config_file=""
statefile=""
# needed for default config
script_dir=$(dirname -- "$(readlink -f -- "$0";)");

game_directory=${PWD} #set to current working dir

function load_config_file {

if [ -z "${config_file}" ] || ! [ -f "${config_file}" ]; then

    if [ -f "${game_directory}/mount_disk.conf" ]; then
        config_file="$game_directory/mount_disk.conf"
    elif [ -f "$script_dir/mount_disk.conf" ]; then
        config_file="$script_dir/mount_disk.conf"
    else
        echo "no config file, please specify -i and -n"
    fi
fi


# clean config file of anything we don't want (arbitrary execution)

# try sourcing the config file and setting the variables, disable shellchecks SC1090
#shellcheck disable=1090
if [ -f "${config_file}" ]; then
    # check if the file contains something we don't want
    config_file_secured="${config_file}-s"
    if grep -E -q -v '^#|^[^ ]*=[^;]*' "$config_file"; then
        echo "Config file is unclean, cleaning it..." >&2
        # filter the original to a new file
        grep -E '^#|^[^ ]*=[^;&]*'  "$config_file" > "$config_file_secured"
        rm "$config_file" # delete the config file
        mv "$config_file_secured" "$config_file" # and mv our config file there instead
    fi

    source "${config_file}"
    if [ -n "${c_image}" ] && [ -z "${image_file}" ]; then
        image_file="${c_image}"
    fi
    if [ -n "${c_name}" ] && [ -z "${name}" ]; then
        name="${c_name}"
    fi
    if [ -n "${c_cdemu}" ] && [ "${use_cdemu}" != "${c_cdemu}" ]; then
        use_cdemu="${c_cdemu}"
    fi
fi


#check if image_file empty and return error
if [ -z "${image_file}" ]; then
    echo "No image file specified"
    exit 6
fi
#set name to the basename of the image file without the extension if name is unset
if [ -z "${name}" ]; then
    echo "name is empty, script will attempt to use default name which is $(basename "${image_file}")"
    name="$(basename "${image_file}")"
    name="${name%.*}"
fi

}

function print_help {
            echo "USAGE: "mount_disk.sh -i "image_file" -n "name" [-e] [-c "config_file"]
            echo "-e: use cdemu instead of udisksctl"
            echo "-g: specify game directory, otherwise assumed to be PWD"
            echo "Config file: SYNTAX c_name=NAME c_image=IMAGE c_game_directory=GAMEDIR c_cdemu=[true||false] default name ./mount_disk.conf"
            exit 0
}

function parse_commandline {

while getopts "c:i:n:g:eh" optchar; do
    case "${optchar}" in
        c) echo "Trying to use config file: ${OPTARG}"; config_file="${OPTARG}";;
        i) echo "using image file: ${OPTARG}"; image_file="${OPTARG}";;
        n) echo "using name ${OPTARG}"; name="${OPTARG}";;
        h) print_help ;;
        e) echo "USING CDEMU, please make sure sr0 is not loaded"; use_cdemu=true ;;
        g) echo "game directory is ${OPTARG}"; game_directory="${OPTARG}";;
        *) echo "Unknown parameter!"; print_help;;
    esac
    echo loop
done
echo we were here
}

function mount_udisks {
    if [ -f "${image_file}" ]; then
        loop_device="$(LC_ALL=C udisksctl loop-setup -r -f "${image_file}" | sed 's/.* \([^ ]*\)\.$/\1/' )"
        udisksctl mount -b "${loop_device}"
    else
        echo "image file not found, abort";
        exit 2
    fi
    # save loop_device and save that we did not use cdemu
    echo "s_cdemu=false" >> "${statefile}"
    echo "s_bdevice=${loop_device}" >> "${statefile}"
}

function mount_cdemu {
    real_cdemu="$(which "cdemu")"
    if [ -z "${real_cdemu}" ]; then
        echo "CDEMU not installed"
        exit 3
    fi
    cdemu status | grep -q "/" # bad idea, but if mounted it will contain a / somewhere
    drive_empty="$?"
    cdemu status | grep -q "${image_file}"
    image_mounted="$?"

    if [ "${drive_empty}" == "0" ]; then
        echo "Drive not empty: currently not able to unmount the correct drive"
        exit 4
    fi

    if [ "${image_mounted}" == "0" ]; then
        echo "image already mounted, don't do anything"
        exit 5
    fi
    cdemu load 0 "${image_file}"
    sleep 1s # sleep for a second, so that the cdemu reports the image mounted
    udisksctl mount -b "/dev/sr0"
    # save mountpoint for unmounter and tell that we used cdemu
    echo "s_cdemu=true" >> "${statefile}"
    echo "s_bdevice=/dev/sr0" >> "${statefile}"
}
# we had this in a function call, this was never gonna work....
while getopts "c:i:n:g:eh" optchar; do
    case "${optchar}" in
        c) echo "Trying to use config file: ${OPTARG}"; config_file="${OPTARG}";;
        i) echo "using image file: ${OPTARG}"; image_file="${OPTARG}";;
        n) echo "using name ${OPTARG}"; name="${OPTARG}";;
        h) print_help ;;
        e) echo "USING CDEMU, please make sure sr0 is not loaded"; use_cdemu=true ;;
        g) echo "game directory is ${OPTARG}"; game_directory="${OPTARG}";;
        *) echo "Unknown parameter!"; print_help;;
    esac
    echo loop
done

load_config_file

#check if image_file empty and return error
if [ -z "${image_file}" ]; then
    echo "No image file specified"
    exit 6
fi
#set name to the basename of the image file without the extension
if [ -z "${name}" ]; then
    echo "name is empty, script will attempt to use default name which is $(basename "${image_file}")"
    name="$(basename "${image_file}")"
    name="${name%.*}"
fi
statefile="${tmpfiledir}/${name}-state"


if [ "${use_cdemu}" == "true" ]; then
    mount_cdemu
else
    mount_udisks
fi

