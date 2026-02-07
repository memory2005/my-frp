# 服务器公网地址
serverAddr = "0.0.0.0"
serverPort = 7000
auth.token = "admin"
user = "台式机"
# 失败重连配置
loginFailExit = false
# 使用 KCP 协议 (UDP)，大幅提升远程桌面的流畅度，减少鼠标延迟
transport.protocol = "kcp"
# 开启 TCP 复用，提高连接效率
transport.tcpMux = true

# --- 代理 1：Windows 远程桌面 (RDP) ---
[[proxies]]
name = "RDP_PC1"
type = "tcp"
localIP = "192.168.1.11"
localPort = 3389
remotePort = 33890
# 开启压缩，在网络环境较差时提升画面加载速度
transport.useCompression = true

# --- 代理 2：内网设备远程唤醒 (WOL) ---
[[proxies]]
name = "WOL_PC"
type = "udp"
# 建议直接填写目标电脑的内网固定 IP，或者使用局域网广播地址 .255
localIP = "192.168.1.11"
localPort = 9
remotePort = 9000
