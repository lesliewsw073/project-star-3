# 通告每日拍攝判定公式 v1

> 程式：`JobDayEvaluator.gd`  
> 常數：`SHOOT_STAT_RATIO = 0.90`（全局統一）

## 接案快照（JobInstance）

| 字段 | 说明 |
|------|------|
| `accept_mode` | `NORMAL`（100% 达标接案）/ `INVITE`（邀请接案） |
| `accept_req_snapshot` | 接案时 `req_* > 0` 的快照 |
| `accept_shoot_floor` | 每项 `int(req * 0.90)` |
| `accept_total_day` | 接案日 |

**NORMAL**：拍摄日属性层恒通过（道具降属性不影响本通告合格）。  
**INVITE**：拍摄日检查 `current >= floor`（90% 线）。

## 邀请分数（占位）

```text
invite_score =
  company_reputation * 0.4
+ company_public_opinion * 0.3
+ artist.fame * 0.15
+ artist.popularity * 0.10
+ successful_jobs_count * 0.05
```

默认门槛 `300`（`JobDayEvaluator.DEFAULT_INVITE_THRESHOLD`）。

## 每日判定顺序

1. 事件 `event.job_force_fail` / `event.job_force_fail.{job_id}` → FAILED  
2. 状态硬失败（生病、RED、疲劳≥85、压力≥76、预估超标）→ FAILED  
3. 属性层（INVITE 才检）→ 不达标 FAILED  
4. Roll `p_fail` → FAILED  
5. Roll `p_perfect` → PERFECT 否则 SUCCESS

详见 `JobDayEvaluator.gd` 与 `tools/job_day_evaluator_sandbox.py`。
