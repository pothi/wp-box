#!/usr/bin/env fish

# Requirements:
#   - php_ver

set php_ver 8.3

function user_remove -a the_user
    # if php_ver is 6.0 then php_ver_short is 60
    set php_ver_short $(echo $php_ver | tr -d \.)

    echo This script removes the user and relevant config files!; echo

    if not string length --quiet $the_user
        echo No username is provided.
        exit 1
    else if not id -u $the_user &>/dev/null
        echo The user does not exist in the server!
        exit 1
    end

    # configure the HOME - if an underscore exists in the username, then drop the rest
    set the_home $(echo $the_user | awk -F _ '{print $1}')

    # delete nginx files
    if test -f /etc/nginx/conf.d/fpm"$php_ver_short"_$the_home.conf
        rm /etc/nginx/conf.d/fpm"$php_ver_short"_$the_home.conf
        nginx -t &>/dev/null && systemctl restart nginx
        echo Removed the nginx file.
    end

    # remove PHP conf
    set php_pool_file /etc/php/$php_ver/fpm/pool.d/$the_home.conf

    if test -f $php_pool_file
        rm $php_pool_file
        php-fpm$php_ver -t &>/dev/null && systemctl restart php$php_ver-fpm
        echo Removed the PHP Pool File.
    end

    # remove passwd auth for user
    if test -f /etc/ssh/sshd_config.d/enable-passwd-auth-$the_user.conf
        rm /etc/ssh/sshd_config.d/enable-passwd-auth-$the_user.conf
        sshd -t && systemctl restart ssh
    end

    # delete the user
    userdel $the_user
    rm -rf /home/$the_home
    echo Removed the user from the server.

    if test -f /etc/sudoers.d/$the_user
        rm /etc/sudoers.d/$the_user
        echo The sudo privilege is removed.
    end

    # echo Username: $the_user
    # echo User HOME: "/home/$the_home"
    # echo Password: $the_pass

end

user_remove $argv[1]
# user_remove pothi 'My-Complex_Password;2024'
