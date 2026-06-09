# Kaloud Told（柯唠叨）

> 唯一带「自动撤回」的 Windows Claude Code 桌面通知插件。
> The only Windows toast-notification plugin for Claude Code that **auto-dismisses** itself.

一个会"唠叨"提醒你的 Claude 通知小助手——做完决定，通知自己消失，不留堆积。

## ✨ 为什么是它（差异化）

- 🎯 **独家「自动撤回」**：你按完 Yes/No、回答完问题、或一轮跑完后，通知会**自动消失**，不用手动清（目前全赛道独此一家）
- 🪶 **轻量零依赖**：纯 PowerShell + Windows 原生 WinRT，不装任何额外运行时
- 🪟 **Windows 一等公民**：专为 Windows 打造，不是跨平台工具的附属
- 🖱️ **点击跳转**：点通知跳回你正在工作的 VS Code 窗口

## 🔔 支持的通知

| 通知 | 何时触发 |
|---|---|
| 🔐 需要授权 | 工具要你批准时（显示具体工具名）|
| ✅ 任务完成 | 一轮对话跑完 |
| ❓ 有问题 | Claude 用 AskUserQuestion 问你时 |
| 📋 计划就绪 | plan mode 提交计划、等你批准时 |
| ⏱️ 会话限制 | 撞到用量上限 |
| 🔴 API 错误 | API 报错（细分：登录失效 / 限流 / 服务器 / 连接）|

**全部通知都带「自动撤回」。**

## 💻 环境要求

- **Windows 10 (1709+) 或 Windows 11**
- **PowerShell 5.1**（Windows 自带，无需安装）
- **FullLanguage 模式**（普通家用电脑默认就是；若企业 AppLocker/WDAC 把 PowerShell 锁成 ConstrainedLanguage，则弹不出通知）
- 在 VS Code 集成终端 / Windows Terminal / Claude 桌面 App 里跑 Claude Code 都支持

> ⚠️ 开发与测试于 Windows 11，尚未在多台机器验证。遇到问题欢迎提 issue 反馈。

## 📦 安装

```
/plugin marketplace add <你的GitHub用户名>/kaloud-told
/plugin install kaloud-told@kaloud-told
```

## 🏷️ 名字由来

**Kaloud Told / 柯唠叨**——作者姓"柯"(K)，把 Claude 拟人成一个会"唠叨提醒你"的小助手：

- 中文「柯唠叨」= 柯（姓）+ 唠叨（通知的本质，就是唠叨提醒你一声）+ 给 Claude 起的中文名
- 英文 `Kaloud Told` = K(柯) + aloud(出声) + Told(告知)，整体谐音 Claude
- 中英双关：柯 = K、唠叨 = aloud told

## 📄 License

MIT
