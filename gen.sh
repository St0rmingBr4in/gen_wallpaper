#!/bin/sh

set -e

OUTPUTW=1920
OUTPUTH=1080

INPUTDIR=images/input
TOSCALEDIR=images/to_scaled
SCALEDDIR=images/scaled
OUTPUTDIR=images/output

extention=".png"
scalingmode="skip"
extendmode="plaincolor"

targetres=${OUTPUTW}x${OUTPUTH}

mkdir -p $OUTPUTDIR $TOSCALEDIR $SCALEDDIR
[ ! -d $INPUTDIR ] && echo "No images to process" && exit 1

case $scalingmode in
"skip")
  SCALEDDIR=$INPUTDIR
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

inputs=$(find $SCALEDDIR -type f -exec file {} \; | awk -F: '{ if ($2 ~/[Ii]mage|EPS/) print $1}')

# shellcheck source=/usr/bin/env_parallel.sh
. "$(command -v env_parallel.sh)"
printf '%s' "$inputs" | env_parallel --progress --bar ./extend.sh {} "$extendmode" $targetres '$(basename {})'$extention "$OUTPUTDIR"
