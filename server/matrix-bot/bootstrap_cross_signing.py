#!/usr/bin/env python3
"""
Einmaliges Bootstrap-Script fuer Cross-Signing des Bot-Accounts (MATRIX_USER_ID).

Richtet Master-, Self-Signing- und User-Signing-Key fuer den Bot ein und
signiert damit Allys eigenes Geraet. Dadurch verschwindet die Warnung
"Durch ein vom Besitzer nicht verifiziertes Geraet verschluesselt" in
Element dauerhaft, fuer alle aktuellen und zukuenftigen Raeume - ohne
Passwort, da es sich um den allerersten Cross-Signing-Upload fuer diesen
Account handelt (MSC3967: kein UIA fuer Erst-Upload noetig).

Dieses Script muss nur EINMAL ausgefuehrt werden.
"""
import json
import os
import sys

import requests
from signedjson.key import (
    generate_signing_key,
    encode_signing_key_base64,
    encode_verify_key_base64,
    get_verify_key,
)
from signedjson.sign import sign_json

HOMESERVER = os.environ.get("MATRIX_HOMESERVER", "http://synapse:8008")
USER_ID = os.environ["MATRIX_USER_ID"]
DEVICE_ID = os.environ.get("MATRIX_DEVICE_ID", "ALLYBOTV2")
SCHLUESSEL_DATEI = "/app/store/cross_signing_keys.json"
ACCESS_TOKEN = os.environ["MATRIX_ACCESS_TOKEN"]

HEADERS = {"Authorization": f"Bearer {ACCESS_TOKEN}"}


def api(method, path, body=None):
    resp = requests.request(method, f"{HOMESERVER}{path}", headers=HEADERS, json=body)
    if not resp.ok:
        print(f"[FEHLER] {method} {path} -> {resp.status_code}: {resp.text}", file=sys.stderr)
        resp.raise_for_status()
    return resp.json()


def make_key(usage):
    key = generate_signing_key(usage)
    pub = encode_verify_key_base64(get_verify_key(key))
    # Bei Cross-Signing-Keys MUSS die Key-ID aus dem oeffentlichen Schluessel
    # selbst bestehen (ed25519:<pubkey>), nicht aus einem beliebigen Namen.
    key.version = pub
    return key, pub


def main():
    master_key, master_pub = make_key("master")
    self_signing_key, self_pub = make_key("self_signing")
    user_signing_key, user_pub = make_key("user_signing")

    master_key_obj = {
        "user_id": USER_ID,
        "usage": ["master"],
        "keys": {f"ed25519:{master_pub}": master_pub},
    }
    self_signing_key_obj = {
        "user_id": USER_ID,
        "usage": ["self_signing"],
        "keys": {f"ed25519:{self_pub}": self_pub},
    }
    user_signing_key_obj = {
        "user_id": USER_ID,
        "usage": ["user_signing"],
        "keys": {f"ed25519:{user_pub}": user_pub},
    }

    sign_json(self_signing_key_obj, USER_ID, master_key)
    sign_json(user_signing_key_obj, USER_ID, master_key)

    print("[1/3] Lade Cross-Signing-Keys hoch...")
    api("POST", "/_matrix/client/v3/keys/device_signing/upload", {
        "master_key": master_key_obj,
        "self_signing_key": self_signing_key_obj,
        "user_signing_key": user_signing_key_obj,
    })
    print("      OK")

    print("[2/3] Hole aktuelles Geraete-Schluesselobjekt...")
    query_result = api("POST", "/_matrix/client/v3/keys/query", {
        "device_keys": {USER_ID: [DEVICE_ID]}
    })
    device_keys_obj = query_result["device_keys"][USER_ID][DEVICE_ID]
    print("      OK")

    print("[3/3] Signiere Geraet mit Self-Signing-Key und lade hoch...")
    sign_json(device_keys_obj, USER_ID, self_signing_key)
    api("POST", "/_matrix/client/v3/keys/signatures/upload", {
        USER_ID: {DEVICE_ID: device_keys_obj}
    })
    print("      OK")

    with open(os.open(SCHLUESSEL_DATEI, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump({
            "master_private_key": encode_signing_key_base64(master_key),
            "self_signing_private_key": encode_signing_key_base64(self_signing_key),
            "user_signing_private_key": encode_signing_key_base64(user_signing_key),
            "master_public_key": master_pub,
            "self_signing_public_key": self_pub,
            "user_signing_public_key": user_pub,
        }, f, indent=2)

    print("\nFertig. Cross-Signing fuer", USER_ID, "ist eingerichtet.")
    print("Master-Key (Fingerprint):", master_pub)


if __name__ == "__main__":
    main()
