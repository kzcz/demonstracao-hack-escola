#!/usr/bin/bash
(( UID )) && { # Runs only if $UID is not 0
    echo "Restarting as root"
    exec sudo bash "$(realpath "${BASH_SOURCE[0]}")" # Re-executes the script as root
}
systemctl disable ssh --now
echo "root:root" | chpasswd # Sets the password of root to "root"
chsh -s /usr/bin/bash # Changes the shell of root to bash
FILE="$(mktemp)" # Generate a randomly named file to store config for sshd
printf 'Port 2222\nPermitRootLogin yes\nPasswordAuthentication yes\nUsePAM no\n' > $FILE
WIFI="$(LC_ALL=C nmcli -t -f active,ssid dev wifi | grep "^yes:" | cut -d: -f2)" # Extracts the wifi the computer is connected to
IP="$(ip a s scope global | awk 'BEGIN { got_ip=0; }{ sub(/[[:space:]]+/,""); sub(/\/.*/,"",$2); if((!got_ip) && /^inet/) print $2 }')" # Extracts the first ip reachable from the exterior
echo "1. Join the WiFi network $WIFI"
echo "2. Run ssh root@$IP -p2222"
[ ! -d /run/sshd ] && { mkdir -p /run/sshd; chmod 0755 /run/sshd; } # The file may or may not exist already, so we create it if it doesn't.
/usr/sbin/sshd -D -f $FILE
