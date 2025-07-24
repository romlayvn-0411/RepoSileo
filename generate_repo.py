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

def extract_control_data(deb_path):
    try:
        with open(deb_path, 'rb') as f:
            data = f.read()

        # .deb is an ar archive: starts with "!<arch>\n"
        if not data.startswith(b'!<arch>\n'):
            print(f"Warning: {deb_path} is not a valid .deb file")
            return None

        def get_ar_members(data):
            offset = 8  # skip "!<arch>\n"
            while offset < len(data):
                header = data[offset:offset+60]
                name = header[:16].decode().strip()
                size = int(header[48:58].decode().strip())
                file_data = data[offset+60:offset+60+size]
                yield name, file_data
                offset += 60 + size
                if size % 2 != 0:
                    offset += 1  # align to even

        control_data = None
        found_control_tar = False
        
        for name, content in get_ar_members(data):
            print(f"Processing archive member: {name} in {deb_path}")
            if "control.tar" in name:
                found_control_tar = True
                try:
                    # Try .gz
                    if name.endswith(".gz"):
                        with gzip.GzipFile(fileobj=BytesIO(content)) as gz:
                            with tarfile.open(fileobj=gz) as tar:
                                for member in tar.getmembers():
                                    if member.name == "./control" or member.name == "control":
                                        control_file = tar.extractfile(member)
                                        control_data = control_file.read().decode()
                                        break
                    # Try .xz
                    elif name.endswith(".xz"):
                        import lzma
                        with lzma.LZMAFile(BytesIO(content)) as xz:
                            with tarfile.open(fileobj=BytesIO(xz.read())) as tar:
                                for member in tar.getmembers():
                                    if member.name == "./control" or member.name == "control":
                                        control_file = tar.extractfile(member)
                                        control_data = control_file.read().decode()
                                        break
                    # Try uncompressed
                    else:
                        with tarfile.open(fileobj=BytesIO(content)) as tar:
                            for member in tar.getmembers():
                                if member.name == "./control" or member.name == "control":
                                    control_file = tar.extractfile(member)
                                    control_data = control_file.read().decode()
                                    break
                except Exception as e:
                    print(f"Error extracting control data from {name} in {deb_path}: {str(e)}")
                break

        if not found_control_tar:
            print(f"Warning: No control.tar found in {deb_path}")
            return None

        if not control_data:
            print(f"Warning: Control file not found in {deb_path}")
            return None

        return control_data.strip()
    except Exception as e:
        print(f"Error processing {deb_path}: {str(e)}")
        return None

def generate_packages_file():
    output = ""
    for file in sorted(os.listdir(DEB_DIR)):
        if file.endswith(".deb"):
            deb_path = os.path.join(DEB_DIR, file)
            print(f"\nProcessing: {deb_path}")
            
            control = extract_control_data(deb_path)
            if control is None:
                print(f"Skipping {file} due to errors")
                continue
                
            size = os.path.getsize(deb_path)

            with open(deb_path, 'rb') as f:
                content = f.read()
                md5sum = hashlib.md5(content).hexdigest()
                sha256sum = hashlib.sha256(content).hexdigest()

            entry = f"{control}\nFilename: {DEB_DIR}/{file}\nSize: {size}\nMD5sum: {md5sum}\nSHA256: {sha256sum}\n\n"
            output += entry

    print("\nWriting output files...")
    with open(OUTPUT_PACKAGES, "w", encoding="utf-8") as f:
        f.write(output)

    with gzip.open(OUTPUT_PACKAGES_GZ, "wb") as f:
        f.write(output.encode("utf-8"))

    with bz2.open(OUTPUT_PACKAGES_BZ2, "wb") as f:
        f.write(output.encode("utf-8"))
    
    print("Done!")

if __name__ == "__main__":
    generate_packages_file()
