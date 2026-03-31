# WordPress (in a GNU/Linux) Box - Fish Shell based Scripts

## Requirement

* Fish Shell 4
* Ubuntu LTS (26.04, 24.04)
+ Debian 13, 12

## How to get started?

**Common steps for both Debian and Ubuntu**

```
sudo apt-get update
sudo apt-get install --yes fish
fish --version
sudo chsh --shell /usr/bin/fish
sudo chsh --shell /usr/bin/fish $USER
```

## Note on fish shell versions

Ubuntu 26.04 (Resolute Raccoon) comes with fish shell version 4.
Ubuntu 24.04 (or below) and Debian 13 (or below) come with fish shell version 3.

## To get latest fish shell version...

You may add the fish shell repo and then update to the latest version. To add the repo, use one of the following guidelines...

**Ubuntu - all versions**

```
sudo add-apt-repository --yes --no-update --ppa fish-shell/release-4
```

**Debian 13**

```
echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_13/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_13/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
```

**Debian 12**

```
curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:4/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_4.gpg > /dev/null
echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/4/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:4.list
```

### To install with a startup script...

On Ubuntu...

```
add-apt-repository --yes --ppa fish-shell/release-4
apt-get install --yes fish
chsh --shell /usr/bin/fish
```

