#!/bin/bash

#声明
copyright_message=$(cat << EOF
===========================================================
    本脚本用于在 Ubuntu 系统上安装 URSim 仿真软件
===========================================================
EOF
)

# 获取原始用户
ORIGINAL_USER="${SUDO_USER:-$(whoami)}"

# 获取原始用户的主目录
USER_HOME=$(getent passwd "$ORIGINAL_USER" | awk -F: '{print $6}')

# 桌面路径
case "$LANG" in
    zh_CN.UTF-8|zh_CN|zh*)
        DESKTOP_PATH="${USER_HOME}/桌面"
        ;;
    *)
        DESKTOP_PATH="${USER_HOME}/Desktop"
        ;;
esac

# =============== 用户可修改配置区域 ===============
# 安装位置配置
URSIM_ROOT="${USER_HOME}/ursim-5.15.1.126626"  # URSim主安装目录

# 版本信息配置
VERSION="5.15.1.126626"                    # 要安装的URSim版本号
DOWNLOAD_URL="https://s3-eu-west-1.amazonaws.com/ur-support-site/215129/URSim_Linux-5.15.1.126626.tar.gz"

# 系统服务配置
SERVICE_NAME="ursim-daemon"                # 系统服务名称

# 高级设置（无特殊需要不建议修改）
LOG_FILE="${USER_HOME}/ursim_install.log"      # 安装日志路径
RUN_LOG="${USER_HOME}/ursim_runtime.log"       # 运行日志路径
JAVA_VERSION="8"                           # 要安装的Java版本
# =============== 配置结束 ===============

# 初始化日志系统
exec > >(tee -a "${LOG_FILE}") 2>&1
echo "===== $(date) 安装日志开始 ====="

# 功能：打印带有蓝色样式的标题信息，用于提示操作阶段
print_header() {
    echo -e "\n\033[1;36m===== $1 =====\033[0m"
}

# 功能：打印带有黄色样式的警告信息
print_warning() {
    echo -e "\033[1;33m$1\033[0m"
}

# 功能：打印带有绿色样式的成功信息
print_success() {
    echo -e "\033[1;32m$1\033[0m"
}

# 功能：打印声明
print_success "$copyright_message"


# 函数：检查命令执行结果
check_command() {
    if [ $? -ne 0 ]; then
        echo -e "\033[1;31m错误：$1 失败！\033[0m"
        echo "详细信息请查看 ${LOG_FILE}"
        exit 1
    fi
}

# 函数：用户确认
user_confirm() {
    local prompt="$1 [Y/n] "
    while true; do
        read -p "$prompt" answer
        case "$answer" in
            [Yy]|"" ) return 0 ;;
            [Nn] ) return 1 ;;
            * ) echo "请输入 Y 或 N" ;;
        esac
    done
}


# 函数：Java版本
print_java_version() {
    echo -e "\n当前Java版本："
    local java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    if [ -z "$java_version" ]; then
        echo "未安装 Java"
    else
        echo "$java_version"
    fi
}

# 函数：显示系统信息
show_system_info() {
    print_header "系统信息检查"

    # 基础系统信息
    echo "操作系统版本："
    lsb_release -a
    echo -e "\n系统架构：$(uname -m)"

    # 硬件信息
    echo -e "\n处理器信息:"
    echo "$(lscpu | grep -E 'Model name|Socket|CPU\(s\)' | sed 's/^[ \t]*//')"
    echo "- 内存总量: $(grep MemTotal /proc/meminfo | awk '{print $2/1024 " MB"}')"
    echo "- 磁盘空间: $(df -h / | awk 'NR==2 {print $4}') 可用"

    output=$(print_java_version)
    print_warning "$output"
}

