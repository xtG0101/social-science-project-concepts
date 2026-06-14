# 夹心层时间困境 — MVP Spec

## 它做什么

一个 3–5 分钟的单页网页小游戏：用户在无尽任务清单里清任务，同时尝试点「独处 10 分钟」——清单会立刻补满，休息会被打断或推迟，让玩家体验「清单做不完、做回自己永远排最后」。

## 给谁用

同龄人、老师、试玩同学——尤其是见过父母一边忙工作一边顾家、或自己也在多重角色里切换的人。不需要会玩游戏，打开就能懂。

## 核心流程

1. **开始** — 用户点「开始」；屏幕显示：「你是这一家的安排者。把今天过完。」
2. **清任务** — 用户点击完成任务（上班、做饭、辅导作业等）；任务完成但马上弹新的，孩子落寞条缓慢下降。
3. **第一次想休息** — 用户发现底部「独处 10 分钟」并点击；读条开始后被紧急任务打断（如「加班」「陪诊」插入清单）。
4. **再试仍失败** — 用户再清几轮任务后又点「独处」；系统提示「已为您重新安排优先级」，休息按钮再次变灰。
5. **结尾** — 无赢/输；一句带讽刺与冲击力的收束 + 2–3 个反馈题（最想做什么却做不到、清单是否做不完、谁最难受）。

## 不在 MVP 里

- 拖拽布偶、爸妈双角色、三场景地图切换
- 祖辈完整任务线与 stakeholder 点选视角
- 三条状态条（MVP 只保留疲惫条 + 孩子落寞条）
- 音效、复杂动画、色调渐变、操作变慢
- 7 Beat 完整弧线、访谈原话实时嵌入、调研驱动参数
- 通关、最优解、隐藏小任务（如喝咖啡）

## 怎么收集反馈

- **结尾屏 2–3 题**：最想点但点不了的是什么；是否感到清单永远做不完（1–5 分）；若这是你家的一天，谁最难受、为什么（开放题）。可链到问卷星 / Google 表单，或页内 textarea。
- **局内简单统计**（localStorage）：完成任务数、尝试休息次数、被打断次数；结尾展示给用户，兼作展示与论文素材。
- **线下试玩 5–10 人**：观察是否在中期开始找休息按钮、打断时是否愣住，记在试玩表上。

## Research Question & Hypothesis

Research Question: How does my interactive web demo affect users' awareness that sandwich generation time poverty is a structural problem?

Hypothesis: I hypothesize that after using my interactive web demo, users will increase their awareness that sandwich generation time poverty is a structural problem.
