# clash_for_win7

一个面向 Windows 7 的 Mihomo 轻量启动器，使用批处理和 PowerShell 管理内核、系统代理与订阅，并通过本机网页界面选择节点、测试延迟。

本项目不是原版 Clash for Windows，也不是 Mihomo 官方客户端。源码仓库提供启动脚本、配置模板和离线 UI，**不包含 Mihomo 内核、代理节点或订阅服务**。`v4.0.0` Release 压缩包附带 Mihomo 上游内核；实际能否在 Windows 7 上运行，取决于所用内核是否兼容该系统。

## Release 快速开始

1. 从 [v4.0.0 Release](https://github.com/happywosabi/clash_for_win7/releases/tag/v4.0.0) 下载 `Mihomo_Win7_Starter_v4_fixed.zip` 并解压到可写目录。压缩包内已包含名为 `mihomo.exe` 的内核，**无需再重命名或单独下载**。
2. 双击解压目录中的 `Start_Mihomo_Win7_v4.bat`。首次运行时，在命令行输入可被 Mihomo 作为 HTTP 代理提供者读取的订阅地址；脚本会生成本机 `config.yaml`。
3. 等待内核启动和订阅更新。浏览器会打开本机 UI；若未自动打开，请访问 **http://127.0.0.1:9090/ui/**。
4. 在 UI 中确认内核及系统代理状态，选择代理组节点。退出时点击“停止 Mihomo”，以便同时关闭系统代理。

订阅地址可能包含私密令牌，请勿上传 `config.yaml`。Release 内核的 Windows 7 兼容性尚未在所有环境中验证；若启动失败，请运行 `Diagnose_v4.bat` 并查看 `mihomo.log`。

## 功能

- 首次运行时输入订阅地址，自动生成本地 `config.yaml`。
- 启动 Mihomo 后，**每次启动主动更新 HTTP 类型的代理提供者**；模板中的提供者还会按配置周期更新。
- 在网页界面查看运行状态、选择代理组节点、手动更新订阅。
- 对单个节点或全部节点测试连接延迟，显示毫秒数及最近一次记录。
- 在网页界面启用或关闭当前用户的 Windows 系统代理，或关闭代理并停止 Mihomo 内核。
- 提供独立的停止脚本和诊断脚本。

## 运行要求

- Windows 7 电脑，以及与系统架构和 Windows 版本兼容的 `mihomo.exe`。Release 已包含一个内核；从源码使用时需自行准备。本项目的脚本以 Windows 7 x64 为目标，不要假定 Mihomo 的每个新版本都仍支持 Windows 7。
- 系统自带的 `cmd.exe`、Windows PowerShell 和可加载 `System.Web.Extensions` 的 .NET Framework 环境。
- 一个能被 Mihomo `proxy-providers` 作为 HTTP 提供者读取的 Clash/Mihomo 格式订阅地址。普通网页地址或其他客户端专用格式不能直接使用。
- 对项目目录的写入权限，以及修改当前用户 `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings` 的权限。
- 空闲的本机端口 `7890`、`9090`、`9091`，以及能访问本机网页的浏览器。启动脚本会优先尝试已安装的 360 浏览器，否则使用默认浏览器。

可以从 [Mihomo 官方发布页](https://github.com/MetaCubeX/mihomo/releases)获取内核；请自行核对所下载版本的 Windows 7 兼容性、架构及上游许可。

## 从源码使用

1. 下载或克隆本项目，将所有项目文件放在同一个目录。把自行获取的内核命名为 `mihomo.exe`，放在 `Start_Mihomo_Win7_v4.bat` 旁边。不要把内核放进 `ui` 或 `providers` 目录。
2. 双击 `Start_Mihomo_Win7_v4.bat`。第一次运行会在命令行提示输入订阅地址，并生成 `config.yaml`。订阅地址可能含有令牌，请勿公开。
3. 等待命令行出现 `Port 9090 is listening` 和 `API works without authentication`。脚本随后尝试更新订阅、启用系统代理，并打开本机 UI。
4. 如果浏览器没有自动打开，手动访问 **http://127.0.0.1:9090/ui/**。请使用这个精确地址，不要改成 `localhost`，否则网页中的本机控制功能可能无法使用。
5. 在 UI 中确认“内核”“系统代理”“控制服务”的状态，然后选择代理组中的节点。需要时使用“测速”或“全部测速”。

首次订阅获取需要网络。更新失败时启动流程仍会继续，你可以查看命令行提示、`mihomo.log`，或在 UI 的“订阅提供者”中再次点击“更新订阅”。

## 日常使用

| 操作 | 方法 | 说明 |
| --- | --- | --- |
| 启动 | 双击 `Start_Mihomo_Win7_v4.bat` | 启动前会结束系统中所有名为 `mihomo.exe` 的旧进程。不要同时运行其他同名 Mihomo 实例。 |
| 切换节点 | 在 UI 的代理组中选择节点或 `AUTO` | 模板中的 `PROXY` 组默认为主选择组，`AUTO` 为自动延迟优选组。 |
| 更新订阅 | 每次启动自动执行；也可点击“更新订阅” | 启动时只主动更新 HTTP 类型的代理提供者；失败不会阻止 UI 打开。 |
| 节点测速 | 点击节点旁的“测速”或“全部测速” | 使用 `https://www.gstatic.com/generate_204` 测连接延迟，超时为 5 秒；这**不是下载速度测试**。全部测速会分批并发执行。 |
| 关闭或重新启用系统代理 | 点击 UI 顶部对应按钮 | 只修改当前 Windows 用户的系统代理设置，不停止内核。某些应用不会遵循 Windows 系统代理。 |
| 正常退出 | 在 UI 中点击“停止 Mihomo”并确认 | 先关闭系统代理，再停止 Mihomo；本机控制服务也会退出。浏览器页面可以直接关闭。 |
| 应急停止 | 双击 `Stop_Mihomo.bat` | 结束所有名为 `mihomo.exe` 的进程，并尝试关闭系统代理。此脚本**不会主动结束** `Control_Server.ps1` 的 PowerShell 窗口；必要时关闭该窗口后再重新启动。 |
| 排查问题 | 双击 `Diagnose_v4.bat` | 显示配置关键项、端口状态、API 响应与 `mihomo.log`。分享输出前先检查是否包含敏感信息。 |

UI 是由 Mihomo 本机提供的静态页面，不依赖在线 UI 资源；订阅更新、节点测速和代理连接仍然需要相应的网络访问。

## 文件说明

```text
clash_for_win7/
├─ Start_Mihomo_Win7_v4.bat  # 主入口
├─ Stop_Mihomo.bat           # 应急停止
├─ Diagnose_v4.bat           # 诊断信息
├─ Prepare_Config.ps1        # 首次生成、后续修正控制器配置
├─ Update_Providers.ps1      # 启动时更新 HTTP 代理提供者
├─ Control_Server.ps1        # 供 UI 操作系统代理和内核的本机服务
├─ Run_Mihomo.cmd            # 实际启动内核并写入日志
├─ config.template.yaml      # 可公开的配置模板
├─ ui/index.html             # 本机网页界面
├─ providers/.keep           # 保留提供者缓存目录
├─ mihomo.exe                # 用户自行放入，不应提交
├─ config.yaml               # 首次运行生成，含私人订阅地址
├─ providers/pqjc.yaml       # Mihomo 下载的订阅缓存
├─ mihomo.log                # 内核运行日志
└─ control.log               # 控制服务出错时可能生成
```

树中最后五项是运行时文件或用户自行提供的文件，初始仓库不包含它们。

## 配置与工作原理

默认配置见 `config.template.yaml`：

| 设置 | 默认值 | 用途 |
| --- | --- | --- |
| `mixed-port` | `7890` | 本机 HTTP/SOCKS 混合代理端口，也是系统代理指向的端口。 |
| `external-controller` | `127.0.0.1:9090` | Mihomo API 和网页 UI 的本机端口。 |
| `secret` | 空字符串 | 本机 UI 使用无密钥 API；详见下方安全说明。 |
| `external-ui` | `./ui` | 使用项目自带 UI。 |
| 控制服务 | `127.0.0.1:9091` | PowerShell 服务，用于 UI 开关系统代理及停止内核。 |
| `proxy-providers.pqjc` | HTTP 提供者 | 首次输入的订阅地址会写入这里，缓存到 `providers/pqjc.yaml`。 |

每次启动时，`Prepare_Config.ps1` 都会把 `config.yaml` 中的 `external-controller`、`secret` 和 `external-ui` 调整为上述本机值，并禁用 `external-ui-url`。因此**不要依赖手工修改这些字段**；端口 `7890`、`9090`、`9091` 也写在多个脚本和 UI 中，仅改模板中的端口不能完成迁移。

需要更换订阅地址时，先关闭 Mihomo，再编辑本机 `config.yaml` 中 `proxy-providers.pqjc.url` 的值，保存后重新启动。若删除 `config.yaml`，下次启动会重新要求输入地址，并从模板创建新文件；原先对 `config.yaml` 的其他自定义修改不会保留。更多提供者配置参见 [Mihomo 官方文档](https://wiki.metacubex.one/en/config/proxy-providers/)。

启动顺序是：准备配置，结束旧内核，启动新内核并等待 API，通过 API 请求更新 HTTP 订阅，设置当前用户的系统代理，启动本机控制服务，最后打开 UI。模板还设置了提供者的 `interval: 3600`；这是 Mihomo 的周期更新设置，与本项目“每次启动主动更新”是两件事。

## 常见问题

### 提示找不到 `mihomo.exe`

确认文件名准确，且与 `Start_Mihomo_Win7_v4.bat` 位于同一目录。源码仓库不包含内核，`v4.0.0` Release 包含名为 `mihomo.exe` 的内核；还要确认内核版本可在你的 Windows 7 系统上运行。

### 内核没有监听 `127.0.0.1:9090`

运行 `Diagnose_v4.bat`，查看 `mihomo.log` 中的配置错误、核心兼容性或端口占用信息。也可以在命令提示符运行 `netstat -ano | findstr :9090` 检查端口。启动脚本会尝试结束旧的 `mihomo.exe`，但不会结束占用该端口的其他程序。

### 端口已监听，但 API 检查失败或提示需要认证

检查是否启动了另一份 Mihomo、是否打开了另一份项目目录，以及当前 `config.yaml` 的 `external-controller` 和 `secret`。本项目需要本机 `9090` 的 API 可在无密钥情况下访问，启动脚本会对 `/version` 做检查。不要把控制器开放给局域网或公网来绕过此问题。

### 系统拒绝创建 `ProxyServer`

UI 和启动脚本会提示这一错误。先检查安全软件的拦截记录与当前用户的注册表权限；确认程序来源可信后，可**临时关闭杀毒软件以排查**，重试启用系统代理，完成后立即重新开启防护。若电脑受组织策略管理，也可能是策略限制，不能简单归因于杀毒软件。代理启用失败时不要以为流量已接管，应以 UI 中的系统代理状态为准。

### 订阅更新失败或没有节点

检查订阅地址是否有效、是否能作为 Mihomo HTTP 代理提供者读取，以及本机能否访问订阅服务器。启动时更新失败只会出现警告，UI 仍会打开；在“订阅提供者”中可再次点击“更新订阅”。同时检查 `mihomo.log` 和本地 `providers` 目录。普通网页或不兼容的订阅格式不会自动转换。

### 节点测速显示失败、超时或很慢

测速请求需要节点能够访问默认测试地址 `https://www.gstatic.com/generate_204`。失败可能是节点、网络或测试地址不可达；显示的毫秒数是连接延迟，不代表带宽。全量测速时请等待全部节点完成。

### UI 显示旧页面或按钮不能用

先确认浏览器地址为 `http://127.0.0.1:9090/ui/`，而不是另一份项目目录对应的旧进程；启动脚本会给地址附加随机参数以减少缓存影响。仍显示旧页面时，可按 `Ctrl+F5` 强制刷新。如果界面提示“控制服务未连接”，检查 `9091` 端口是否被占用、PowerShell 是否被阻止，并查看 `control.log`。手动使用 `Stop_Mihomo.bat` 后，旧控制服务可能仍占用 `9091`。

### 停止后仍无法上网

确认 Windows 系统代理已关闭。可以重新运行 `Stop_Mihomo.bat`，或在 Windows 的 Internet 选项中检查当前用户的代理设置。若注册表写入受到拒绝，停止脚本不一定能成功修改代理状态。

## 安全与隐私

- `config.yaml` 含有订阅 URL，URL 可能自带账号令牌；`providers` 缓存和日志也可能暴露节点、地址或其他敏感信息。**不要把这些运行时文件上传到 GitHub，也不要在 Issue 中原样贴出日志。**本仓库提供 `.gitignore`，但如果文件已经被 Git 跟踪，忽略规则不会自动将其移除；上传前务必核对待提交文件。
- 为兼容本机 UI，脚本将 Mihomo API 设为无密钥，仅监听 `127.0.0.1:9090`；控制服务仅监听 `127.0.0.1:9091`。不要把这些地址改成 `0.0.0.0`、映射到公网，或通过其他方式开放给不可信设备。
- 启动和停止脚本按进程名处理**所有** `mihomo.exe`，不区分是否由本项目启动。与其他 Mihomo 客户端并用前请注意这一点。
- 系统代理只影响遵循 Windows 当前用户代理设置的应用；本项目没有安装驱动，也不保证接管所有程序的流量。

## Mihomo 上游许可证

Release 中的 `mihomo.exe` 属于 [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)，其 [上游许可证](https://github.com/MetaCubeX/mihomo/blob/main/LICENSE) 为 MIT。以下保留上游的完整版权及许可声明；它**仅适用于 Mihomo 上游软件**，不代表本项目脚本和 UI 已取得 MIT 授权。

```text
Copyright 2023 KT

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

## 开源发布前检查

- [ ] 补充明确的 `LICENSE` 文件，确定本项目代码的使用和再分发条件；当前仓库尚未声明开源许可证。
- [ ] 不提交 `mihomo.exe`，除非已核对 Mihomo 上游许可并明确发布方式。用户可以从上游自行下载内核。
- [ ] 确认 `config.yaml`、订阅缓存、日志和其他私人数据未被 Git 跟踪，也未进入任何待推送的历史提交。公开前检查 `git status` 与 `git ls-files`；已提交过的密钥应先撤销或轮换。
- [ ] 在目标 Windows 7 环境中按“快速开始”完整测试一次，并在发布说明中注明测试过的系统版本、浏览器和 Mihomo 内核版本。

项目名称 `clash_for_win7` 只用于描述用途；Mihomo 属于其各自的上游项目，相关商标和许可由权利人持有。
