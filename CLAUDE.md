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

`claude/CLAUDE.md`、`claude/settings.json`、`.claude/settings.json` は Bash から書けない。Claude Code が自分の設定を守るため。編集は Edit ツール。

git がこの 3 ファイルを書き換えようとすると途中で止まる。作業ツリーを書き換えない手順に置き換える。

- `git reset --hard <ref>` ではなく `git reset <ref>`
- 3 ファイル以外の差分は `git checkout -- <path>` で戻す
- 3 ファイルは `git show <ref>:<path>` を読み、Edit で合わせる
- `allowWrite`、`skip-worktree` では解決しない。調査済み

`excludedCommands` は効くが、このリポジトリでは自己無効化する。`claude/settings.json` の `sandbox` に git と gh のワーキングツリー書き換え系を置いた。

- 除外したコマンドは protected paths も書き換えられる。`git stash push` で確認済み
- `"git pull *"` は `git pull origin main` にマッチする。書式は確認済み
- ただし設定の置き場所が、git の書き換え対象そのもの
- `claude/settings.json` を別の版に戻す操作は、その時点で除外設定を消す
- 続くコマンドはサンドボックス内で走り、`unable to unlink old` で止まる
- `git stash push` は通り `git stash pop` が落ちた。この非対称がその証拠
- よって上の手順は引き続き必要。`excludedCommands` は他リポジトリ向けの保険

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
