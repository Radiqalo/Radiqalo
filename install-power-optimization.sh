#!/bin/bash

# Arch Linux电源优化快速安装脚本
# 适用于机械革命耀世16u笔记本电脑
# 使用前请仔细阅读 arch-linux-power-optimization.md

set -e

echo "=========================================="
echo "Arch Linux 电源优化安装脚本"
echo "机械革命耀世16u"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否以root运行
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}请不要以root用户运行此脚本${NC}"
    echo "脚本会在需要时提示输入sudo密码"
    exit 1
fi

echo -e "${YELLOW}此脚本将安装和配置以下工具：${NC}"
echo "1. TLP - 电源管理"
echo "2. PowerTOP - 电源监控"
echo "3. acpi - 电池信息"
echo ""
echo -e "${YELLOW}注意：此脚本会修改系统配置${NC}"
read -p "是否继续？(y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "安装已取消"
    exit 1
fi

echo ""
echo "=========================================="
echo "步骤 1/5: 更新系统包数据库"
echo "=========================================="
sudo pacman -Sy

echo ""
echo "=========================================="
echo "步骤 2/5: 安装电源管理工具"
echo "=========================================="
echo "安装 TLP, PowerTOP 和 ACPI..."
sudo pacman -S --needed --noconfirm tlp tlp-rdw powertop acpi

echo ""
echo "=========================================="
echo "步骤 3/5: 禁用冲突的服务"
echo "=========================================="
echo "禁用 systemd-rfkill 服务以避免与TLP冲突..."
if sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>&1 | grep -q "Created symlink"; then
    echo -e "${GREEN}成功禁用systemd-rfkill服务${NC}"
else
    echo -e "${YELLOW}systemd-rfkill服务可能已被禁用或不存在${NC}"
fi

echo ""
echo "=========================================="
echo "步骤 4/5: 配置TLP"
echo "=========================================="
if [ -f "tlp-recommended.conf" ]; then
    echo "发现推荐的TLP配置文件"
    read -p "是否应用推荐配置？(y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo mkdir -p /etc/tlp.d
        sudo cp tlp-recommended.conf /etc/tlp.d/01-custom.conf
        echo -e "${GREEN}TLP配置已应用到 /etc/tlp.d/01-custom.conf${NC}"
    fi
else
    echo -e "${YELLOW}未找到 tlp-recommended.conf，将使用TLP默认配置${NC}"
fi

echo ""
echo "=========================================="
echo "步骤 5/5: 启用并启动TLP服务"
echo "=========================================="
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo -e "${GREEN}电源管理工具已成功安装并配置${NC}"
echo ""
echo "建议的后续步骤："
echo ""
echo "1. 重启系统以确保所有设置生效："
echo "   sudo reboot"
echo ""
echo "2. 重启后，检查TLP状态："
echo "   sudo tlp-stat -s"
echo ""
echo "3. 查看电池信息："
echo "   acpi -V"
echo "   sudo tlp-stat -b"
echo ""
echo "4. 运行PowerTOP查看电源使用情况："
echo "   sudo powertop"
echo ""
echo "5. （可选）运行PowerTOP校准（需要30分钟，接电运行）："
echo "   sudo powertop --calibrate"
echo ""
echo "6. 监控实时功耗："
echo "   watch -n 2 'acpi -V'"
echo ""
echo "详细文档请参考: arch-linux-power-optimization.md"
echo ""

# 显示当前电池状态
echo "=========================================="
echo "当前电池状态："
echo "=========================================="
acpi -V 2>/dev/null || echo "无法获取电池信息"
echo ""

# 显示TLP版本
echo "TLP版本："
tlp-stat -s | grep "TLP" | head -1 || echo "TLP状态检查失败"
echo ""

echo -e "${GREEN}脚本执行完毕！${NC}"
