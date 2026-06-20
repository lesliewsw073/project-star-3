---
event_id: story_visit_npc_shopkeeper_01_purchase_01
title: 购物离开·01
arc_type: flavor_repeat
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: false
cooldown_days: 0
dialogue_pool: shop_purchase_leave
pool_variant: 01
affection_settlement: none
required_flags:
  shopkeeper_intro_done: true
sets_flags: {}
godot_resource: data/story_events/daily/npcs/npc_shopkeeper_01/purchase_leave/shop_purchase_01.tres
---

> **池**：`shop_purchase_leave` · 结账后离开商店时随机 01～03

### [Scene: 老欧的铺子 · 柜台]

*(纸绳系得整齐，收据折好压在袋底。)*

**npc_shopkeeper_01**: "都为您备好了。收据在袋里——公司账目若需凭证，请留好。我不过问您怎么报，那是您的内务。"

**protagonist**: "多谢。"

**npc_shopkeeper_01**: "若艺人中意，日后不妨带一句口信来。我收在柜台里，不外传——比张贴广告体面些。"
