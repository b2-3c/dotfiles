HISTFILESIZE=100000
HISTSIZE=10000

shopt -s histappend
shopt -s checkwinsize
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

# Return early if non-interactive (prevents wal from running during non-interactive shells)
[[ $- != *i* ]] && return

# Import colorscheme from 'wal' asynchronously
# Only run if we have a display/wayland session
if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
   (cat ~/.cache/wal/sequences &)
   wal -R -q
fi

if [[ $TERM != "dumb" ]]; then
   eval "$(starship init bash --print-full-init)"
fi
