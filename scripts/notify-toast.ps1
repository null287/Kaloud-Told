param([string]$Type = "notify")

$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

# 加载 WinRT 类型（弹窗和撤回都要用）
try {
  [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
  [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
  [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] > $null
} catch {}

# 检测 API 错误（读 transcript 尾部的 isApiErrorMessage；返回 auth/rate/server/overload/空）
function Get-ApiErrorStatus {
  param([string]$transcriptPath)
  if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) { return '' }
  try { $lines = Get-Content $transcriptPath -Tail 50 -Encoding UTF8 -ErrorAction Stop } catch { return '' }
  $lastErr = $null
  foreach ($ln in $lines) {
    if ($ln -notmatch 'isApiErrorMessage') { continue }
    try { $m = $ln | ConvertFrom-Json } catch { continue }
    if ($m.isApiErrorMessage -eq $true) { $lastErr = $m }
  }
  if (-not $lastErr) { return '' }
  switch ("$($lastErr.error)") {
    'authentication_failed' { return 'auth' }
    'rate_limit'            { return 'rate' }
    'server_error'          { return 'server' }
    default                 { return 'overload' }
  }
}

# 读取 hook 通过 stdin 传入的 JSON（强制 UTF-8，否则含中文的数据会乱码导致解析失败）
$raw = ""
try {
  if ([Console]::IsInputRedirected) {
    $stdinStream = [Console]::OpenStandardInput()
    $stdinReader = New-Object System.IO.StreamReader($stdinStream, [System.Text.Encoding]::UTF8)
    $raw = $stdinReader.ReadToEnd()
    $stdinReader.Close()
  }
} catch {}

$ntype = ""; $msg = ""; $toolName = ""; $transcriptPath = ""; $lastAsstMsg = ""; $toolInput = $null; $cwd = ""
if ($raw) {
  try {
    $o = $raw | ConvertFrom-Json
    $ntype = "$($o.notification_type)"
    $msg = "$($o.message)"
    $toolName = "$($o.tool_name)"
    $transcriptPath = "$($o.transcript_path)"
    $lastAsstMsg = "$($o.last_assistant_message)"
    $toolInput = $o.tool_input
    $cwd = "$($o.cwd)"
  } catch {}
}

# 点击通知的跳转目标：动态用当前工作目录（cwd），取不到则用用户主目录（已脱敏，无硬编码路径）
$launchDir = if ($cwd) { $cwd } else { $env:USERPROFILE }
$launchUri = "vscode://file/" + ($launchDir -replace '\\','/')

# 通知分组：授权弹窗归 ccperm（按工具名区分，截断 16 字符防超限）；回合结束/状态/PreToolUse 弹窗归 ccstop
$permGroup = 'ccperm'
$stopGroup = 'ccstop'
$permTag = 'perm'
if ($toolName) {
  if ($toolName.Length -gt 16) { $permTag = $toolName.Substring(0, 16) } else { $permTag = $toolName }
}

# clearperm：你已对授权做出 Yes/No 决定后（或回答问题/批准计划后），撤回对应的常驻弹窗
if ($Type -eq "clearperm") {
  try { [Windows.UI.Notifications.ToastNotificationManager]::History.Remove($permTag, $permGroup, $appId) } catch {}
  try { [Windows.UI.Notifications.ToastNotificationManager]::History.Remove('pretool', $stopGroup, $appId) } catch {}
  exit 0
}

# clearall：你发新消息时触发，清掉所有还挂着的授权弹窗 + 状态/PreToolUse 弹窗
if ($Type -eq "clearall") {
  try { [Windows.UI.Notifications.ToastNotificationManager]::History.RemoveGroup($permGroup, $appId) } catch {}
  try { [Windows.UI.Notifications.ToastNotificationManager]::History.RemoveGroup($stopGroup, $appId) } catch {}
  exit 0
}

# 决定弹什么文案 + 标签
$tag = ""; $group = ""
if ($Type -eq "stop") {
  # 回合结束：先清残留授权弹窗；再按优先级判定 会话限制 > API错误 > 任务完成
  try { [Windows.UI.Notifications.ToastNotificationManager]::History.RemoveGroup($permGroup, $appId) } catch {}
  if ($lastAsstMsg -match "Session limit reached|reached your usage limit|out of free messages|approaching your usage limit") {
    $Title = "⏱️ 会话限制"; $Body = "用量到顶了，开新对话或等额度恢复"
  }
  else {
    $apiErr = Get-ApiErrorStatus $transcriptPath
    if ($apiErr -eq 'auth')       { $Title = "🔴 API 错误·登录失效"; $Body = "认证过期了，去终端跑 /login" }
    elseif ($apiErr -eq 'rate')   { $Title = "🔴 API 错误·限流"; $Body = "请求太频繁被限流，等会儿再试" }
    elseif ($apiErr -eq 'server') { $Title = "🔴 API 错误·服务器"; $Body = "Anthropic 服务器出错，稍后重试" }
    elseif ($apiErr -eq 'overload') { $Title = "🔴 API 错误"; $Body = "API 连接出错，稍后重试" }
    else { $Title = "✅ 任务完成"; $Body = "这一轮跑完了，回来看看" }
  }
  $tag = 'stop'; $group = $stopGroup
}
elseif ($Type -eq "permission") {
  # AskUserQuestion/ExitPlanMode 已由 PreToolUse 弹 ❓/📋，这里不重复弹授权（去重）
  if ($toolName -eq "AskUserQuestion" -or $toolName -eq "ExitPlanMode") { exit 0 }
  $Title = "🔐 需要授权"
  if ($toolName) { $Body = "$toolName 工具要你批准，去终端按 Yes / No" }
  else { $Body = "有操作要你批准，去终端按 Yes / No" }
  $tag = $permTag; $group = $permGroup
}
elseif ($Type -eq "pretool") {
  # 来自 PreToolUse hook：AskUserQuestion / ExitPlanMode
  if ($toolName -eq "AskUserQuestion") {
    $Title = "❓ 有问题"
    $q = ""
    try { $q = "$($toolInput.questions[0].question)" } catch {}
    if ($q) { $Body = $q } else { $Body = "Claude 有问题要问你，去终端看看" }
  }
  elseif ($toolName -eq "ExitPlanMode") {
    $Title = "📋 计划就绪"
    $plan = ""
    try { $plan = "$($toolInput.plan)" } catch {}
    $firstLine = ""
    if ($plan) { $firstLine = ($plan -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1) }
    if ($firstLine) { $Body = "$firstLine".Trim() } else { $Body = "计划做好了，等你批准" }
  }
  else { exit 0 }
  $tag = 'pretool'; $group = $stopGroup
}
else {
  # 来自 Notification hook：兜底其他未知通知
  if ($ntype -eq "permission_prompt" -or $ntype -eq "idle_prompt" -or $ntype -eq "auth_success" -or $msg -match "waiting for your input") { exit 0 }
  $Title = "🔔 需要你"; $Body = "Claude 在找你，点我跳回 VS Code"
}

# 文案过长截断（问题/计划全文可能很长）
if ($Body -and $Body.Length -gt 80) { $Body = $Body.Substring(0, 80) + "…" }

# 弹 Windows Toast（务必 exit 0，绝不 exit 2，否则会拒绝授权）
try {
  $t = [System.Security.SecurityElement]::Escape($Title)
  $m = [System.Security.SecurityElement]::Escape($Body)
  $lu = [System.Security.SecurityElement]::Escape($launchUri)
  $xml = '<toast scenario="reminder" launch="' + $lu + '" activationType="protocol"><visual><binding template="ToastGeneric"><text>' + $t + '</text><text>' + $m + '</text></binding></visual><audio src="ms-winsoundevent:Notification.Default"/><actions><action activationType="system" arguments="dismiss" content="知道了"/></actions></toast>'
  $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
  $doc.LoadXml($xml)
  $toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
  if ($tag) { $toast.Tag = $tag }
  if ($group) { $toast.Group = $group }
  [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
} catch {}
exit 0
