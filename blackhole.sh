#!/usr/bin/env bash


source "$PWD/framework.sh"

setup_term
dual_list 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
dual_list 'Keyboard' 'Set system keyboard layout' 'Hostname' 'Set the hostname of the install'

ask_text 'Please enter a hostname:'
message=$(cat <<EOF
INSTALL FINISHED
Thank you for using the blackhole Void Linux Installer, please press any key to continue
EOF
)
show_text "$message"

restore_term
echo $selected
