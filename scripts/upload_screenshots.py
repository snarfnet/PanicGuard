#!/usr/bin/env python3
"""Upload simulator screenshots to App Store Connect."""

import os, sys, json, time, jwt, requests, glob

APP_ID = "6771247559"
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
KEY_PATH = os.environ["ASC_KEY_PATH"]

# ASC screenshot display types
DISPLAY_TYPES = {
    "iphone": "APP_IPHONE_67",
    "ipad": "APP_IPAD_PRO_13_M4",
}

def get_token():
    with open(KEY_PATH, "r") as f:
        key = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, **kwargs):
    base = "https://api.appstoreconnect.apple.com/v1"
    url = f"{base}{path}" if path.startswith("/") else path
    headers = {
        "Authorization": f"Bearer {get_token()}",
        "Content-Type": "application/json",
    }
    r = requests.request(method, url, headers=headers, **kwargs)
    if r.status_code >= 400:
        print(f"API error {r.status_code}: {r.text[:500]}")
    return r

def get_version_localizations():
    r = api("GET", f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=READY_FOR_REVIEW,PREPARE_FOR_SUBMISSION,WAITING_FOR_REVIEW,IN_REVIEW,REJECTED")
    versions = r.json().get("data", [])
    if not versions:
        r = api("GET", f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS")
        versions = r.json().get("data", [])
    if not versions:
        print("No app store version found")
        sys.exit(1)
    version_id = versions[0]["id"]
    print(f"Version ID: {version_id}")

    r = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    localizations = r.json().get("data", [])
    return localizations

def delete_existing_screenshots(loc_id, display_type):
    r = api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshots?filter[screenshotDisplayType]={display_type}")
    existing = r.json().get("data", [])
    for ss in existing:
        api("DELETE", f"/appScreenshots/{ss['id']}")
        print(f"  Deleted existing screenshot {ss['id']}")

def upload_screenshot(loc_id, display_type, filepath, position):
    filename = os.path.basename(filepath)
    filesize = os.path.getsize(filepath)

    # Reserve
    payload = {
        "data": {
            "type": "appScreenshots",
            "attributes": {
                "fileName": filename,
                "fileSize": filesize,
            },
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            },
        }
    }
    r = api("POST", "/appScreenshots", json=payload)
    if r.status_code >= 400:
        print(f"  Failed to reserve screenshot: {r.text[:300]}")
        return
    ss_data = r.json()["data"]
    ss_id = ss_data["id"]
    upload_ops = ss_data["attributes"].get("uploadOperations", [])

    # Upload parts
    with open(filepath, "rb") as f:
        file_bytes = f.read()

    for op in upload_ops:
        offset = op["offset"]
        length = op["length"]
        chunk = file_bytes[offset:offset + length]
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        resp = requests.put(op["url"], headers=headers, data=chunk)
        if resp.status_code >= 400:
            print(f"  Upload chunk failed: {resp.status_code}")
            return

    # Commit
    import hashlib
    md5 = hashlib.md5(file_bytes).hexdigest()
    commit_payload = {
        "data": {
            "type": "appScreenshots",
            "id": ss_id,
            "attributes": {
                "uploaded": True,
                "sourceFileChecksum": md5,
            },
        }
    }
    r = api("PATCH", f"/appScreenshots/{ss_id}", json=commit_payload)
    if r.status_code < 400:
        print(f"  Uploaded {filename} as {display_type}")
    else:
        print(f"  Commit failed: {r.text[:300]}")

def main():
    localizations = get_version_localizations()
    if not localizations:
        print("No localizations found")
        sys.exit(1)

    for loc in localizations:
        loc_id = loc["id"]
        locale = loc["attributes"]["locale"]
        print(f"\nLocale: {locale} (ID: {loc_id})")

        for device_type, display_type in DISPLAY_TYPES.items():
            screenshots = sorted(glob.glob(f"screenshots/{device_type}/*.png"))
            if not screenshots:
                print(f"  No {device_type} screenshots found")
                continue

            print(f"  Uploading {len(screenshots)} {device_type} screenshots...")
            delete_existing_screenshots(loc_id, display_type)

            for i, filepath in enumerate(screenshots):
                upload_screenshot(loc_id, display_type, filepath, i)
                time.sleep(1)

    print("\nDone!")

if __name__ == "__main__":
    main()
