 #!/bin/bash
path=~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/
plugin=Lin.xcplugin

if [ ! -x "$path" ]; then
    echo "making xcode plugins folder"
    mkdir -p "$path"
fi
if [ -x "$path$plugin" ]; then
    echo "deleting the old plugin"
    rm -rf "$path$plugin"
fi
echo "making new plugin"
cp -R "$plugin" "$path"
echo "success. now restart xcode."
