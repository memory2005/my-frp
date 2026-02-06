#!/bin/bash

# 1. 权限检查
if [ "$EUID" -ne 0 ]; then 
  echo "错误：请以 root 用户运行此脚本"
  exit 1
fi

# 2. 自动检测系统架构
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    PLATFORM="linux_amd64"
elif [ "$ARCH" = "aarch64" ]; then
    PLATFORM="linux_arm64"
else
    echo "暂不支持的架构: $ARCH"
    exit 1
fi

# 3. 获取 GitHub 最新版本号
echo "正在检测 frp 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo "无法获取版本号，请检查网络连接"
    exit 1
fi

echo "准备安装版本: v$LATEST_VERSION ($PLATFORM)"

# 4. 下载并解压
URL="https://github.com/fatedier/frp/releases/download/v${LATEST_VERSION}/frp_${LATEST_VERSION}_${PLATFORM}.tar.gz"
wget -O frp.tar.gz $URL
tar -zxvf frp.tar.gz
cd frp_${LATEST_VERSION}_${PLATFORM}

# 5. 安装二进制文件
cp -f frps /usr/local/bin/
chmod +x /usr/local/bin/frps
mkdir -p /etc/frp

# 6. 写入新版 TOML 配置文件 (增加 KCP 支持)
# 设置默认值
BIND_PORT=7000
KCP_PORT=7000  # KCP 通常与 BIND_PORT 共用端口号，但走 UDP 协议
DASH_PORT=7500
TOKEN="admin"

cat << TOML > /etc/frp/frps.toml
bindPort = $BIND_PORT
kcpBindPort = $KCP_PORT
auth.token = "$TOKEN"

[webServer]
addr = "0.0.0.0"
port = $DASH_PORT
user = "admin"
password = "admin"
TOML

# 7. 配置 systemd 服务
cat << SERVICE > /etc/systemd/system/frps.service
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.toml

[Install]
WantedBy=multi-user.target
SERVICE

# 8. 启动与清理
systemctl daemon-reload
systemctl enable frps
systemctl restart frps

echo "==============================================="
echo "✅ frps 安装并启动成功 (已开启 KCP 支持)！"
echo "-----------------------------------------------"
echo "🏠 服务端 IP: $(curl -s ifconfig.me)"
echo "🔑 绑定端口: $BIND_PORT (TCP/UDP)"
echo "🛡️ 鉴权 Token: $TOKEN"
echo "📊 Dashboard: http://$(curl -s ifconfig.me):$DASH_PORT"
echo "👤 管理账号/密码: admin / admin"
echo "==============================================="

# 清理安装包
cd ..
rm -rf frp.tar.gz frp_${LATEST_VERSION}_${PLATFORM}
