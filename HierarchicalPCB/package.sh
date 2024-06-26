#!/bin/zsh

set -e
setopt CSH_NULL_GLOB
echo "Generates a package for the KiCAD Repository"

echo "Fetching repository."
if [[ ! -d plugins_src ]]; then
    git clone --single-branch git@github.com:gauravmm/HierarchicalPcb.git plugins_src
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
    convert plugins_src/images/icon-orig.png -resize 64x64 resources/icon.png 
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
    --exclude images \
    --exclude '**/*.fbp' \
    --exclude '**/__pycache__' \
    plugins_src/ plugins

# Generate metadata.json
jq ".versions=[{
    \"version\": \"$CURRTAG\",
    \"status\": \"stable\",
    \"kicad_version\": \"8.0\"
}]" < repo-metadata.json > metadata.json
touch -t $CURRTIMESTAMP metadata.json

# Pack it into a zip file
rm package.zip || true
../tools/deterministic-zip_linux-amd64 -r package.zip metadata.json plugins/ resources/

# Add or update the JSON entry in the repo metadata:
python3 ../tools/update_repo_metadata.py "{
    \"version\": \"$CURRTAG\",
    \"status\": \"stable\",
    \"kicad_version\": \"8.0\",
    \"download_sha256\": \"$(sha256sum package.zip | cut -d ' ' -f 1)\",
    \"download_size\": $(du -b package.zip | cut -f 1),
    \"download_url\": \"https://github.com/gauravmm/HierarchicalPcb/releases/download/$CURRTAG/package.zip\",
    \"install_size\": $(python3 ../tools/installedsize.py package.zip)
}"
