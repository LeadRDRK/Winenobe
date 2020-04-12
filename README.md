# Winenobe
Winenobe is a script which semi-automatically installs Finobe and adds URI handlers.

This script is not created or officially supported by the Finobe team. It might not work correctly.
# Dependencies
- Wine Staging (Wine Stable and Wine Dev have a bug which prevents the camera from working properly.)
- wget

This script will not automatically install those for you ! You MUST install them manually.
# How to use it
0. If you haven't installed the dependencies above, go do it right now !
1. Download the latest winenobe.sh from the [releases page](https://github.com/LeadRDRK/Winenobe/releases)
- Alternatively, you may clone or download the repository. Please be aware that the version on the repo is bleeding edge and might be broken. Don't do this unless you know what you're doing.
2. Open up a terminal emulator. Change the directory to the one that contains the script.
3. Run `chmod +x winenobe.sh`
4. Depending on the version you wanted to install, run the following commands:
- `./winenobe.sh 2016` for 2016
- `./winenobe.sh 2012` for 2012
- Run `./winenobe.sh --help` to display additional options.
5. Hit Play on a game and you should be able to join!
# Additional Notes
To join a 2012 game, you must join the game repeatedly until it launches. This is most likely a Wine bug and has nothing to do with this script.
