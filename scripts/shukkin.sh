#!/bin/bash
# 会社マルチエージェントシステム 出勤スクリプト
# Usage: ./scripts/shukkin.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "  会社マルチエージェントシステム"
echo "  出勤スクリプト"
echo "========================================"
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# tmuxがインストールされているか確認
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}エラー: tmux がインストールされていません${NC}"
    exit 1
fi

# claude がインストールされているか確認
if ! command -v claude &> /dev/null; then
    echo -e "${RED}エラー: claude CLI がインストールされていません${NC}"
    exit 1
fi

# 既存のセッションをチェック
check_session() {
    local session_name=$1
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}警告: セッション '$session_name' は既に存在します${NC}"
        read -p "既存のセッションを終了して再作成しますか? (y/N): " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$session_name"
            echo -e "${GREEN}セッション '$session_name' を終了しました${NC}"
        else
            echo "既存のセッションを維持します"
            return 1
        fi
    fi
    return 0
}

# セッション作成関数
create_session() {
    local session_name=$1
    local -n panes=$2  # 配列を参照渡し

    echo -e "${BLUE}セッション '$session_name' を作成中...${NC}"

    # セッション作成（最初のペインも同時に作成される）
    tmux new-session -d -s "$session_name" -c "$PROJECT_DIR"

    # 残りの3ペインを作成
    tmux split-window -t "$session_name:0" -h -c "$PROJECT_DIR"
    tmux split-window -t "$session_name:0.0" -v -c "$PROJECT_DIR"
    tmux split-window -t "$session_name:0.1" -v -c "$PROJECT_DIR"

    # レイアウトを整える（2x2グリッド）
    tmux select-layout -t "$session_name:0" tiled

    echo -e "${GREEN}セッション '$session_name' を作成しました${NC}"
}

# Claude起動関数
start_claude() {
    local session=$1
    local pane=$2
    local instruction_file=$3
    local role_name=$4

    echo -e "  ${BLUE}$role_name を起動中...${NC}"

    # Claude Code を起動
    tmux send-keys -t "$session:0.$pane" "cd $PROJECT_DIR && claude --instruction-file $instruction_file" Enter

    sleep 1
}

# メイン処理
echo ""
echo -e "${BLUE}=== 部長セッション (company) ===${NC}"

if check_session "company"; then
    create_session "company" dummy

    echo "部長陣を起動します..."
    start_claude "company" 0 "instructions/bucho_kikaku.md" "企画部長"
    start_claude "company" 1 "instructions/bucho_kaihatsu.md" "開発部長"
    start_claude "company" 2 "instructions/bucho_design.md" "デザイン部長"
    start_claude "company" 3 "instructions/bucho_qa.md" "QA部長"
fi

echo ""
echo -e "${BLUE}=== メンバーセッション (members) ===${NC}"

if check_session "members"; then
    create_session "members" dummy

    echo "メンバー陣を起動します..."
    start_claude "members" 0 "instructions/member_kikaku.md" "企画メンバー"
    start_claude "members" 1 "instructions/member_kaihatsu.md" "開発メンバー"
    start_claude "members" 2 "instructions/member_design.md" "デザインメンバー"
    start_claude "members" 3 "instructions/member_qa.md" "QAメンバー"
fi

echo ""
echo "========================================"
echo -e "${GREEN}全員の出勤が完了しました${NC}"
echo "========================================"
echo ""
echo "セッション一覧:"
echo "  - company  : 部長セッション (tmux attach -t company)"
echo "  - members  : メンバーセッション (tmux attach -t members)"
echo ""
echo "ペイン構成:"
echo "  ┌─────────┬─────────┐"
echo "  │  0.0    │  0.1    │"
echo "  │(企画)   │(開発)   │"
echo "  ├─────────┼─────────┤"
echo "  │  0.2    │  0.3    │"
echo "  │(デザイン)│(QA)     │"
echo "  └─────────┴─────────┘"
echo ""
echo "使い方:"
echo "  1. tmux attach -t company で部長セッションにアタッチ"
echo "  2. queue/president_request.yaml に依頼を記載"
echo "  3. 議長に通知を送信"
echo ""
echo "議長ローテーション (依頼ID % 4):"
echo "  0: 企画部長 (company:0.0)"
echo "  1: 開発部長 (company:0.1)"
echo "  2: デザイン部長 (company:0.2)"
echo "  3: QA部長 (company:0.3)"
echo ""
