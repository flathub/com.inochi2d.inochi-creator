import json
from os import path
import sys

# HACK: Undocumented way to add local packages directly to the project
# .This function takes the name and version of a dependency
# .and adds it to the .dub/packages/local-packages.json
# .inside inochi-creator

out_path = sys.argv[1]
deps_path = sys.argv[2]
name = sys.argv[3]
version = sys.argv[4]

data = []
if path.exists(out_path):
    with open(out_path, "r") as f:
        data = json.loads(f.read())
data.append(
	{
		"name": name,
		"path": path.join(deps_path, name),
		"version": version
	},
)
with open(out_path, "w") as f:
    json.dump(data, f, indent=2)