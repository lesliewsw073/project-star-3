# project-star-3 跨机同步指南

> **用途**：在另一台 Mac／环境首次拉取、日常同步、交给 Cursor AI 续作时的交接文档。  
> **云端位置**：本文件随 Git 仓库同步，GitHub 上可直接阅读。  
> **最后更新**：2026-06-20

---

## 仓库信息

| 项目 | 值 |
|---|---|
| GitHub 仓库 | https://github.com/lesliewsw073/project-star-3 |
| Clone URL（HTTPS） | `https://github.com/lesliewsw073/project-star-3.git` |
| Clone URL（SSH） | `git@github.com:lesliewsw073/project-star-3.git` |
| 默认分支 | `main` |
| 引擎 | Godot **4.6**（`config/features` 含 GL Compatibility） |
| 主场景 | `res://GameRoot.tscn`（见 `project.godot`） |

### Git 提交作者（本专案惯例）

| 字段 | 值 |
|---|---|
| user.name | `Luke073` |
| user.email | `lesliewsw073@gmail.com` |

作者名可自订；GitHub 归因靠 **已验证邮箱** 关联账号。

---

## 给 Cursor AI 的唤醒指令（回家／换机时用）

在新机器打开 Cursor，进入 clone 下来的 `project-star-3` 工作区后，可直接对 AI 说：

```
请读 docs/MACHINE_SYNC.md，帮我在这台机器完成 project-star-3 的同步与环境检查。
仓库：https://github.com/lesliewsw073/project-star-3
同 GitHub 账号 lesliewsw073。
```

AI 应依本文完成：`git pull`、Godot 打开检查、本地被 ignore 的目录说明、以及日常 push/pull 规则。

---

## 一、新机器首次设置

### 1. 安装前置

- [ ] **Git**（macOS 通常已有；`git --version`）
- [ ] **Godot 4.6**（或兼容 4.x，建议与主开发机同大版本）
- [ ] （可选）Python 3 — 跑 `tools/` 下 sandbox／图片脚本时需要

### 2. Clone 仓库

```bash
cd ~/Projects   # 或你习惯的目录
git clone https://github.com/lesliewsw073/project-star-3.git
cd project-star-3
```

若已配置 SSH key，可改用：

```bash
git clone git@github.com:lesliewsw073/project-star-3.git
```

### 3. Git 身份（仅本仓库，推荐）

```bash
git config user.name "Luke073"
git config user.email "lesliewsw073@gmail.com"
```

### 4. GitHub 认证

GitHub **不接受账号密码** push，需二选一：

**HTTPS + Personal Access Token（曾成功用过）**

1. https://github.com/settings/tokens → Generate new token (classic)
2. 勾选 **`repo`**
3. `git push` 时：Username = `lesliewsw073`，Password = **token**（`ghp_...`）

**SSH（长期省事）**

```bash
ssh-keygen -t ed25519 -C "lesliewsw073@gmail.com"
cat ~/.ssh/id_ed25519.pub   # 贴到 GitHub → Settings → SSH keys
git remote set-url origin git@github.com:lesliewsw073/project-star-3.git
```

### 5. 用 Godot 打开

```bash
# 若 godot 在 PATH：
godot4 --path . project.godot

# 或 Godot 编辑器 → Import → 选 project.godot
```

首次打开会生成 **`.godot/`** 缓存（已在 `.gitignore`，勿提交）。

---

## 二、日常同步规则（防冲突）

```
换环境离开前  →  git push
新环境开始前  →  git pull
```

标准流程：

```bash
git pull
# …编辑、Godot 测试…
git status
git add .
git commit -m "简短说明这次改了什么"
git push
```

**不要** force push `main`，除非明确知道后果。

---

## 三、不会进 Git 的本地内容（各机自行生成）

以下被 `.gitignore` 排除，clone 后**不会**出现，属正常：

| 路径 / 模式 | 说明 |
|---|---|
| `.godot/` | Godot 导入缓存，每台机器各自生成 |
| `.DS_Store` | macOS 杂项 |
| `docs/FULL_CODEBASE.md` | 可用 `tools/generate_full_codebase_md.py` 本地再生 |
| `tools/image_tools/.venv/` | Python 虚拟环境，本地 `pip install -r requirements.txt` |
| `tools/LibreSprite/LibreSprite.app/` | 本地 LibreSprite 安装包 |
| `export_presets.cfg` | 导出预设（可能含本机路径／凭证） |

### 图片工具 venv（需要跑 image_tools 时）

```bash
cd tools/image_tools
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 四、专案特殊约定（AI／写作必读）

### 桌面 Master Spec（唯一真相来源，不在 repo 内）

| 文件 | 路径 |
|---|---|
| 总 spec | `/Users/luke/Desktop/docs/项目梳理_明星志愿3精神续作.md` |
| 剧本人设 | `/Users/luke/Desktop/docs/剧本人设写作规范.md` |
| 图片规格 | `/Users/luke/Desktop/docs/图片规格与尺寸.md` |

`docs/writing/` 为 Obsidian 镜像，**以桌面三份为准**。换机若 Desktop 路径不同，需自行同步这三份 md（iCloud／U 盘／另建 repo 均可）。

### 测试内容标记

- 除 **artist_003（米语）** 正式稿外，多数预填为测试内容
- 新增 `.tres` 设 `is_test_content = true`，并更新 `docs/writing/CONTENT_TIER_REGISTRY.md`
- 详见 `.cursor/rules/test-content-marking.mdc`

### 秘书不可收礼

- 硬性设定，见 `.cursor/rules/secretary-no-gifts.mdc`

---

## 五、已知仓库注意事项

1. **`UI/STHeiti Light.ttc`** 约 53 MB，超过 GitHub 建议 50 MB，首次 push 仅有 warning，未阻断。
2. 首次 commit 之后，Mac mini 上曾有一个**未提交**本地修改：`cursor_png/comfyui_output/artist_001_pixel_128.png` — 换机前在主开发机 `git status` 确认是否已 push。

---

## 六、常用命令速查

```bash
# 看状态
git status
git log --oneline -5

# 只拉不 merge 冲突时
git pull --rebase

# 看 remote
git remote -v

# 跑全部 sandbox（需 Python）
python3 tools/run_all_sandboxes.py
```

---

## 七、交接检查清单（换机完成后打勾）

- [ ] `git pull` 无冲突，在 `main` 分支
- [ ] Godot 4.6 能打开 `project.godot` 并运行主场景
- [ ] `git config user.name` / `user.email` 正确
- [ ] `git push` 认证可用（token 或 SSH）
- [ ] （若写剧情）桌面三份 Master Spec 已拷到本机或可访问路径
- [ ] （若跑图工具）`tools/image_tools/.venv` 已本地建好

---

*本文档随 repo 更新；修改后记得 `git add docs/MACHINE_SYNC.md && git commit && git push`。*
