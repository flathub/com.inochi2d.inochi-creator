import yaml
import sys

yaml_path = sys.argv[1]

data = {}
with open(yaml_path, "r") as f:
    data = yaml.safe_load(f)

sources = []

if "modules" in data:
    for module in data["modules"]:
        if "name" in module and module["name"] == "Inochi-Creator":
            if "sources" in module:
                sources = module["sources"]
                break

for source in sources:
    if "type" in source and source["type"] == "git":
        if "url" in source and "inochi-creator" in source["url"]:
            if "commit" in source:
                print(source["commit"])
                break
