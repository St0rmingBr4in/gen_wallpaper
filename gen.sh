#!/bin/sh

set -e

OUTPUTW=1920
OUTPUTH=1080

INPUTDIR=images/input
TOSCALEDIR=images/to_scaled
SCALEDDIR=images/scaled
OUTPUTDIR=images/output

targetres=${OUTPUTW}x${OUTPUTH}

mkdir -p $OUTPUTDIR $TOSCALEDIR
[ ! -d $INPUTDIR ] && echo "No images to process" && exit 1
cp $INPUTDIR/* $TOSCALEDIR

echo "Building docker for upscaling"
docker build waifu2x -t waifu2x

nvidia-docker run -v `pwd`/images:/images waifu2x /images/upscale.sh $OUTPUTW $OUTPUTH /$TOSCALEDIR /$SCALEDDIR

[ ! -d $SCALEDDIR ] && echo "No images to process" && exit 1

for img_path in $SCALEDDIR/*; do
  for name in $(basename $img_path); do
    echo "Processing $name"

    echo "Getting background color..."
    background=$(convert $img_path -format "%[pixel:p{1,1}]" info:)

    echo "Setting background color..."
    convert $img_path -background $background -resize $targetres -gravity center -extent $targetres $OUTPUTDIR/$name
  done
done
