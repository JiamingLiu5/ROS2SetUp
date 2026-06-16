#!/bin/bash

# Force non-interactive frontend so installations never halt for prompts
export DEBIAN_FRONTEND=noninteractive

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting RunPod ROS 2 Jazzy & Workspace Setup ==="

# ---------------------------------------------------------------------
# 1. System Prerequisites & ROS 2 Repository Setup
# ---------------------------------------------------------------------
apt-get update && apt-get install -y curl gnupg2 lsb-release git

# Safely download GPG key
mkdir -p /usr/share/keyrings
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add ROS2 repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# ---------------------------------------------------------------------
# 2. Install ROS 2 Jazzy & Development Tools
# ---------------------------------------------------------------------
apt-get update
apt-get install -y \
    python3-vcstool \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-jazzy-desktop

# ---------------------------------------------------------------------
# 3. Environment Setup (System Level)
# ---------------------------------------------------------------------
if [ -f /opt/ros/jazzy/setup.bash ]; then
    source /opt/ros/jazzy/setup.bash
    
    # Ensure it sticks in ~/.bashrc for interactive terminal sessions
    if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
        echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
    fi
else
    echo "CRITICAL ERROR: ROS 2 Jazzy installation failed!" && exit 1
fi

# ---------------------------------------------------------------------
# 4. Initialize and Update Rosdep
# ---------------------------------------------------------------------
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    rosdep init
fi

# Temporarily disable 'set -e' for brittle network calls
set +e
rosdep update
set -e

# ---------------------------------------------------------------------
# 5. Create/Verify Persistent Workspace Volume
# ---------------------------------------------------------------------
mkdir -p /workspace/bookros2_ws/src
cd /workspace/bookros2_ws/src

# Smart Clone: Only clones if the directory isn't already present
if [ ! -d "book_ros2" ]; then
    git clone -b jazzy-devel https://github.com/fmrico/book_ros2.git
else
    echo "--> Repository 'book_ros2' already exists in persistent storage. Skipping clone."
fi

# Smart Import: Skips files already cloned on subsequent RunPod boots
if [ -f "book_ros2/third_parties.repos" ]; then
    vcs import . < book_ros2/third_parties.repos --skip-existing
else
    echo "Warning: third_parties.repos not found!"
fi

# ---------------------------------------------------------------------
# 6. Install Workspace Dependencies via Rosdep
# ---------------------------------------------------------------------
cd /workspace/bookros2_ws
apt-get update

# Explicitly target jazzy distro to prevent container identity errors
rosdep install --from-paths src --ignore-src -r -y --rosdistro jazzy

# ---------------------------------------------------------------------
# 7. Build and Source the Workspace
# ---------------------------------------------------------------------
colcon build --symlink-install

if [ -f /workspace/bookros2_ws/install/setup.bash ]; then
    source /workspace/bookros2_ws/install/setup.bash
    
    if ! grep -q "source /workspace/bookros2_ws/install/setup.bash" ~/.bashrc; then
        echo "source /workspace/bookros2_ws/install/setup.bash" >> ~/.bashrc
    fi
fi

echo "========================================================================="
echo "=== ROS 2 Jazzy Setup, Workspace Build, and Environment Complete! ==="
echo "========================================================================="
