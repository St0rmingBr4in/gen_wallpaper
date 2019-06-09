#!/bin/sh

set -e

img_path="$1"
extendmode="$2"
targetres="$3"
outputname="$4"
output="$5/$outputname"

TMP=/tmp
extended="$TMP/extended_$outputname"
extended_cutted="$TMP/extended_cutted_$outputname"
extended_fill="$TMP/extended_fill_$outputname"
regex="\\([0-9]\\+\\): ([0-9 ,]\\+) \\+\#[0-9A-Z]\\+ \\+"

gen_ext_img()
(
  convert "$img_path" -background "$1" -resize "$targetres>" -format "%[fx:w-2]x%[fx:h-2]" -write info: -gravity center -extent "$targetres" "$2"
)

plain_color()
(
  gen_ext_img "$1" "$output"
)

filter_transparent()
{
  grep -v ImageMagick | grep -v 'graya(0,0)' | grep -v none || true
}

smooth_transition()
(
  magick "$extended_cutted" -fill none -stroke "$1" -draw "rectangle 0,0 %[fx:w - 1],%[fx:h - 1]" "$extended_cutted"
  convert "$extended_cutted" txt:- | filter_transparent | sed -e "s/$regex/\\1,/" |  convert "$extended_cutted" -alpha off -sparse-color inverse '@-' "$extended_fill"
  convert "$extended_fill" "$extended" -composite "$output"
)

inscribed_res=$(gen_ext_img "transparent" "$extended")

convert "$extended" \( -size "$inscribed_res" xc:none \) -alpha set -gravity center -compose copy -composite "$extended_cutted"

hist="$(convert "$extended_cutted" -format "%c" histogram:info: | filter_transparent)"
background="$(printf '%s' "$hist" | sort -r -h | head -n1 | sed -e "s/$regex//")"

case $extendmode in
"plaincolor")
  plain_color "$background"
  ;;
"smoothtransition")
  smooth_transition "$background"
  ;;
"auto")
  if [ "$(identify -format %k "$extended_cutted")" -gt 10 ]; then
      smooth_transition "$background" || plain_color "$background"
  else
      plain_color "$background"
  fi
  ;;
esac
