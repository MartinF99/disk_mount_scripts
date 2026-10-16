#!/bin/bash

tmpfiledir="${HOME}/.cache/disk_mounter"

name=""
statefile=""
config_file=""

# needed for default config
script_dir=$(dirname -- "$(readlink -f -- "$0";)");

game_directory=${PWD} #set to current working dir



function print_usage {
    echo "script needs a name, and/or a disk_mounter config file"
    echo "disk_unmounter -c config_file -n name -g gamedir -h"
}

function parse_commandline {
    while getopts c:n:g:h optchar
    do
        case $optchar in
        c) config_file="${OPTARG}";;
        n) name="${OPTARG}";;
        g) game_directory="${OPTARG}";;
        h) print_usage; exit 0;;
        *) print_usage; exit 2;;
        esac
    done

    if [ ! -d "${game_directory}" ]; then
        game_directory="${PWD}"
    fi
}

function load_configfile {
    if [ -z "${config_file}" ] || ! [ -f "${config_file}" ]; then
        if [ -f "${game_directory}/mount_disk.conf" ]; then
            config_file="$game_directory/mount_disk.conf"
        elif [ -f "$script_dir/mount_disk.conf" ]; then
            config_file="$script_dir/mount_disk.conf"
        else
            echo "no config file, please specify -i and -n"
            return
        fi
    fi
#shellcheck disable=1090
    source "${config_file}"

    if [ -z "${name}" ]; then

        if [ -n "${c_name}" ]; then
            name="${c_name}"
        elif [ -n "${c_image}" ]; then
            name=$(basename "${c_image}") #create the name from the provided config file, if it exists
            name="${name%.*}"
        else
            echo "name unset and config file not specified"
            exit 1
        fi
    fi

    echo "$name"

    statefile="${tmpfiledir}/${name}-state"
    echo "$statefile"
}

function load_state {
    if [ -f "${statefile}" ]; then
        statefile="${tmpfiledir}/${name}-state"
    else
        echo "No statefile found, doing nothing"
        exit 5
    fi

    source "$statefile"
}

function unmount_udisksctl {
    if [ -n "${s_bdevice}" ]; then
        udisksctl unmount -b "${s_bdevice}"
        udisksctl loop-delete -b "${s_bdevice}"
    else
        echo "ERROR: loop device unset"
        exit 6
    fi
}

function unmount_cdemu {
    udisksctl unmount -b "/dev/sr0"
    cdemu unload 0
}


parse_commandline "$@"

load_configfile

load_state

if [ "${s_cdemu}" == "true" ]; then
    unmount_cdemu
else
    unmount_udisksctl
fi

# get rid of the state, but leave if something went wrong
rm "$statefile"





