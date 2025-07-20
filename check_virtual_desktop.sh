#!/bin/bash

# 虚拟桌面环境状态检查脚本

echo "==================================================="
echo "虚拟桌面环境状态检查"
echo "==================================================="

# 检查 PID 文件
if [ -f "/tmp/virtual-desktop-pids.txt" ]; then
    echo "PID 文件存在，读取配置信息..."
    source /tmp/virtual-desktop-pids.txt
    
    echo "配置信息:"
    echo "- 显示器号: :$DISPLAY_NUM"
    echo "- VNC 端口: $VNC_PORT"
    echo "- noVNC Web 端口: $NOVNC_PORT"
    echo ""
else
    echo "PID 文件不存在，服务可能未启动"
    echo ""
fi

# 检查各个进程状态
echo "进程状态检查:"

# 检查 Xvfb
XVFB_RUNNING=$(pgrep -f "Xvfb.*:99" | wc -l)
if [ $XVFB_RUNNING -gt 0 ]; then
    echo "✓ Xvfb 虚拟显示服务器: 运行中"
    pgrep -f "Xvfb.*:99" | while read pid; do
        echo "  PID: $pid"
    done
else
    echo "✗ Xvfb 虚拟显示服务器: 未运行"
fi

# 检查 Fluxbox
FLUXBOX_RUNNING=$(pgrep fluxbox | wc -l)
if [ $FLUXBOX_RUNNING -gt 0 ]; then
    echo "✓ Fluxbox 桌面管理器: 运行中"
    pgrep fluxbox | while read pid; do
        echo "  PID: $pid"
    done
else
    echo "✗ Fluxbox 桌面管理器: 未运行"
fi

# 检查 x11vnc
X11VNC_RUNNING=$(pgrep x11vnc | wc -l)
if [ $X11VNC_RUNNING -gt 0 ]; then
    echo "✓ x11vnc VNC 服务器: 运行中"
    pgrep x11vnc | while read pid; do
        echo "  PID: $pid"
    done
else
    echo "✗ x11vnc VNC 服务器: 未运行"
fi

# 检查 noVNC
NOVNC_RUNNING=$(pgrep -f "novnc_proxy" | wc -l)
if [ $NOVNC_RUNNING -gt 0 ]; then
    echo "✓ noVNC Web 客户端: 运行中"
    pgrep -f "novnc_proxy" | while read pid; do
        echo "  PID: $pid"
    done
else
    echo "✗ noVNC Web 客户端: 未运行"
fi

echo ""

# 检查端口占用
echo "端口占用检查:"
netstat -tulpn 2>/dev/null | grep ":5999\|:6080" | while IFS= read -r line; do
    echo "$line"
done

if ! netstat -tulpn 2>/dev/null | grep -q ":5999\|:6080"; then
    echo "未检测到相关端口占用"
fi

echo ""

# 显示日志文件状态
echo "日志文件状态:"
LOG_DIR="/var/log/virtual-desktop"
if [ -d "$LOG_DIR" ]; then
    echo "日志目录: $LOG_DIR"
    ls -la $LOG_DIR/ 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo "日志目录不存在: $LOG_DIR"
fi

echo ""

# 访问信息
if [ $XVFB_RUNNING -gt 0 ] && [ $X11VNC_RUNNING -gt 0 ] && [ $NOVNC_RUNNING -gt 0 ]; then
    echo "==================================================="
    echo "服务正在运行，可以通过以下方式访问:"
    echo "1. VNC 客户端: localhost:5999"
    echo "2. 网页访问: http://localhost:6080"
    echo "==================================================="
else
    echo "==================================================="
    echo "部分或全部服务未运行"
    echo "请运行 ./start_virtual_desktop.sh 启动服务"
    echo "==================================================="
fi
