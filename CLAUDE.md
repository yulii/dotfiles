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
