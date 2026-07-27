#!/usr/bin/env python3
"""Strip China CDN mirrors from OpenWrt projectsmirrors.json without breaking JSON."""
from pathlib import Path
import json
import sys

p = Path(sys.argv[1] if len(sys.argv) > 1 else "scripts/projectsmirrors.json")
if not p.is_file():
	sys.exit(0)

data = json.loads(p.read_text())
drop = (".cn/", "tencent", "aliyun")
for key, urls in list(data.items()):
	if isinstance(urls, list):
		data[key] = [u for u in urls if not any(d in u for d in drop)]
p.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n")
print(f"fixed mirrors: {p}")
