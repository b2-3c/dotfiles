#!/usr/bin/env bash
#
# Take a screenshot of the target passed
#
# Author:  Jesse Mirabel <sejjymvm@gmail.com>
# Date:    January 2, 2025
# License: MIT

DIR="$HOME/Pictures/Screenshots"

usage() {
	cat <<- EOF
		USAGE: ${0##*/} [TARGET]

		Take a screenshot of the target passed

		TARGETS:
		  active    Currently active window
		  area      Manually select a rectangular region or window
		  output    Currently active output
		  screen    Entire screen including all visible outputs
	EOF
}

main() {
	if [[ ! -d $DIR ]]; then
		mkdir -p "$DIR"
	fi

	local name file

	name="Screenshot_$(date +%Y%m%d_%H%M%S_%2N).png"
	file="$DIR/$name"

	case $1 in
		area)
			grimblast --freeze copysave "$1" "$file"
			;;
		active | output | screen)
			grimblast copysave "$1" "$file"
			;;
		*)
			usage >&2
			return 1
			;;
	esac

	if [[ ! -s $file ]]; then
		rm -f "$file"
		return 1
	fi

	notify-send "$name saved in $DIR" -i "$file"
}

main "$@"
