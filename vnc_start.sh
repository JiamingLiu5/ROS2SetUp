#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "=== Installing Lightweight XFCE Desktop & VNC ==="
apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-tools \
    novnc \
    websockify \
    dbus-x11

# 1. Configure the VNC password (Change 'runpod2026' to your preferred password)
echo "Setting up VNC password..."
mkdir -p ~/.vnc
echo "runpod2026" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# 2. Create the XFCE Startup script for VNC
cat << 'EOF' > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
if command -v dbus-launch >/dev/null 2>&1; then
    eval "$(dbus-launch --sh-syntax)"
fi
startxfce4 &
EOF
chmod +x ~/.vnc/xstartup

# 3. Kill any zombie VNC servers and start a fresh screen (:1 maps to port 5901)
vncserver -kill :1 2>/dev/null || true
vncserver :1 -geometry 1280x720 -depth 24

# 4. Start noVNC Web Proxy on port 8080 pointing to the VNC server
echo "=== Launching Web-VNC interface on Port 8080 ==="
websockify --web /usr/share/novnc/ 8080 localhost:5901 &

echo "=== VNC Setup Completed Successfully! ==="

source /opt/ros/jazzy/setup.bash
source /workspace/bookros2_ws/install/setup.bash
