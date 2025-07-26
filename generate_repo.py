import os
import gzip
import bz2
import hashlib
import tarfile
from io import BytesIO

DEB_DIR = "debs"
OUTPUT_PACKAGES = "Packages"
OUTPUT_PACKAGES_GZ = "Packages.gz"
OUTPUT_PACKAGES_BZ2 = "Packages.bz2"

def new_func():
    OUTPUT_PACKAGES = "Packages"
    return OUTPUT_PACKAGES

OUTPUT_PACKAGES = new_func()

def generate_packages_file():
    output = ""
    for file in sorted(os.listdir(DEB_DIR)):
        if file.endswith(".deb"):
            deb_path = os.path.join(DEB_DIR, file)
            try:
                size = os.path.getsize(deb_path)
                with open(deb_path, 'rb') as f:
                    content = f.read()
                    md5sum = hashlib.md5(content).hexdigest()
                output += f"Filename: {DEB_DIR}/{file}\nSize: {size}\nMD5sum: {md5sum}\n\n"
            except Exception as e:
                print(f"Error processing {file}: {e}")

    with open(OUTPUT_PACKAGES, "w", encoding="utf-8") as f:
        f.write(output)

    with gzip.open(OUTPUT_PACKAGES_GZ, "wb") as f:
        f.write(output.encode("utf-8"))

    with bz2.open(OUTPUT_PACKAGES_BZ2, "wb") as f:
        f.write(output.encode("utf-8"))
    
    print("Done!")

if __name__ == "__main__":
    generate_packages_file()
