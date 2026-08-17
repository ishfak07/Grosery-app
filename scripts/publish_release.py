"""Upload an AAB to Google Play production track with a given update priority.

Usage:
    python scripts/publish_release.py <path-to-service-account.json> [--track internal]
    python scripts/publish_release.py <path-to-service-account.json> --check-only

Defaults to the production track, 100% rollout, and inAppUpdatePriority=5.

Before touching Play, this checks (read-only) whether the versionCode implied
by pubspec.yaml already exists:

  1. assigned to a release on any track (edits().tracks().list), and
  2. already uploaded as a bundle, even if never assigned to a track
     (edits().bundles().list) — this can happen if a previous run's upload
     succeeded but the process died/timed out before the track update or
     commit.

If it's already on a track, the run aborts (use --skip-duplicate-check to
override). If it's only sitting as an uploaded, unassigned bundle, that
bundle is reused for the release instead of re-uploading the AAB. Otherwise
the bundle is uploaded fresh. The upload itself is resumable, chunked, and
retried on transient network/5xx errors; the edit is only committed once
both the upload (or reuse) and the track update have succeeded.
"""

import argparse
import sys
from pathlib import Path

import httplib2
from google.oauth2 import service_account
from google_auth_httplib2 import AuthorizedHttp
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE_NAME = "com.ishi.grocerydelivery"
AAB_PATH = Path("build/app/outputs/bundle/release/app-release.aab")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

# Android App Bundles don't have a registered IANA MIME type; Play's own
# upload docs/samples use this generic binary type.
AAB_MIMETYPE = "application/octet-stream"

# The previous plain (non-resumable) upload of a ~66MB bundle was hitting
# "TimeoutError: The write operation timed out" on some networks. Resumable
# uploads in bounded chunks, with a generous per-request timeout and
# automatic retry/backoff, are the standard fix.
HTTP_TIMEOUT_SECONDS = 120
UPLOAD_CHUNK_SIZE = 8 * 1024 * 1024  # 8 MiB — multiple of 256 KiB, as required.
UPLOAD_RETRIES = 5


def _build_service(service_account_json: str):
    creds = service_account.Credentials.from_service_account_file(
        service_account_json, scopes=SCOPES
    )
    http = httplib2.Http(timeout=HTTP_TIMEOUT_SECONDS)
    # Google's resumable-upload protocol reuses HTTP 308 for "Resume
    # Incomplete" chunk-acknowledgement responses, which never carry a
    # Location header. httplib2 treats 308 as a redirect by default and
    # raises RedirectMissingLocation when one's missing — that's the
    # "Redirected but the response is missing a Location: header." crash
    # seen mid-upload. Disabling follow_redirects lets next_chunk() see the
    # raw 308 status directly, which is how it detects "keep uploading".
    http.follow_redirects = False
    authed_http = AuthorizedHttp(creds, http=http)
    return build("androidpublisher", "v3", http=authed_http, cache_discovery=False)


def _expected_version_code() -> int | None:
    """Read the build number out of pubspec.yaml's `version: X.Y.Z+N` line."""
    pubspec = Path("pubspec.yaml")
    if not pubspec.exists():
        return None
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("version:") and "+" in line:
            return int(line.split("+", 1)[1].strip())
    return None


def _existing_track_versions(service, edit_id: str) -> dict[int, set[str]]:
    """Which versionCodes are already assigned to a release, on which tracks."""
    tracks = (
        service.edits()
        .tracks()
        .list(editId=edit_id, packageName=PACKAGE_NAME)
        .execute(num_retries=UPLOAD_RETRIES)
        .get("tracks", [])
    )
    found: dict[int, set[str]] = {}
    for track in tracks:
        for release in track.get("releases", []):
            for version_code in release.get("versionCodes", []):
                found.setdefault(int(version_code), set()).add(track["track"])
    return found


def _existing_bundle_versions(service, edit_id: str) -> set[int]:
    """Which versionCodes already exist as uploaded bundles (any track or none)."""
    bundles = (
        service.edits()
        .bundles()
        .list(editId=edit_id, packageName=PACKAGE_NAME)
        .execute(num_retries=UPLOAD_RETRIES)
        .get("bundles", [])
    )
    return {int(bundle["versionCode"]) for bundle in bundles}


def _discard_edit(service, edit_id: str) -> None:
    try:
        service.edits().delete(
            editId=edit_id, packageName=PACKAGE_NAME
        ).execute(num_retries=UPLOAD_RETRIES)
    except Exception:
        pass  # Unused/uncommitted edits expire on their own; not fatal.


