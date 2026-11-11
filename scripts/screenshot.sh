#!/usr/bin/env bash
# 从已连接设备/模拟器截图到 docs/acceptance/screenshots/。
# 用法：scripts/screenshot.sh <page>-<state>
# 示例：scripts/screenshot.sh community-list-default
# 多设备时可用 HDC_TARGET 指定：HDC_TARGET=xxx scripts/screenshot.sh ...
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVECO_HOME="${DEVECO_HOME:-/Applications/DevEco-Studio.app}"
HDC="$DEVECO_HOME/Contents/sdk/default/openharmony/toolchains/hdc"
OUT_DIR="${OUT_DIR:-$ROOT/docs/acceptance/screenshots}"
NAME="${1:-screen-$(date +%Y%m%d-%H%M%S)}"

if [[ ! -x "$HDC" ]]; then
  echo "找不到 hdc: $HDC" >&2
  echo "请确认 DevEco SDK 已安装，或手动用 DevEco Studio 截图。" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"
REMOTE="/data/local/tmp/hcyj-${NAME}.jpeg"

echo "==> 设备列表"
"$HDC" list targets || true

if [[ -n "${HDC_TARGET:-}" ]]; then
  "$HDC" -t "$HDC_TARGET" shell snapshot_display -f "$REMOTE" >/dev/null
  "$HDC" -t "$HDC_TARGET" file recv "$REMOTE" "$OUT_DIR/${NAME}.jpeg" >/dev/null
  "$HDC" -t "$HDC_TARGET" shell rm -f "$REMOTE" >/dev/null 2>&1 || true
else
  "$HDC" shell snapshot_display -f "$REMOTE" >/dev/null
  "$HDC" file recv "$REMOTE" "$OUT_DIR/${NAME}.jpeg" >/dev/null
  "$HDC" shell rm -f "$REMOTE" >/dev/null 2>&1 || true
fi

if command -v sips >/dev/null 2>&1; then
  sips -s format png "$OUT_DIR/${NAME}.jpeg" --out "$OUT_DIR/${NAME}.png" >/dev/null 2>&1
  rm -f "$OUT_DIR/${NAME}.jpeg"
fi

echo "==> 截图：$OUT_DIR/${NAME}.png"
