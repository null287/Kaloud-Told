# Kaloud Told (柯唠叨)

**English** | [中文](README.zh.md)

> The only Windows toast-notification plugin for Claude Code that **auto-dismisses** itself.

A notification helper that "nags" you — once you make a decision, the notification clears itself. No clutter left behind.

## ✨ Why Kaloud Told

- 🎯 **Exclusive auto-dismiss**: After you hit Yes/No, answer a question, or a turn finishes, the notification **disappears on its own** — no manual cleanup. (Currently the only plugin doing this.)
- 🪶 **Lightweight, zero-dependency**: Pure PowerShell + native Windows WinRT. No extra runtime to install.
- 🪟 **Windows first-class**: Built for Windows, not a cross-platform afterthought.
- 🖱️ **Click to jump back**: Click the notification to jump back to your VS Code window.

## 🔔 Notification Types

| Notification | Triggers when |
|---|---|
| 🔐 Permission needed | A tool needs your approval (shows the tool name) |
| ✅ Task done | A turn finishes |
| ❓ Question | Claude asks you via AskUserQuestion |
| 📋 Plan ready | plan mode submits a plan for approval |
| ⏱️ Session limit | You hit the usage limit |
| 🔴 API error | An API error occurs (login expired / rate limit / server / connection) |

**All of them auto-dismiss.**

## 💻 Requirements

- **Windows 10 (1709+) or Windows 11**
- **PowerShell 5.1** (built into Windows, nothing to install)
- **FullLanguage mode** (the default on normal PCs; if AppLocker/WDAC locks PowerShell into ConstrainedLanguage, notifications won't fire)
- Works whether you run Claude Code in VS Code's integrated terminal, Windows Terminal, or the Claude desktop app

> ⚠️ Developed and tested on Windows 11; not yet tested across multiple machines. Issues / feedback welcome.

## 📦 Install

```
/plugin marketplace add null287/Kaloud-Told
/plugin install kaloud-told@kaloud-told
```

## 🏷️ About the Name

**Kaloud Told / 柯唠叨** — the author's surname is "Ke" (K), personifying Claude as a little helper that "nags" you:

- Chinese 「柯唠叨」 = Ke (surname) + 唠叨 (*nagging* — the essence of a notification) + a Chinese nickname for Claude
- English `Kaloud Told` = K (Ke) + *aloud* + *Told*, which sounds like "Claude"
- A bilingual pun: Ke = K, 唠叨 = aloud told

## 📄 License

MIT
