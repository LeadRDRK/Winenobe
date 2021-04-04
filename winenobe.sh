#!/usr/bin/env bash
VERSION="1.2.3-git"

[ "$OSTYPE" != "linux-gnu" ] && echo "WARNING: Operating system not supported ! Use this at your own risk."
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

failed () {
	echo "ERROR: \"$last_command\" filed with exit code $?."
	echo "Cannot continue, exiting."
	exit 1
}

print_usage () {
	echo "Usage: ./winenobe.sh [option] version"
	echo "\"version\" can be either 2012 or 2016."
	echo
	echo "Options:"
	echo "   --help,      -h           Displays this help message and exit."
	echo "   --version,   -v           Displays the version and exit."
	echo "   --uninstall, -u comp      Uninstalls the specified component(s)"
	echo "                             of the specified version."
	echo
	echo "   \"comp\" can be one of the following:"
	echo "   - files: Remove files only."
	echo "   - reg: Remove registry entries."
	echo "   - uri: Remove desktop file and URI handler."
	echo "   - all: Remove all of the above (full removal)."
	echo
	echo "   --skip,      -s task      Skips a task."
	echo
	echo "   \"task\" can be one of the following:"
	echo "   - install: skips installation."
	echo "   - uri: skips URI registration."
	echo
}

# check for requirements
for program in wine wineserver wget sed cat
do
	if ! command -v "$program" > /dev/null 2>&1
	then
		echo "$program not found ! Program not installed or incorrectly configured."
		exit 1
	fi
done

# checks for wineprefix, if doesn't exist define it anyways.
if [ -z "$WINEPREFIX" ]
then
	WINEPREFIX="$HOME/.wine"
fi

W_DRIVE_C="$WINEPREFIX/drive_c"
W_APPDATA="$W_DRIVE_C/users/$(whoami)/Local Settings/Application Data"
if [ -d "$W_DRIVE_C/windows/syswow64" ]
then
	W_PROGFILES="$W_DRIVE_C/Program Files (x86)"
else
	W_PROGFILES="$W_DRIVE_C/Program Files"
fi

# check parameters
case "$1" in
	"--skip" | "-s")
		case "$2" in
			"install")
				SKIPINSTALL=true
				;;
			"uri")
				SKIPURI=true
				;;
			*)
				echo "Invalid task."
				echo
				print_usage
				exit 1
				;;
		esac
		F_VERSION="$3"
		;;
	"--help" | "-h")
		print_usage
		exit
		;;
	"--version" | "-v")
		echo "Winenobe v$VERSION"
		exit
		;;
	"--uninstall" | "-u")
		F_VERSION="$3"
		case "$2" in
			files)
				RMFILES=true
				;;
			reg)
				RMREG=true
				;;
			uri)
				RMURI=true
				;;
			all)
				RMFILES=true
				RMREG=true
				RMURI=true
				;;
			*)
				echo "Invalid component."
				echo
				print_usage
				exit 1
				;;
		esac
		UNINST=true
		;;
	*)
		F_VERSION="$1"
		;;
esac

if [ -z "$F_VERSION" ]
then
	print_usage
	exit
fi

uninstall () {
	if [ "$F_VERSION" = "2012" ]
	then
		INSTALLPATH="$W_DRIVE_C/Finobe/2012"
		DESKTOPFILE="$HOME/.local/share/applications/finobe-player-2012.desktop"
		MIMETYPE="x-scheme-handler/finobetw"
	else
		INSTALLPATH="$W_APPDATA/Finobe"
		DESKTOPFILE="$HOME/.local/share/applications/finobe-player-2016.desktop"
		MIMETYPE="x-scheme-handler/finobesi"
	fi
	MIMEENTRY="$MIMETYPE=$(basename "$DESKTOPFILE")"
	MIMEAPPS="$HOME/.local/share/applications/mimeapps.list"

	if [ ! -z "$RMFILES" ]
	then
		if [ -d "$INSTALLPATH" ]
		then
            echo "Removing Finobe $F_VERSION..."
			rm -rf "$INSTALLPATH" || failed
		else
			echo "Finobe $F_VERSION installation not found, skipping."
		fi
		
		if [ "$F_VERSION" = "2016" ] && [ -d "$W_PROGFILES/Finobe" ]
        then
            echo "Removing legacy Finobe $F_VERSION installation..."
			rm -rf "$W_PROGFILES/Finobe" || failed
        fi
	fi

	if [ ! -z "$RMURI" ]
	then
		echo "Removing desktop file and URI handler..."
		if [ -f "$DESKTOPFILE" ]
		then
			rm "$DESKTOPFILE" || failed
		else
			echo "Desktop file not found, skipping."
		fi

		if grep -Fxq "$MIMEENTRY" "$MIMEAPPS"
		then
			sed -i "s#$MIMEENTRY##g" "$MIMEAPPS" || failed
		else
			echo "URI handler not found, skipping."
		fi
	fi

	if [ ! -z "$RMREG" ]
	then
		echo "Deleting registries..."
		if [ "$F_VERSION" = "2012" ]
		then
			wine regedit /D "HKEY_CURRENT_USER\\Software\\FinobeLauncher" || failed
		else
			wine regedit /D "HKEY_CURRENT_USER\\Software\\Finobe" || failed
			wine regedit /D "HKEY_CURRENT_USER\\Software\\Finobe_Penelope" || failed
		fi
	fi
	echo "Uninstallation completed successfully."
	exit
}

