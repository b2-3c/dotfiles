#!/bin/bash
# AUR installer using yay because paru has decided to communicate exclusively in binary

fzf_args=(
  --multi
  --preview 'yay -Siia {1}'
  --preview-label='alt-p: toggle preview, alt-b/B: toggle PKGBUILD, alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --bind 'alt-b:change-preview:yay -Gpa {1} | tail -n +5'
  --bind 'alt-B:change-preview:yay -Siia {1}'
  --color 'pointer:green,marker:green'
  --header 'AUR Package Installer - Select with Tab, Enter to install'
  --prompt 'Package: '
)

if ! command -v yay &>/dev/null; then
  echo "Error: yay not found."
  exit 1
fi

pkg_names=$(yay -Slqa | fzf "${fzf_args[@]}")

if [[ -n "$pkg_names" ]]; then
  echo "$pkg_names" | tr '\n' ' ' | xargs yay -S

  if command -v updatedb &>/dev/null; then
    sudo updatedb &
  fi

  echo
  gum spin --spinner "globe" --title "Done! Press any key to close..." -- bash -c 'read -n 1 -s'
fi
