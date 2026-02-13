#!/usr/bin/env bash
#
# Launch a Rofi menu based on the option passed
#
# Requirements:
# - rofi
# - rofi-calc
# - rofi-emoji
# - cliphist
# - wl-clipboard
#
# Author:  Jesse Mirabel <sejjymvm@gmail.com>
# Date:    January 3, 2025
# License: MIT

usage() {
	cat <<- EOF
		USAGE: ${0##*/} [OPTION]

		Launch a Rofi menu based on the option passed

		OPTIONS:
		  a    app launcher
		  m    emoji picker
		  v    clipboard
		  w    window switcher
		  x    calculator
	EOF
}

main() {
	case $1 in
		a)
			pkill rofi ||
			      rofi -show drun       \
			           -show-icons      \
			           -disable-history \
			           -config "$HOME/.config/rofi/app-launcher.rasi"
			;;
		m)
			pkill rofi ||
			      rofi -modi emoji             \
			           -show emoji             \
			           -emoji-format "{emoji}" \
			           -kb-accept-alt ""       \
			           -kb-custom-1 Ctrl+c     \
			           -kb-secondary-copy ""   \
			           -config "$HOME/.config/rofi/emoji-picker.rasi"
			;;
		v)
			pkill rofi ||
			cliphist list |
			      rofi -dmenu             \
			           -display-columns 2 \
			           -p " "            \
			           -config "$HOME/.config/rofi/clipboard.rasi" |
			cliphist decode |
			wl-copy
			;;
		w)
			pkill rofi ||
			      rofi -show window \
			           -config "$HOME/.config/rofi/window-switcher.rasi"
			;;
		x)
			pkill rofi ||
			      rofi -show calc          \
			           -modi calc          \
			           -hint-welcome ""    \
			           -hint-result ""     \
			           -kb-accept-entry "" \
			           -lines 0            \
			           -no-history         \
			           -no-show-match      \
			           -no-sort            \
			           -terse              \
			           -config "$HOME/.config/rofi/calculator.rasi"
			;;
		*)
			usage >&2
			return 1
			;;
	esac
}

main "$@"
