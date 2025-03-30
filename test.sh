#!/bin/sh

# 定义目录
HY2_DIR="/storage/emulated/0/hy2"

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 用户身份运行此脚本"
  exit 1
fi

# 创建目录
mkdir -p "$HY2_DIR"

# 更新系统
echo "更新系统..."
freebsd-update fetch install
pkg update -f

# 安装 wget (如果未安装)
pkg info wget >/dev/null 2>&1 || pkg install -y wget

# 安装 Hysteria2
echo "安装 Hysteria2..."
pkg info go >/dev/null 2>&1 || pkg install -y go
export GOPATH=/usr/home/$(whoami)/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
go install github.com/HyNetwork/hysteria/cmd/hysteria2@latest

# 创建 Hysteria2 配置文件 (config.json)
echo "创建 Hysteria2 配置文件..."
cat > "$HY2_DIR/config.json" <<EOF
{
  "listen": "0.0.0.0:6890",
  "cert": "none",
  "key": "none",
  "up_mbps": 100,
  "down_mbps": 100,
  "disable_udp": false,
  "obfs": {
      "password": "your_obfs_password"
  },
  "users": [
    {
      "name": "user1",
      "password": "your_user_password"
    }
  ]
}
EOF

# 替换 OBFS 密码和用户密码
sed -i '' "s/your_obfs_password/$(openssl rand -base64 16)/g" "$HY2_DIR/config.json"
sed -i '' "s/your_user_password/$(openssl rand -base64 16)/g" "$HY2_DIR/config.json"

# 输出配置信息
echo "Hysteria2 配置文件已生成：$HY2_DIR/config.json"
echo "请注意保管此文件，特别是 OBFS 密码和用户密码。"
echo "你可以修改此文件以调整配置。"
echo "OBFS密码: $(jq -r '.obfs.password' "$HY2_DIR/config.json")"
echo "用户名: $(jq -r '.users[0].name' "$HY2_DIR/config.json")"
echo "用户密码: $(jq -r '.users[0].password' "$HY2_DIR/config.json")"

# 创建启动脚本 (start.sh)
echo "创建启动脚本..."
cat > "$HY2_DIR/start.sh" <<EOF
#!/bin/sh
cd "$HY2_DIR"
/usr/home/$(whoami)/go/bin/hysteria2 server --config config.json
EOF
chmod +x "$HY2_DIR/start.sh"

# 创建停止脚本 (stop.sh)
echo "创建停止脚本..."
cat > "$HY2_DIR/stop.sh" <<EOF
#!/bin/sh
killall hysteria2
EOF
chmod +x "$HY2_DIR/stop.sh"

# 提示用户启动 Hysteria2
echo "Hysteria2 已安装并配置完成。"
echo "运行以下命令启动 Hysteria2 服务："
echo "  cd $HY2_DIR && ./start.sh"
echo "运行以下命令停止 Hysteria2 服务："
echo "  cd $HY2_DIR && ./stop.sh"

# 提示用户配置客户端
echo ""
echo "请根据你的客户端，配置以下信息："
echo "服务器地址: 你的服务器 IP 地址:6890"
echo "用户名: user1 (默认)"
echo "密码: 见上面的用户密码"
echo "OBFS 密码: 见上面的 OBFS 密码"
echo "协议: HTTP"

echo "请确保服务器的 6890 端口已开放 (UDP)。"

exit 0
