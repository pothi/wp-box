#!/usr/bin/env fish

function sudo_add -a the_user
    echo This script adds the privilege of running sudo without password!; echo

    if not string length --quiet $the_user
        echo No user is provided.
    else
        echo "$the_user ALL=(ALL) NOPASSWD:ALL"> /etc/sudoers.d/$the_user
        echo The sudo privilege is added.
    end
end

sudo_add $argv[1]
