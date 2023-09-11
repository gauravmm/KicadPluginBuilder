#!python3

from pathlib import Path
import zipfile


def instsize(path: Path):
    with zipfile.ZipFile(path, "r") as z:
        return sum(entry.file_size for entry in z.infolist() if not entry.is_dir())


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python installedsize.py <filename>")
        sys.exit(1)

    print(instsize(Path(sys.argv[1])))
