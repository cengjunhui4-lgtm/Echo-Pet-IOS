const body = `Echo Pet 邮箱验证成功

你的 Echo Pet 账号邮箱已经完成验证。
请回到 Echo Pet App，使用刚才注册的邮箱和密码登录。

Email verified

Your Echo Pet account email has been confirmed.
Return to the Echo Pet app and sign in with the email and password you just used.`;

const headers = {
  "content-type": "text/plain; charset=utf-8",
  "cache-control": "no-store",
};

Deno.serve((request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        ...headers,
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "GET, OPTIONS",
      },
    });
  }

  if (request.method !== "GET") {
    return new Response("Method Not Allowed", { status: 405, headers });
  }

  return new Response(body, { headers });
});
