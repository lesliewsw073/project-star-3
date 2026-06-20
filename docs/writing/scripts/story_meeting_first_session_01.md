---
event_id: story_meeting_first_session_01
event_title: 首次週日會議
arc_type: secretary_tutorial
owner: secretary
story_channel: meeting
meeting_scope: first
participants: [secretary]
character_id: secretary
execute_once: true
blocking: true
affection_settlement: once
affection_delta: 2
priority: 200
cooldown_days: 0
pool_id: ""
required_flags: {}
sets_flags:
  meeting.first_session_done: true
status: draft
godot_resource: res://data/story_events/meeting/00_first_session.tres
---

## 場景描述

首次週日會議開場；玩家剛簽約完、排下週行程前。秘書說明右側排程與跟隨勾選。

## 對話

| speaker_id | speaker_name | text |
|------------|--------------|------|
| secretary | 小唯 | 制作人，歡迎來到首次週日會議。今天沒有當日行程，請專心排下週計畫。 |
| secretary | 小唯 | 右側可以編排每位藝人的下週草稿、勾選跟隨對象。完成後記得按「結束週日會議」。 |
| protagonist | 製作人 | 明白了。先把下週節奏定下來。 |
