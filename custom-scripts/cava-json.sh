#!/usr/bin/env bash
cfg="$1"
limit=${CAVA_SILENCE_FRAMES:-100} # ~0.5s at 60 FPS
silence=0
last=""

cava -p "$cfg" | while read -r line; do
   clean="${line//;/}"
   if [[ "${clean//0/}" == "" ]]; then
      ((silence++))
      if ((silence >= limit)); then
         printf '{"text":"","class":"silent"}\n'
      else
         printf '{"text":"%s","class":"active idle"}\n' "$last"
      fi
   else
      silence=0
      last="$clean"
      printf '{"text":"%s","class":"active"}\n' "$clean"
   fi
done
