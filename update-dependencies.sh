#!/usr/bin/env bash

set -e

source ./semver.sh

# TODO: Add options for latest tag and nightly
# LATEST_TAG=1

mkdir -p dep.build

# Delete any old virtualenv to be sure te recreate a clean one
find ./dep.build -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

# Download inochi-creator
pushd dep.build

git clone https://github.com/Inochi2D/inochi-creator.git

# Download deps
mkdir -p ./deps
pushd deps
git clone https://github.com/Inochi2D/inochi2d.git
git clone https://github.com/Inochi2D/facetrack-d.git
git clone https://github.com/Inochi2D/vmc-d.git
git clone https://github.com/Inochi2D/inmath.git
git clone https://github.com/Inochi2D/psd-d.git
git clone https://github.com/Inochi2D/fghj.git
git clone https://github.com/Inochi2D/bindbc-imgui.git
git clone https://github.com/KitsunebiGames/i18n.git i18n-d
git clone https://github.com/Inochi2D/dportals.git
git clone https://github.com/Inochi2D/gitver.git
git clone https://github.com/dcarp/semver.git
popd #deps

if [[ "${LATEST_TAG}" -eq 1 ]]; then
    # Get correct versions for latest tag
    LATEST_TAG=$(git -C ./inochi-creator/ describe --tags \
        `git -C ./inochi-creator/ rev-list --tags --max-count=1`)
    git -C ./inochi-creator/ checkout $LATEST_TAG

    # Update repos to their state at marked date
    CREATOR_DATE=$(git -C ./inochi-creator/ show -s --format=%ci)
    for d in ./deps/*/ ; do
        DEP_COMMIT=$(git -C $d log --before="$CREATOR_DATE" -n1 --pretty=format:"%H" | head -n1)
        git -C $d checkout $DEP_COMMIT
    done
fi

# Fix tag for inochi2d and semver version
INOCHI2D_TAG=v$(grep -oP 'inochi2d.*~>\K(.*)(?=")' ./inochi-creator/dub.sdl)
CUR_INOCHI2D_TAG=$(git -C ./deps/inochi2d/ describe --tags \
        `git -C ./deps/inochi2d/ rev-list --tags --max-count=1`)
if [[ "$CUR_INOCHI2D_TAG" != "$INOCHI2D_TAG" ]]; then
    git -C ./deps/inochi2d/ tag -d "$INOCHI2D_TAG" || true
    git -C ./deps/inochi2d/ tag "$INOCHI2D_TAG"
fi
SEMVER_TAG=v$(grep -oP 'semver.*~>\K(.*)(?=")' ./deps/gitver/dub.sdl)
git -C ./deps/semver/ checkout "$SEMVER_TAG"

#HACK: Undocumented way to add local packages directly to the project
function add_dep() {
python3 << EOF
import json
from os import path
data = []
if path.exists("./inochi-creator/.dub/packages/local-packages.json"):
    with open("./inochi-creator/.dub/packages/local-packages.json", "r") as f:
        data = json.loads(f.read())
data.append(
	{
		"name": "$1",
		"path": "../deps/$1/",
		"version": "$2"
	},
)
with open("./inochi-creator/.dub/packages/local-packages.json", "w") as f:
    json.dump(data, f, indent=2)
EOF
}

mkdir -p ./inochi-creator/.dub/packages
for d in ./deps/*/ ; do
    add_dep $(basename $d) "$(semver $d)"
done

# Download dependencies and generate dub.selections.json in the process
pushd inochi-creator
dub describe >> ../describe.json
popd #inochi-creator

popd #dep.build

# Get / Install flatpak-dub-generator
wget \
    -O ./dep.build/flatpak-dub-generator.py \
    https://raw.githubusercontent.com/flatpak/flatpak-builder-tools/master/dub/flatpak-dub-generator.py 

# Generate the dependency file
python ./dep.build/flatpak-dub-generator.py \
    --output=./dep.build/dub-dependencies.json \
    ./dep.build/inochi-creator/dub.selections.json

# Swap dub archives for forked libraries
python3 << EOF
import json
import os
import subprocess
import re

data = []
result = []
with open("./dep.build/dub-dependencies.json", "r") as f:
    data = json.loads(f.read())

forked_sources = os.listdir("./dep.build/deps")

url_re = re.compile(r"https://code\.dlang\.org/packages/(.*)/")

result.append({
    "type": "git",
    "url": subprocess.check_output(
        ["git", "-C", "./dep.build/inochi-creator", 
        "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
    "commit" : subprocess.check_output(
        ["git", "-C", "./dep.build/inochi-creator", 
        "rev-parse", "HEAD"]).decode("utf-8").strip(),
    "disable-shallow-clone": True
    })

result.append({
    "type": "git",
    "url": subprocess.check_output(
        ["git", "-C", "./dep.build/deps/gitver", 
        "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
    "commit" : subprocess.check_output(
        ["git", "-C", "./dep.build/deps/gitver", 
        "rev-parse", "HEAD"]).decode("utf-8").strip(),
    "dest": ".flatpak-dub/gitver",
    "disable-shallow-clone": True
    })

result.append({
    "type": "git",
    "url": subprocess.check_output(
        ["git", "-C", "./dep.build/deps/semver", 
        "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
    "commit" : subprocess.check_output(
        ["git", "-C", "./dep.build/deps/semver", 
        "rev-parse", "HEAD"]).decode("utf-8").strip(),
    "dest": ".flatpak-dub/semver",
    "disable-shallow-clone": True
    })

for source in data:
    if source["type"] == "archive":
        url_check = url_re.match(source["url"])
        if url_check is not None and url_check[1] in forked_sources:
            repo_name = url_check[1]
            new_src = {
                "type": "git",
                "url": subprocess.check_output(
                    ["git", "-C", "./dep.build/deps/%s" % repo_name, 
                    "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
                "commit" : subprocess.check_output(
                    ["git", "-C", "./dep.build/deps/%s" % repo_name, 
                    "rev-parse", "HEAD"]).decode("utf-8").strip(),
                "dest": source["dest"],
                "disable-shallow-clone": True
            }

            #HACK: this repo has a weird submodule 
            if repo_name == "fghj":
                new_src["disable-submodules"] = True
            result.append(new_src)
        else:
            result.append(source)
    else:
        result.append(source)

with open("./dub-add-local-sources.json", "w") as f:
    json.dump(result, f, indent=4)
EOF
