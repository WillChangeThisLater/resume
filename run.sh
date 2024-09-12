#!/bin/bash

# remove the old outputs
rm -rf paul_wendt.aux paul_wendt.log paul_wendt.out paul_wendt.pdf paul_wendt.png

# regenerate resume
docker run --rm -v "$PWD":/data latex pdflatex -interaction nonstopmode paul_wendt.tex >/dev/null

# check if the output pdf exists
if [ ! -f paul_wendt.pdf ]; then
    echo "Failed to generate PDF"
    exit 1
fi

pdftoppm -png paul_wendt.pdf > paul_wendt.png

mupdf paul_wendt.pdf
