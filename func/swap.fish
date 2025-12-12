# To be placed in $fish_function_path
# most likely in ~/.config/fish/functions

set swap_file '/swapfile'
set swap_size 1
set swap_sysctl_file '/etc/sysctl.d/60-swap-local.conf'
set sleep_time_between_tasks 2

function swap -d 'Create, update, delete or show swap info'
    argparse --name=swap 'h/help' 'd/delete' 'c/create=!_validate_int --min 1' -- $argv
    or return

    if set -q _flag_help
        __swap_print_help
        return 0
    end

    if set -q _flag_delete
        __swap_delete
        return 0
    end

    if set -q _flag_create
        set swap_size $_flag_create
        __swap_add $swap_size
        return 0
    end

    if not set -q argv[1]
        # printf (_ "%ls: Expected at least %d args, got only %d\n") funcsave 1 0 >&2
        free -m | sed '/^Mem/d' | sed 's/free.*/free/'

        echo; echo By default, this function displays the swap info, if any.
        echo Use -h or --help to see the available options.
        return 1
    end

end

function __swap_print_help

    printf '%s\n\n' 'Create, update, delete or show swap.'

    printf 'Usage: %s [-c/--create <size>] [-u/--update <size>] [-d/--delete] [-s/--show] [-v/--version] [-h/--help]\n\n' swap

    printf '\t%s\t%s\n' "-c, --create" "Create a swap with the given size in GBs (default 1)."
    printf '\t%s\t%s\n' "-u, --update" "Update or increase the swap size to the given size."
    printf '\t%s\t%s\n' "-d, --delete" "Delete the existing swap, if any."
    printf '\t%s\t%s\n' "-s, --show" "Show swap info."
    printf '\t%s\t%s\n' "-v, --version" "Prints the version info"
    printf '\t%s\t%s\n' "-h, --help" "Prints help"

    printf "\nFor more info, changelog and documentation... https://github.com/pothi/\n"

end

function __swap_delete
    # Remove swap file
    if test -f "$swap_file"
        swapoff "$swap_file"
        rm "$swap_file"
    else
        echo Swap file not found.
    end

    # Remove fstab entry
    if grep -qw swap /etc/fstab >/dev/null
        sed -i '/swap/d' /etc/fstab
    end

    [ -f "$swap_sysctl_file" ] && rm "$swap_sysctl_file"
    service procps force-reload
    if test $status -ne 0; echo Error: reloading procps failed!; end

    echo Swap and swap config are removed, if existed.
    free -m | sed '/^Mem/d' | sed 's/free.*/free/'
end

function __swap_add -a swap_size
    # create swap if unavailable
    set -l is_swap_enabled $(free | grep -iw swap | awk {'print $2'}) # 0 means no swap

    if test "$is_swap_enabled" -eq 0
        # echo $swap_size

        printf '%-72s' 'Creating and setting up Swap...'
        # echo -----------------------------------------------------------------------------

        # check for swap file
        if test -f $swap_file
            rm $swap_file
        end

        # on a desktop, we may use fdisk to create a partition to be used as swap
        fallocate -l "$swap_size"G "$swap_file" >/dev/null
        if test $status -ne 0; echo Error: fallocate failed!; end

        # only root should be able to read it or / and write into it
        chmod 600 $swap_file

        # mark a file / partition as swap
        mkswap $swap_file >/dev/null
        if test $status -ne 0; echo Error: mkswap failed!; end

        # enable swap
        # printf '%-72s' "Waiting for swap file to get ready..."
        # sleep $sleep_time_between_tasks
        # echo done.

        swapon "$swap_file"
        if test $status -ne 0; echo Error: swapon failed!; end

        # display summary of swap (only for logging purpose)
        # swapon --show
        # swapon -s

        # to make the above changes permanent
        # enable swap upon boot
        if ! grep -qw swap /etc/fstab
            echo "$swap_file none swap sw 0 0" >> /etc/fstab
        end

        # fine-tune swap
        if ! test -f $swap_sysctl_file
            echo -e "# Ref: https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-22-04\n" > $swap_sysctl_file
            echo 'vm.swappiness=10' >> $swap_sysctl_file
            echo 'vm.vfs_cache_pressure = 50' >> $swap_sysctl_file
        end

        # apply changes
        # as per /etc/sysctl.d/README.sysctl
        if ! service procps force-reload
            echo Error reloading procps!
        end
        # alternative way
        # sysctl -p $swap_sysctl_file

        # echo -----------------------------------------------------------------------------
        echo done!
        free -m | sed '/^Mem/d' | sed 's/free.*/free/'
    else
        echo Swap already exists.
    end

end
