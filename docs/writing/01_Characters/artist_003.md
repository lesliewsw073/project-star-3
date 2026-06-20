---
artist_id: artist_003
display_name: 米语
english_name: Puzzle
age: 22
style: 韩系、御姐、顶尖舞者、表现力拉满
specs: 主持人/唱跳歌手
pets: 玉米蛇*1，蜥蜴*2
height: 167cm
weight: 48kg
bust: 82cm
waist: 60cm
hip: 86cm
favoriteFood: 蔬菜、鸡蛋
dislikedFood: 高热量的食物
story_gate: opening_pick
visual_portrait: assets/characters/artists/artist_003/portrait/artist_003_portrait.png
poachable: none
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
> | `favor_gain_mod` | 0 | 好感获取修正（待企划） |
> | `stress_gain_mod` | 1 | 压力上升修正（完美主义／高压训练，待微调） |
> | `fatigue_gain_mod` | 1 | 疲劳上升修正（训练量大，待微调） |
> | `satisfaction_gain_mod` | 0 | 满意度上升修正（理性务实，待微调） |
>
> 对齐 Godot `Artist_Resource`「养成修正」；`*_mod` 为有正负的修正，`*_abs` 为绝对加值。带「待企划／待微调」者请定稿后改数值。

## 零、归属规则

- **不可挖角**：rival 挖角对她无效；`poachable: none`
- **会主动离开**：羁绊不足时，可走主线一次性离开（海外体育频道邀请／低好感孤立线）；**不是**「只等主角解约才走」
- **主角可解约**：周日会议内主角可主动解约，腾出 roster 名额

---

## ## 一、 基础视觉与外形设计（Appearance）

- **### 整体视觉风格**：_(例如：冷艳高孤、极简线条感、或者是带有强烈力量感的健康美)_
    
- **### 面部与五官特征**：_(例如：眼神坚毅、高鼻梁、唇线分明，不笑时自带距离感)_
    
- **### 发型与发色**：_(例如：利落的黑色直长发、或舞台高马尾)_
    
- **### 身材比例与体型**：由于她极度自律且有大量舞蹈训练，体型呈现出**极低体脂、肌肉线条紧致且修长**的视觉效果，具有强烈的舞台延展性。
    
- **### 标志性穿搭/私服**：
    
    - _工作/舞台_：极具视觉震撼力的干练舞者装扮、或突出线条感的高级定制。
        
    - _私下_：极其舒适、便于运动的极简风私服（可能带有一点方便照顾爬宠的耐脏、利落元素）。
        

## ## 二、 核心性格与行为侧写（Personality）

- **### 极致完美主义**：对待通告与工作永远追求100%甚至超越完美的答卷，不容许任何瑕疵。
    
- **### 极度克制与高自律**：对饮食兴趣不大，日常严格控体，常常因为过度专注工作与训练而**忘记吃东西**。
    
- **### 理性务实的回报观**：对初期签约金无所谓，但对续约金额有明确、不过分但符合实力的标准，坚信付出必须获得对等回报。
    

## ## 三、 日常生活与隐藏萌点（Daily Life）

- **### 满档的神秘私生活**：表面上神龙见首不见尾，实际上海量的时间都被舞蹈课、外语练习和硬核录像复盘填满。
    
- **### 唯一的柔情（爬宠）**：生活没有任何娱乐爱好，内心深处所有的温柔与耐心，全部倾注给了家里饲养的**爬行类宠物（爬宠）**。
    

## ## 四、 人际关系与原生家庭（Relationships）

- **### 远距离的家庭关系**：父母居住在很远的地方，日常仅靠电话联系。因此主线中与父母的剧情并不多，造就了她独立解决一切的个性。
    
- **### 与主角的羁绊/冲突点**：她因为高强度训练和控体导致“忘记吃东西”的病态作息，是早期与主角产生剧情碰撞和关怀冲突的核心切入点。
    

## ## 五、 生涯发展与命运分歧点（Career & Route）

- **### 职业路线规划**：包含一部分主持工作，但核心方向为“唱跳全能舞台路线”。
    
- **### 舞台风格**：演唱会以大量高难度舞蹈编排为核心，视觉效果极其震撼，具备绝对的统治力。
    
- **### 中期核心剧情分歧（海外体育频道邀请）**（即 **主动离开** 触发点，见 §零）：
    
    - _【低好感度 / 孤立线】_：与主角羁绊不足，**主动提出解约**，前往国外追求更高的事业巅峰。
        
        - _【高好感度 / 恋爱线】_：与主角建立深厚羁绊，为了主角拒绝海外重金邀请，留在国内发展。

### 003 签约 event（已定稿台词）

- 签约：[[02_Story_Events/1_Main_Story/Artists/artist_003/00_office_sign_01]]
- 首次例会：[[02_Story_Events/1_Main_Story/Artists/artist_003/01_first_meeting_01]]
- 周会聊天：`2_Daily_Loops/Artists/Meeting_Weekly/artist_003/`（`Basic/` 01～03 ✅；其余子夹待写）· 台账 [[02_Story_Events/2_Daily_Loops/Artists/Meeting_Weekly/台词库台账]]
- 行程结算池：`2_Daily_Loops/Artists/Schedule_Result/artist_003/`（fail / success / perfect 各 3 套）
- 大地图偶遇：`2_Daily_Loops/Artists/Map_Encounters/artist_003/Permanent/`（5 套，含体育主持）· Flag_Unlock（爬宠）/ Conditional 待写
