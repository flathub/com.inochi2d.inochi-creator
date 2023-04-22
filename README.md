# Inochi Creator

## update-dependencies.sh script

This script can generate dependency lists for specific tags and nightly builds of inochi-creator.
It follows the following process

### Download Stage
* Clears the working folder (`./dep.build`).
* Clones inochi-creator repository.
  * If the `--tag=latest-tag` argument was passed, then it checks out the latest tag
  * If the `--tag=nightly` argument was passed, it does nothing (leaves it at the top of the main branch)
  * If the `--tag=<string>` argument was passed, it checkouts the `<string>` tag/branch/commit
  * if there where no arguments, it will checkout the commit hash to checkout from `./inochi-creator-source.json`
* If it's not reading the `./inochi-creator-source.json` file, then it will proceed to 
* Clones all the forked repositories into the deps folder.
  * If its not a nightly build, then it sincronizes the deps with the inochi-creator repo through the following steps.
  * Checkout the latest tag for inochi-creator.
  * Check the date from inochi-creator's latest tag head.
  * For each repo find the latest commit before the date of the latest tag's head.
  * Checkout that commit.
* Fix the tag for inochi2d if it's broken.
* Checkout semver version required for gitver.

### Build Stage
* Add all the forked repositories as local dependencies for the inochi-creator project.
* Run `dub describe` to download the dependencies and list the required versions on `dub.selections.json`.

### Process Stage
* Get `flatpak-dub-generator.py` from [flatpak-builder-tools](https://github.com/flatpak/flatpak-builder-tools).
* Run through the processed `dub.selections.json` to generate `dub-add-local-sources.json`.
  * Adds the gitver and semver repositories
  * Replace all the forked libraries with the propper git repositories and commit hashes

### Examples:
```sh
./update-dependencies.sh
```

Will read the ./inochi-creator-source.json file, get the commit hash and
update all the dependencies from ./dub-add-local-sources.json to the
ones corresponding to the date of that commit.

```sh
./update-dependencies.sh --tag=nightly
```

Will checkout all the main branches of all the dependencies and calculate
dependencies considering them.

```sh
./update-dependencies.sh --tag=v0.7.3
```

Will checkout the v0.7.3 tag from the inochi-creator repository and it 
will update the dependencies from ./dub-add-local-sources.json to the
ones corresponding to the date of that commit..

```sh
./update-dependencies.sh --tag=latest-tag --verify
```

Will check the repository for the latest tag, if it's different from
the one stored in ./inochi-creator-source.json, it will update the
dependencies from ./dub-add-local-sources.json.