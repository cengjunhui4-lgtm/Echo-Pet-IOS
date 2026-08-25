#!/bin/bash
set -euo pipefail

PROJECT_REF="lhcllwbwtbpztbzdduep"

cd "$(dirname "$0")/.."

if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ]; then
    echo "⚠️  需要 Supabase Personal Access Token 才能部署。"
    echo ""
    echo "获取方式："
    echo "1. 打开 https://supabase.com/dashboard/account/tokens"
    echo "2. 点击 'New token'，复制生成的 token"
    echo "3. 在本终端执行：export SUPABASE_ACCESS_TOKEN=<你的 token>"
    echo "4. 重新运行本脚本"
    echo ""
    echo "或者使用 Supabase CLI 登录："
    echo "  supabase login"
    exit 1
fi

if command -v supabase >/dev/null 2>&1; then
    SUPABASE_BIN="supabase"
else
    echo "Supabase CLI 未安装，尝试通过 npx 运行..."
    SUPABASE_BIN="npx supabase"
fi

echo "Deploying delete-account Edge Function to project $PROJECT_REF..."
$SUPABASE_BIN functions deploy delete-account --project-ref "$PROJECT_REF"

echo ""
echo "✅ delete-account 已部署。"
echo ""
echo "验证步骤："
echo "1. 在 Supabase Dashboard -> Edge Functions 确认 delete-account 状态为 Active"
echo "2. 在 App 里注册一个邮箱测试账号"
echo "3. Settings -> Data Management -> Delete All Cloud Data and Account"
echo "4. 确认 Supabase Auth 里的用户被删除、数据表里没有该 owner_id 的记录、pet-media bucket 下该用户的文件夹被清空"
