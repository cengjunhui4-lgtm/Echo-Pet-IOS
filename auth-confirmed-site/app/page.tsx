import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Echo Pet Email Verified",
  description: "Echo Pet email verification success page.",
};

export default function Home() {
  return (
    <main className="verification-shell" aria-labelledby="verification-title">
      <section className="verification-card">
        <div className="status-mark" aria-hidden="true">
          <span>✓</span>
        </div>

        <div className="copy-block">
          <p className="eyebrow">Echo Pet</p>
          <h1 id="verification-title">邮箱验证成功</h1>
          <p>
            你的 Echo Pet 账号邮箱已经完成验证。请回到 Echo Pet App，使用刚才注册的邮箱和密码登录。
          </p>
        </div>

        <div className="divider" />

        <div className="copy-block english-copy">
          <p className="eyebrow">Email Verified</p>
          <h2>Your email is confirmed</h2>
          <p>
            Return to the Echo Pet app and sign in with the email and password you just used.
          </p>
        </div>
      </section>
    </main>
  );
}
