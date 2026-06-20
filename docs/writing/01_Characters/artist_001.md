---
artist_id: artist_001
display_name: 夏知秋
english_name: Yoko
age: 18
style: 英伦摇滚、复古、少女反差
specs: 吉他手/主唱/作词作曲
height: 159cm
weight: 46kg
bust: 78cm
waist: 58cm
hip: 82cm
favoriteFood: 甜甜的蛋糕
pets: ""
dislikedFood: ""
story_gate: opening_pick
visual_portrait: assets/characters/artists/artist_001/portrait/artist_001_portrait.png
poachable: none
leave_policy: player_terminate_only
birthday: ""  # MM-DD · 周会 `artist_birthday` 节日 · 待企划
---

> [!abstract]- 养成修正（`Artist_Resource` · 8 栏）
>
> | 字段 | 值 | 企划说明 |
> |------|-----|----------|
> | `contract_diff_mod` | 0 | 续约／签约难度修正 |
> | `fail_rate_abs` | 0 | 打工／课程额外失败率（绝对加值） |
> | `perfect_rate_abs` | 0 | 完美判定加成（绝对加值） |
> | `morality_mod` | 0 | 道德变化修正 |
> | `favor_gain_mod` | 1 | 好感获取修正（较易提升） |
> | `stress_gain_mod` | -1 | 压力上升修正（负=较慢） |
> | `fatigue_gain_mod` | -1 | 疲劳上升修正（负=较慢） |
> | `satisfaction_gain_mod` | 1 | 满意度上升修正（较易提升） |
>
> 对齐 Godot `Artist_Resource`「养成修正」；`*_mod` 为有正负的修正，`*_abs` 为绝对加值。玩感：养着舒心。

## 一、名字与身份

- **中文名**：夏知秋
- **英文名 Yoko**：偶像是 **约翰·列侬**（John Lennon）
- **年龄**：18 岁，**刚刚高中毕业**
- **家境**：比较富裕，父母很疼爱；有一个妹妹
- **定位**：**女一号**艺人

## 二、外形与日常偏好

- **体型**：159 cm／46 kg；偏纤细少女骨架（三围占位 78-58-82，待视觉定稿）
- **整体气质**：英伦摇滚路线，与外表少女、可爱偏好形成反差
- **标志物件**：复古电吉他；日常爱买 **黑胶唱片**，用手机做简单 demo 采样
- **喜欢**：一切偏少女、可爱的东西；甜甜的蛋糕
- **讨厌**：一个人独处

## 三、音乐取向与创作

- **整体风格**：**英伦摇滚**（相对复古，与当下潮流贴合度不高）
- **喜欢的乐团**：披头士（The Beatles）、电台司令（Radiohead）
- **最爱的曲**：电台司令〈High and Dry〉
- **经历**：高中玩过乐队、当过主唱；参加过很多小众展会
- **才华**：能自己 **作词作曲**；对歌唱有相当强烈的热爱；**原创热情极大**，会有很多原创歌曲
- **曲风**：以相对复古的英伦摇滚为主

## 四、能力与养成短板（前期）

| 面向 | 状态 |
|------|------|
| 音色底子 | 有辨识度和条件，但唱法偏 **大白嗓**（直白、缺技巧修饰） |
| 自我认知 | **不自知**；家人、同学一直友好，无恶意地掩盖、不戳破 |
| 前期转折 | 主角 **第一次直说** → 当下 **深受打击** → **很快振作**，练习 **相当努力** |
| 唱功 | 一般，需大量时间培养 |
| 舞台表现 | 有勇气，但四肢僵硬、只会喊；需长期培养 |
| 原创产出 | 高 |

> 养成主轴：**原创多 × 唱功／舞台需时间堆**；「点破大白嗓 → 短打击 → 狠练」是前期核心成长 beat。

## 五、剧情设计方针

- **基调**：不过分戏剧化、不堆强冲突；以 **简单、正向反馈** 为主
- **冲突与反差**：交给 **002、003** 承担
- **内容重心**：**日常小故事**——表面平淡，靠生活细节最吸引人
- **家庭线**：会出现父母剧情（成绩好、希望她读书、音乐当爱好 vs 她要走音乐），但宜 **轻、软、可化解**，不宜做成 heavy drama

## 六、入队与开局流程

### 游戏结构（001／002／003 相同）

详见 [[00_Project_Spec/开局流程_取名与三选一签约]]。

```text
取名/公司名 → 三选一（行动名 UI）→ 该角色专属签约剧情 → 后续节点（001：旁白跳日 → 周日例会）
```

### 001 签约 event（已定稿台词）

- 签约：[[02_Story_Events/1_Main_Story/Artists/artist_001/00_street_sign_01]]
- 首次例会：[[02_Story_Events/1_Main_Story/Artists/artist_001/01_first_meeting_01]]
- 周会聊天：`2_Daily_Loops/Artists/Meeting_Weekly/artist_001/`（`Basic/` 01～03 ✅；Award / Festival / Original_Song / Schedule_Performance 待写）· 台账 [[02_Story_Events/2_Daily_Loops/Artists/Meeting_Weekly/台词库台账]]
- 行程结算池：`2_Daily_Loops/Artists/Schedule_Result/artist_001/`（fail / success / perfect 各 3 套）
- 大地图偶遇：`2_Daily_Loops/Artists/Map_Encounters/artist_001/Permanent/`（5 套）· Flag_Unlock / Conditional 待写