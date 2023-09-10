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
CURRTIMESTAMP="$(cd plugins_src; git log -1 --format=%ct | date +'%Y%m%d%H%M.%S')"

# Generate icon if not exists
if [[ ! -f resources/icon.png ]]; then
    echo "Generating icon."
    mkdir resources || true
    convert plugins_src/keyboard.png -resize 64x64 resources/icon.png 
fi

echo "Copying files to package dir."
if [[ -d plugins ]]; then
    rm -rf plugins
fi
mkdir plugins
rsync -av \
    --exclude .git \
    --exclude .gitignore \
    --exclude README.md \
    --exclude 'keyboard.png' \
    --exclude '**/*.fbp' \
    --exclude '**/__pycache__' \
    plugins_src/ plugins

# Generate metadata.json
jq ".versions=[{
    \"version\": \"$CURRTAG\",
    \"status\": \"stable\",
    \"kicad_version\": \"7.0\"
}]" < repo-metadata.json > metadata.json
touch -t $CURRTIMESTAMP metadata.json

UNPACKED_BYTES=$(du -bd 0 metadata.json plugins/ resources/ | cut -f 1 | tr "\n" "+" | sed "s/+$/\n/" | bc)

# Pack it into a zip file
rm package.zip || true
zip -Xr package.zip metadata.json plugins/ # resources/

# Add or update the JSON entry:
python3 ../tools/update_repo_metadata.py "{
    \"version\": \"$CURRTAG\",
    \"status\": \"stable\",
    \"kicad_version\": \"7.0\",
    \"download_sha256\": \"$(sha256sum package.zip | cut -d ' ' -f 1)\",
    \"download_size\": $(du -b package.zip | cut -f 1),
    \"download_url\": \"https://github.com/gauravmm/KLEPlacement/releases/download/$CURRTAG/package.zip\",
    \"install_size\": $UNPACKED_BYTES
}"
