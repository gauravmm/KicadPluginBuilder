import hashlib
import io


READ_SIZE = 65536


def getsha256(filename):
    hash = hashlib.sha256()
    with io.open(filename, "rb") as f:
        data = f.read(READ_SIZE)
        while data:
            hash.update(data)
            data = f.read(READ_SIZE)
    return hash.hexdigest()


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python hash.py <filename>")
        sys.exit(1)
    print(getsha256(sys.argv[1]))
