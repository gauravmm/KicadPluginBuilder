#!/bin/zsh

set -e
setopt CSH_NULL_GLOB


echo "Generates a package for the KiCAD Repository"

rm -r ./**/__pycache__ || true

UNPACKED_BYTES=$(du -bd 0 metadata.json plugins/ resources/ | cut -f 1 | tr "\n" "+" | sed "s/+$/\n/" | bc)
echo "UNPACKED_BYTES: $UNPACKED_BYTES"

# Pack it into a zip file
rm package.zip || true
zip -r package.zip metadata.json plugins/ resources/ -x "plugins/.git/**" -x plugins/.gitignore -x plugins/README.md -x "plugins/images/**" -x "**/*.fbp"

# Get the current tag, if one exists.
CURRTAG="$(cd plugins; git describe --tags)"

echo "
JSON ENTRY:
{
    'version': '$CURRTAG',
    'status': 'stable',
    'kicad_version': '7.0',
    'download_sha256': '$(sha256sum package.zip | cut -d ' ' -f 1)',
    'download_size': $(du -b package.zip | cut -f 1),
    'download_url': 'https://github.com/YOUR/DOWNLOAD/URL/kicad-beautiful-theme.zip',
    'install_size': $UNPACKED_BYTES
}"