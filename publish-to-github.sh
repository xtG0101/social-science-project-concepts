#!/usr/bin/env bash
# 在本地终端运行：推送 GitHub + 开启 Pages +（可选）邀请老师为协作者
#
# 用法：
#   ./publish-to-github.sh
#   TEACHER_GITHUB=老师用户名 ./publish-to-github.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
REPO_NAME="social-science-project-concepts"
OWNER="xtG0101"
TEACHER_GITHUB="${TEACHER_GITHUB:-}"

if [ ! -d .git ]; then
  git init
  git add .
  git commit -m "Add concept document for two social science interactive projects."
fi
git branch -M main 2>/dev/null || true

if ! command -v gh >/dev/null 2>&1; then
  echo "请先安装 GitHub CLI: brew install gh"
  echo "然后登录: gh auth login"
  exit 1
fi

gh auth status

if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "$OWNER/$REPO_NAME" --public --source=. --remote=origin --push
else
  git push -u origin main
fi

gh api -X POST "repos/$OWNER/$REPO_NAME/pages" \
  -f build_type=legacy \
  -f source='{"branch":"main","path":"/"}' 2>/dev/null || true

if [ -n "$TEACHER_GITHUB" ]; then
  echo ""
  echo "正在邀请协作者: $TEACHER_GITHUB ..."
  gh api -X PUT "repos/$OWNER/$REPO_NAME/collaborators/$TEACHER_GITHUB" \
    -f permission=push 2>/dev/null || \
  gh api -X PUT "repos/$OWNER/$REPO_NAME/collaborators/$TEACHER_GITHUB" \
    -f permission=read 2>/dev/null || \
  echo "⚠️  邀请失败，请手动在网页添加（见下方说明）"
fi

echo ""
echo "════════════════════════════════════════"
echo "✅ 推送完成！发给老师的链接："
echo ""
echo "📁 仓库（代码）:"
echo "   https://github.com/$OWNER/$REPO_NAME"
echo ""
echo "🌐 在线预览（概念文档）:"
echo "   https://$OWNER.github.io/$REPO_NAME/"
echo "   （Pages 首次启用可能需要 2–5 分钟）"
echo ""
echo "👥 若老师需要「共创 / 编辑」权限："
echo "   1. 打开 https://github.com/$OWNER/$REPO_NAME/settings/access"
echo "   2. 点击 Add people → 输入老师的 GitHub 用户名"
echo "   3. 权限选 Read（只读）或 Write（可改）"
echo "   4. 老师邮箱会收到邀请，接受后即可访问"
echo ""
echo "   或用命令邀请（把 TEACHER 换成老师用户名）："
echo "   TEACHER_GITHUB=TEACHER ./publish-to-github.sh"
echo "════════════════════════════════════════"
