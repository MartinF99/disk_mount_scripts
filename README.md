# Disk mounting and unmounting scripts
These scripts are designed to automate mounting disk images for old games

## installation
put them in your path

## usage

    mount_disk.sh [-c "config_file"] [-i "disk_image"] [-n "name"] [-g "game_dir"] [-e]
    unmount_disk.sh [-c "config_file"] [-n "name"]
### Parameters

#### mount_disk

    -c "config_file" specify a configuration file (if unused the script tries to find one in the current PWD or a specified game_dir with -g)
    -i "disk_image" specify a path to a disk images (overwrites config file)
    -n "name" specify a name used to save the state for the unmounter
    -e Use cdemu instead of udisksctl (can be useful for some games)
    -g "game_dir" specify a game dir, if config file is not specified looks for mount_disk.conf in the game directory folder, otherwise expects game_dir to be the PWD
    
    
#### unmount_disk:
    expects mount to be executed and a statefile to exist in $HOME/.cache/disk-mounter
    
    -c config_file, will be used to autogenerate name based on c_image, same logic as with mount_disk, uses same config file
    -n "name", specify the name used to run mount_disk.sh if empty tries to generate based on c_image

