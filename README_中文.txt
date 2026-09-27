Mihomo Win7 Starter v4
=====================

v3 的错误：
-d "%~dp0"

%~dp0 在 Windows 中会得到：
E:\mihomo\

由于末尾反斜杠和引号组合，某些 Win7/cmd 参数解析会把后面的：
-f E:\mihomo\config.yaml
一起错误地解析成 -d 的路径。

v4 修复：
先执行：
cd /d "%~dp0"
set "ROOT=%CD%"

此时 ROOT 是：
E:\mihomo

没有末尾反斜杠。

实际运行命令：
"%ROOT%\mihomo.exe" -d "%ROOT%" -f "%ROOT%\config.yaml"

另外使用 Run_Mihomo.cmd 单独执行内核，避免 start/cmd /c 多层引号问题。

正常启动后应看到：
[OK] Port 9090 is listening.
HTTP 200
[OK] API works without authentication.

如果仍失败，请运行 Diagnose_v4.bat。

控制台操作
==========

运行 Start_Mihomo_Win7_v4.bat 后，浏览器会打开本地控制台。
界面可以切换代理组、更新订阅、关闭或重新启用系统代理，以及停止 Mihomo 内核。
“节点测速”显示每个订阅节点的延迟（毫秒），可以单独测试或点击“全部测速”。
每次运行启动脚本时，内核 API 就绪后会自动向 HTTP 订阅发起更新请求。
如果网络或订阅服务不可用，启动窗口会显示警告，控制台仍会打开。
停止内核时会先关闭系统代理，避免 Windows 继续使用已停止的代理端口。

控制按钮由 Control_Server.ps1 提供，只监听 127.0.0.1:9091。
如果界面显示“本机控制服务未连接”，请重新运行启动脚本。

如果 Windows 拒绝创建 ProxyServer 注册表值，启动窗口和控制台都会提示。
请暂时关闭杀毒软件，在界面点击“启用系统代理”重试，完成后重新开启杀毒软件。
