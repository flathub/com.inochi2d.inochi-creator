import subprocess
import json
import sys

data = []
result = []

out_path = sys.argv[1]
repo_path = sys.argv[2]

commit = subprocess.check_output(
    ["git", "-C", repo_path, 
    "rev-parse", "HEAD"]).decode("utf-8").strip()
url = subprocess.check_output(
    ["git", "-C", repo_path, 
    "config", "--get", "remote.origin.url"]).decode("utf-8").strip()

# Add inochi-creator entry
result.append({
        "type": "git",
        "url": url,
        "commit" : commit,
        "disable-shallow-clone": True
    })

with open(out_path, "w") as f:
    json.dump(result, f, indent=4)
