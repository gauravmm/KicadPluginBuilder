import json
from pathlib import Path
import sys

filename = Path("repo-metadata.json")
# Provide the new version as a json string
merge = json.loads(sys.argv[1])

metadata = json.loads(filename.read_text())
for i, v in enumerate(metadata["versions"]):
    if v["version"] == merge["version"]:
        metadata["versions"][i] = merge
        break
else:
    metadata["versions"].append(merge)

filename.write_text(json.dumps(metadata, indent=4))
