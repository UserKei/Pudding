# Agent 使用说明

## 项目背景

这是 `Pudding` Godot 游戏项目，用于参加金海豚奖游戏开发大赛。

本项目的 Game Jam 主题是“别按那个键”。当前处于快速原型迭代开发阶段，玩法、叙事和 Q 键含义都可以随着测试反馈继续调整，不要过早锁死解释。

开发时可以主动思考并搜索网上高评分游戏的相关设计参考，尤其是平台跳跃、叙事选择、风险按钮、诱惑机制和短流程 Game Jam 作品。

改动应尽量小、清晰，并遵循现有项目结构。

## 共享文档

团队共享知识库放在飞书 Wiki：

https://fcnvne8jukji.feishu.cn/wiki/IebJwuivtixxnrk56sncsmoQncb?fromScene=spaceOverview

在做较重要的玩法、设计、叙事、制作流程或技术决策前，先查看相关飞书文档。飞书是团队协作和持续更新文档的主要来源。

推荐查询流程：

1. 使用用户身份解析 Wiki 节点：

   ```bash
   lark-cli wiki +node-get --as user --node-token "https://fcnvne8jukji.feishu.cn/wiki/IebJwuivtixxnrk56sncsmoQncb?fromScene=spaceOverview" --format json
   ```

2. 如果该节点是知识空间或目录，使用返回的 `space_id` 和对应节点 token 查看子节点：

   ```bash
   lark-cli wiki +node-list --as user --space-id "<space_id>" --parent-node-token "<node_token>" --page-all --format json
   ```

3. 如果需要读取文档正文，先读取 Lark 文档工作流：

   ```bash
   lark-cli skills read lark-doc
   ```

   然后按该工作流使用对应的 `lark-cli docs` 命令。

如果认证或权限失败，请让用户授权，或请用户提供所需文档内容。除非用户明确要求使用 bot 身份，否则不要静默切换到 bot 身份。

## 本地文档规则

本仓库用于保存稳定、偏执行层面的文档：

- `AGENTS.md`：Codex 和其他 agent 在编辑前必须遵守的规则。
- `docs/`：直接影响实现、构建步骤、资源或架构的简短本地说明。

飞书用于保存团队协作文档：

- 游戏设计笔记
- 任务规划
- 会议记录
- 待讨论问题
- 持续变化的规格说明
- 长篇讨论内容

避免把完整飞书文档复制进仓库。如果飞书中的决策会影响代码，请在本地补一段简短摘要，并链接回对应飞书来源。

## 协作流程

编辑前：

1. 阅读本文件。
2. 如果任务依赖团队背景，请查看相关飞书文档。
3. 运行 `git status --short`，避免覆盖队友的改动。

编辑时：

- 改动范围应贴合当前请求。
- 优先使用清晰的文件名和简单的项目组织方式。
- 除非任务需要，不要重组资源、场景或脚本。

完成时：

- 说明是否有飞书文档需要更新。
- 说明修改过哪些本地文档。
- 说明已完成的验证；如果无法验证，也要说明原因。
