---
event_id: story_visit_npc_shopkeeper_01_leave_empty_03
title: 空手离开·03
arc_type: flavor_repeat
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: false
cooldown_days: 0
dialogue_pool: shop_leave_empty
pool_variant: 03
affection_settlement: none
required_flags:
  shopkeeper_intro_done: true
sets_flags: {}
godot_resource: data/story_events/daily/npcs/npc_shopkeeper_01/leave_empty/shop_leave_empty_03.tres
---

> **池**：`shop_leave_empty` · variant 03

### [Scene: 老欧的铺子 · 门口]

**npc_shopkeeper_01**: "没有合适的？许是艺人尚未开口——您回去问一问，下回若需留货，报上名目即可。"

**protagonist**: "有数了，谢。"

**npc_shopkeeper_01**: "不必客气。铜铃响，便是招呼；不买，也不得罪人——我在这行待久了，懂分寸。"
