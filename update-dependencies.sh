#!/usr/bin/env bash

set -e

source ./scripts/semver.sh

MODE="READ"
VERIFY_CREATOR=0

# Parse options
for i in "$@"; do
  case $i in
    -h|--help)
cat <<EOL
Usage: $0 [OPTION]...
Checks inochi-creator repository, calculates dependencies and stores them 
on files ready to be used by flatpak-builder.

  --tag=<string>    Defines which version of inochi-creator to checkout.
                    * "nightly" will checkout the latest commit from all 
                    repositories
                    * "latest-tag" will checkout the latest tag available
                    * Any other string will be processed as a
                    tag/branch/commit to checkout
                    * If the parameter is not defined, it will read the 
                    commit from ./inochi-creator-source.json
    --verify        Check if the requested commit is equal to the one
                    registered in ./inochi-creator-source.json, if it
                    applies, then the process stops.
                    This argument has no effect if the --tag option
                    is not used
    --help          display this help and exit

EOL
    exit 0
    ;;
    --verify)
      VERIFY_CREATOR=1
    ;;
    -t=*|--tag=*)
      TAG="${i#*=}"
      if [[ $TAG == "nightly" ]] ; then
        MODE="NIGHTLY"
      elif [[ $TAG == "latest-tag" ]] ; then
        MODE="LATEST_TAG"
      else 
        MODE="CHECKOUT"
      fi
      shift # past argument=value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

echo "Running on $MODE mode."
if [[ $VERIFY_CREATOR -eq 1 ]]; then
    echo "Update verification ON."
else
    echo "Update verification OFF."
fi

mkdir -p dep.build

# Delete any old virtualenv to be sure te recreate a clean one
find ./dep.build -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

# Download inochi-creator
pushd dep.build

git clone https://github.com/Inochi2D/inochi-creator.git

# Get the correct checkout target
if [[ "${MODE}" == "READ" ]]; then
    # Read commit hash from inochi-creator-source.json
    CHECKOUT_TARGET=$(grep -oP '"commit".*"\K(.*)(?=")' ../inochi-creator-source.json)
elif [[ "${MODE}" == "LATEST_TAG" ]]; then
    # Get the latest tag from the tag list
    CHECKOUT_TARGET=$(git -C ./inochi-creator/ describe --tags \
        `git -C ./inochi-creator/ rev-list --tags --max-count=1`)
elif [[ "${MODE}" == "CHECKOUT" ]]; then
    CHECKOUT_TARGET=$TAG
fi
git -C ./inochi-creator/ checkout $CHECKOUT_TARGET

# Write inochi-creator version
if [[ "${MODE}" != "READ" ]]; then
    if [[ $VERIFY_CREATOR -eq 1 ]]; then
        COMMIT=$(grep -oP '"commit": "\K(.*)(?=")' ../inochi-creator-source.json)
        NEW_COMMIT=$(git -C ./inochi-creator rev-parse HEAD)
        if [[ "$COMMIT" == "$NEW_COMMIT" ]]; then
            echo "No update found for inochi-creator"
            exit 1
        fi
    fi

    python3 ../scripts/write-creator-source.py \
        "../inochi-creator-source.json" \
        "./inochi-creator"
fi

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

# Download gitver and semver
git clone https://github.com/Inochi2D/gitver.git
git clone https://github.com/dcarp/semver.git
popd #deps

if [[ "${MODE}" != "NIGHTLY" ]]; then
    # Update repos to their state at marked date
    CREATOR_DATE=$(git -C ./inochi-creator/ show -s --format=%ci)
    for d in ./deps/*/ ; do
        DEP_COMMIT=$(git -C $d log --before="$CREATOR_DATE" -n1 --pretty=format:"%H" | head -n1)
        git -C $d checkout $DEP_COMMIT
    done
fi

# Fix tag for inochi2d and semver version
# .This perl regular expresion will match strings that contain
# .`inochi2d`, `~>` and `"`, with anything in between those things
# .it will output only the things between `~>` and `"`
REQ_INOCHI2D_TAG=v$(grep -oP 'inochi2d.*~>\K(.*)(?=")' ./inochi-creator/dub.sdl)
CUR_INOCHI2D_TAG=$(git -C ./deps/inochi2d/ describe --tags \
        `git -C ./deps/inochi2d/ rev-list --tags --max-count=1`)
if [[ "$CUR_INOCHI2D_TAG" != "$REQ_INOCHI2D_TAG" ]]; then
    git -C ./deps/inochi2d/ tag -d "$REQ_INOCHI2D_TAG" || true
    git -C ./deps/inochi2d/ tag "$REQ_INOCHI2D_TAG"
fi
# .Same logic as above, but now using semver instead of inochi2d
REQ_SEMVER_TAG=v$(grep -oP 'semver.*~>\K(.*)(?=")' ./deps/gitver/dub.sdl)
git -C ./deps/semver/ checkout "$REQ_SEMVER_TAG"

# Add the dependencies to the inochi creator's local-packages file
# .The version is calculated to semver format using the git tag
# .the commit hash and the commit distance to the tag.
mkdir -p ./inochi-creator/.dub/packages
for d in ./deps/*/ ; do
    python3 ../scripts/write-local-packages.py \
        ./inochi-creator/.dub/packages/local-packages.json \
        ../deps/ \
        $(basename $d) \
        "$(semver $d)"
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
python3 ./scripts/write-dub-deps.py \
    ./dep.build/dub-dependencies.json \
    ./dub-add-local-sources.json \
    ./dep.build/deps
 