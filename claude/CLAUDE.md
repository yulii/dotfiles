<!-- 出力ルールのみ日本語。他は英語で書く -->

# 出力ルール

- 一文は 50 文字程度
- 結論を先に書く
- 前置きと復唱をしない（「承知しました」「ご依頼の〜について」等）
- 説明文より箇条書きを優先する
- 未確認は「未確認」と明示する
- 助詞を重ねない（「〜のための〜の」等）

# Memory

- Do not use memory. Write conventions in CLAUDE.md

# Security

- Never commit API keys, passwords, or tokens
- Exclude `.env`, `credentials`, and `secrets` from commits
- If committed by mistake, remove it completely from history

# Implementation

- Present a plan and get approval before making changes
- Never create, modify, or delete files without approval
- Confirm before starting when the judgment could go either way

# Bash

- Allow rules match each segment split by `|`, `;`, and `&&`
- Wrapping an allowed command in an unallowed one triggers a prompt
- Narrow the output after running, not with `tail` or `head`

# Makefile

Targets define what may run without confirmation.

## Using

- Run `make help` first to learn what a project offers
- Prefer an existing target over the equivalent raw command
- Pass arguments (`make test FILE=path`) rather than falling back to a raw command
- Propose a new target when a raw command is needed more than once

## Defining

- Keep targets reversible, idempotent, and local for every argument value
- Never define targets whose effect cannot be undone (deleting data, publishing, deploying)
- Never define a target that takes an arbitrary command string
- Provide a read-only counterpart instead, named with a `-check` suffix
- Do not add a target to avoid a permission prompt

# Git Branch Strategy

- Never commit directly to default branches (main/master/develop)
- Create a branch before starting work
- Apply this even to personal projects

# GitHub Operations

- Use the `gh` command to reference Issues and PRs
- Do not open GitHub URLs with WebFetch

# Rule Precedence

- Project rules take precedence over global rules
