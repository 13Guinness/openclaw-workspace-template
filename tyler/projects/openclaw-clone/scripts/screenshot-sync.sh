#!/bin/bash
# Copy latest screenshot from workspace/screenshots to latest-screenshot.png (clean filename)
LATEST=$(ls -1t ~/.openclaw/workspace/screenshots/*.png 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
    cp "$LATEST" ~/.openclaw/workspace/latest-screenshot.png
fi
