# Lubuntu 14.04 LTS 升级到 Ubuntu 18.04 LTS 指南

## 一、风险提示
⚠️ **重要警告**：  
- 直接从 14.04 升级到 18.04 可能失败，需分两步完成：**14.04 → 16.04 → 18.04**。  
- 升级前请备份所有重要数据！  
- 本指南适用于 VMware 虚拟机环境，物理机操作需谨慎。


## 二、升级前准备
### 1. 下载配置
```bash
# 下载 URSim 虚拟机镜像（需登录）
链接：https://s3-eu-west-1.amazonaws.com/ur-support-site/215130/URSim_VIRTUAL-5.15.1.126626.rar  
用户名：ur  
密码：easybot
```

### 2. 虚拟机配置
- **硬件要求**：
  - 内存：16GB  
  - 处理器：4×4 核心  
  - 硬盘：120GB  
  - 网络适配器：NAT  
  - 显示：开启 3D 图形加速（8GB）  
- **VMware Tools**：
  - 启用时间同步和自动更新。

### 3. 终端操作技巧
- **粘贴**：在终端中使用 `Ctrl + Shift + V` 或鼠标中键。  
- **乱码修复**：  
  ```bash
  export LANG=en_US.UTF-8
  ```


## 三、系统升级流程

### 1. 升级到 Lubuntu 16.04 LTS（Xenial）
#### 1.1 调整软件源
```bash
sudo sed -i 's/trusty/xenial/g' /etc/apt/sources.list
sudo apt update
```

#### 1.2 执行系统升级
```bash
sudo apt dist-upgrade -y
sudo do-release-upgrade
```

### 2. 升级到 Ubuntu 18.04 LTS（Bionic）
#### 2.1 调整软件源
```bash
sudo sed -i 's/xenial/bionic/g' /etc/apt/sources.list
sudo apt update
```

#### 2.2 执行系统升级
```bash
sudo apt dist-upgrade -y
sudo do-release-upgrade
```


## 四、桌面环境迁移
### 1. 安装 Ubuntu 桌面
```bash
sudo apt install ubuntu-desktop
sudo apt install gdm  # 选择 GDM 作为登录管理器
```

### 2. 卸载 Lubuntu 残留
```bash
sudo apt remove --purge lubuntu-desktop -y
sudo apt autoremove -y
sudo apt clean
```

### 3. 验证卸载结果
```bash
dpkg -l | grep lubuntu  # 检查是否有残留包
```


## 五、系统配置优化
### 1. 语言与输入法设置
#### 1.1 安装中文支持
```bash
sudo apt install language-pack-zh-hans language-pack-gnome-zh-hans
```

#### 1.2 配置系统语言
```bash
sudo update-locale LANG=zh_CN.UTF-8 LC_TIME=zh_CN.UTF-8 LC_MONETARY=zh_CN.UTF-8
sudo timedatectl set-timezone Asia/Shanghai
```

#### 1.3 安装输入法
```bash
sudo apt install fcitx fcitx-pinyin fcitx-config-gtk
im-config -n fcitx
```

#### 1.4 配置环境变量
```bash
echo 'export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx' >> ~/.profile
source ~/.profile
```

### 2. 自动登录配置
```bash
sudo mkdir /etc/gdm3
sudo nano /etc/gdm3/custom.conf
```
```conf
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = ur  
```
```bash
sudo systemctl restart gdm3
```


## 六、URSim 环境配置（附录）
### 1. 控制器检测
1. 确认安全配置：`汉堡菜单 > Settings > 中文版 > Apply and Restart`。  
2. 导入 Robotiq 夹具：将文件从 `/tmp/VMwareDnD/` 拖入 URSim。

### 2. 程序运行
```bash
# 示例程序路径
/tmp/VMwareDnD/20245500285/Demos/balloon/20240830_balloon.urp
```


## 七、常见问题处理
### 1. 无法登录图形界面
```bash
# 进入命令行界面
Ctrl + Alt + F1
# 修复依赖
sudo apt install -f
# 重启 GDM3
sudo systemctl restart gdm3
```

### 2. 32 位系统兼容性
⚠️ **注意**：  
- **32 位系统**：请使用 [URSim32 安装手册]  
- **64 位系统**：请使用 `ursim64.sh` 脚本  
- Ubuntu 18.04 官方不再支持 32 位系统，需确认 URSim 版本与系统架构匹配。

## 八、系统优化建议
```bash
# 安装图形化工具
sudo apt install gdebi synaptic gnome-tweaks gnome-shell-extensions

# 清理旧内核
sudo apt autoremove --purge linux-image-`uname -r`
```


## 九、验证升级结果
```bash
# 检查系统版本
lsb_release -a

# 检查内核版本
uname -r
```