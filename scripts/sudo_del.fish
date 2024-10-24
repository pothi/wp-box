#!/usr/bin/env fish

function sudo_remove -a the_user
    echo This script removes the privilege of running sudo!; echo

    if not string length --quiet $the_user
        echo No user is provided.
    else if not test -f /etc/sudoers.d/$the_user
        echo The user does not have sudo privilege or wrong username was provided.
    else
        rm /etc/sudoers.d/$the_user
        echo The sudo privilege is removed.
    end
end

sudo_remove $argv[1]
