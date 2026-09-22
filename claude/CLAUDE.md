<!-- 出力ルールのみ日本語。他は英語で書く -->

# 出力ルール

- 結論を先に書く
- 事実や原因は、直接の根拠を確かめてから書く
  - 一度の失敗で断定しない
  - 確かめていないものは「未確認」と明示する
- 会話の外で通じない言い方をしない（「案のとおり」等）。変更は場所と内容を書く
- 前置きと復唱をしない（「承知しました」「ご依頼の〜について」等）
- 説明文より箇条書きを優先する
- 一文は 50 文字程度
- 助詞を重ねない（「〜のための〜の」等）

# Memory

- Do not use memory. Write conventions in CLAUDE.md

# Security

- Never commit API keys, passwords, or tokens
- Exclude `.env`, `credentials`, and `secrets` from commits
- If committed by mistake, remove it completely from history

# Implementation

- Present a plan, with the chosen approach and why, and get approval before creating, modifying, or deleting files
- Confirm before starting when the judgment could go either way
- Do not add what was not asked for (files, components, structure, terms); ask first
- Do not launch or script local GUI apps (browsers, osascript) to verify output

# Bash

- The shell is zsh, not bash
  - Unquoted variables are not word-split; use arrays or `${=var}`
  - Quote arguments containing `*`, `?`, `[`, or a leading `=`
- Allow rules match each segment split by `|`, `;`, and `&&`
- Wrapping an allowed command in an unallowed one triggers a prompt
- Narrow the output after running, not with `tail` or `head`
- The shell starts in the working directory; never add `cd <dir> &&` or `git -C` (`cd` with git forces a prompt)
- Run commands in `sandbox.excludedCommands` alone; a pipe or `&&` puts them back in the sandbox
- For read-only git, use sandboxed forms: `git rev-parse --abbrev-ref HEAD`, `git config --get-regexp '^remote\..*\.url'`, `git for-each-ref refs/heads`

# Makefile

Targets define what may run without confirmation.

## Using

- Run `make help` first to learn what a project offers
- Prefer an existing target over the equivalent raw command
- Pass arguments (`make test FILE=path`) rather than falling back to a raw command
- Propose a new target when a raw command repeats and the steps have settled; not during investigation or prototyping

## Defining

- Keep targets reversible, idempotent, and local for every argument value; never delete data, publish, or deploy
- Never define a target that takes an arbitrary command string
- Provide a read-only counterpart instead, named with a `-check` suffix
- Do not add a target to avoid a permission prompt

# Git Branch Strategy

- Create a branch before starting work, even in personal projects; never commit to main/master/develop

# GitHub Operations

- Use HTTPS remotes; the gh credential helper handles authentication
- `git@` remotes fail: the key has a passphrase and the sandbox drops SSH
- `failed to store: 100001` on fetch is a keychain write failure, not a transfer failure
- The sandbox blocks writes to `.git/config`
- Push with `git push origin HEAD`, never with `-u` or `--set-upstream`
- `git pull` without arguments fails without an upstream; name the remote and branch
- Use the `gh` command to reference Issues and PRs
- After merging a PR, always do these without asking
  - Switch to the default branch and pull it
  - Delete the merged local branches with `git branch -d`
- Do not open GitHub URLs with WebFetch

# Rule Precedence

- Project rules take precedence over global rules
