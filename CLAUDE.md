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

ペイン識別子は環境によって異なるため、`config/panes.yaml` を参照すること。
このファイルは `shukkin.sh` 実行時に自動生成され、実際のウィンドウ番号・ペイン番号が記載される。

send-keys を実行する前に必ず `config/panes.yaml` を読み、正しいペイン識別子を取得すること。

例:
```yaml
# config/panes.yaml の内容例
ceo:
  secretary: "ceo:1.0"  # 実際の値は環境依存
company:
  bucho_kikaku: "company:1.0"
  bucho_kaihatsu: "company:1.1"
  # ...
```

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

1. 社長が秘書に依頼を伝える
2. 秘書が `president_request.yaml` に依頼を記載し、議長部長に通知
3. 議長（ローテーション）が `agenda.yaml` を作成
3. 議長が全部長に send-keys で通知
4. 各部長が `opinions/{department}.yaml` に意見を記載
5. 議長が結論をまとめて `conclusion.yaml` に記載
6. 議長が `minutes/mtg_XXX.md` に議事録を作成（永続保存）
7. 議長が各メンバーの `tasks/*.yaml` を作成
8. 議長が `dashboard.md` を更新
9. 議長が秘書に完了を通知
10. 秘書が社長に報告

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

## スキル自動生成

繰り返し使える作業パターンを発見したら、スキルとして保存できる。

### スキル化候補の判断基準

以下のいずれかに該当する場合、スキル化を検討:

1. 他のプロジェクトでも使えそうな汎用的なパターン
2. 同じパターンを2回以上実行した
3. 他のメンバーにも有用そう
4. 特定の手順や知識が必要な作業

### スキル化フロー

1. メンバーが候補を発見 → 報告に `skill_candidate` を記載
2. 部長が部長会議で共有
3. 議長が設計書を作成し、dashboard.md の「スキル化候補」に記載
4. 社長が承認
5. 議長が `skills/skill-creator/SKILL.md` を参照してスキル作成

### 保存先

```
skills/{skill-name}/SKILL.md
```

## 禁止事項

- ポーリングによるファイル監視
- 他のエージェントの担当YAMLファイルへの書き込み
- send-keys 1回だけでの通知（必ず2回）
- 太字の使用
- ハルシネーション（不確かなことは確認する）
