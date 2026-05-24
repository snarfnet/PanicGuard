#!/usr/bin/env python3
"""Upload screenshots to App Store Connect via appScreenshotSets API."""

import os, sys, json, time, hashlib, jwt, requests

APP_ID = "6771247559"
KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER_ID = os.environ["ASC_ISSUER_ID"]
KEY_PATH = os.environ["ASC_KEY_PATH"]

DISPLAY_TYPES = {
    "iphone": "APP_IPHONE_67",
    "ipad": "APP_IPAD_PRO_3GEN_129",
}

SCREENSHOT_FILES = {
    "iphone": [
        "screenshots/iphone/screenshot_01_ready.png",
        "screenshots/iphone/screenshot_02_active.png",
        "screenshots/iphone/screenshot_03_record.png",
        "screenshots/iphone/screenshot_04_location.png",
    ],
    "ipad": [
        "screenshots/ipad/ipad_screenshot_01_ready.png",
        "screenshots/ipad/ipad_screenshot_02_active.png",
        "screenshots/ipad/ipad_screenshot_03_record.png",
        "screenshots/ipad/ipad_screenshot_04_location.png",
    ],
}

def get_token():
    with open(KEY_PATH, "r") as f:
        key = f.read()
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": KEY_ID})

def api(method, path, **kwargs):
    base = "https://api.appstoreconnect.apple.com/v1"
    url = f"{base}{path}" if path.startswith("/") else path
    headers = {"Authorization": f"Bearer {get_token()}", "Content-Type": "application/json"}
    r = requests.request(method, url, headers=headers, **kwargs)
    if r.status_code >= 400:
        print(f"  API {r.status_code}: {r.text[:400]}")
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
    return r.json().get("data", [])

def get_or_create_screenshot_set(loc_id, display_type):
    """Get existing screenshot set or create a new one."""
    r = api("GET", f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?filter[screenshotDisplayType]={display_type}")
    sets = r.json().get("data", [])
    if sets:
        return sets[0]["id"]

    # Create new set
    payload = {
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            },
        }
    }
    r = api("POST", "/appScreenshotSets", json=payload)
    if r.status_code >= 400:
        return None
    return r.json()["data"]["id"]

def delete_existing_screenshots(set_id):
    """Delete all screenshots in a screenshot set."""
    r = api("GET", f"/appScreenshotSets/{set_id}/appScreenshots")
    existing = r.json().get("data", [])
    for ss in existing:
        api("DELETE", f"/appScreenshots/{ss['id']}")
        print(f"    Deleted {ss['id']}")

def upload_screenshot(set_id, filepath):
    filename = os.path.basename(filepath)
    filesize = os.path.getsize(filepath)

    # Reserve
    payload = {
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileName": filename, "fileSize": filesize},
            "relationships": {
                "appScreenshotSet": {
                    "data": {"type": "appScreenshotSets", "id": set_id}
                }
            },
        }
    }
    r = api("POST", "/appScreenshots", json=payload)
    if r.status_code >= 400:
        return False
    ss_data = r.json()["data"]
    ss_id = ss_data["id"]
    upload_ops = ss_data["attributes"].get("uploadOperations", [])

    with open(filepath, "rb") as f:
        file_bytes = f.read()

    for op in upload_ops:
        chunk = file_bytes[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        resp = requests.put(op["url"], headers=headers, data=chunk)
        if resp.status_code >= 400:
            print(f"    Upload chunk failed: {resp.status_code}")
            return False

    # Commit
    md5 = hashlib.md5(file_bytes).hexdigest()
    r = api("PATCH", f"/appScreenshots/{ss_id}", json={
        "data": {
            "type": "appScreenshots", "id": ss_id,
            "attributes": {"uploaded": True, "sourceFileChecksum": md5},
        }
    })
    if r.status_code < 400:
        print(f"    Uploaded {filename}")
        return True
    return False

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
            screenshots = [p for p in SCREENSHOT_FILES[device_type] if os.path.exists(p)]
            if not screenshots:
                print(f"  No {device_type} screenshots found, skipping")
                continue

            set_id = get_or_create_screenshot_set(loc_id, display_type)
            if not set_id:
                print(f"  Failed to get/create screenshot set for {display_type}")
                continue

            print(f"  {device_type} set: {set_id} - uploading {len(screenshots)} screenshots")
            delete_existing_screenshots(set_id)

            for filepath in screenshots:
                upload_screenshot(set_id, filepath)
                time.sleep(1)

    print("\nDone!")

if __name__ == "__main__":
    main()
