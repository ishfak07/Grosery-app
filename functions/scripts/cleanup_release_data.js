#!/usr/bin/env node
"use strict";

const {spawnSync} = require("child_process");
const admin = require("firebase-admin");

const DEFAULT_PROJECT_ID = "grocery-delivery-app-388bc";
const PAGE_SIZE = 100;
const DELETE_CONCURRENCY = 10;

const DATA_COLLECTIONS = [
  "shops",
  "offers",
  "products",
  "orders",
  "account_sales",
  "delivery_reward_payments",
  "delivery_reward_adjustments",
  "support_tickets",
  "support_messages",
  "notifications",
  "password_reset_requests",
  "account_deletion_requests",
  "legacy_media_cleanup",
];

const STORAGE_PREFIXES = [
  "user_uploads/",
  "catalog/",
  "orders/",
  "support/",
];

function parseArgs(argv) {
  const options = {
    projectId: DEFAULT_PROJECT_ID,
    storageBucket: "",
    confirmProject: "",
    yes: false,
    deleteAdmins: false,
    deleteSettings: false,
    skipAuth: false,
    skipFirestore: false,
    skipStorage: false,
    help: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    switch (arg) {
      case "--project":
        options.projectId = requireValue(argv, ++index, arg);
        break;
      case "--bucket":
        options.storageBucket = requireValue(argv, ++index, arg);
        break;
      case "--confirm-project":
        options.confirmProject = requireValue(argv, ++index, arg);
        break;
      case "--yes":
        options.yes = true;
        break;
      case "--delete-admins":
        options.deleteAdmins = true;
        break;
      case "--delete-settings":
        options.deleteSettings = true;
        break;
      case "--skip-auth":
        options.skipAuth = true;
        break;
      case "--skip-firestore":
        options.skipFirestore = true;
        break;
      case "--skip-storage":
        options.skipStorage = true;
        break;
      case "--help":
      case "-h":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown option: ${arg}`);
    }
  }

  if (!options.storageBucket) {
    options.storageBucket = `${options.projectId}.firebasestorage.app`;
  }
  return options;
}

function requireValue(argv, index, flag) {
  const value = argv[index];
  if (!value || value.startsWith("--")) {
    throw new Error(`${flag} requires a value.`);
  }
  return value;
}

function printHelp() {
  console.log(`
Usage:
  node scripts/cleanup_release_data.js [options]

Dry run, no deletion:
  npm run cleanup:release:dry-run

Live cleanup, preserving admin accounts and app_settings:
  npm run cleanup:release

Options:
  --project <id>            Firebase project id. Default: ${DEFAULT_PROJECT_ID}
  --bucket <name>           Firebase Storage bucket.
  --confirm-project <id>    Required with --yes and must match --project.
  --yes                     Actually delete data. Without this, dry run only.
  --delete-admins           Also delete Firestore/Auth admin accounts.
  --delete-settings         Also delete app_settings documents.
  --skip-auth               Do not delete Firebase Authentication users.
  --skip-firestore          Do not delete Firestore documents.
  --skip-storage            Do not delete Firebase Storage files.
`);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  if (options.yes && options.confirmProject !== options.projectId) {
    throw new Error(
      "--yes requires --confirm-project with the exact project id.",
    );
  }
  if (options.skipFirestore && options.skipAuth && options.skipStorage) {
    throw new Error("All cleanup areas are skipped.");
  }
  if (options.skipFirestore && options.skipAuth === false && !options.deleteAdmins) {
    throw new Error(
      "Cannot preserve admins while skipping Firestore. Use --delete-admins " +
        "or remove --skip-firestore.",
    );
  }

  const accessToken = getFirebaseCliAccessToken();
  const context = {
    options,
    accessToken,
    cloudinaryUrls: new Set(),
    preservedAdminUids: new Set(),
    firestoreDeleted: 0,
    firestoreWouldDelete: 0,
    storageDeleted: 0,
    storageWouldDelete: 0,
    authDeleted: 0,
    authWouldDelete: 0,
    authErrors: 0,
    preservedAdmins: 0,
    preservedSettings: 0,
  };

  printHeader(options);

  if (!options.skipFirestore) {
    await cleanupFirestore(context);
  }
  if (!options.skipAuth) {
    await cleanupAuth(context);
  }
  if (!options.skipStorage) {
    await cleanupStorage(context);
  }

  printSummary(context);
}

function printHeader(options) {
  console.log(`Project: ${options.projectId}`);
  console.log(`Mode: ${options.yes ? "LIVE DELETE" : "DRY RUN"}`);
  console.log(
    `Admins: ${options.deleteAdmins ? "delete" : "preserve admin role docs/accounts"}`,
  );
  console.log(
    `Settings: ${options.deleteSettings ? "delete app_settings" : "preserve app_settings"}`,
  );
  console.log("");
}

function getFirebaseCliAccessToken() {
  const cli = process.platform === "win32" ? "firebase.cmd" : "firebase";
  const result = spawnSync(cli, ["login:list", "--json"], {
    encoding: "utf8",
    shell: process.platform === "win32",
  });
  if (result.status !== 0) {
    throw new Error(
      "Could not read Firebase CLI login. Run `firebase login` first.",
    );
  }

  const parsed = JSON.parse(result.stdout);
  const accessToken = parsed.result?.[0]?.tokens?.access_token;
  if (!accessToken) {
    throw new Error(
      "Firebase CLI is logged in, but no access token was returned.",
    );
  }
  return accessToken;
}

async function cleanupFirestore(context) {
  console.log("Firestore");
  await cleanupUsersCollection(context);

  for (const collectionPath of DATA_COLLECTIONS) {
    await cleanupCollection(context, collectionPath);
  }

  if (context.options.deleteSettings) {
    await cleanupCollection(context, "app_settings");
  } else {
    const settings = await listCollectionDocuments(context, "app_settings");
    context.preservedSettings = settings.length;
    console.log(`  app_settings: preserved ${settings.length}`);
  }
  console.log("");
}

async function cleanupUsersCollection(context) {
  const docs = await listCollectionDocuments(context, "users");
  const docsToDelete = [];
  for (const doc of docs) {
    collectCloudinaryUrls(doc, context.cloudinaryUrls);
    const uid = documentId(doc);
    const role = doc.fields?.role?.stringValue || "";
    if (role === "admin" && !context.options.deleteAdmins) {
      context.preservedAdminUids.add(uid);
      context.preservedAdmins += 1;
    } else {
      docsToDelete.push(doc);
    }
  }

  await cleanupDocumentList(context, "users", docsToDelete);
  if (!context.options.deleteAdmins) {
    console.log(`  users: preserved ${context.preservedAdmins} admin account(s)`);
  }
}

async function cleanupCollection(context, collectionPath) {
  const docs = await listCollectionDocuments(context, collectionPath);
  for (const doc of docs) {
    collectCloudinaryUrls(doc, context.cloudinaryUrls);
  }
  await cleanupDocumentList(context, collectionPath, docs);
}

async function cleanupDocumentList(context, label, docs) {
  const orderedDocs = [];
  for (const doc of docs) {
    orderedDocs.push(...await descendantDocuments(context, doc));
    orderedDocs.push(doc);
  }

  context.firestoreWouldDelete += orderedDocs.length;
  if (!context.options.yes) {
    console.log(`  ${label}: would delete ${orderedDocs.length}`);
    return;
  }

  await runPool(orderedDocs, DELETE_CONCURRENCY, async (doc) => {
    await firestoreDelete(context, documentPath(doc));
    context.firestoreDeleted += 1;
  });
  console.log(`  ${label}: deleted ${orderedDocs.length}`);
}

async function descendantDocuments(context, doc) {
  const output = [];
  const subcollections = await listSubcollectionIds(context, documentPath(doc));
  for (const collectionId of subcollections) {
    const nestedPath = `${documentPath(doc)}/${collectionId}`;
    const nestedDocs = await listCollectionDocuments(context, nestedPath);
    for (const nestedDoc of nestedDocs) {
      collectCloudinaryUrls(nestedDoc, context.cloudinaryUrls);
      output.push(...await descendantDocuments(context, nestedDoc));
      output.push(nestedDoc);
    }
  }
  return output;
}

async function listCollectionDocuments(context, collectionPath) {
  const docs = [];
  let pageToken = "";
  do {
    const url = new URL(firestoreUrl(context, collectionPath));
    url.searchParams.set("pageSize", `${PAGE_SIZE}`);
    if (pageToken) {
      url.searchParams.set("pageToken", pageToken);
    }
    const body = await fetchJson(context, url, {method: "GET"});
    docs.push(...(body.documents || []));
    pageToken = body.nextPageToken || "";
  } while (pageToken);
  return docs;
}

async function listSubcollectionIds(context, docPath) {
  const ids = [];
  let pageToken = "";
  do {
    const url = `${firestoreUrl(context, docPath)}:listCollectionIds`;
    const body = await fetchJson(context, url, {
      method: "POST",
      body: JSON.stringify({
        pageSize: PAGE_SIZE,
        ...(pageToken ? {pageToken} : {}),
      }),
    });
    ids.push(...(body.collectionIds || []));
    pageToken = body.nextPageToken || "";
  } while (pageToken);
  return ids;
}

async function firestoreDelete(context, docPath) {
  await fetchJson(context, firestoreUrl(context, docPath), {method: "DELETE"});
}

function firestoreUrl(context, path) {
  return `https://firestore.googleapis.com/v1/projects/` +
    `${context.options.projectId}/databases/(default)/documents/` +
    encodePath(path);
}

function encodePath(path) {
  return path.split("/").map(encodeURIComponent).join("/");
}

function documentPath(doc) {
  return doc.name.split("/documents/")[1];
}

function documentId(doc) {
  const parts = documentPath(doc).split("/");
  return parts[parts.length - 1];
}

async function cleanupAuth(context) {
  console.log("Authentication");
  const appName = "release-cleanup";
  const existing = admin.apps.find((app) => app.name === appName);
  const app = existing || admin.initializeApp({
    credential: {
      getAccessToken: async () => ({
        access_token: context.accessToken,
        expires_in: 3600,
      }),
    },
    projectId: context.options.projectId,
  }, appName);

  const uidsToDelete = [];
  let pageToken;
  do {
    const page = await admin.auth(app).listUsers(1000, pageToken);
    for (const user of page.users) {
      if (
        context.options.deleteAdmins ||
        !context.preservedAdminUids.has(user.uid)
      ) {
        uidsToDelete.push(user.uid);
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);

  context.authWouldDelete = uidsToDelete.length;
  if (!context.options.yes) {
    console.log(`  auth users: would delete ${uidsToDelete.length}`);
    return;
  }

  for (const batch of chunks(uidsToDelete, 1000)) {
    const result = await admin.auth(app).deleteUsers(batch);
    context.authDeleted += result.successCount;
    context.authErrors += result.failureCount;
  }
  console.log(
    `  auth users: deleted ${context.authDeleted}` +
      (context.authErrors ? `, failed ${context.authErrors}` : ""),
  );
}

async function cleanupStorage(context) {
  console.log("Storage");
  for (const prefix of STORAGE_PREFIXES) {
    const objects = await listStorageObjects(context, prefix);
    context.storageWouldDelete += objects.length;

    if (!context.options.yes) {
      console.log(`  ${prefix}: would delete ${objects.length}`);
      continue;
    }

    await runPool(objects, DELETE_CONCURRENCY, async (object) => {
      await storageDelete(context, object.name);
      context.storageDeleted += 1;
    });
    console.log(`  ${prefix}: deleted ${objects.length}`);
  }
  console.log("");
}

async function listStorageObjects(context, prefix) {
  const objects = [];
  let pageToken = "";
  do {
    const url = new URL(
      `https://storage.googleapis.com/storage/v1/b/` +
        `${encodeURIComponent(context.options.storageBucket)}/o`,
    );
    url.searchParams.set("prefix", prefix);
    url.searchParams.set("maxResults", "1000");
    if (pageToken) {
      url.searchParams.set("pageToken", pageToken);
    }
    const body = await fetchJson(context, url, {method: "GET"});
    objects.push(...(body.items || []));
    pageToken = body.nextPageToken || "";
  } while (pageToken);
  return objects;
}

async function storageDelete(context, objectName) {
  await fetchJson(
    context,
    `https://storage.googleapis.com/storage/v1/b/` +
      `${encodeURIComponent(context.options.storageBucket)}/o/` +
      encodeURIComponent(objectName),
    {method: "DELETE"},
  );
}

async function fetchJson(context, url, init) {
  const response = await fetch(url, {
    ...init,
    headers: {
      Authorization: `Bearer ${context.accessToken}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });

  if (response.status === 404) {
    return {};
  }
  if (response.status === 204) {
    return {};
  }

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${text}`);
  }
  return text ? JSON.parse(text) : {};
}

function collectCloudinaryUrls(doc, output) {
  collectCloudinaryUrlsFromFields(doc.fields || {}, output);
}

function collectCloudinaryUrlsFromFields(fields, output) {
  for (const value of Object.values(fields)) {
    collectCloudinaryUrlsFromValue(value, output);
  }
}

function collectCloudinaryUrlsFromValue(value, output) {
  if (!value) {
    return;
  }
  if (
    typeof value.stringValue === "string" &&
    value.stringValue.includes("res.cloudinary.com/")
  ) {
    output.add(value.stringValue);
    return;
  }
  if (value.mapValue?.fields) {
    collectCloudinaryUrlsFromFields(value.mapValue.fields, output);
  }
  for (const child of value.arrayValue?.values || []) {
    collectCloudinaryUrlsFromValue(child, output);
  }
}

async function runPool(items, limit, worker) {
  let index = 0;
  const workers = Array.from(
    {length: Math.min(limit, items.length)},
    async () => {
      while (index < items.length) {
        const current = items[index++];
        await worker(current);
      }
    },
  );
  await Promise.all(workers);
}

function chunks(items, size) {
  const output = [];
  for (let index = 0; index < items.length; index += size) {
    output.push(items.slice(index, index + size));
  }
  return output;
}

function printSummary(context) {
  const live = context.options.yes;
  console.log("Summary");
  console.log(
    `  Firestore docs ${live ? "deleted" : "that would be deleted"}: ` +
      `${live ? context.firestoreDeleted : context.firestoreWouldDelete}`,
  );
  console.log(
    `  Auth users ${live ? "deleted" : "that would be deleted"}: ` +
      `${live ? context.authDeleted : context.authWouldDelete}`,
  );
  console.log(
    `  Storage files ${live ? "deleted" : "that would be deleted"}: ` +
      `${live ? context.storageDeleted : context.storageWouldDelete}`,
  );
  if (!context.options.deleteAdmins) {
    console.log(`  Preserved admin account(s): ${context.preservedAdmins}`);
  }
  if (!context.options.deleteSettings) {
    console.log(`  Preserved app_settings doc(s): ${context.preservedSettings}`);
  }
  if (context.cloudinaryUrls.size > 0) {
    console.log(
      `  Cloudinary URL(s) found in deleted docs: ` +
        `${context.cloudinaryUrls.size}`,
    );
    console.log("  Cloudinary assets are not deleted by this Firebase cleanup.");
  }
  if (!live) {
    console.log("");
    console.log("Dry run only. No Firebase data was deleted.");
  }
}

main().catch((error) => {
  console.error(`Cleanup failed: ${error.message}`);
  process.exit(1);
});
