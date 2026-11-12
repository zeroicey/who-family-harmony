#!/usr/bin/env bash
# 构建 HarmonyOS debug HAP。
# 可覆盖 DEVECO_HOME 指向其他 DevEco Studio 安装目录。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVECO_HOME="${DEVECO_HOME:-/Applications/DevEco-Studio.app}"
HVIGORW="$DEVECO_HOME/Contents/tools/hvigor/bin/hvigorw"
NODE_BIN="$DEVECO_HOME/Contents/tools/node/bin"
OHPM_BIN="$DEVECO_HOME/Contents/tools/ohpm/bin"

if [[ ! -x "$HVIGORW" ]]; then
  echo "找不到 hvigorw: $HVIGORW" >&2
  echo "请设置 DEVECO_HOME 指向 DevEco Studio 安装目录。" >&2
  exit 2
fi

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO_HOME/Contents/sdk}"
export PATH="$NODE_BIN:$OHPM_BIN:$PATH"

cd "$ROOT"
echo "==> build: $ROOT"
"$HVIGORW" assembleHap --mode module -p product=default -p buildMode=debug --no-daemon

HAP="$ROOT/entry/build/default/outputs/default/entry-default-unsigned.hap"
if [[ -f "$HAP" ]]; then
  echo "==> HAP: $HAP"
else
  echo "构建结束但未找到预期 HAP，请检查输出。" >&2
  exit 1
fi
