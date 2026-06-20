---
event_id: story_visit_npc_shopkeeper_01_purchase_03
title: 购物离开·03
arc_type: flavor_repeat
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: false
cooldown_days: 0
dialogue_pool: shop_purchase_leave
pool_variant: 03
affection_settlement: none
required_flags:
  shopkeeper_intro_done: true
sets_flags: {}
godot_resource: data/story_events/daily/npcs/npc_shopkeeper_01/purchase_leave/shop_purchase_03.tres
---

> **池**：`shop_purchase_leave` · variant 03

### [Scene: 老欧的铺子 · 柜台]

**npc_shopkeeper_01**: *(将纸袋双手递出，指节在袋角处略作停顿)* "请小心，有一角略尖。若是赠礼，贺卡恕不代笔——字句由您来写，艺人才认得您的诚意。"

**protagonist**: "明白。"

**npc_shopkeeper_01**: "那便不耽搁您了。路上不必急——急信，我向来不在店门口回。"