# 函数：处理Java环境
setup_java() {
    print_header "配置Java环境"
    # 检测当前Java版本
    echo -n "正在检测Java版本..."
    CURRENT_JAVA=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    [ -z "$CURRENT_JAVA" ] && CURRENT_JAVA="未安装"
    echo " [当前版本: ${CURRENT_JAVA}]"

    # 卸载冲突的Java版本
    if [[ "$CURRENT_JAVA" != *"1.8"* ]]; then
        print_warning "检测到不兼容的Java版本，即将卸载并安装Java ${JAVA_VERSION}"
        user_confirm "是否继续？" || exit 1

        echo -n "正在卸载旧Java环境..."
        sudo apt-get purge -y openjdk-* &>> "${LOG_FILE}"
        sudo apt-get autoremove -y &>> "${LOG_FILE}"
        echo " [完成]"

        # 安装指定版本Java
        echo -n "正在安装Java 8..."
        sudo apt-get install -y openjdk-${JAVA_VERSION}-jdk openjdk-${JAVA_VERSION}-jre &>> "${LOG_FILE}"
        check_command "Java环境安装"

        # 设置默认Java
        sudo update-alternatives --set java /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64/jre/bin/java
        sudo update-alternatives --set javac /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64/bin/javac
        echo " [完成]"
    else
        print_success "Java 1.8 已存在"
    fi
    output=$(print_java_version)
    print_warning "$output"
}

# 预显示关键信息
print_header "URSim 安装提示"
echo "请确认以下信息："
echo "-------------------------------------"
echo "安装包下载地址：${DOWNLOAD_URL}"
echo "默认安装位置：${URSIM_ROOT}"
echo "安装包存储位置：${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz"
echo "-------------------------------------"
echo "按 Enter 使用默认配置，或输入新路径"

read -p "新安装位置（当前：${URSIM_ROOT}）：" new_path
[ -n "$new_path" ] && URSIM_ROOT="$new_path"

# 主安装流程
print_header "URSim 安装程序 v5.15"
show_system_info

# 用户确认
user_confirm "确认系统信息正确并继续安装？" || exit 0

# 预检查：安装包处理
print_header "安装包检查"
echo "您可以手动下载安装包："
echo "${DOWNLOAD_URL}"
echo "并放置于：${DESKTOP_PATH}"

SKIP_DOWNLOAD=0
if [ -f "${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz" ]; then
    print_success "检测到已存在安装包"
    user_confirm "是否跳过下载？" && SKIP_DOWNLOAD=1
fi

# 镜像源配置
print_header "镜像源配置"
echo "请选择镜像源："
echo "0. 不修改源（默认）"
echo "1. 阿里云源"
echo "2. 清华大学源"
echo "3. 网易源"
print_warning "Ubuntu 24 LTS 请使用清华大学源 2"
read -p "输入序号 ：" choice
case $choice in
    1) MIRROR_SOURCE="https://mirrors.aliyun.com/ubuntu/" ;;
    2) MIRROR_SOURCE="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/" ;;
    3) MIRROR_SOURCE="https://mirrors.163.com/ubuntu/" ;;
    0|"") MIRROR_SOURCE="" ;;
    *) MIRROR_SOURCE="" ;;
esac

if [ -n "$MIRROR_SOURCE" ]; then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    UBUNTU_CODENAME=$(lsb_release -cs)
    cat <<EOF | sudo tee /etc/apt/sources.list >/dev/null
deb ${MIRROR_SOURCE} ${UBUNTU_CODENAME} main restricted universe multiverse
deb ${MIRROR_SOURCE} ${UBUNTU_CODENAME}-updates main restricted universe multiverse
deb ${MIRROR_SOURCE} ${UBUNTU_CODENAME}-backports main restricted universe multiverse
deb ${MIRROR_SOURCE} ${UBUNTU_CODENAME}-security main restricted universe multiverse
EOF
    sudo apt update
fi

# 步骤 0：安装必要依赖（多版本适配）
print_header "安装系统依赖"
echo "正在配置多架构支持..."
sudo dpkg --add-architecture i386
sudo apt-get update -y

UBUNTU_VERSION=$(lsb_release -rs)
echo "检测到 Ubuntu ${UBUNTU_VERSION}"

UBUNTU_SPECIFIC_DEPS=""
if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    UBUNTU_SPECIFIC_DEPS="libcurl3:i386 libgl1:i386 libegl1:i386 libglvnd0:i386"
    print_header "==================== 开始安装 Ubuntu ${UBUNTU_VERSION} LTS 依赖 ========================"
else
    UBUNTU_SPECIFIC_DEPS="libcurl4:i386 libgl1-mesa-glx:i386 libjava3d-*"
    print_header "==================== 开始安装 Ubuntu ${UBUNTU_VERSION} LTS 依赖 ========================"
fi

