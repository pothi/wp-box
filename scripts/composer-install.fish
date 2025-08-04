#!/usr/bin/env fish

# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md

set ver 2.0

# Variables

set install_dir ~/.local/bin

test ! -d $install_dir; and  mkdir -p $install_dir

if test ! -f $install_dir/composer
    echo 'Installing Composer for PHP...'

    set EXPECTED_CHECKSUM "$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
    set ACTUAL_CHECKSUM "$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

    if test "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM"
        # >&2 echo 'ERROR: Invalid installer checksum'
        echo 'ERROR: Invalid installer checksum'
        rm /tmp/composer-setup.php
        exit 1
    end

    php /tmp/composer-setup.php --quiet --install-dir=$install_dir --filename=composer

    rm /tmp/composer-setup.php &> /dev/null

    crontab -l 2>/dev/null | grep -qF 'composer'
    if test $status -ne 0
        # ( crontab -l; echo; echo "# auto-update composer - nightly" ) | crontab -
        # ( crontab -l; echo "@daily $install_dir/composer self-update > /dev/null" ) | crontab -
        set min (random 0 59)
        set hour (random 0 23)
        begin; crontab -l 2>/dev/null; echo; echo "$min $hour * * * $install_dir/composer self-update >> ~/log/composer-update.log 2>&1"; end | crontab -
    else
        echo A cron entry is already in place to auto-update composer!
    end

end

echo "Composer is installed at $install_dir. Please make sure this dir is in PATH."
