# Arch Linux 电源优化指南 - 机械革命耀世16u

本指南专门针对机械革命耀世16u笔记本电脑在Arch Linux系统下的电源优化配置，帮助降低拔电后的功耗。

## 目录
1. [安装必要的电源管理工具](#安装必要的电源管理工具)
2. [TLP配置（推荐）](#tlp配置推荐)
3. [CPU调频优化](#cpu调频优化)
4. [显卡电源管理](#显卡电源管理)
5. [显示屏和背光优化](#显示屏和背光优化)
6. [USB设备电源管理](#usb设备电源管理)
7. [无线设备省电](#无线设备省电)
8. [其他优化建议](#其他优化建议)
9. [监控和测试](#监控和测试)

## 安装必要的电源管理工具

首先安装基础的电源管理工具：

```bash
# 安装TLP（推荐的电源管理工具）
sudo pacman -S tlp tlp-rdw

# 如果使用ThinkPad，额外安装（耀世16u可跳过）
# sudo pacman -S tp_smapi acpi_call

# 安装电源监控工具
sudo pacman -S powertop acpi

# 启用并启动TLP服务
sudo systemctl enable tlp.service
sudo systemctl start tlp.service

# 确保其他电源管理服务被禁用（避免冲突）
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
```

## TLP配置（推荐）

TLP是最简单有效的电源管理解决方案。编辑配置文件：

```bash
sudo nano /etc/tlp.conf
```

### 推荐的TLP配置项

```conf
# CPU调频设置
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# CPU能耗/性能策略（Intel第6代及更新）
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# CPU最小/最大频率
CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=30

# CPU Boost（关闭可省电但降低性能）
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# 平台配置文件
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# 磁盘设备
DISK_DEVICES="nvme0n1"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# SATA链接电源管理
SATA_LINKPWR_ON_AC="max_performance"
SATA_LINKPWR_ON_BAT="min_power"

# PCI Express主动状态电源管理
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave

# 显卡电源管理（针对Intel核显）
INTEL_GPU_MIN_FREQ_ON_AC=0
INTEL_GPU_MIN_FREQ_ON_BAT=0
INTEL_GPU_MAX_FREQ_ON_AC=0
INTEL_GPU_MAX_FREQ_ON_BAT=0
INTEL_GPU_BOOST_FREQ_ON_AC=0
INTEL_GPU_BOOST_FREQ_ON_BAT=0

# 无线电设备开关
DEVICES_TO_DISABLE_ON_STARTUP=""
DEVICES_TO_ENABLE_ON_STARTUP="wifi bluetooth"
DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE="bluetooth"

# WiFi省电模式
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# 音频省电
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1
SOUND_POWER_SAVE_CONTROLLER=Y

# USB自动挂起
USB_AUTOSUSPEND=1
USB_BLACKLIST_PHONE=1

# 运行时电源管理
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto
```

应用配置：
```bash
sudo tlp start
```

## CPU调频优化

### 使用cpupower（如果不使用TLP）

```bash
# 安装cpupower
sudo pacman -S cpupower

# 查看当前CPU信息
cpupower frequency-info

# 设置省电模式
sudo cpupower frequency-set -g powersave

# 创建systemd服务自动切换
sudo nano /etc/systemd/system/cpupower-battery.service
```

服务内容：
```ini
[Unit]
Description=Set CPU governor to powersave on battery
ConditionACPower=false

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g powersave

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable cpupower-battery.service
```

## 显卡电源管理

### Intel核显优化

```bash
# 检查当前GPU状态
sudo cat /sys/class/drm/card0/gt_cur_freq_mhz
sudo cat /sys/class/drm/card0/gt_max_freq_mhz

# 创建内核参数优化文件
sudo nano /etc/modprobe.d/i915.conf
```

添加以下内容：
```conf
options i915 enable_guc=2 enable_fbc=1 enable_psr=2
```

### 独立显卡管理（如有NVIDIA独显）

对于混合显卡配置：

```bash
# 安装nvidia和optimus-manager
sudo pacman -S nvidia nvidia-utils optimus-manager

# 或使用开源方案
sudo pacman -S mesa xf86-video-nouveau

# 使用envycontrol切换显卡模式（推荐）
yay -S envycontrol

# 切换到集成显卡模式（最省电）
sudo envycontrol -s integrated

# 或使用混合模式
sudo envycontrol -s hybrid

# 重启系统
sudo reboot
```

## 显示屏和背光优化

### 自动降低亮度

```bash
# 安装clight（自动调节亮度）
yay -S clight

# 或手动设置
# 查看当前亮度
cat /sys/class/backlight/*/brightness

# 设置亮度（范围通常是0-255或0-100）
echo 50 | sudo tee /sys/class/backlight/*/brightness

# 创建udev规则，电池模式自动降低亮度
sudo nano /etc/udev/rules.d/99-backlight-battery.rules
```

添加以下内容：
```
# 拔电时降低亮度到50%
SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/bin/sh -c 'echo 50 > /sys/class/backlight/intel_backlight/brightness'"

# 接电时恢复亮度到80%
SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/bin/sh -c 'echo 200 > /sys/class/backlight/intel_backlight/brightness'"
```

### 显示器超时和待机

```bash
# X11环境设置
xset dpms 300 600 900  # 待机、挂起、关闭时间（秒）
xset s 180 180         # 屏保时间

# 写入~/.xinitrc或~/.xprofile使其永久生效
echo "xset dpms 300 600 900" >> ~/.xinitrc
```

## USB设备电源管理

### 启用USB自动挂起

```bash
# 检查USB设备状态
lsusb
cat /sys/bus/usb/devices/*/power/control

# 启用所有USB设备自动挂起（TLP已包含）
# 或手动设置
for device in /sys/bus/usb/devices/*/power/control; do
    echo auto | sudo tee $device
done

# 将特定设备加入黑名单（如鼠标、键盘可能需要排除）
# 在/etc/tlp.conf中设置USB_BLACKLIST
```

## 无线设备省电

### WiFi省电模式

```bash
# 检查WiFi接口名称
ip link

# 启用WiFi省电模式
sudo iw dev wlan0 set power_save on

# 永久启用，创建systemd服务
sudo nano /etc/systemd/system/wifi-powersave.service
```

服务内容：
```ini
[Unit]
Description=WiFi power saving mode
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/iw dev wlan0 set power_save on

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable wifi-powersave.service
```

### 蓝牙省电

```bash
# 电池模式下禁用蓝牙（如不使用）
sudo systemctl stop bluetooth.service
sudo systemctl disable bluetooth.service

# 或通过TLP配置自动管理
```

## 其他优化建议

### 1. 关闭不必要的后台服务

```bash
# 查看启用的服务
systemctl list-unit-files --state=enabled

# 禁用不需要的服务（示例）
sudo systemctl disable cups.service      # 打印服务
sudo systemctl disable avahi-daemon.service  # 网络发现
sudo systemctl disable ModemManager.service  # 调制解调器管理
```

### 2. 使用zram（压缩内存）

```bash
# 安装zram-generator
sudo pacman -S zram-generator

# 配置zram
sudo nano /etc/systemd/zram-generator.conf
```

添加内容：
```ini
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
```

启用：
```bash
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
```

### 3. 笔记本模式工具

```bash
# 安装laptop-mode-tools（替代TLP的方案）
sudo pacman -S laptop-mode-tools

# 编辑配置
sudo nano /etc/laptop-mode/laptop-mode.conf

# 启用服务
sudo systemctl enable laptop-mode.service
```

### 4. 减少磁盘写入

```bash
# 在/etc/fstab中为tmpfs和主分区添加noatime选项
sudo nano /etc/fstab

# 示例：
# /dev/nvme0n1p2  /  ext4  defaults,noatime  0  1
# tmpfs  /tmp  tmpfs  defaults,noatime,mode=1777  0  0
```

### 5. 内核参数优化

```bash
# 编辑GRUB配置
sudo nano /etc/default/grub

# 在GRUB_CMDLINE_LINUX_DEFAULT中添加：
# GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pcie_aspm=force i915.enable_psr=2"

# 更新GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 监控和测试

### 1. 使用PowerTOP

```bash
# 运行PowerTOP校准（需要30分钟，接电运行）
sudo powertop --calibrate

# 查看电源使用情况
sudo powertop

# 自动应用所有建议（谨慎使用）
sudo powertop --auto-tune

# 生成HTML报告
sudo powertop --html=powerreport.html
```

### 2. 查看电池信息

```bash
# 使用acpi
acpi -b
acpi -V

# 使用upower
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# 实时监控功耗
watch -n 2 'upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|energy-rate"'
```

### 3. 监控CPU和GPU

```bash
# CPU频率监控
watch -n 1 'grep MHz /proc/cpuinfo'

# 或使用
watch -n 1 'cpupower frequency-info | grep "current CPU frequency"'

# GPU监控（Intel）
sudo watch -n 1 'cat /sys/class/drm/card0/gt_cur_freq_mhz'

# 温度监控
watch -n 2 sensors
```

### 4. 检查电源状态

```bash
# 查看所有设备电源状态
cat /sys/kernel/debug/wakeup_sources

# 查看正在运行的进程功耗
ps aux --sort=-%cpu | head -10

# 使用s-tui监控压力测试
sudo pacman -S s-tui stress
s-tui
```

## 预期效果

正确配置后，机械革命耀世16u在电池模式下应该能够达到：
- 空闲功耗：8-12W
- 轻度办公：12-18W
- 网页浏览：15-20W
- 视频播放：18-25W

续航时间应该能够提升30-50%，具体取决于使用场景和电池容量。

## 故障排除

### 如果功耗仍然很高

1. 检查是否有程序异常占用CPU：`htop`
2. 检查是否有设备未进入省电模式：`sudo powertop`
3. 检查内核日志：`sudo dmesg | grep -i power`
4. 检查USB设备状态：`lsusb -t`
5. 检查TLP状态：`sudo tlp-stat -s`

### 如果某些设备不工作

某些设备（如USB鼠标、外置硬盘）可能因激进的电源管理而出现问题，将它们添加到排除列表：

```bash
# 编辑TLP配置
sudo nano /etc/tlp.conf

# 找到USB_DENYLIST并添加设备ID（使用lsusb查找）
# 格式：USB_DENYLIST="1234:5678 5678:9abc"
```

## 参考资源

- [Arch Wiki - Power Management](https://wiki.archlinux.org/title/Power_management)
- [Arch Wiki - TLP](https://wiki.archlinux.org/title/TLP)
- [Arch Wiki - PowerTOP](https://wiki.archlinux.org/title/Powertop)
- [TLP官方文档](https://linrunner.de/tlp/)

---

**注意**：进行电源优化时建议逐步测试，避免一次性应用所有设置。首先使用TLP的默认配置，然后根据实际需求逐步调整。
