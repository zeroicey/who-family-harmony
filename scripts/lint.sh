#!/usr/bin/env bash
# 运行 DevEco CodeLinter（错误级别会导致非零退出）。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVECO_HOME="${DEVECO_HOME:-/Applications/DevEco-Studio.app}"
NODE="$DEVECO_HOME/Contents/tools/node/bin/node"
LINTER="$DEVECO_HOME/Contents/plugins/codelinter/run/index.js"

if [[ ! -x "$NODE" || ! -f "$LINTER" ]]; then
  echo "找不到 CodeLinter 或 Node：$LINTER" >&2
  echo "请设置 DEVECO_HOME 指向 DevEco Studio 安装目录。" >&2
  exit 2
fi

cd "$ROOT"
echo "==> lint: entry/src/main/ets"
exec "$NODE" "$LINTER" -c code-linter.json5 -e error entry/src/main/ets
