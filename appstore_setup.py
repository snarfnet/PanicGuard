"""ASC API: Stalker Deterrent (PanicGuard) metadata setup"""
import json, time, base64, jwt, requests

KEY_ID = "WDXGY9WX55"
ISSUER_ID = "2be0734f-943a-4d61-9dc9-5d9045c46fec"
KEY_PATH = r"C:\Users\Windows\Downloads\AuthKey_WDXGY9WX55.p8"
BASE = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "6771247559"

with open(KEY_PATH) as f:
    _key = f.read()

def h():
    now = int(time.time())
    token = jwt.encode({"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}, _key, algorithm="ES256", headers={"kid": KEY_ID})
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

def api(method, path, **kw):
    return requests.request(method, f"{BASE}{path}", headers=h(), **kw)

# 1. Category
r = api("GET", f"/apps/{APP_ID}/appInfos")
info_id = r.json()["data"][0]["id"]
print(f"Info ID: {info_id}")

api("PATCH", f"/appInfos/{info_id}", json={"data": {"type": "appInfos", "id": info_id,
    "relationships": {
        "primaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}},
        "secondaryCategory": {"data": {"type": "appCategories", "id": "LIFESTYLE"}}
    }}})
print("Category: set")

# 2. Content rights
api("PATCH", f"/apps/{APP_ID}", json={"data": {"type": "apps", "id": APP_ID,
    "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}})
print("Content rights: set")

# 3. Privacy URL
r = api("GET", f"/appInfos/{info_id}/appInfoLocalizations")
for loc in r.json()["data"]:
    api("PATCH", f"/appInfoLocalizations/{loc['id']}", json={"data": {
        "type": "appInfoLocalizations", "id": loc["id"],
        "attributes": {"privacyPolicyUrl": "https://snarfnet.github.io/"}}})
    print(f"Privacy ({loc['attributes']['locale']}): set")

# 4. Add en-US appInfo
r = api("POST", "/appInfoLocalizations", json={"data": {
    "type": "appInfoLocalizations",
    "attributes": {"locale": "en-US", "name": "Stalker Deterrent", "privacyPolicyUrl": "https://snarfnet.github.io/"},
    "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}}}})
print(f"en-US appInfo: {r.status_code}")

# 5. Age rating
r = api("GET", f"/appInfos/{info_id}/ageRatingDeclaration")
if r.status_code == 200:
    ard_id = r.json()["data"]["id"]
    api("PATCH", f"/ageRatingDeclarations/{ard_id}", json={"data": {"type": "ageRatingDeclarations", "id": ard_id,
        "attributes": {
            "horrorOrFearThemes": "NONE", "violenceCartoonOrFantasy": "NONE", "violenceRealistic": "NONE",
            "violenceRealisticProlongedGraphicOrSadistic": "NONE", "sexualContentGraphicAndNudity": "NONE",
            "sexualContentOrNudity": "NONE", "profanityOrCrudeHumor": "NONE", "matureOrSuggestiveThemes": "NONE",
            "alcoholTobaccoOrDrugUseOrReferences": "NONE", "gamblingSimulated": "NONE",
            "medicalOrTreatmentInformation": "NONE", "contests": "NONE", "gunsOrOtherWeapons": "NONE",
            "gambling": False, "lootBox": False, "unrestrictedWebAccess": False,
            "advertising": True, "userGeneratedContent": False, "messagingAndChat": False,
            "parentalControls": False, "healthOrWellnessTopics": False, "ageAssurance": False
        }}})
    print("Age rating: set")

# 6. Version
r = api("GET", f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS")
version_id = r.json()["data"][0]["id"]
print(f"Version ID: {version_id}")

api("PATCH", f"/appStoreVersions/{version_id}", json={"data": {
    "type": "appStoreVersions", "id": version_id,
    "attributes": {"copyright": "2026 tokyonasu"}}})

# 7. Version localizations
r = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
for loc in r.json()["data"]:
    if loc["attributes"]["locale"] == "ja":
        api("PATCH", f"/appStoreVersionLocalizations/{loc['id']}", json={"data": {
            "type": "appStoreVersionLocalizations", "id": loc["id"],
            "attributes": {
                "description": "あなたの安全を守るパーソナルセーフティアプリ。\n\n主な機能：\n- パニックボタン：1タップで大音量サイレン+フラッシュ点滅\n- 偽着信：リアルな偽の着信で自然に離脱\n- 緊急SMS：GPS位置情報付きで緊急連絡先にSOS送信\n- 証拠録音：アラート中に自動で音声録音\n- シェイク発動：スマホを振るだけでハンズフリー発動\n- 4つのモード：サイレン、フラッシュ、両方、サイレント\n\n緊急時は必ず110番に通報してください。",
                "keywords": "ストーカー,撃退,防犯,安全,護身,サイレン,偽着信,緊急,SOS,パニック,防犯ブザー,位置情報,録音",
                "supportUrl": "https://snarfnet.github.io/",
                "marketingUrl": "https://snarfnet.github.io/"
            }}})
        print("ja version: updated")

r = api("POST", "/appStoreVersionLocalizations", json={"data": {
    "type": "appStoreVersionLocalizations",
    "attributes": {
        "locale": "en-US",
        "description": "Your personal safety companion.\n\nFeatures:\n- Panic Button: one tap triggers loud siren + flash strobe\n- Fake Call: schedule a realistic fake incoming call\n- Emergency SMS: send GPS location to contacts\n- Evidence Recording: auto-record audio during alerts\n- Shake Activation: hands-free alert trigger\n- Multiple modes: Siren, Flash, Both, or Silent\n\nIn an emergency, always call local authorities.",
        "keywords": "stalker,deterrent,safety,panic,siren,fake call,emergency,sos,alert,protection,security",
        "supportUrl": "https://snarfnet.github.io/",
        "marketingUrl": "https://snarfnet.github.io/"
    },
    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
print(f"en-US version: {r.status_code}")

# 8. Review detail
r = api("POST", "/appStoreReviewDetails", json={"data": {
    "type": "appStoreReviewDetails",
    "attributes": {
        "contactFirstName": "Tokyo", "contactLastName": "Nasu",
        "contactEmail": "snarfnet@gmail.com", "contactPhone": "+14155550000",
        "demoAccountRequired": False, "demoAccountName": "", "demoAccountPassword": "",
        "notes": "Personal safety app. Siren, flash, and fake call features help users deter threats. No actual phone calls are made."
    },
    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}}})
print(f"Review detail: {r.status_code}")

# 9. Free price
pp_data = {"s": APP_ID, "t": "USA", "p": "10000"}
pp_id = base64.b64encode(json.dumps(pp_data, separators=(",", ":")).encode()).decode().rstrip("=")
r = api("POST", "/appPriceSchedules", json={
    "data": {"type": "appPriceSchedules", "relationships": {
        "app": {"data": {"type": "apps", "id": APP_ID}},
        "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
        "manualPrices": {"data": [{"type": "appPrices", "id": "${usa-free}"}]}
    }},
    "included": [{"type": "appPrices", "id": "${usa-free}",
        "attributes": {"startDate": None, "endDate": None},
        "relationships": {
            "territory": {"data": {"type": "territories", "id": "USA"}},
            "appPricePoint": {"data": {"type": "appPricePoints", "id": pp_id}}
        }}]
})
print(f"Free price: {r.status_code}")

print(f"\nDone! App ID: {APP_ID}, Version: {version_id}")
