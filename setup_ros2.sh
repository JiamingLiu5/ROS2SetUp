#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Update package list and install prerequisites
sudo apt update && sudo apt install -y curl gnupg2 lsb-release git python3-vcstool python3-colcon-common-extensions

# 2. Download the ROS2 GPG key
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# 3. Add the ROS2 repository to system sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 4. Update package list with the new repository
sudo apt update

# 5. Install ROS 2 Jazzy Desktop
sudo apt install -y ros-jazzy-desktop

# 6. Environment setup (System level)
# Sourcing it in the script so the current shell session can use it
source /opt/ros/jazzy/setup.bash
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

# 7. Initialize and update rosdep
if ! command -v rosdep &> /dev/null; then
    sudo apt install -y python3-rosdep
fi

if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
fi

# Rosdep update can occasionally flake on network errors; 
# we temporarily disable 'set -e' so a network blip doesn't kill the script.
set +e
rosdep update
set -e

# 8. Create ROS 2 Workspace and clone the book repository
cd ~
mkdir -p bookros2_ws/src
cd bookros2_ws/src

# Clone the repository for the Jazzy branch
if [ ! -d "book_ros2" ]; then
    git clone -b jazzy-devel https://github.com/fmrico/book_ros2.git
fi

# 9. Import third-party repositories
if [ -f "book_ros2/third_parties.repos" ]; then
    vcs import . < book_ros2/third_parties.repos
else
    echo "Warning: third_parties.repos not found!"
fi

# 10. Install workspace dependencies via rosdep
cd ~/bookros2_ws
sudo apt update # Ensure apt cache is awake for rosdep
rosdep install --from-paths src --ignore-src -r -y

# 11. Build the workspace
colcon build --symlink-install

# 12. Source the local workspace environment
source ~/bookros2_ws/install/setup.bash
if ! grep -q "source ~/bookros2_ws/install/setup.bash" ~/.bashrc; then
    echo "source ~/bookros2_ws/install/setup.bash" >> ~/.bashrc
fi

echo "=== ROS 2 Jazzy Setup, Workspace Build, and Environment Configuration Complete! ==="
