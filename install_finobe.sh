#!/usr/bin/env bash
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

failed () {
	echo "ERROR: \"$last_command\" filed with exit code $?."
	echo "Cannot continue, exiting."
	exit 1
}

print_usage () {
	echo "Usage: ./install_finobe.sh [option] version"
	echo
	echo "Options:"
	echo "   --skip-installation            Forcefully skips installation."
	echo "   --skip-uri                     Forcefully skips adding the URI handler."
}

# check for requirements
for program in wine wineserver wget sed cat
do
	if ! command -v "$program" > /dev/null 2>&1
	then
		echo "$program not found !"
		exit 1
	fi
done

# check options
case "$1" in
	"--skip-installation")
		SKIPINSTALL=true
		F_VERSION="$2"
		;;
	"--skip-uri")
		SKIPURI=true
		F_VERSION="$2"
		;;
	*)
		F_VERSION="$1"
		;;
esac

# checks if version is specified
if [ -z "$F_VERSION" ] || ( [ "$F_VERSION" != "2012" ] && [ "$F_VERSION" != "2016" ] )
then
	echo "Version not specified or invalid."
	print_usage
	exit 1
fi

# checks for wineprefix, if doesn't exist define it anyways.
if [ -z "$WINEPREFIX" ]
then
	WINEPREFIX="$HOME/.wine"
fi

# determines program files folder
W_DRIVE_C="$WINEPREFIX/drive_c"
if [ -d "$W_DRIVE_C/windows/syswow64" ]
then
	W_PROGFILES="$W_DRIVE_C/Program Files (x86)"
else
	W_PROGFILES="$W_DRIVE_C/Program Files"
fi

finobe_installed () {
	echo "Finobe $F_VERSION is already installed, skipping installation."
	echo
	F_INSTALLED=true
}

# check if finobe is already installed
if [ "$F_VERSION" = "2016" ]
then
	[ -d "$W_PROGFILES/Finobe/Versions" ] && finobe_installed
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
	if [ "$F_VERSION" = "2012" ]
	then
		echo "NOTICE: While this script can install the 2012 client, it is not guaranteed to be the lastest version."
		echo "Also, as of the current wine version (4.15), the 2012 client does not work."
		read -p "Press Enter to continue or CTRL+C to exit..."
		echo
		DLINK="https://files.catbox.moe/ttlil8.bin"
	else
		DLINK="https://leadrdrk.ml/assets/BootstrapperFinobe.notanexe"
	fi
	echo "Downloading..."
	wget --progress=bar:force -O "install.exe" "$DLINK" 2>&1 | progressfilt
	echo
	echo "The installation process will now begin. If Finobe Studio launches after installing, close it."
	if [ "$F_VERSION" = "2012" ]
	then
		echo "WARNING: DO NOT CHANGE THE INSTALLATION DIRECTORY !"
	fi
	read -p "Press Enter to begin installing."
	echo "Installing..."
	wine "install.exe" || failed
	wineserver -w
	if [ "$F_VERSION" = "2016" ]
	then
		INSTALLPATH="$W_PROGFILES/Finobe/Versions"
		cp "install.exe" "$INSTALLPATH/PenelopeLauncher.exe" || failed
	else
		INSTALLPATH="$W_DRIVE_C/Finobe/2012"
	fi
	rm "install.exe" || failed

	if find "$INSTALLPATH" -mindepth 1 -print -quit 2>/dev/null | grep -q .
	then
		echo "Installation successful."
	else
		echo "Installation failed ! Cannot continue, exiting."
		exit 1
	fi
	
	echo
fi

if [ -z "$SKIPURI" ]
then
if [ "$F_VERSION" = "2016" ]
then
	DESKTOPFILE="$HOME/.local/share/applications/finobe-player-2016.desktop"
	LAUNCHER="$W_PROGFILES/Finobe/Versions/PenelopeLauncher.exe"
	if [ ! -f "$LAUNCHER" ]
	then
		echo "PenelopeLauncher.exe not found, downloading it now."
		wget --progress=bar:force -O "$LAUNCHER" "https://leadrdrk.ml/assets/BootstrapperFinobe.notanexe" 2>&1 | progressfilt
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
cat << EOF > "$DESKTOPFILE"
[Desktop Entry]
Version=1
Type=Application
Name=Finobe Player ($F_VERSION)
NoDisplay=true
OnlyShowIn=X-None
Comment=Play Finobe games!
Exec=wine '$LAUNCHER' %U
Actions=
MimeType=$MIMETYPE
Categories=Game
EOF
echo "Created desktop file."

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
echo >> "$MIMEAPPS" || failed
echo "$MIMETYPE=$(basename "$DESKTOPFILE")" >> "$MIMEAPPS"
echo "Added Finobe URI handler."
echo
fi

echo "Tasks completed successfully."