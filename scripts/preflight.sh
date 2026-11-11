#!/usr/bin/env bash
# 开工/交付前预检：仓库卫生 + 路由完整性 + 构建 + 静态检查。
# 用法：scripts/preflight.sh [--no-build]
# 设置 STRICT_PARITY=1 时，残留 Web 图片组件也会被视为失败。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_BUILD=1
[[ "${1:-}" == "--no-build" ]] && RUN_BUILD=0

cd "$ROOT"
errors=0
warnings=0

echo "==> 1/4 仓库卫生"
forbidden="$(git ls-files | grep -E '(^|/)(env\.ets|.*\.(p12|cer|p7b|jks|keystore))$|^(build|\.hvigor|oh_modules)/' || true)"
if [[ -n "$forbidden" ]]; then
  echo "发现不应提交的文件："
  echo "$forbidden"
  errors=$((errors + 1))
else
  echo "OK：未跟踪密钥/签名/构建产物"
fi
if ! grep -q 'entry/src/main/ets/api/env.ets' .gitignore; then
  echo "WARN：.gitignore 未忽略 env.ets"
  warnings=$((warnings + 1))
fi

echo "==> 2/4 路由完整性"
python3 - "$ROOT" <<'PY' || errors=$((errors + 1))
import json
import os
import sys

root = sys.argv[1]
profile = os.path.join(root, 'entry/src/main/resources/base/profile/main_pages.json')
pages_dir = os.path.join(root, 'entry/src/main/ets/pages')

with open(profile, encoding='utf-8') as f:
    routes = json.load(f)['src']

problems = []
for route in routes:
    source = os.path.join(root, 'entry/src/main/ets', route + '.ets')
    if not os.path.exists(source):
        problems.append(f'路由文件不存在: {route}')
        continue
    with open(source, encoding='utf-8') as f:
        if '@Entry' not in f.read():
            problems.append(f'路由页面缺少 @Entry: {route}')

registered = {r.split('/')[-1] for r in routes}
for name in sorted(os.listdir(pages_dir)):
    if not name.endswith('.ets'):
        continue
    stem = name[:-4]
    if stem in registered:
        continue
    with open(os.path.join(pages_dir, name), encoding='utf-8') as f:
        if '@Entry' in f.read():
            problems.append(f'@Entry 页面未注册到 main_pages.json: pages/{name}')

print(f'注册路由 {len(routes)} 个')
if problems:
    print('\n'.join('FAIL：' + p for p in problems))
    sys.exit(1)
print('OK：路由文件与注册表一致')
PY

echo "==> 3/4 Web 图片残留（F3 目标为 0）"
web_refs="$(grep -RIn --include='*.ets' -E 'RemoteImage|WatermarkImage' entry/src/main/ets | grep -v 'components/RemoteImage.ets' | grep -v 'components/WatermarkImage.ets' || true)"
if [[ -n "$web_refs" ]]; then
  echo "WARN：仍有页面使用 Web 图片组件："
  echo "$web_refs" | sed 's/^/  /'
  warnings=$((warnings + 1))
  if [[ "${STRICT_PARITY:-0}" == "1" ]]; then
    errors=$((errors + 1))
  fi
else
  echo "OK：无 Web 图片组件残留"
fi

if [[ "$RUN_BUILD" == "1" ]]; then
  echo "==> 4/4 构建与静态检查"
  "$ROOT/scripts/build.sh"
  "$ROOT/scripts/lint.sh"
else
  echo "==> 4/4 已跳过构建与静态检查（--no-build）"
fi

echo
echo "==> 预检完成：errors=$errors warnings=$warnings"
if [[ "$errors" -gt 0 ]]; then
  exit 1
fi
