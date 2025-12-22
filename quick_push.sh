#!/bin/bash
# クイックGitHubプッシュスクリプト

# 色の定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /home/user/flutter_app

# コミットメッセージを引数から取得、なければデフォルト
MESSAGE="${1:-コードを更新}"

echo -e "${YELLOW}📝 変更をコミット中...${NC}"
git add .
git commit -m "$MESSAGE"

echo -e "${YELLOW}🚀 GitHubにプッシュ中...${NC}"
git push origin main

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ GitHubにアップロード完了!${NC}"
    echo ""
    echo "🔗 https://github.com/YuhiAozora/taxi-education-manager"
else
    echo "❌ プッシュに失敗しました"
fi