sudo apt-get install -y \
    axel \
    $UBUNTU_SPECIFIC_DEPS \
    libxcb-xtest0:i386 \
    libxcb-keysyms1:i386 \
    libxcb-image0:i386 \
    xterm \
    runit \
    fonts-dejavu \
    fonts-ipafont \
    lib32gcc-s1 \
    lib32stdc++6 \
    libc6-i386 \
    libxtst6:i386 \
    libxrender1:i386 \
    libxxf86vm1:i386 \
    libxi6:i386 \
    libglu1-mesa:i386

if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    print_header "==================== 完成安装 Ubuntu ${UBUNTU_VERSION} LTS 依赖 ========================"
else
    print_header "==================== 完成安装 Ubuntu ${UBUNTU_VERSION} LTS 依赖 ========================"
fi

check_command "依赖安装"

# Java 3D依赖特殊处理
print_header "安装Java 3D依赖"
# 检查 apt 是否能找到 libjava3d-java 和 libjava3d-jni
if apt-cache policy libjava3d-java libjava3d-jni | grep -q 'Installed: (none)' && apt-cache policy libjava3d-java libjava3d-jni | grep -q 'Candidate: (none)'; then
    print_warning "软件源中未找到 Java 3D 依赖，尝试下载 .deb 包安装..."
    # 确保镜像源路径以 / 结尾
    if [ -n "$MIRROR_SOURCE" ] && [ "${MIRROR_SOURCE: -1}" != "/" ]; then
        MIRROR_SOURCE="${MIRROR_SOURCE}/"
    fi
    wget "${MIRROR_SOURCE}pool/universe/j/java3d/libjava3d-java_1.5.2+dfsg-18build1_all.deb"
    check_command "下载 libjava3d-java.deb"
    wget "${MIRROR_SOURCE}pool/universe/j/java3d/libjava3d-jni_1.5.2+dfsg-18build1_amd64.deb"
    check_command "下载 libjava3d-jni.deb"
    sudo dpkg -i libjava3d-*.deb || sudo apt-get install -f -y
    if [ $? -ne 0 ]; then
        print_warning "通过下载 .deb 包安装 Java 3D 依赖失败，安装终止。"
        exit 1
    else
        sudo apt-get install -f -y  # 解决依赖问题
        check_command "修复 Java 3D 依赖安装"
    fi
    # 清理下载的 .deb 包文件
    rm -f libjava3d-java_1.5.2+dfsg-18build1_all.deb libjava3d-jni_1.5.2+dfsg-18build1_amd64.deb
else
    # 软件源中能找到，直接使用 apt 安装
    sudo apt install -y libjava3d-java libjava3d-jni
    check_command "使用 apt 安装 Java 3D 依赖"
fi

# 配置Java环境
setup_java

# 步骤 2：下载安装包
if [ $SKIP_DOWNLOAD -eq 0 ]; then
    print_header "下载安装包"
    if command -v axel &>/dev/null; then
        axel -n 5 -o "${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz" "${DOWNLOAD_URL}"
    else
        wget -O "${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz" "${DOWNLOAD_URL}"
    fi
    check_command "安装包下载"
fi

# 步骤 3：解压安装包
print_header "解压安装文件"
sudo mkdir -p "${URSIM_ROOT}"
sudo tar -zxvf "${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz" -C "${USER_HOME}" &>> "${LOG_FILE}"
sudo chown -R ${ORIGINAL_USER}:${ORIGINAL_USER} "${URSIM_ROOT}"  # 修复权限问题
check_command "解压安装包"

# 步骤 4：安装守护进程
print_header "服务配置"
sudo mkdir -p "${URSIM_ROOT}/service" /etc/service
cat <<EOF | sudo tee "/etc/runit/runsvdir-${SERVICE_NAME}/run" >/dev/null
#!/bin/sh
exec 2>&1
exec chpst -u$(whoami) runsvdir ${URSIM_ROOT}/service
EOF
sudo chmod +x "/etc/runit/runsvdir-${SERVICE_NAME}/run"
sudo ln -sf "/etc/runit/runsvdir-${SERVICE_NAME}" /etc/service/
check_command "服务配置"

