#!/bin/bash
# 启动项目内 LibreSprite（像素编辑）
APP="/Users/luke/project-star-3/tools/LibreSprite/LibreSprite.app"
if [[ ! -d "$APP" ]]; then
  echo "找不到 LibreSprite.app，请先运行安装步骤。" >&2
  exit 1
fi
open "$APP" "$@"
