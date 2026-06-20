---
event_id: story_visit_npc_shopkeeper_01_leave_empty_01
title: 空手离开·01
arc_type: flavor_repeat
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: false
cooldown_days: 0
dialogue_pool: shop_leave_empty
pool_variant: 01
affection_settlement: none
required_flags:
  shopkeeper_intro_done: true
sets_flags: {}
godot_resource: data/story_events/daily/npcs/npc_shopkeeper_01/leave_empty/shop_leave_empty_01.tres
---

> **池**：`shop_leave_empty` · 未购买离开商店时随机 01～03

### [Scene: 老欧的铺子 · 门口]

**npc_shopkeeper_01**: "今日未有中意的？无妨。货架不会连夜逃走——下次若带着清单来，我为您省些工夫。"

**protagonist**: "好，先走了。"

**npc_shopkeeper_01**: "慢走。缺什么，再来便是；不必硬撑到最后一刻。"
