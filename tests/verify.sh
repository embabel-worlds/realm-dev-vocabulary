#!/bin/sh
# Battery for realm-dev-vocabulary. A vocabulary has no producers and no views, so what can be
# wrong with it live is that a parent type is missing from the world's schema: a child realm that
# names it then loads degraded. This checks every parent type is known to the appliance.
#
#   APPLIANCE=http://127.0.0.1:11043 AUTH=user:pass sh tests/verify.sh
#
# The last line on success is exactly `ALL CHECKS PASS`.
set -e
cd "$(dirname "$0")/.."
exec python3 - <<'PY'
import base64, json, os, re, sys, urllib.request
base = os.environ.get("APPLIANCE", "http://127.0.0.1:11043").rstrip("/")
auth = os.environ.get("AUTH") or os.environ.get("EMBABEL_AUTH") or sys.exit("set AUTH=user:pass")
req = urllib.request.Request(base + "/api/v1/admin/kg/schema",
                             headers={"Authorization": "Basic " + base64.b64encode(auth.encode()).decode()})
schema = urllib.request.urlopen(req, timeout=120).read().decode()
names = re.findall(r"^- name: (\w+)", open("types/vocabulary.yml").read(), re.M)
missing = [n for n in names if not re.search(r"\b" + n + r"\b", schema)]
for n in names:
    print(("  ok   " if n not in missing else "  FAIL ") + n + " in the world's schema")
if missing:
    print("DRIFT FOUND: " + ", ".join(missing)); sys.exit(1)
print("ALL CHECKS PASS")
PY
