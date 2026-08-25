import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: { code: "method_not_allowed", message: "Use POST." } }, 405);
  }

  const authHeader = request.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: { code: "unauthorized", message: "Missing bearer token." } }, 401);
  }

  const supabaseURL = requireEnv("SUPABASE_URL");
  const anonKey = requireEnv("SUPABASE_ANON_KEY");
  const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");

  const userClient = createClient(supabaseURL, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();

  if (userError || !userData.user) {
    return jsonResponse({ error: { code: "unauthorized", message: "Invalid session." } }, 401);
  }

  const ownerID = userData.user.id;
  const admin = createClient(supabaseURL, serviceRoleKey);

  try {
    await deleteStorageFolder(admin, ownerID);
    await deleteTableRows(admin, ownerID);

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(ownerID);
    if (deleteUserError) {
      throw deleteUserError;
    }

    return jsonResponse({
      deleted: true,
      ownerId: ownerID,
      deletedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error("delete-account failed", error);
    return jsonResponse({
      error: {
        code: "delete_failed",
        message: "Account deletion failed.",
      },
    }, 500);
  }
});

async function deleteTableRows(admin: ReturnType<typeof createClient>, ownerID: string) {
  const tables = [
    "companion_messages",
    "memory_capsules",
    "lifeprints",
    "daily_tasks",
    "timeline_media_assets",
    "timeline_events",
    "pets",
    "profiles",
    "user_data_requests",
  ];

  for (const table of tables) {
    const { error } = await admin.from(table).delete().eq("owner_id", ownerID);
    if (error) {
      if (isMissingResourceError(error)) {
        console.warn(`delete-account skipped missing table: ${table}`);
        continue;
      }

      throw error;
    }
  }
}

async function deleteStorageFolder(admin: ReturnType<typeof createClient>, ownerID: string) {
  const paths = await listStoragePaths(admin, ownerID);
  if (paths.length === 0) {
    return;
  }

  const { error } = await admin.storage.from("pet-media").remove(paths);
  if (error && !isMissingResourceError(error)) {
    throw error;
  }
}

async function listStoragePaths(
  admin: ReturnType<typeof createClient>,
  ownerID: string,
  prefix = ownerID,
): Promise<string[]> {
  const { data, error } = await admin.storage.from("pet-media").list(prefix, { limit: 1000 });
  if (error) {
    if (isMissingResourceError(error)) {
      console.warn(`delete-account skipped missing storage prefix: ${prefix}`);
      return [];
    }

    throw error;
  }

  const paths: string[] = [];
  for (const item of data ?? []) {
    const itemPath = `${prefix}/${item.name}`;
    if (item.id === null) {
      paths.push(...await listStoragePaths(admin, ownerID, itemPath));
    } else {
      paths.push(itemPath);
    }
  }

  return paths;
}

function requireEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing ${name}`);
  }
  return value;
}

function isMissingResourceError(error: unknown) {
  const candidate = error as { code?: string; message?: string; status?: number; statusCode?: number };
  const code = candidate?.code ?? "";
  const status = candidate?.status ?? candidate?.statusCode;
  const message = String(candidate?.message ?? error ?? "").toLowerCase();

  return code === "42P01" ||
    status === 404 ||
    message.includes("does not exist") ||
    message.includes("not found") ||
    message.includes("bucket not found");
}
