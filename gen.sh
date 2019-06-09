#!/bin/sh

set -e

OUTPUTW=1920
OUTPUTH=1080

INPUTDIR=images/input
TOSCALEDIR=images/to_scaled
SCALEDDIR=images/scaled
OUTPUTDIR=images/output
TMP=/tmp

extention=".png"
scalingmode="skip"

targetres=${OUTPUTW}x${OUTPUTH}

mkdir -p $OUTPUTDIR $TOSCALEDIR $SCALEDDIR
[ ! -d $INPUTDIR ] && echo "No images to process" && exit 1

case $scalingmode in
"skip")
  cp $INPUTDIR/* $SCALEDDIR
  ;;
"waifu2x")
  cp $INPUTDIR/* $TOSCALEDIR

  echo "Building docker for upscaling"
  docker build waifu2x -t waifu2x

  echo "Running docker for upscaling"
  nvidia-docker run -v "$(pwd)/images:/images" waifu2x /images/upscale.sh $OUTPUTW $OUTPUTH /$TOSCALEDIR /$SCALEDDIR
  ;;
esac

[ ! -d $SCALEDDIR ] && echo "Error in scaling" && exit 1

for img_path in "$SCALEDDIR"/*; do
  for name in $(basename "$img_path")$extention; do
    echo "Processing $name"

    extended="$TMP/extended_$name"
    extended_cutted="$TMP/extended_cutted_$name"
    extended_fill="$TMP/extended_fill_$name"

    echo "Generating transparent extended image"
    convert "$img_path" -background transparent -resize "$targetres>" -gravity center -extent $targetres "$extended"

    echo "Generating transparent extended cutted image"
    convert "$extended" \( -size $(($(identify -format "%w" "$img_path") - 2))x$(($(identify -format "%h" "$img_path") - 2)) xc:none \) -alpha set -gravity center -compose copy -composite "$extended_cutted"

    echo "Generating background image"
    convert "$extended_cutted" txt:- | grep -v ImageMagick | grep -v 'graya(0,0)' | grep -v none | sed -e 's/: ([0-9,]\+)  #[0-9A-Z]\+  /,/' |  convert "$extended_cutted" -alpha off -sparse-color shepards '@-' "$extended_fill"

    echo "Generating final image"
    convert "$extended_fill" "$extended" -composite "$OUTPUTDIR/$name"
  done
done
