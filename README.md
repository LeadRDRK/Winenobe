# Finobe is dead.
Consequently, this script is now useless. However, the code is still here for future referencing if needed.
# Winenobe
Winenobe is a script which semi-automatically installs Finobe and adds URI handlers.

This script is not created or officially supported by the Finobe team.

Have a problem or just wanna talk? Join our Discord server: https://discord.gg/Svg4ZS8cfc
# Dependencies
- wine 6.5 or later
- wget

This script will not automatically install those for you! You MUST install them manually.
# How to use it
0. If you haven't installed the dependencies above, go do it right now!
1. Download the latest winenobe.sh from the [releases page](https://github.com/LeadRDRK/Winenobe/releases)
- Alternatively, you may clone or download the repository. Please be aware that the version on the repo is bleeding edge and might be broken. Don't do this unless you know what you're doing.
2. Open up a terminal emulator. Change the directory to the one that contains the script.
3. Run `chmod +x winenobe.sh`
4. Depending on the version you wanted to install, run the following commands:
- `./winenobe.sh 2016` for 2016
- `./winenobe.sh 2012` for 2012
- Run `./winenobe.sh --help` to display additional options.
5. Hit Play on a game and you should be able to join!
# Troubleshooting
Some Linux distributions come with a very minimal Wine package. As a result, some optional Wine dependencies required for Finobe to run are missing and thus, it crashes and doesn't want to install.

To fix this, you need to install these optional dependencies. Common missing dependencies are `gnutls` and `libldap`

On Arch Linux, you can install all of these missing dependencies using these commands:
```sh
sudo pacman -S expac
sudo pacman -S $(expac '%n %o' | grep ^wine)
```
# Known issues
Finobe 2012 does not work.
