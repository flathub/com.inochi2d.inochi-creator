import json
import os
import subprocess
import re
import sys

in_path = sys.argv[1]
out_path = sys.argv[2]
deps_path = sys.argv[3]

data = []
result = []
with open(in_path, "r") as f:
    data = json.loads(f.read())

forked_sources = os.listdir(deps_path)

# .Regular expression used to capture the name
# .of the dependency from the url. used to check if the
# .entry is in the list of forked_sources
url_re = re.compile(r"https://code\.dlang\.org/packages/(.*)/")

# Add gitver entry
gitver_path = os.path.join(deps_path, "gitver")

result.append({
    "type": "git",
    "url": subprocess.check_output(
        ["git", "-C", gitver_path, 
        "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
    "commit" : subprocess.check_output(
        ["git", "-C", gitver_path, 
        "rev-parse", "HEAD"]).decode("utf-8").strip(),
    "dest": ".flatpak-dub/gitver",
    "disable-shallow-clone": True
    })

# Add semver entry
semver_path = os.path.join(deps_path, "semver")

result.append({
    "type": "git",
    "url": subprocess.check_output(
        ["git", "-C", semver_path, 
        "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
    "commit" : subprocess.check_output(
        ["git", "-C", semver_path, 
        "rev-parse", "HEAD"]).decode("utf-8").strip(),
    "dest": ".flatpak-dub/semver",
    "disable-shallow-clone": True
    })

# Process all entries
for source in data:
    if source["type"] == "archive":
        url_check = url_re.match(source["url"])
        if url_check is not None and url_check[1] in forked_sources:
            # If the entry is one of the forked libraries, replace it
            # with the one from git
            repo_name = url_check[1]
            repo_path = os.path.join(deps_path, repo_name)
            new_src = {
                "type": "git",
                "url": subprocess.check_output(
                    ["git", "-C", repo_path, 
                    "config", "--get", "remote.origin.url"]).decode("utf-8").strip(),
                "commit" : subprocess.check_output(
                    ["git", "-C", repo_path, 
                    "rev-parse", "HEAD"]).decode("utf-8").strip(),
                "dest": source["dest"],
                "disable-shallow-clone": True
            }

            #HACK: the fghj repo has a submodule that crashes flatpak 
            if repo_name == "fghj":
                new_src["disable-submodules"] = True
            result.append(new_src)
        else:
            result.append(source)
    else:
        result.append(source)

with open(out_path, "w") as f:
    json.dump(result, f, indent=4)