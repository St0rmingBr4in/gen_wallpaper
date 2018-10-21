#!/bin/sh

set -e

outputw=${1:-1920}
outputh=${2:-1080}

INPUTDIR=${3:-/images/to_scale}
OUTPUTDIR=${4:-/images/scaled}

SCALE_FACTOR=2
NOISE_CANCEL=2
EXTRAOPTIONS="-force_cudnn 1 -resume 1"

[ ! -d $INPUTDIR ] && echo "No images to scale" && exit 1
mkdir -p $OUTPUTDIR

image_large_enough()
{
  imgw=$(identify -format "%w" $1)
  imgh=$(identify -format "%h" $1)

  [ $imgw -ge $outputw ] || [ $imgh -ge $outputh ]
}

scale_batch()
{
  th waifu2x.lua $EXTRAOPTIONS -noise_level $3 -m noise_scale -scale $SCALE_FACTOR -l $1 -o $2/%s_x${SCALE_FACTOR}.png
}

while [ -n "$(ls -A $INPUTDIR)" ]; do

  for img in $INPUTDIR/*; do
    if image_large_enough $img; then
      name=$(basename $img)
      echo "$name is large enough... skipping"
      mv $img $OUTPUTDIR/$name
    else
      echo $img >> to_process.txt
    fi
  done

  if [ -s to_process.txt ]; then
    echo "Upscaling images:"
    cat to_process.txt
    scale_batch to_process.txt $INPUTDIR $NOISE_CANCEL
  fi

  while read old; do
    rm $old
  done < to_process.txt

  :> to_process.txt
  NOISE_CANCEL=0

done