def _report_check(
    expected_version_code: int | None,
    track_versions: dict[int, set[str]],
    bundle_versions: set[int],
) -> None:
    print(f"Package: {PACKAGE_NAME}")
    if expected_version_code is None:
        print("Could not read a build number from pubspec.yaml (version: X.Y.Z+N).")
    else:
        print(f"Expected versionCode (from pubspec.yaml): {expected_version_code}")

    print(f"versionCodes already uploaded as bundles: {sorted(bundle_versions) or 'none'}")
    if track_versions:
        print("versionCodes already assigned to a track release:")
        for version_code in sorted(track_versions):
            tracks = ", ".join(sorted(track_versions[version_code]))
            print(f"  {version_code} -> {tracks}")
    else:
        print("versionCodes already assigned to a track release: none")

    if expected_version_code is None:
        return
    if expected_version_code in track_versions:
        tracks = ", ".join(sorted(track_versions[expected_version_code]))
        print(
            f"RESULT: versionCode {expected_version_code} already has a release "
            f"on track(s): {tracks}. Uploading again would be a duplicate/conflict."
        )
    elif expected_version_code in bundle_versions:
        print(
            f"RESULT: versionCode {expected_version_code} is already uploaded as a "
            "bundle but is NOT assigned to any track yet. Safe to reuse without "
            "re-uploading the AAB."
        )
    else:
        print(
            f"RESULT: versionCode {expected_version_code} is absent from both "
            "track releases and uploaded bundles. Safe to upload fresh."
        )


def _upload_bundle(service, edit_id: str) -> str:
    media = MediaFileUpload(
        str(AAB_PATH),
        mimetype=AAB_MIMETYPE,
        chunksize=UPLOAD_CHUNK_SIZE,
        resumable=True,
    )
    request = service.edits().bundles().upload(
        editId=edit_id,
        packageName=PACKAGE_NAME,
        media_body=media,
    )
    response = None
    while response is None:
        status, response = request.next_chunk(num_retries=UPLOAD_RETRIES)
        if status:
            print(f"Upload progress: {int(status.progress() * 100)}%")
    version_code = response["versionCode"]
    print(f"Uploaded AAB as versionCode {version_code}")
    return version_code


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("service_account_json")
    parser.add_argument("--track", default="production")
    parser.add_argument("--priority", type=int, default=5)
    parser.add_argument("--user-fraction", type=float, default=None,
                         help="Omit for 100%% rollout; pass e.g. 0.2 for a staged rollout")
    parser.add_argument("--skip-duplicate-check", action="store_true",
                         help="Skip the pre-upload check for an already-released/uploaded versionCode.")
    parser.add_argument("--check-only", action="store_true",
                         help="Only run the duplicate/bundle check and report the result; "
                                "does not upload, update tracks, or commit anything.")
    args = parser.parse_args()

    if not AAB_PATH.exists():
        sys.exit(f"AAB not found at {AAB_PATH}")

    service = _build_service(args.service_account_json)
    expected_version_code = _expected_version_code()

    # A read-only edit is the only way the API exposes current track/bundle
    # state; nothing is modified until (and unless) we explicitly commit it.
    edit_id = service.edits().insert(
        body={}, packageName=PACKAGE_NAME
    ).execute(num_retries=UPLOAD_RETRIES)["id"]

    track_versions: dict[int, set[str]] = {}
    bundle_versions: set[int] = set()
    if not args.skip_duplicate_check or args.check_only:
        print("Checking Google Play for an existing release/bundle of this versionCode...")
        track_versions = _existing_track_versions(service, edit_id)
        bundle_versions = _existing_bundle_versions(service, edit_id)
        _report_check(expected_version_code, track_versions, bundle_versions)

    if args.check_only:
        _discard_edit(service, edit_id)
        return

    reuse_existing_bundle = False
    if not args.skip_duplicate_check and expected_version_code is not None:
        if expected_version_code in track_versions:
            tracks = ", ".join(sorted(track_versions[expected_version_code]))
            _discard_edit(service, edit_id)
            sys.exit(
                f"versionCode {expected_version_code} already exists on track(s): "
                f"{tracks}. Aborting before upload to avoid a duplicate/conflicting "
                "release. Pass --skip-duplicate-check to override if this is "
                "intentional."
            )
        if expected_version_code in bundle_versions:
            reuse_existing_bundle = True

    if reuse_existing_bundle:
        version_code = str(expected_version_code)
        print(
            f"versionCode {version_code} is already uploaded as a bundle and not "
            "yet on any track — reusing it instead of re-uploading the AAB."
        )
    else:
        try:
            version_code = _upload_bundle(service, edit_id)
        except Exception as error:
            print(
                f"UPLOAD FAILED ({error}). Edit {edit_id} was NOT committed — "
                "no changes were made to Play Console."
            )
            raise

    release = {
        "versionCodes": [str(version_code)],
        "inAppUpdatePriority": args.priority,
    }
    if args.user_fraction is None:
        release["status"] = "completed"
    else:
        release["status"] = "inProgress"
        release["userFraction"] = args.user_fraction

    try:
        service.edits().tracks().update(
            editId=edit_id,
            track=args.track,
            packageName=PACKAGE_NAME,
            body={"track": args.track, "releases": [release]},
        ).execute(num_retries=UPLOAD_RETRIES)
    except Exception as error:
        print(
            f"TRACK UPDATE FAILED ({error}). Edit {edit_id} was NOT committed — "
            "the uploaded bundle sits in an uncommitted edit only; "
            "Play Console/production is unchanged."
        )
        raise

    commit = service.edits().commit(
        editId=edit_id, packageName=PACKAGE_NAME
    ).execute(num_retries=UPLOAD_RETRIES)
    print(f"Committed edit {commit['id']} to track '{args.track}'.")
    print(f"versionCode: {version_code}")
    print(f"Rollout: {'100%' if args.user_fraction is None else args.user_fraction}")
    print(f"inAppUpdatePriority: {args.priority}")


if __name__ == "__main__":
    main()
