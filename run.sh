#!/bin/sh

export ENV_OUTPUT_PNG_FILENAME=./sample.d/out.png

export ENV_WIDTH=320
export ENV_HEIGHT=180

color_rgba8="1.0 0.0 0.0 1.0"
color_rgba8="0.5 0.7 0.3 1.0"

export ENV_COLOR_STRING="${color_rgba8}"

mkdir -p ./sample.d

./ColorToImage

ls -lh "${ENV_OUTPUT_PNG_FILENAME}"
file "${ENV_OUTPUT_PNG_FILENAME}"
