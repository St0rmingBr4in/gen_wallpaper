#!/bin/sh

set -e

OUTPUTH=1080
OUTPUTW=1920

INPUTDIR=input
OUTPUTDIR=output

targetres=${OUTPUTW}x${OUTPUTH}

mkdir -p $OUTPUTDIR

for img_path in $INPUTDIR/*; do
  for name in $(basename $img_path); do
    echo "Processing $name"

    #background=$(convert $img_path -colorspace rgb -format "%[pixel:p{10,10}]" info:)
    background=$(convert $img_path -crop 1x1+40+30 -depth 8 -format "%[pixel:p{1,1}]" info:)

    convert $img_path -background $background -resize $targetres -gravity center -extent $targetres $OUTPUTDIR/$name
  done
done
