# Echo Pet Legal Pages (Privacy Policy & Terms of Use)

这两个 HTML 文件用于 App Store Connect 的 **Privacy Policy URL** 和 **Terms of Use URL** 字段，也可以放在 App 内作为外链打开。

## 推荐托管方式：GitHub Pages

本地已准备好可直接 push 的仓库：

```
/Users/zizy/WorkBuddy/2026-08-10-14-50-39/echopet-legal
```

### 操作步骤

1. 在 GitHub 上新建一个 **public** 仓库，命名为 `echopet-legal`。
2. 执行下面的命令把本地仓库 push 上去（把 `<your-username>` 换成你的 GitHub 用户名）：

```bash
cd "/Users/zizy/WorkBuddy/2026-08-10-14-50-39/echopet-legal"
git remote add origin https://github.com/<your-username>/echopet-legal.git
git branch -M main
git push -u origin main
```

3. 打开 GitHub 仓库页面 → **Settings → Pages**。
4. **Source** 选择 **Deploy from a branch**，分支选 `main` / `/(root)`，保存。
5. 等 1–2 分钟，页面生效后 URL 为：

- **Privacy Policy URL**: `https://<your-username>.github.io/echopet-legal/privacy-policy.html`
- **Terms of Use URL**: `https://<your-username>.github.io/echopet-legal/terms-of-use.html`

把这两个 URL 填到 App Store Connect 的对应字段即可。

## 其他托管方式

也可以把 `privacy-policy.html` 和 `terms-of-use.html` 上传到 Cloudflare Pages、Vercel、Netlify 或自有服务器，只要是 HTTPS 公开可访问即可。

## 更新内容

如果后续修改了 `docs/app-store/privacy-policy.md` 或 `terms-of-use.md`，重新运行：

```bash
python3 generate-legal-html.py
```

然后把生成的新 HTML 文件复制到 `echopet-legal` 仓库，提交并 push。
