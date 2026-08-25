import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

type CompanionRequest = {
  petId?: string;
  message?: string;
  languageCode?: string;
  relationship?: {
    userRole?: string;
    petRole?: string;
  };
  settings?: {
    memoryEnabled?: boolean;
    tone?: string;
  };
};

type DeepSeekMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

const deepSeekProvider = "deepseek";
const defaultModel = "deepseek-v4-flash";

serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: { code: "method_not_allowed", message: "Use POST." } }, 405);
  }

  try {
    const authorization = request.headers.get("Authorization") ?? "";
    if (!authorization.startsWith("Bearer ")) {
      return jsonResponse({ error: { code: "unauthorized", message: "Missing Supabase bearer token." } }, 401);
    }

    const supabaseUrl = requireEnv("SUPABASE_URL");
    const anonKey = requireEnv("SUPABASE_ANON_KEY");
    const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
    const deepSeekKey = requireEnv("DEEPSEEK_API_KEY");
    const deepSeekBaseURL = Deno.env.get("DEEPSEEK_BASE_URL") ?? "https://api.deepseek.com";
    const deepSeekModel = Deno.env.get("DEEPSEEK_MODEL") ?? defaultModel;

    const body = await readRequestBody(request);
    const petId = body.petId?.trim();
    const userMessage = body.message?.trim();
    const languageCode = body.languageCode ?? "zh_Hans";

    if (!petId || !userMessage) {
      return jsonResponse({ error: { code: "bad_request", message: "petId and message are required." } }, 400);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data: authData, error: authError } = await userClient.auth.getUser();

    if (authError || !authData.user) {
      return jsonResponse({ error: { code: "unauthorized", message: "Invalid Supabase session." } }, 401);
    }

    const userId = authData.user.id;
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data: pet, error: petError } = await admin
      .from("pets")
      .select("*")
      .eq("id", petId)
      .eq("owner_id", userId)
      .is("deleted_at", null)
      .single();

    if (petError || !pet) {
      return jsonResponse({ error: { code: "not_found", message: "Pet was not found for this user." } }, 404);
    }

    const memoryEnabled = body.settings?.memoryEnabled !== false && pet.ai_memory_enabled !== false;
    const context = memoryEnabled
      ? await loadCompanionContext(admin, userId, petId)
      : { lifeprint: null, timelineEvents: [], dailyTasks: [], chatHistory: [] };

    const messages = buildDeepSeekMessages({
      languageCode,
      userMessage,
      relationship: body.relationship,
      pet,
      context,
    });

    const deepSeekReply = await requestDeepSeek({
      baseURL: deepSeekBaseURL,
      apiKey: deepSeekKey,
      model: deepSeekModel,
      messages,
    });
    const reply = appendDisclosure(deepSeekReply, languageCode);
    const generatedAt = new Date().toISOString();
    const sourceMemoryIds = context.timelineEvents.map((event) => event.id).slice(0, 6);
    const sourceTaskIds = context.dailyTasks.map((task) => task.id).slice(0, 6);

    await admin.from("companion_messages").insert({
      pet_id: petId,
      owner_id: userId,
      role: "user",
      content: userMessage,
      is_ai_generated: false,
      request_context: { languageCode, relationship: body.relationship ?? null },
    });

    const { data: assistantMessage } = await admin
      .from("companion_messages")
      .insert({
        pet_id: petId,
        owner_id: userId,
        role: "assistant",
        content: reply,
        is_ai_generated: true,
        source_timeline_event_ids: sourceMemoryIds,
        source_daily_task_ids: sourceTaskIds,
        source_lifeprint_id: context.lifeprint?.id ?? null,
        request_context: { memoryEnabled, languageCode },
        model_version: `${deepSeekModel}-deepseek-v1`,
        provider: deepSeekProvider,
        mode: "deepseek",
      })
      .select("id")
      .single();

    return jsonResponse({
      messageId: assistantMessage?.id ?? crypto.randomUUID(),
      reply,
      isAiGenerated: true,
      sourceMemoryIds,
      modelVersion: `${deepSeekModel}-deepseek-v1`,
      provider: deepSeekProvider,
      mode: "deepseek",
      generatedAt,
      petId,
    });
  } catch (error) {
    console.error("companion-chat failed", error);
    return jsonResponse({
      error: {
        code: "companion_chat_failed",
        message: "Companion AI is temporarily unavailable.",
      },
    }, 500);
  }
});

async function readRequestBody(request: Request): Promise<CompanionRequest> {
  try {
    return await request.json() as CompanionRequest;
  } catch {
    return {};
  }
}

