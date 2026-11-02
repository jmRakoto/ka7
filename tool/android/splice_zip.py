"""Copies a zip entry by entry, replacing usr/lib/<name>.so with rebuilt ones.

Usage: splice_zip.py <original.zip> <folder with rebuilt .so> <output.zip>

Every other entry keeps its bytes, attributes (symlinks included) and order,
so youtubedl-android unpacks the copy exactly like the original.
"""

import os
import sys
import zipfile

LIBS = ["libsharpyuv", "libwebp", "libwebpdecoder", "libwebpdemux", "libwebpmux"]


def main(original: str, rebuilt: str, output: str) -> None:
    replacements = {
        f"usr/lib/{lib}.so": os.path.join(rebuilt, f"{lib}.so") for lib in LIBS
    }
    replaced = set()
    with zipfile.ZipFile(original) as source, zipfile.ZipFile(
        output, "w", zipfile.ZIP_DEFLATED
    ) as target:
        for info in source.infolist():
            if info.filename in replacements:
                with open(replacements[info.filename], "rb") as lib:
                    target.writestr(info, lib.read())
                replaced.add(info.filename)
            else:
                target.writestr(info, source.read(info))
    missing = set(replacements) - replaced
    if missing:
        sys.exit(f"not found in {original}: {sorted(missing)}")


if __name__ == "__main__":
    main(*sys.argv[1:])
