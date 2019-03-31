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
  nvidia-docker run -v `pwd`/images:/images waifu2x /images/upscale.sh $OUTPUTW $OUTPUTH /$TOSCALEDIR /$SCALEDDIR
  ;;
esac

[ ! -d $SCALEDDIR ] && echo "Error in scaling" && exit 1

for img_path in $SCALEDDIR/*; do
  for name in $(basename $img_path)$extention; do
    echo "Processing $name"

    echo "Generating transparent extended image"
    convert $img_path -background transparent -resize "$targetres>" -gravity center -extent $targetres $TMP/extended_$name

    echo "Generating transparent extended cutted image"
    convert $TMP/extended_$name \( -size $(($(identify -format "%w" $img_path) - 2))x$(($(identify -format "%h" $img_path) - 2)) xc:none \) -alpha set -gravity center -compose copy -composite $TMP/extended_cutted_$name

    echo "Generating background image"
    convert $TMP/extended_cutted_$name txt:- | grep -v ImageMagick | grep -v 'graya(0,0)' | grep -v none | sed -e 's/: ([0-9,]\+)  #[0-9A-Z]\+  /,/' |  convert $TMP/extended_cutted_$name -alpha off -sparse-color shepards '@-' $TMP/extended_fill_$name

    echo "Generating final image"
    convert $TMP/extended_fill_$name $TMP/extended_$name -composite $OUTPUTDIR/$name
  done
done