if [ "$F_VERSION" != "2012" ] && [ "$F_VERSION" != "2016" ]
then
	echo "Specified version is invalid."
	echo
	print_usage
	exit 1
fi

[ ! -z "$UNINST" ] && uninstall

finobe_installed () {
	echo "Finobe $F_VERSION is already installed, skipping."
	echo
	F_INSTALLED=true
}

# check if finobe is already installed
if [ "$F_VERSION" = "2016" ]
then
	[ -d "$W_APPDATA/Finobe/Versions" ] && finobe_installed
else
	[ -d "$W_DRIVE_C/Finobe/2012" ] && finobe_installed
fi

# source: https://stackoverflow.com/a/4687912
progressfilt () {
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    do
        if $flag
        then
            printf '%s' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]
            then
                count=0
            else
                ((count++))
                if ((count > 1))
                then
                    flag=true
                fi
            fi
        fi
    done
}

if [ -z "$F_INSTALLED" ] && [ -z "$SKIPINSTALL" ]
then
	# yes those files links below are the original
	if [ "$F_VERSION" = "2012" ]
	then
		echo "NOTICE: While this script can install the 2012 client, it is not guaranteed to be the lastest version."
		read -p "Press Enter to continue or CTRL+C to exit..."
		echo
		DLINK="https://files.catbox.moe/ttlil8.bin"
	else
		DLINK="https://files.catbox.moe/xnmxem.bin"
	fi
	echo "Downloading..."
	wget --progress=bar:force -O "install.exe" "$DLINK" 2>&1 | progressfilt
	echo
	echo "The installation process will now begin. If Finobe Studio launches after installing, close it."
	if [ "$F_VERSION" = "2012" ]
	then
		echo
		echo "WARNING: DO NOT CHANGE THE INSTALLATION DIRECTORY !"
		echo "Refer to the repo's README for instructions on how to join 2012 games."
	fi
	echo
	echo "Close all other Wine processes before proceeding !"
	read -p "Press Enter to begin installing."
	echo "Installing..."
	wine "install.exe" || failed
	wineserver -w
	if [ "$F_VERSION" = "2016" ]
	then
		INSTALLPATH="$W_APPDATA/Finobe/Versions"
		cp "install.exe" "$INSTALLPATH/PenelopeLauncher.exe" || failed
	else
		INSTALLPATH="$W_DRIVE_C/Finobe/2012"
	fi
	rm "install.exe"

	if find "$INSTALLPATH" -mindepth 1 -print -quit 2>/dev/null | grep -q .
	then
		echo "Installation successful."
	else
		echo "Installation failed ! Cannot continue, exiting."
		exit 1
	fi
	
	echo
fi

[ ! -z "$SKIPURI" ] && exit

if [ "$F_VERSION" = "2016" ]
then
	DESKTOPFILE="$HOME/.local/share/applications/finobe-player-2016.desktop"
	LAUNCHER="$W_APPDATA/Finobe/Versions/PenelopeLauncher.exe"
	if [ ! -f "$LAUNCHER" ]
	then
		echo "PenelopeLauncher.exe not found, downloading it now."
		wget --progress=bar:force -O "$LAUNCHER" "https://files.catbox.moe/xnmxem.bin" 2>&1 | progressfilt
		echo
	fi
else
	DESKTOPFILE="$HOME/.local/share/applications/finobe-player-2012.desktop"
	LAUNCHER="$W_DRIVE_C/Finobe/2012/FinobeLauncher.exe"
fi

if [ "$F_VERSION" = "2016" ]
then
	MIMETYPE="x-scheme-handler/finobesi"
else
	MIMETYPE="x-scheme-handler/finobetw"
fi

if [ -f "$DESKTOPFILE" ]
then
	echo "Desktop file already added, skipping."
else
	cat << EOF > "$DESKTOPFILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Finobe Player ($F_VERSION)
Comment=Play Finobe games!
Exec=wine '$LAUNCHER' %u
Categories=Game;
MimeType=$MIMETYPE
EOF
	echo "Created desktop file."
	echo "Updating desktop database..."
	update-desktop-database "$HOME/.local/share/applications"
fi

MIMEAPPS="$HOME/.local/share/applications/mimeapps.list"
if [ ! -f "$MIMEAPPS" ]
then
	echo "mimeapps.list not found, creating."
	echo "[Default Applications]" > "$MIMEAPPS" || failed
fi
if ! grep -Fxq "[Default Applications]" "$MIMEAPPS"
then
	echo "[Default Applications]" >> "$MIMEAPPS" || failed
fi

MIMEENTRY="$MIMETYPE=$(basename "$DESKTOPFILE")"
if grep -Fxq "$MIMEENTRY" "$MIMEAPPS"
then
	echo "Finobe URI handler already added, skipping."
else
	echo >> "$MIMEAPPS" || failed
	echo "$MIMEENTRY" >> "$MIMEAPPS"
	echo "Added Finobe URI handler."
	echo "Updating MIME database..."
	update-mime-database "$HOME/.local/share/mime"
	echo
fi
