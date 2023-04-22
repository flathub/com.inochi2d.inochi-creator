# Inochi Creator

## update-dependencies.sh script

This script will generate the dependency lists for inochi-creator, using as reference the commit hash from the `./com.inochi2d.inochi-creator.yml` file.

### Verification stage
* Extract the commit hash from the `./com.inochi2d.inochi-creator.yml` file (`checkout target`)
* The next part of the process can be skipped if you use the `-f/--force` argument.
  * If it's not a nightly build and a `.dep_target` file exists.
    * Extract the commit hash from `.dep_target`.
    * If both hashes are the same, then the process exits with err code 1.

### Download Stage
* Clears the working folder (`./dep.build`).
* Clones inochi-creator repository.
* Checkouts the commit hash from the `checkout target`.
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
  * Adds the gitver and semver repositories.
  * Replace all the forked libraries with the propper git repositories and commit hashes.
* If it's a nightly build, it will remove the `.dep_target` file.
  * If its not, it will store the `checkout target` to the `.dep_target` file.