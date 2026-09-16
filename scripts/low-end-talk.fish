#!/usr/bin/env fish

# Ensure script runs with superuser privileges
if test (id -u) -ne 0
    echo "Error: This script must be run as root or with sudo."
    exit 1
end

set -x DEBIAN_FRONTEND noninteractive
set -x PATH ~/bin ~/.local/bin /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /snap/bin

set JOURNALD_MAX_DISK_USAGE "512M"
set MYSQL_DIR "/var/lib/mysql"

echo "=== Starting Server Optimization ==="

# --------------------------------------------------
# 1. Measure Initial MySQL Directory Size
# --------------------------------------------------
if test -d $MYSQL_DIR
    echo "--> [BEFORE] Disk space used by $MYSQL_DIR:"
    du -sh $MYSQL_DIR
else
    echo "--> Warning: $MYSQL_DIR does not exist."
end

# --------------------------------------------------
# 2. Journald Tweaks
# --------------------------------------------------
# ref: https://blog.tuxclouds.org/posts/journalctl-clean-up-and-tricks/
# to reduce the usage
# verify current disk usage
# journalctl --disk-usage
echo "--> Configuring systemd-journald max disk usage limit..."
mkdir -p /etc/systemd/journald.conf.d

# Write configuration file directly
echo -e "[Journal]\nSystemMaxUse=$JOURNALD_MAX_DISK_USAGE" > /etc/systemd/journald.conf.d/disk-usage.conf

systemctl restart systemd-journald
journalctl --vacuum-size=$JOURNALD_MAX_DISK_USAGE > /dev/null 2>&1
echo "    Journald restricted to $JOURNALD_MAX_DISK_USAGE."

# --------------------------------------------------
# 3. Disable MySQL Binlogs & Purge Existing Logs
# --------------------------------------------------
if systemctl is-active --quiet mysql
    echo "--> Purging MySQL binlogs gracefully via SQL..."
    # Purge binlog index and files cleanly via MySQL command line
    mysql -e "RESET MASTER;" 2>/dev/null; or true

    echo "--> Stopping MySQL service to update configuration..."
    systemctl stop mysql
else
    echo "--> MySQL service is not running. Proceeding with configuration..."
end

echo "--> Applying 'skip-log-bin' to MySQL config..."
mkdir -p /etc/mysql/mysql.conf.d
echo -e "[mysqld]\nskip-log-bin" > /etc/mysql/mysql.conf.d/80-skip-log-bin.conf

# Fallback clean-up: remove orphaned binlog files & index if any remain
if test -d $MYSQL_DIR
    rm -f (path filter $MYSQL_DIR/binlog.* $MYSQL_DIR/mysql-bin.*)
end

echo "--> Restarting MySQL service..."
systemctl start mysql

# --------------------------------------------------
# 4. Measure Final MySQL Directory Size
# --------------------------------------------------
if test -d $MYSQL_DIR
    echo "--> [AFTER] Disk space used by $MYSQL_DIR:"
    du -sh $MYSQL_DIR
end

# Default 3 - to reduce the disk space used by snap revisions
snap set system refresh.retain=2

echo "=== Optimization Complete ==="
