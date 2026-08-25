import assert from "node:assert/strict";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("https://echopet-auth-confirmed.example/", {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("renders the Echo Pet email verification success page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /Echo Pet Email Verified/);
  assert.match(html, /邮箱验证成功/);
  assert.match(html, /你的 Echo Pet 账号邮箱已经完成验证/);
  assert.match(html, /Your email is confirmed/);
  assert.match(html, /Return to the Echo Pet app/);
  assert.doesNotMatch(html, /Your site is taking shape|Building your site|codex-preview/i);
});
