#!/bin/bash

tmpfiledir="${HOME}/.cache/disk_mounter"

name=""
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
        h) print_usage; exit;;
        *) print_usage; exit;;
        esac
    done

    if [ ! -d "${game_directory}" ]; then
        game_directory="${PWD}"
    fi
}

function load_configfile {

}
