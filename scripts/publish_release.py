"""Upload an AAB to Google Play production track with a given update priority.

Usage:
    python scripts/publish_release.py <path-to-service-account.json> [--track internal]

Defaults to the production track, 100% rollout, and inAppUpdatePriority=5.
"""

import argparse
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE_NAME = "com.ishi.grocerydelivery"
AAB_PATH = Path("build/app/outputs/bundle/release/app-release.aab")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("service_account_json")
    parser.add_argument("--track", default="production")
    parser.add_argument("--priority", type=int, default=5)
    parser.add_argument("--user-fraction", type=float, default=None,
                         help="Omit for 100%% rollout; pass e.g. 0.2 for a staged rollout")
    args = parser.parse_args()

    if not AAB_PATH.exists():
        sys.exit(f"AAB not found at {AAB_PATH}")

    creds = service_account.Credentials.from_service_account_file(
        args.service_account_json, scopes=SCOPES
    )
    service = build("androidpublisher", "v3", credentials=creds)

    edit_request = service.edits().insert(body={}, packageName=PACKAGE_NAME)
    edit_id = edit_request.execute()["id"]

    upload = service.edits().bundles().upload(
        editId=edit_id,
        packageName=PACKAGE_NAME,
        media_body=MediaFileUpload(str(AAB_PATH), mimetype="application/octet-stream"),
    ).execute()
    version_code = upload["versionCode"]
    print(f"Uploaded AAB as versionCode {version_code}")

    release = {
        "versionCodes": [str(version_code)],
        "inAppUpdatePriority": args.priority,
    }
    if args.user_fraction is None:
        release["status"] = "completed"
    else:
        release["status"] = "inProgress"
        release["userFraction"] = args.user_fraction

    service.edits().tracks().update(
        editId=edit_id,
        track=args.track,
        packageName=PACKAGE_NAME,
        body={"track": args.track, "releases": [release]},
    ).execute()

    commit = service.edits().commit(
        editId=edit_id, packageName=PACKAGE_NAME
    ).execute()
    print(f"Committed edit {commit['id']} to track '{args.track}'.")
    print(f"Rollout: {'100%' if args.user_fraction is None else args.user_fraction}")
    print(f"inAppUpdatePriority: {args.priority}")


if __name__ == "__main__":
    main()
