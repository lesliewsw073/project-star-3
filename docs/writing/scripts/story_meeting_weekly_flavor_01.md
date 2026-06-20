---
event_id: story_meeting_weekly_flavor_01
event_title: 週會開場
arc_type: secretary_flavor
owner: secretary
story_channel: meeting
meeting_scope: weekly
participants: [secretary]
character_id: secretary
execute_once: false
blocking: false
affection_settlement: once
affection_delta: 1
priority: 50
cooldown_days: 7
pool_id: meeting_weekly_flavor
required_flags:
  meeting.first_session_done: true
sets_flags: {}
status: draft
godot_resource: res://data/story_events/meeting/01_weekly_flavor.tres
---

## 場景描述

非首次的常規週日會議開場；秘書簡短提醒排程與跟隨，不阻塞 UI。

## 對話

| speaker_id | speaker_name | text |
|------------|--------------|------|
| secretary | 小唯 | 制作人，本週的週日會議開始了。右側可以調整下週行程，別忘了勾選要跟隨的藝人。 |
| secretary | 小唯 | 若有藝人疲勞或壓力偏高，建議排一兩天休息。完成後按「結束週日會議」提交。 |
