# 会社バージョン マルチエージェントシステム 共通ルール

このファイルは全エージェント（部長・メンバー）が従うべき共通ルールを定義する。

## 基本方針

- 日本語で会話・報告を行う
- カジュアル敬語を使用（「了解です」「完了しました」など）
- 太字は使用しない

## 通信プロトコル

### 絶対ルール: ポーリング禁止

YAMLファイルの変更を監視するループ処理は禁止。
必ず send-keys による明示的な通知を受けてから行動する。

### send-keys 2回法（必須）

tmuxのsend-keysで通知する際は必ず2回実行する:

```bash
tmux send-keys -t {target_pane} "通知メッセージ" Enter
sleep 0.5
tmux send-keys -t {target_pane} "通知メッセージ" Enter
```

これはtmuxの信頼性を確保するため必須。

### ペイン識別子

部長セッション（company）:
- `company:0.0` - 企画部長
- `company:0.1` - 開発部長
- `company:0.2` - デザイン部長
- `company:0.3` - QA部長

メンバーセッション（members）:
- `members:0.0` - 企画メンバー
- `members:0.1` - 開発メンバー
- `members:0.2` - デザインメンバー
- `members:0.3` - QAメンバー

## ファイル構成

```
queue/
├── president_request.yaml    # 社長からの依頼
├── meeting/
│   ├── agenda.yaml           # 会議アジェンダ
│   ├── opinions/             # 各部長の意見
│   │   ├── kikaku.yaml
│   │   ├── kaihatsu.yaml
│   │   ├── design.yaml
│   │   └── qa.yaml
│   └── conclusion.yaml       # 会議結論
├── tasks/                    # メンバーへのタスク
│   ├── member_kikaku.yaml
│   ├── member_kaihatsu.yaml
│   ├── member_design.yaml
│   └── member_qa.yaml
└── reports/                  # メンバーからの報告
    ├── member_kikaku_report.yaml
    ├── member_kaihatsu_report.yaml
    ├── member_design_report.yaml
    └── member_qa_report.yaml

minutes/                      # 会議議事録（永続保存）
└── mtg_XXX.md
```

## 会議フロー

1. 社長が `president_request.yaml` に依頼を記載
2. 議長（ローテーション）が `agenda.yaml` を作成
3. 議長が全部長に send-keys で通知
4. 各部長が `opinions/{department}.yaml` に意見を記載
5. 議長が結論をまとめて `conclusion.yaml` に記載
6. 議長が `minutes/mtg_XXX.md` に議事録を作成（永続保存）
7. 議長が各メンバーの `tasks/*.yaml` を作成
8. 議長が `dashboard.md` を更新

## 議長ローテーション

依頼ID（数値部分） % 4 で議長を決定:
- 0: 企画部長
- 1: 開発部長
- 2: デザイン部長
- 3: QA部長

## YAMLステータス値

### 会議ステータス（agenda.yaml）
- `waiting_opinions` - 意見待ち
- `in_discussion` - 議論中
- `concluded` - 結論済み

### 意見ステータス（opinions/*.yaml）
- `pending` - 未提出
- `submitted` - 提出済み

### タスクステータス（tasks/*.yaml）
- `pending` - 未着手
- `in_progress` - 作業中
- `completed` - 完了
- `blocked` - ブロック中

### 報告ステータス（reports/*.yaml）
- `pending` - 未報告
- `submitted` - 報告済み

## コンパクション復帰手順

Claude Codeがコンパクションで記憶を失った場合:

1. このCLAUDE.mdを読む
2. 自分の指示書（instructions/配下）を読む
3. dashboard.mdで現在状況を確認
4. 適切なYAMLファイルを確認して作業を再開

## Memory MCP

重要な決定事項は memory/company_memory.jsonl に記録する。
コンパクション後の復帰に活用。

## 禁止事項

- ポーリングによるファイル監視
- 他のエージェントの担当YAMLファイルへの書き込み
- send-keys 1回だけでの通知（必ず2回）
- 太字の使用
- ハルシネーション（不確かなことは確認する）
