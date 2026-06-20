---
event_id: story_sign_artist_001_street_01
title: 路边弹唱·签约
arc_type: main_once
owner: artist_001
channel: sign
participants:
  - artist_001
  - protagonist
execute_once: true
affection_settlement: none
required_flags:
  opening_pick: artist_001
sets_flags:
  sign_artist_001_done: true
godot_resource: data/story_events/main/artists/artist_001/00_street_sign_01.tres
cg_id_01: sign_street_01_01
cg_id_02: sign_street_01_02
cg_id_03: sign_street_01_03
---

> **触发**：开局三选一「**下楼透透气**」。  
> **001 签约**：路边相遇 + 名片；Gameplay **跳过** 父母/签字过程。  
> **下一 event**：[[01_first_meeting_01]] · `story_meeting_artist_001_first_session_01`

### [Scene: 公司楼下 · 路边 · 傍晚]

*(环境：写字楼夹缝里的窄人行道，晚风。远处车流声被一把木吉他的扫弦盖住。)*【CG: sign_street_01_01】

*(夏知秋坐在路沿石上，膝上抱着贴满贴纸的吉他，正唱最后一段副歌——声音有点大白，但很亮。)*

*(你下楼透气，在几步外停住。她唱完，抬头。)*

**artist_001**: "啊~你好啊！谢谢你听到最后！"

**protagonist**: "现在很少听到这么纯的英伦摇滚了，可是这几首我都没听过，是哪个乐队的作品？"

**artist_001**: *(拨了一下弦，有点不好意思地笑)* "刚才那些都是我自己写的哦~"

**protagonist**: "……高中生能写出这种水平的作品？对摇滚的理解很通透，又有自己的风格。"

**artist_001**: *(眼睛亮了一下，又迅速低头拨弄和弦)* "嘿嘿，其实我已经毕业啦。我还存了好多自己写的歌，正在发给唱片公司。"

**protagonist**: "这种复古风，市场接受度不算高。唱片公司还没回音的话……有兴趣来我公司试着发唱片吗？"【CG: sign_street_01_02】

**artist_001**: *(抱着吉他微微后仰，打量你)* "叔叔你的公司？是可以发正式唱片的吗？"

**protagonist**: "是啊，刚成立，虽然目前规模不大。但可以给你百分之百原创优先权。"

**artist_001**: *(停顿半拍，指尖在琴箱上轻轻敲了两下)* "真的吗？不用去唱那些千篇一律的流行歌，只唱自己的原创就行？"

**protagonist**: "嗯。不过你现在的唱功还很青涩，得加强训练。我今天能从你的歌里听出极大的热情，我愿意在你身上赌一把！"

**artist_001**: *(把吉他往怀里收了收，声音软下来)* "……听起来有点心动。但是我得先跟爸爸妈妈商量一下。对了，叔叔，可以给我张你的名片吗？"

*(你从口袋里掏出名片，递过去。她双手接过，认真看了一眼公司名。)*【CG: sign_street_01_03】

**protagonist**: "当然。这是我的名片，请收下，这种事一定要跟父母先商量的，那我希望有你的好消息。"

*(她把名片小心夹进琴包侧袋，冲你挥了挥手指。)*

**artist_001**: "嗯！那……叔叔再见！"

*(她重新抱起吉他，指尖落在和弦上。你转身回楼，晚风里还留着刚才那首歌的余韵。)*

### [Transition · 时间跳跃 · 不演出父母/签字]

*(旁白)*

**旁白**：她说过要和父母商量。你没有再追问——数日后，第一个周日，你第一次以老板身份坐在会议桌前。

> **下一 event**：[[01_first_meeting_01]]
