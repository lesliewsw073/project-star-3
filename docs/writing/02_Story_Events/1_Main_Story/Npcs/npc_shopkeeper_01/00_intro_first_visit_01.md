---
event_id: story_visit_npc_shopkeeper_01_intro_01
title: 商店·首次光临介绍
arc_type: main_once
owner: npc_shopkeeper_01
channel: visit
participants:
  - npc_shopkeeper_01
  - protagonist
execute_once: true
affection_settlement: none
required_flags: {}
sets_flags:
  shopkeeper_intro_done: true
godot_resource: data/story_events/main/npcs/npc_shopkeeper_01/00_intro_first_visit.tres
---

> **触发**：玩家**第一次**进入商店设施 · `fac_shop`。  
> **之后**：日常池见 `2_Daily_Loops/Npcs/npc_shopkeeper_01/`（`enter` / `purchase_leave` / `leave_empty`）。  
> **人设**：[[01_Characters/npc_shopkeeper_01]]

### [Scene: 大楼旁独栋旧店面 · 白天]

*(招牌漆皮剥落，门框漆色发暗，夹在两栋写字楼之间，窄得像是被城市挤出来的一截。你推开门，门顶铜铃轻轻响了一声。)*

*(与门外判若两界。)*

*(暖黄灯光从低垂的灯罩里淌下来，照着深色木架与玻璃柜。架上摆着练声用的哨片、贴着「艺人适用」的小标签、缎带扎好的礼盒，还有几样叫不上名字、却摆得极整齐的老物件。空气里先扑来几种香水混在一起的味道——甜、沉、略带回甘——底下还缠着一丝很淡的硫磺气，像远处有人刚熄了一小簇火。)*

*(柜台后站着一位银发老绅士。深色大衣的肩领绣着细花，马甲是提花暗纹，领口一团雪白的蕾丝领结，当中一枚金胸针嵌着深色宝石。他抬眼，目光温和，像等这一刻已经很久了。)*

**npc_shopkeeper_01**: "欢迎。第一次来？"

**protagonist**: "……这外面和里面，不太像同一家店。"

**npc_shopkeeper_01**: *(极轻地笑了一下)* "街面留给风跟雨，里面留给用得着的东西。您若是 {company_name} 的 {protagonist_full_name}——我认得这张脸，新成立的经纪公司，在这条街上很醒目。"

**protagonist**: "您怎么知道？"

**npc_shopkeeper_01**: "做这一行久了，谁起、谁落，耳朵比眼睛灵。叫我老欧就好。这铺子开了很多年；破产的经纪公司换了一茬又一茬，我这儿还在。"

**protagonist**: "制作人常来吗？"

**npc_shopkeeper_01**: "常来。送礼、应急、给艺人补练声练舞的小玩意儿，稀奇一点的也有——您慢慢看，架上什么都有。价格写在标签上，我不口头加价。"

*(他从柜台下取出一张纸质价目，纸质发黄，字迹却清楚，边角压了平整的铜尺痕。)*

**npc_shopkeeper_01**: "闻得到几种香？别紧张，不是给您下咒。只是有些货，存放时需要那样。至于那一丁点硫磺气——"

**protagonist**: "炼金术？"

**npc_shopkeeper_01**: *(微微扬眉，像是被逗乐了)* "您比上一位老板有想象力。当成旧屋子的脾气就好。看中什么，喊我一声；不买也没关系——这行当已经够累了，不必进门还绷着。"

*(他把价目推过柜台，指节修长，动作从容。)*

**npc_shopkeeper_01**: "以后您就是老主顾了，{player_address}。铃铛响，就是招呼。"
