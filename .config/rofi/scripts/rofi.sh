#!/usr/bin/env bash
#
# Launch a Rofi menu based on the option passed
#
# Requirements: rofi, rofi-calc, rofi-emoji, cliphist, wl-clipboard, imagemagick
#

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

clipboard_menu() {
	THUMB_DIR="/tmp/rofi-clipboard-thumbs"
	mkdir -p "$THUMB_DIR"

	ENTRIES=$(cliphist list 2>/dev/null)
	[ -z "$ENTRIES" ] && return

	IMG_LINES=()
	TXT_LINES=()

	while IFS= read -r LINE; do
		RAW=$(cliphist decode <<< "$LINE" 2>/dev/null | head -c 16 | xxd -p 2>/dev/null || true)
		case "$RAW" in
			89504e47*|ffd8ff*|52494646*)
				IMG_LINES+=("$LINE") ;;
			*)
				TXT_LINES+=("$LINE") ;;
		esac
	done <<< "$ENTRIES"

	HAS_IMGS=${#IMG_LINES[@]}
	HAS_TXTS=${#TXT_LINES[@]}

	# نص فقط → القائمة الأصلية بدون تغيير
	if [ "$HAS_IMGS" -eq 0 ]; then
		echo "$ENTRIES" | \
			rofi -dmenu \
			     -display-columns 2 \
			     -p " " \
			     -config "$HOME/.config/rofi/clipboard.rasi" | \
			cliphist decode | wl-copy
		return
	fi

	# صور فقط → قائمة بأيقونات
	if [ "$HAS_TXTS" -eq 0 ]; then
		_clipboard_images "${IMG_LINES[@]}"
		return
	fi

	# خليط: اختر النوع أولاً
	SECTION=$(printf '%s\n' \
		"󰈚  Text  (${HAS_TXTS})" \
		"󰸉  Images  (${HAS_IMGS})" \
	| rofi -dmenu -p " " \
	       -config "$HOME/.config/rofi/clipboard.rasi")
	[ -z "$SECTION" ] && return

	case "$SECTION" in
		*"Text"*)
			printf '%s\n' "${TXT_LINES[@]}" | \
				rofi -dmenu \
				     -display-columns 2 \
				     -p " " \
				     -config "$HOME/.config/rofi/clipboard.rasi" | \
				cliphist decode | wl-copy
			;;
		*"Images"*)
			_clipboard_images "${IMG_LINES[@]}"
			;;
	esac
}

_clipboard_images() {
	local LINES=("$@")
	THUMB_DIR="/tmp/rofi-clipboard-thumbs"

	ROFI_INPUT=""
	for LINE in "${LINES[@]}"; do
		CLIP_ID=$(echo "$LINE" | cut -f1)
		SAFE_ID=$(echo "$CLIP_ID" | tr -dc '0-9a-zA-Z_-')
		THUMB="$THUMB_DIR/clip_${SAFE_ID}.png"

		if [ ! -f "$THUMB" ]; then
			cliphist decode <<< "$LINE" | \
				convert - -thumbnail 84x84^ -gravity center -extent 84x84 "$THUMB" 2>/dev/null || true
		fi

		[ -f "$THUMB" ] && ROFI_INPUT+="${CLIP_ID}\x00icon\x1f${THUMB}\n"
	done

	[ -z "$ROFI_INPUT" ] && return

	CHOICE=$(printf "%b" "$ROFI_INPUT" | rofi -dmenu \
		-p " " \
		-config "$HOME/.config/rofi/clipboard-image.rasi")
	[ -z "$CHOICE" ] && return

	for LINE in "${LINES[@]}"; do
		CLIP_ID=$(echo "$LINE" | cut -f1)
		if [ "$CLIP_ID" = "$CHOICE" ]; then
			cliphist decode <<< "$LINE" | wl-copy
			break
		fi
	done
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
			pkill rofi || clipboard_menu
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
