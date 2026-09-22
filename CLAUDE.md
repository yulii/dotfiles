# スコープ

このリポジトリの大半はグローバル設定の実体である。

- `init/links` にあるパスはグローバル。編集は全プロジェクトに及ぶ
- ないパスは dotfiles 固有
- 編集前に判定し、グローバルなら影響範囲を先に伝える
- リンクの増減は `init/links` だけを編集する

混同しやすい対。

- `CLAUDE.md`（dotfiles 専用）と `claude/CLAUDE.md`（全プロジェクト共通）
- `.claude/settings.json`（dotfiles 専用）と `claude/settings.json`（全プロジェクト共通）
- `.gitignore`（このリポジトリ）と `.gitignore_global`（全リポジトリ）
- `.git/hooks`（この clone）と `~/.git-templates`（今後 clone する全リポジトリ）
- `test/`（dotfiles 自身のみ）と機械全体の状態

# サンドボックス

次の 7 ファイルは Bash から書けない。編集は Edit ツール。

- `claude/CLAUDE.md`、`claude/settings.json`、`.claude/settings.json`。Claude Code が自分の設定を守るため
- `.gitconfig`、`.zshrc`、`.zprofile`、`.plex`。理由は未確認。リンクの有無とは一致しない

sandbox の中の git がこれらを書き換えようとすると、途中で止まる。止まったら、作業ツリーを書き換えない手順に切り替える。

- `git reset --hard <ref>` ではなく `git reset <ref>`
- 7 ファイル以外の差分は `git checkout -- <path>` で戻す
- 7 ファイルは `git show <ref>:<path>` を読み、Edit で合わせる
- `allowWrite`、`skip-worktree` では解決しない。調査済み

`claude/settings.json` の `sandbox.excludedCommands` に、git と gh のワーキングツリー書き換え系を置いた。除外したコマンドは sandbox の外で走る。

- 除外したコマンドは protected paths も書き換えられる。`git stash push`、`git switch`、単独の `git pull` で確認済み
- 除外は単独で実行したときだけ効く。`git remote add` の `.git/config` 書き込みで確認済み

| 書き方 | 走る場所 |
|---|---|
| `git … 2>&1` | sandbox の外 |
| `git … \| cat` | sandbox の中 |
| `git … && echo` | sandbox の中 |

# コミット

- `git commit` の前に必ず `make test` を実行する
- 失敗が残ったままコミットしない
- グローバル側を変えたら `make test-env` も実行する

# フック

- 自動で動くのは git-secrets のグローバルフックのみ
- 供給元は `.gitconfig` の `init.templatedir`
- `core.hooksPath` は設定しない。グローバルフックが無効になる

# テスト

- git フックでは実行しない。CI も使わない
- リンクしないルート直下のファイルは `test/repo.sh` の `exempt` に追加する
- hook と `secrets.patterns` の判定は `test/cases/*.tsv` の表で確かめる
  - 1 行に `期待値<TAB>入力`。`#` で始まる行はコメント
  - 変えたら、通るべき例と止まるべき例を両方足す
  - 追加した例が、変更前の版で落ちることを確かめる
- `secrets.tsv` は鍵に似た行を持つ。`.gitallowed` で許可している