async function loadCompanionContext(
  admin: ReturnType<typeof createClient>,
  userId: string,
  petId: string,
) {
  const [lifeprintResult, timelineResult, tasksResult, historyResult] = await Promise.all([
    admin
      .from("lifeprints")
      .select("id, summary, personality_traits, favorite_things, habits, relationship_patterns, generated_at")
      .eq("pet_id", petId)
      .eq("owner_id", userId)
      .eq("is_current", true)
      .order("generated_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    admin
      .from("timeline_events")
      .select("id, title, story, happened_at, mood, emotion_tags, behavior_tags, importance, ai_summary")
      .eq("pet_id", petId)
      .eq("owner_id", userId)
      .order("happened_at", { ascending: false })
      .limit(12),
    admin
      .from("daily_tasks")
      .select("id, title, note, due_on, due_at, is_completed, template_key, mood_after, importance")
      .eq("pet_id", petId)
      .eq("owner_id", userId)
      .order("due_on", { ascending: false })
      .limit(12),
    admin
      .from("companion_messages")
      .select("id, role, content, created_at")
      .eq("pet_id", petId)
      .eq("owner_id", userId)
      .order("created_at", { ascending: false })
      .limit(12),
  ]);

  return {
    lifeprint: lifeprintResult.data,
    timelineEvents: timelineResult.data ?? [],
    dailyTasks: tasksResult.data ?? [],
    chatHistory: (historyResult.data ?? []).reverse(),
  };
}

function buildDeepSeekMessages(input: {
  languageCode: string;
  userMessage: string;
  relationship?: CompanionRequest["relationship"];
  pet: Record<string, unknown>;
  context: {
    lifeprint: unknown;
    timelineEvents: unknown[];
    dailyTasks: unknown[];
    chatHistory: unknown[];
  };
}): DeepSeekMessage[] {
  const isChinese = input.languageCode.toLowerCase().startsWith("zh");
  const disclosure = isChinese
    ? "（本消息由 AI 基于宠物记忆生成）"
    : "(This message was generated by AI based on pet memories)";

  const systemPrompt = isChinese
    ? [
      "你是 Echo Pet 的 Companion AI。",
      "你要基于 Supabase 中保存的宠物资料、LifePrint、Timeline、每日陪伴任务和近期聊天历史，用温柔陪伴型语气回应。",
      "你可以采用宠物第一视角，但不能声称宠物真实复活，不能编造没有出现在上下文里的重要经历。",
      "如果上下文不足，要温柔地承认不确定，并邀请用户继续记录。",
      `不要自行添加结尾 AI 提示，服务端会统一追加：${disclosure}`,
    ].join("")
    : [
      "You are Echo Pet's Companion AI.",
      "Reply with a gentle companion tone based on the saved pet profile, LifePrint, Timeline, daily care tasks, and recent chat history.",
      "You may use a pet-like first-person voice, but must never claim the pet has truly been resurrected and must not invent major experiences absent from context.",
      "If context is limited, gently acknowledge uncertainty and invite the user to keep recording.",
      `Do not add the final AI disclosure yourself; the server will append: ${disclosure}`,
    ].join(" ");

  const memoryPayload = {
    userMessage: input.userMessage,
    relationship: input.relationship ?? null,
    pet: input.pet,
    lifeprint: input.context.lifeprint,
    timelineEvents: input.context.timelineEvents,
    dailyTasks: input.context.dailyTasks,
    recentChatHistory: input.context.chatHistory,
  };

  return [
    { role: "system", content: systemPrompt },
    {
      role: "user",
      content: `${isChinese ? "请基于下面 JSON 中的真实宠物记忆生成一条回复：" : "Generate one reply based on the real pet memory JSON below:"}\n${
        JSON.stringify(memoryPayload, null, 2)
      }`,
    },
  ];
}

async function requestDeepSeek(input: {
  baseURL: string;
  apiKey: string;
  model: string;
  messages: DeepSeekMessage[];
}): Promise<string> {
  const response = await fetch(`${input.baseURL.replace(/\/$/, "")}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${input.apiKey}`,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify({
      model: input.model,
      messages: input.messages,
      temperature: 0.7,
      max_tokens: 700,
      thinking: { type: "disabled" },
      stream: false,
    }),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`DeepSeek HTTP ${response.status}: ${details.slice(0, 500)}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;

  if (typeof reply !== "string" || reply.trim().length === 0) {
    throw new Error("DeepSeek response did not contain choices[0].message.content.");
  }

  return reply.trim();
}

function appendDisclosure(reply: string, languageCode: string): string {
  const disclosure = languageCode.toLowerCase().startsWith("zh")
    ? "（本消息由 AI 基于宠物记忆生成）"
    : "(This message was generated by AI based on pet memories)";

  if (reply.includes(disclosure)) {
    return reply;
  }

  return `${reply}\n${disclosure}`;
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}