# 步骤 5：安装运行时库
print_header "安装运行时库"
sudo mkdir -p /usr/local/urcontrol
sudo cp -R "${URSIM_ROOT}/runtime" /usr/local/urcontrol/
sudo chown -R ${ORIGINAL_USER}:${ORIGINAL_USER} /usr/local/urcontrol
check_command "运行时库安装"

# 启动脚本修复
print_header "启动脚本优化"
START_SCRIPT="${URSIM_ROOT}/start-ursim.sh"
sudo sed -i "2i export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\nexport LD_LIBRARY_PATH=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server" "${START_SCRIPT}"

# 创建桌面快捷方式 (仅UR5)
print_header "创建快捷方式"
DESKTOP_FILE="${DESKTOP_PATH}/ursim-${VERSION}.UR5.desktop"
cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Version=${VERSION}
Type=Application
Terminal=false
Name=URSim ${VERSION} UR5
Exec=${URSIM_ROOT}/start-ursim.sh UR5
Icon=${URSIM_ROOT}/ursim-icon.png
EOF
sudo chown ${ORIGINAL_USER}:${ORIGINAL_USER} "${DESKTOP_FILE}"
chmod +x "${DESKTOP_FILE}"

# 权限修复
print_header "修复权限"

# 修改用户主目录及其子目录和文件的所有权
echo "正在修改用户主目录 ${USER_HOME} 的所有权为 ${ORIGINAL_USER}:${ORIGINAL_USER}..."
if sudo chown -R "$ORIGINAL_USER:$ORIGINAL_USER" "${USER_HOME}"; then
    print_success "用户主目录 ${USER_HOME} 的所有权修改成功。"
else
    print_warning "修改用户主目录 ${USER_HOME} 的所有权失败，请检查日志文件 ${LOG_FILE} 获取详细信息。"
fi

# 修改 URSim 安装目录下所有文件的权限
echo "正在修改 URSim 安装目录 ${URSIM_ROOT} 下所有文件的权限为 755..."
if sudo find "${URSIM_ROOT}" -type f -exec chmod 755 {} \; ; then
    print_success "URSim 安装目录 ${URSIM_ROOT} 下所有文件的权限修改成功。"
else
    print_warning "修改 URSim 安装目录 ${URSIM_ROOT} 下所有文件的权限失败，请检查日志文件 ${LOG_FILE} 获取详细信息。"
fi

# 清理安装包
print_header "清理安装包"
rm -f "${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz"

# 最终检查
print_header "安装验证"
echo "关键组件检查："
[ -f "${URSIM_ROOT}/URControl" ] && echo "✓ URControl 存在" || echo "✗ URControl 缺失"
[ -f "/usr/lib/jvm/java-8-openjdk-amd64/bin/java" ] && echo "✓ Java 8 已安装" || echo "✗ Java 8 未安装"
glxinfo | grep "OpenGL version" && echo "✓ OpenGL 可用" || echo "✗ OpenGL 不可用"

# 安装摘要
print_header "安装摘要"
echo "已执行的操作记录："
grep -E 'install|remove|mkdir|chown' "${LOG_FILE}" | tail -n 20
echo "-------------------------------------"
echo "已创建目录：${URSIM_ROOT}"
echo "已下载文件：${DESKTOP_PATH}/URSim_Linux-${VERSION}.tar.gz（安装后已自动删除）"

# 完成提示
print_success "\n安装完成！请按以下步骤操作："
if [[ "$UBUNTU_VERSION" == "24.04" ]]; then
    echo "1. 右击桌面图标选择'允许运行'"
    echo "2. 双击启动URSim"
    echo "3. 首次启动可能需要3-5分钟加载时间"
    echo "4. 查看实时日志：tail -f ${RUN_LOG}"
else
    echo "1. 在桌面找到 'ursim-${VERSION}.UR5' 图标"
    echo "2. 右击选择'允许运行'"
    echo "3. 双击启动仿真器"
    echo "4. 如需重启请手动执行：sudo reboot"
fi

echo -e "请检查以下重要信息："
echo "-------------------------------------"
echo "主程序路径：${URSIM_ROOT}"
echo "桌面快捷方式：${DESKTOP_FILE}"
echo "运行时日志：${RUN_LOG}"
echo "-------------------------------------"

echo "===== $(date '+%Y-%m-%d %H:%M:%S') 安装日志结束 ====="
exit 0