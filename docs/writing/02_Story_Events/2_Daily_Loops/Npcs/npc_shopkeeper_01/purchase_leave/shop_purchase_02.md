---
event_id: story_visit_npc_shopkeeper_01_purchase_02
title: 购物离开·02
arc_type: flavor_repeat
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: false
cooldown_days: 0
dialogue_pool: shop_purchase_leave
pool_variant: 02
affection_settlement: none
required_flags:
  shopkeeper_intro_done: true
sets_flags: {}
godot_resource: data/story_events/daily/npcs/npc_shopkeeper_01/purchase_leave/shop_purchase_02.tres
---

> **池**：`shop_purchase_leave` · variant 02

### [Scene: 老欧的铺子 · 柜台]

**npc_shopkeeper_01**: "承惠。这几样近来走得快，您挑的恰是其中较稳当的——并非奉承，我很少为成交改口。"

**protagonist**: "够用就好。"

**npc_shopkeeper_01**: "够用，便是分寸。这行耗神，不必堆无用的东西。下次见，{player_address}——仍欢迎您推门进来。"
