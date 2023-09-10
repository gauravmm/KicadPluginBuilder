#!/bin/zsh

set -e
setopt CSH_NULL_GLOB
echo "Generates a package for the KiCAD Repository"

echo "Fetching repository."
if [[ ! -d plugins_src ]]; then
    git clone --single-branch git@github.com:gauravmm/KLEPlacement.git plugins_src
fi
(   cd plugins_src; 
    git reset --hard;
    git clean -fdx;
    git pull origin master;
    git fetch --tags;
)
# Get the current tag, if one exists.
CURRTAG="$(cd plugins_src; git describe --tags)"

echo "Copying files to package dir."
if [[ -d plugins ]]; then
    rm -rf plugins
fi
mkdir plugins
rsync -av \
    --exclude .git \
    --exclude .gitignore \
    --exclude README.md \
    --exclude images \
    --exclude '**/*.fbp' \
    --exclude '**/__pycache__' \
    plugins_src/ plugins

UNPACKED_BYTES=$(du -bd 0 metadata.json plugins/ resources/ | cut -f 1 | tr "\n" "+" | sed "s/+$/\n/" | bc)
echo "UNPACKED_BYTES: $UNPACKED_BYTES"

# Pack it into a zip file
rm package.zip || true
zip -r package.zip metadata.json plugins/ # resources/

# Add or update the JSON entry:
JSONSTR="{
    \"version\": \"$CURRTAG\",
    \"status\": \"stable\",
    \"kicad_version\": \"7.0\",
    \"download_sha256\": \"$(sha256sum package.zip | cut -d ' ' -f 1)\",
    \"download_size\": $(du -b package.zip | cut -f 1),
    \"download_url\": \"https://github.com/gauravmm/KLEPlacement/releases/download/$CURRTAG/package.zip\",
    \"install_size\": $UNPACKED_BYTES
}"
python3 ../tools/update_metadata.py "$JSONSTR"