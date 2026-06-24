---
status: planning
date: 2026-06-24
slug: skeleton-flesh-axis
distilled_to:
---

# 设计 spec — 以"骨架 / 肉"重定 skill 内容主轴

## 目标

把 skill 内容组织的**主轴**从"变更频率(rate of change)"重定为"**抽象度:骨架(skeleton)vs 肉(flesh)**"。骨架 = 不变的设计/过程/行为**理论**(treasure);肉 = 当前代码的**事实**(地图 / 约定 / 坑,随 refactor 漂)。skill 同时持有两者,但**清晰分开、不混**。

## 背景(为什么)

按变更频率拆时,"慢漂的肉"(如模块树 `modules-and-packages.md`)和"抽象骨架"(如 `api-contract.md`)都因为"稳定-ish"被塞进 `architecture/`。结果 architecture/ 把**收敛的抽象骨架**和**发散的代码地图**混在一起,看不出哪个是不变理论、哪个是会漂的地图 —— 这就是"分了很多模块但本质还发散"的根因。

关键事实:**tier 名字已唯一决定骨架/肉**(architecture/workflows/rules → 骨架;conventions/gotchas/references → 肉),所以物理父目录 `骨架/`+`肉/` 是零信息增益的冗余仪式。正确的落地是**提纯 tier + 声明透镜**,不是加父目录。

`rate-of-change` 不是错,是个**会把"慢漂地图"误判成架构的启发式**;真正的判据是抽象度。

保留不动(与本轴正交):**记录易错点(gotchas)、AAR、工作流驱动**等机制。

## 设计

### ① 透镜 + tier 归属

**骨架(不变的理论/方法):**
- `architecture/` — 抽象设计理论:分层方向、契约即兼容边界、编排层(Manager)、事务/锁原则、统一封装**机制**、架构禁止项。不点具体类名/路径。
- `workflows/` — 过程理论(怎么做任务)。单文件夹,正确。
- `rules/` — agent 行为方法论(子 Agent 反问、改动纪律)。

**肉(当前代码的事实,会漂):**
- `references/` — **代码地图**:模块树、包职责、DAL 目录结构、source-index。顶部标注"随 refactor 漂,以真实代码为准"。
- `conventions/` — house style:命名、路径形态、命令、格式。
- `gotchas/` — 坑(点名具体符号),按模块一文件。

### ② 提纯 architecture/(治本)

从 architecture/ 移出"肉",归位:
- `modules-and-packages.md`、`dal-layout.md` → `references/`(代码地图)。
- `call-chains.md`:点名具体类的链路 → `references/`;"调用方向(web→biz→core→dal、不反向)"这条**原则** → 留 architecture/(并入分层原则)。
- `response-envelope.md`:具体字段名(success/errorCode/...)与类名绑定(GlobalResponseAdvice 等)→ `conventions/`(我们的封套用这套字段/符号 = house style);"统一封装、错误 in-band(HTTP 200 + errorCode)、分页是边界转换"这组**机制原则** → 留 architecture/。

architecture/ 只留抽象不变量:api-contract、manager-layer、prohibitions、transactions-locks、integration-and-config + 分层/响应/RPC 的**原则**。

**判据(写进 playbook):** "一次大 refactor(改模块名、挪文件)后,这句话还成立且有用吗?成立 → 骨架;它描述的是当前代码(地图 / 名字 / 路径 / 某符号的坑)→ 肉。"

### ③ SBA 文档 reconcile(把已 push 的 ee1456d 讲对)

- `SKILL.md` Content Classification:主轴改为"抽象(骨架/肉)";architecture/ 定义从"稳定结构事实"收紧成"抽象设计理论";代码地图归 references/。点明 rate-of-change 只是会误判慢漂地图的启发式。
- `references/rate-of-change-split.md` → reframe 成"骨架/肉 split"(判据如上);保留路径迁移 / hub / 路由重derive 等机制章节。
- `references/progressive-rigor.md`、`references/layout.md`、`TEMPLATES-GUIDE.md` 跟着对齐(architecture=骨架理论,references=肉地图)。

### ④ 工具(基本不动)

扁平 tier 不变,无 churn。`references/` 已在脚本 `TIER_DIRS`。`route-reachability.sh`:`references/`(肉地图)仍按 lookup 层豁免(按需查),`architecture/`/`conventions/`/`gotchas/`/`rules/` 仍要 route-reachable。脚本 0~1 行改动。

### ⑤ 纯度维持

软边界靠**判据 + review**(自动查不了"地图 vs 原则",grep 不出)。不上重型门;最多在 `templates/skill/workflows/task-closure.md` 加一句提示:"新建 `architecture/` 文件前先过骨架判据。"

### ⑥ 下游传导

`chaos` / `chaos_web`:把 architecture/ 里的代码地图(modules-and-packages、dal-layout 等)挪进 references/;更新各自 architecture/index 与路由。中等改动,扁平结构不变。

## 验收标准

- [ ] SBA `architecture/` 的定义在所有文档里一致 = "抽象设计理论(骨架)",不含代码地图。
- [ ] `rate-of-change-split.md` 以骨架/肉判据为主轴,rate-of-change 降为启发式注脚。
- [ ] chaos / chaos_web 的 architecture/ 不再含模块树 / 目录结构类地图(已挪 references/)。
- [ ] 两下游 `route-reachability` 0 unreachable、`audit-orphans` 0 orphan 仍成立。
- [ ] task-closure 有"骨架判据"review 提示。
- [ ] `check-all` 绿;UPSTREAM-CHANGES 记录本次主轴重定。

## Out of scope

- 不加物理父目录 `骨架/`+`肉/`(冗余,已否决)。
- 不上自动"纯度"门(自动判不了地图 vs 原则)。
- 不动 gotchas-recording / AAR / workflow-driven 机制。
- 不动 route-reachability / audit-orphans / hub 等已落地的可达性工具(只可能加一行 tier)。

## Open questions

- 代码地图放 `references/` 够清楚,还是要单开一个更直白命名的肉地图层(如 `map/`)?(默认 references/,除非你想要更强的命名信号。)
