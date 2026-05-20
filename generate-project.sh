#!/bin/bash
# generate-project.sh — Generate MeshTalk.xcodeproj using XcodeGen
set -euo pipefail

cd "$(dirname "$0")"

# Check for xcodegen
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "ERROR: Homebrew not found. Install XcodeGen manually:"
        echo "  brew install xcodegen"
        echo "  OR: mint install yonaskolb/XcodeGen"
        exit 1
    fi
fi

# Generate a simple app icon (green circle) if not present
if [ ! -f "MeshTalk/Assets.xcassets/AppIcon.appiconset/AppIcon.png" ]; then
    echo "Generating app icon..."
    if command -v python3 &> /dev/null; then
        python3 -c "
import struct, zlib, io

def create_png(width, height):
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', zlib.crc32(chunk) & 0xFFFFFFFF)

    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    raw_data = bytearray()
    cx, cy = width // 2, height // 2
    r = min(width, height) // 2 - 40
    for y in range(height):
        raw_data.append(0)  # filter byte
        for x in range(width):
            dx, dy = x - cx, y - cy
            dist = (dx*dx + dy*dy) ** 0.5
            if dist < r:
                # Green circle with slight gradient
                g = int(180 + 75 * (1 - dist/r))
                raw_data.extend([30, min(255, g), 30])
            else:
                raw_data.extend([15, 15, 15])  # dark bg

    compressed = zlib.compress(bytes(raw_data), 9)
    png = b'\x89PNG\r\n\x1a\n'
    png += make_chunk(b'IHDR', ihdr_data)
    png += make_chunk(b'IDAT', compressed)
    png += make_chunk(b'IEND', b'')
    return png

with open('MeshTalk/Assets.xcassets/AppIcon.appiconset/AppIcon.png', 'wb') as f:
    f.write(create_png(1024, 1024))
print('App icon generated.')
"
    else
        echo "WARNING: python3 not found, skipping icon generation"
    fi
fi

echo "Generating Xcode project..."
xcodegen generate --spec project.yml

echo ""
echo "✅ MeshTalk.xcodeproj generated successfully!"
echo ""
echo "Next steps:"
echo "  1. Open MeshTalk.xcodeproj in Xcode"
echo "  2. Configure signing team (Signing & Capabilities)"
echo "  3. Connect your iPhone and build (⌘R)"
echo ""
echo "Or build from command line:"
echo "  xcodebuild -project MeshTalk.xcodeproj -scheme MeshTalk -destination 'generic/platform=iOS' build"
