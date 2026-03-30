# To be placed in $fish_function_path
# most likely in /etc/fish/functions

set ver 1.5

#TODO: auto-update, show swap size in rounded GBs.

# changelog
# version: 1.5
#   - date: 2026-03-29
#   - improve addition and deletion process
#   - activate show option.
#   - show version info

set swap_file '/swapfile'
set swap_size 1
set swap_sysctl_file '/etc/sysctl.d/60-swap-local.conf'
set sleep_time_between_tasks 2

if not type -q check_status_func
    function check_status_func -a return_value error_message
        if test $return_value -ne 0
            echo >&2 -e "\nError: $error_message\n"
            return "$return_value"
        end
    end
end

function swap -d 'Create or delete swap'
    argparse --name=swap 'v/version' 's/show' 'h/help' 'd/delete' 'c/create=!_validate_int --min 1' 'i/increase' -- $argv
    or return

    if set -q _flag_version
        echo $ver
        return 0
    end

    if set -q _flag_show
        echo Use existing command swapon; echo
        echo Usage: swapon -s
        echo Usage: swapon --show
        echo; echo To know more: swapon -h
        return 0
        # old method
        if test -f $swap_file
            echo Swap location: $swap_file
            free | awk '/^Swap:/ {exit !$2}'
            if test $status -eq 0
                echo Swap is active.
            end
        else
            echo Swap file does not exist.
        end
        return 0
    end

    if set -q _flag_help
        __swap_print_help
        return 0
    end

    if set -q _flag_increase
        echo To increase the swap size, delete and re-create the swap for the required size.
        return 0
    end

    if set -q _flag_delete
        fish_is_root_user; or check_status_func $status 'This function requires root privilege.'; or return $status
        __swap_delete
        return 0
    end

    if set -q _flag_create
        fish_is_root_user; or check_status_func $status 'This function requires root privilege.'; or return $status
        set swap_size $_flag_create
        __swap_add $swap_size
        return 0
    end

    # The following is executed when no other option is selected.
    # printf (_ "%ls: Expected at least %d args, got only %d\n") funcsave 1 0 >&2
    # free -m | sed '/^Mem/d' | sed 's/free.*/free/'

    # echo; echo By default, this function displays the swap info, if any.
    # echo Use -h or --help to see the available options.
    # __swap_print_help

end

function __swap_print_help

    printf '%s\n\n' 'Create or delete swap.'

    printf 'Usage: %s [-c/--create <size>] [-u/--update <size>] [-d/--delete] [-s/--show] [-v/--version] [-h/--help]\n\n' swap

    printf '\t%s\t%s\n' "-c, --create" "Create a swap with the given size in GBs (default 1)."
    printf '\t%s\t%s\n' "-i, --increase" "Increase the swap size to the given size."
    printf '\t%s\t%s\n' "-d, --delete" "Delete the existing swap, if any."
    printf '\t%s\t%s\n' "-s, --show" "Show swap info."
    printf '\t%s\t%s\n' "-v, --version" "Prints the version info"
    printf '\t%s\t%s\n' "-h, --help" "Prints help"

    printf "\nFor more info, changelog and documentation... https://github.com/pothi/\n"

end

function __swap_delete
    # disable swap
    free | awk '/^Swap:/ {exit !$2}'
    if test $status -eq 0
        swapoff "$swap_file"
        check_status_func $status 'Could not turn off swap.'; or return $status
        echo Swap is disabled.
    else
        echo Swap is not active.
    end

    # Remove swap file
    if test -f "$swap_file"
        rm "$swap_file"
        check_status_func $status 'Could not remove swap file.'; or return $status
        echo Swap file is removed.
    else
        echo Swap file not found.
    end

    # Remove fstab entry
    if grep -qw swap /etc/fstab >/dev/null
        sed -i '/swap/d' /etc/fstab
        check_status_func $status 'Could not remove swap file.'; or return $status
        echo Swap entry is removed from /etc/fstab
    else
        echo Swap entry is not found in /etc/fstab
    end

    if test -f "$swap_sysctl_file"
        rm "$swap_sysctl_file"
        check_status_func $status 'Could not remove swap config.'; or return $status
        echo Swap config is removed.
    else
        echo Swap config does not exist.
    end

    service procps force-reload
    check_status_func $status 'Could not reload procps.'; or return $status

    systemctl daemon-reload
    check_status_func $status 'Failure reloading systemctl daemon'; or return $status

    free -m | sed '/^Mem/d' | sed 's/free.*/free/'
end

function __swap_add -a swap_size
    # create swap if unavailable
    set -l is_swap_enabled $(free | grep -iw swap | awk {'print $2'}) # 0 means no swap

    if test "$is_swap_enabled" -eq 0
        # echo $swap_size

        # printf '%-72s' 'Creating and setting up Swap...'
        # echo -----------------------------------------------------------------------------

        # check for swap file
        if test -f $swap_file
            rm $swap_file
            check_status_func $status 'Could not remove old swap file.'; or return $status
            echo Existing swap file is removed.
        end

        # on a desktop, we may use fdisk to create a partition to be used as swap
        fallocate -l "$swap_size"G "$swap_file" >/dev/null
        check_status_func $status 'fallocate failure'; or return $status
        echo Swap file is created at $swap_file

        # only root should be able to read it or / and write into it
        chmod 600 $swap_file

        # mark a file / partition as swap
        mkswap $swap_file >/dev/null
        check_status_func $status 'mswap failure'; or return $status
        echo Marked $swap_file as swap

        # enable swap
        # printf '%-72s' "Waiting for swap file to get ready..."
        # sleep $sleep_time_between_tasks
        # echo done.

        swapon "$swap_file"
        check_status_func $status 'swapon failure'; or return $status
        echo Swap is activated.

        # display summary of swap (only for logging purpose)
        # swapon --show
        # swapon -s

        # to make the above changes permanent
        # enable swap upon boot
        grep -qw swap /etc/fstab
        if test $status -ne 0
            echo "$swap_file none swap sw 0 0" >> /etc/fstab
        else
            echo Swap entry already exists in /etc/fstab
        end

        # fine-tune swap
        if not test -f $swap_sysctl_file
            echo -e "# Ref: https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04\n" > $swap_sysctl_file
            echo 'vm.swappiness=10' >> $swap_sysctl_file
            echo 'vm.vfs_cache_pressure = 50' >> $swap_sysctl_file
            echo Swap config  is created at $swap_sysctl_file
        else
            echo Swap config already exists.
        end

        # the following line may be needed to be executed on rare conditions.
        systemctl daemon-reload

        # apply changes
        # as per /etc/sysctl.d/README.sysctl
        service procps force-reload
        check_status_func $status 'Could not reload procps'; or return $status
        # alternative way
        # sysctl -p $swap_sysctl_file

        # echo -----------------------------------------------------------------------------
        free -m | sed '/^Mem/d' | sed 's/free.*/free/'
    else
        echo Swap is already active.
    end

end
