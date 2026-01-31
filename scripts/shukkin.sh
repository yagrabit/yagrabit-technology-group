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

# 最初のウィンドウ番号を取得する関数
get_first_window() {
    local session=$1
    tmux list-windows -t "$session" -F '#{window_index}' | head -1
}

# Claude起動関数
# pane引数が空または"-"の場合はペイン指定を省略（1ペインのセッション用）
start_claude() {
    local session=$1
    local pane=$2
    local instruction_file=$3
    local role_name=$4
    local window=$(get_first_window "$session")
    local target

    if [[ -z "$pane" || "$pane" == "-" ]]; then
        target="$session:$window"
    else
        target="$session:$window.$pane"
    fi

    echo -e "  ${BLUE}$role_name を起動中...${NC}"

    # Claude Code を起動（対話モード）
    tmux send-keys -t "$target" "cd $PROJECT_DIR && claude"
    sleep 0.3
    tmux send-keys -t "$target" Enter

    sleep 2  # Claude起動を待つ

    # 指示書を読ませるコマンドを送信
    tmux send-keys -t "$target" "$instruction_file を読んで役割を理解してください。"
    sleep 0.3
    tmux send-keys -t "$target" Enter

    sleep 1
}

# メイン処理
echo ""
echo -e "${BLUE}=== CEOセッション (ceo) ===${NC}"

if check_session "ceo"; then
    echo -e "${BLUE}セッション 'ceo' を作成中...${NC}"

    # セッション作成（秘書専用、1ペイン）
    tmux new-session -d -s ceo -x 200 -y 50 -c "$PROJECT_DIR"

    echo -e "${GREEN}セッション 'ceo' を作成しました${NC}"

    echo "秘書を起動します..."
    start_claude "ceo" "-" "instructions/hisho.md" "秘書"
fi

echo ""
echo -e "${BLUE}=== 会社セッション (company) ===${NC}"

if check_session "company"; then
    echo -e "${BLUE}セッション 'company' を作成中...${NC}"

    # セッション作成（8ペイン、2×4グリッド）
    # -x -y でサイズを指定（8ペイン分のスペース確保）
    tmux new-session -d -s company -x 300 -y 80 -c "$PROJECT_DIR"

    # 最初のウィンドウ番号を取得
    COMPANY_WINDOW=$(get_first_window "company")
    COMPANY_TARGET="company:$COMPANY_WINDOW"

    # 2x4グリッド作成
    # まず水平に4分割（4列作成）
    tmux split-window -h -t "$COMPANY_TARGET" -c "$PROJECT_DIR"
    tmux split-window -h -t "$COMPANY_TARGET" -c "$PROJECT_DIR"
    tmux split-window -h -t "$COMPANY_TARGET" -c "$PROJECT_DIR"
    tmux select-layout -t "$COMPANY_TARGET" even-horizontal

    # 各ペインを縦に分割（計8ペイン）
    # ペインリストを取得して各ペインを縦分割
    for pane_id in $(tmux list-panes -t "$COMPANY_TARGET" -F '#{pane_id}'); do
        tmux split-window -v -t "$pane_id" -c "$PROJECT_DIR"
    done

    # レイアウトを整える（tiled = 均等配置）
    tmux select-layout -t "$COMPANY_TARGET" tiled

    echo -e "${GREEN}セッション 'company' を作成しました${NC}"

    # ペイン番号のリストを取得（pane-base-indexに依存しない）
    PANES=($(tmux list-panes -t "$COMPANY_TARGET" -F '#{pane_index}'))

    echo "部長陣を起動します..."
    start_claude "company" "${PANES[0]}" "instructions/bucho_kikaku.md" "企画部長"
    start_claude "company" "${PANES[1]}" "instructions/bucho_kaihatsu.md" "開発部長"
    start_claude "company" "${PANES[2]}" "instructions/bucho_design.md" "デザイン部長"
    start_claude "company" "${PANES[3]}" "instructions/bucho_qa.md" "QA部長"

    echo "メンバー陣を起動します..."
    start_claude "company" "${PANES[4]}" "instructions/member_kikaku.md" "企画メンバー"
    start_claude "company" "${PANES[5]}" "instructions/member_kaihatsu.md" "開発メンバー"
    start_claude "company" "${PANES[6]}" "instructions/member_design.md" "デザインメンバー"
    start_claude "company" "${PANES[7]}" "instructions/member_qa.md" "QAメンバー"
fi

echo ""
echo "========================================"
echo -e "${GREEN}全員の出勤が完了しました${NC}"
echo "========================================"
echo ""
echo "セッション一覧:"
echo "  - ceo     : 秘書セッション (tmux attach -t ceo)"
echo "  - company : 会社セッション (tmux attach -t company)"
echo ""
echo "ペイン構成:"
echo ""
echo "  [ceo セッション - 1ペイン]"
echo "  ┌─────────────────────────┐"
echo "  │  0.0 秘書               │"
echo "  └─────────────────────────┘"
echo ""
echo "  [company セッション - 8ペイン (2×4グリッド)]"
echo "  ┌─────────┬─────────┬──────────┬─────────┐"
echo "  │  0.0    │  0.1    │  0.2     │  0.3    │"
echo "  │(企画部長)│(開発部長)│(デザイン │(QA部長) │"
echo "  │         │         │ 部長)    │         │"
echo "  ├─────────┼─────────┼──────────┼─────────┤"
echo "  │  0.4    │  0.5    │  0.6     │  0.7    │"
echo "  │(企画    │(開発    │(デザイン │(QA      │"
echo "  │ メンバー)│ メンバー)│ メンバー)│ メンバー)│"
echo "  └─────────┴─────────┴──────────┴─────────┘"
echo ""
echo "使い方:"
echo "  1. tmux attach -t ceo で秘書セッションにアタッチ"
echo "  2. 秘書に依頼内容を伝える"
echo "  3. 秘書が部長会議を手配し、完了を報告"
echo ""
echo "議長ローテーション (依頼ID % 4):"
echo "  0: 企画部長 (company:0.0)"
echo "  1: 開発部長 (company:0.1)"
echo "  2: デザイン部長 (company:0.2)"
echo "  3: QA部長 (company:0.3)"
echo ""
