# URSim 安装脚本说明

## 一、概述
URSim 是 Universal Robots 公司提供的工业机器人仿真软件，用于离线编程和调试机器人应用。
本脚本实现一键式安装，自动完成系统检测、依赖安装、环境配置、服务部署及权限修复，最终生成桌面快捷方式，便于快速启动。  
⚠️ **注意**：  
- **32 位系统**：请参考 [URSim32 安装手册](ursim32.md)  
- **64 位系统**：请参考 [URSim64 安装手册](README.md)
- Ubuntu 18.04 官方不再支持 32 位系统，需确认 URSim 版本与系统架构匹配。

## 二、脚本功能特点
1. **多版本适配**：支持不同 Ubuntu 版本（如 24.04、22.04 及其他版本）的依赖安装。
2. **镜像源选择**：允许用户选择不同的镜像源（阿里云、清华大学、网易等）来加速软件下载。
3. **日志记录**：详细记录安装过程到日志文件，方便后续排查问题。
4. **用户交互**：在关键步骤提供确认提示，确保用户知晓操作并可选择是否继续。
5. **权限修复**：自动修复安装目录和文件的权限问题。

## 三、安装前准备
### 系统要求
- **操作系统**：Ubuntu 系统
- **Java 版本**：**必须使用 Java 8**（版本 1.8），脚本会自动检测并强制安装。
- **磁盘空间**：至少 2GB 可用空间（含安装包和运行时文件）。

### 其他要求
- 确保网络连接正常，以便下载安装包和依赖项。
- 建议以具有 sudo 权限的用户运行脚本。

## 四、使用方法
### 1. 下载脚本
将脚本保存为一个 `.sh` 文件，例如 `ursim64.sh`。

### 2. 赋予执行权限
```bash
chmod +x ursim64.sh
```

### 3. 运行脚本
```bash
sudo ./ursim64.sh
```

### 4. 配置选择
- 在运行过程中，脚本会提示你确认一些关键信息，如安装位置、镜像源等。你可以按 Enter 使用默认配置，或输入新的路径和选择。
- 对于 Java 环境，如果检测到不兼容的版本，脚本会提示你是否卸载并安装 Java 8。

- **Java 环境处理**：  
  ⚠️ **警告**：脚本会自动检测并卸载系统中不兼容的 Java 版本（非 1.8），**强制安装 Java 8**。  
  - 这可能影响其他依赖 Java 的应用程序（如 Maven、IntelliJ IDEA 等）。  
  - 建议提前备份 Java 环境或确认其他程序兼容性。  
  - 若需保留旧版本，可手动安装 Java 8 后再运行脚本。

### 5. 安装完成
安装完成后，脚本会输出安装摘要和后续操作提示，按照提示操作即可启动 URSim。

## 五、脚本配置说明
脚本中有一些可修改的配置项，你可以根据需要进行调整：

### 安装位置配置
```bash
URSIM_ROOT="${USER_HOME}/ursim-5.15.1.126626"  # URSim主安装目录
```

### 版本信息配置
```bash
VERSION="5.15.1.126626"                    # 要安装的URSim版本号
DOWNLOAD_URL="https://s3-eu-west-1.amazonaws.com/ur-support-site/215129/URSim_Linux-5.15.1.126626.tar.gz"
```

### 系统服务配置
```bash
SERVICE_NAME="ursim-daemon"                # 系统服务名称
```

### 日志文件配置
```bash
LOG_FILE="${USER_HOME}/ursim_install.log"      # 安装日志路径
RUN_LOG="${USER_HOME}/ursim_runtime.log"       # 运行日志路径
```

### Java 版本配置
```bash
JAVA_VERSION="8"                           # 要安装的Java版本
```
**注意**
必须使用 1.8 版本，这是根据相关论坛讨论得出的结论。
 * [在新的 Ubuntu 上安装 URSim 时参数不匹配](https://forum.universal-robots.com/t/parameter-mismatch-when-installing-ursim-on-fresh-ubuntu/2482)
 * [离线模拟器 - E 系列 - 适用于 LINUX 的 UR SIM 5.11.1 删除所有已安装的文件](https://forum.universal-robots.com/t/offline-simulator-e-series-ur-sim-for-linux-5-11-1-removes-all-installed-files/15384)


## 六、常见问题及解决方法
### 1. Java 安装失败
- **问题描述**：脚本在安装 Java 8 时出现错误。
- **解决方法**：检查网络连接，确保可以访问软件源。可以手动尝试使用 `sudo apt-get install -y openjdk-8-jdk openjdk-8-jre` 安装 Java 8。

### 2. 依赖安装失败
- **问题描述**：在安装系统依赖或 Java 3D 依赖时出现错误。
- **解决方法**：检查镜像源配置是否正确，尝试更换镜像源后重新运行脚本。也可以手动安装缺失的依赖项。

### 3. 桌面快捷方式无法启动
- **问题描述**：双击桌面快捷方式无法启动 URSim。
- **解决方法**：检查安装路径和权限是否正确，确保 `start-ursim.sh` 脚本具有执行权限。可以尝试手动在终端中运行该脚本。

## 7、参考下载链接

 * [最新技术资料](https://www.universal-robots.cn/technical-files/)
 * [旧版下载中心](https://www.universal-robots.com/articles/ur/documentation/legacy-download-center/)
