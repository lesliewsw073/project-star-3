---
event_id: story_visit_npc_shopkeeper_01_enter_01
title: 进店招呼·01
arc_type: flavor_repeat
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: false
cooldown_days: 0
dialogue_pool: shop_enter
pool_variant: 01
affection_settlement: none
required_flags:
  shopkeeper_intro_done: true
sets_flags: {}
godot_resource: data/story_events/daily/npcs/npc_shopkeeper_01/enter/shop_enter_01.tres
---

> **池**：`shop_enter` · 打开商店 UI 时随机 01～03

### [Scene: 老欧的铺子 · 柜台 · 白天]

*(铜铃余音未散。几种香水与那丝硫磺气，照旧叠在暖光里。)*

**npc_shopkeeper_01**: "欢迎，{player_address}。今日是为艺人备礼，还是您自己要用？"

**protagonist**: "先看看。"

**npc_shopkeeper_01**: "请便。高处的货，喊我一声便是——我不喜客人踮脚。"
