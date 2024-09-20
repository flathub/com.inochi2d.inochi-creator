# com.inochi2d.inochi-creator

## Update Base

```sh
podman run --rm \
    -v$(pwd):/opt:Z --workdir=/opt \
    docker://ghcr.io/flathub/flatpak-external-data-checker:latest \
    --edit-only ./com.inochi2d.inochi-creator.yml 
```

## Update dependencies

Get the grillo-delmal/inochi-creator-devtest repository.

```sh
cd ..
git clone https://github.com/grillo-delmal/inochi-creator-devtest
cd inochi-creator-devtest
```

Use the update-dependencies.sh

```sh
./update-dependencies.sh \
    --yml-creator=../com.inochi2d.inochi-creator/com.inochi2d.inochi-creator.yml \ 
    --skip-patch
```

## Local Test

```
flatpak-builder --default-branch=localbuild --force-clean --repo=./repo-dir ./build-dir com.inochi2d.inochi-creator.yml

flatpak build-bundle \
    --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo \
    ./repo-dir \
    inochi-creator.x86_64.flatpak \
    com.inochi2d.inochi-creator localbuild
flatpak build-bundle \
    --runtime \
    ./repo-dir \
    inochi-creator.x86_64.debug.flatpak \
    com.inochi2d.inochi_creator.Debug localbuild

flatpak --user -y install inochi-creator.x86_64.flatpak
flatpak --user -y install inochi-creator.x86_64.debug.flatpak
```