#!/bin/bash
# Exit immediately if any command fails
set -e

echo "=== 1. Updating System & Installing Base Dependencies ==="
sudo apt update && sudo apt install -y curl gnupg2 lsb-release python3-pip

echo "=== 2. Setting Up ROS 2 Archive Keys & Resolving GPG Signatures ==="
# Ensure the keyrings directory exists
sudo mkdir -p /usr/share/keyrings

# Download the official ROS 2 key file
sudo curl -sSL https://raw.githubusercontent.com/ros2/ros2/main/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Fix/Fallback: Manually fetch the required F42ED6FBAB17C654 key from keyservers 
# into the keyring to guarantee apt won't throw a NO_PUBKEY verification error.
echo "Verifying and updating ROS 2 signature keys..."
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/ros-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F42ED6FBAB17C654

echo "=== 3. Adding ROS 2 Repository (Auto-Detecting Codename) ==="
# Automatically grabs 'jammy' or 'noble' to prevent 404 errors
CODENAME=$(source /etc/os-release && echo $UBUNTU_CODENAME)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $CODENAME main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

echo "=== 4. Refreshing Package List & Installing Tools + ROS 2 Jazzy ==="
sudo apt update
# Utilities are safely placed here AFTER the repo list has been cryptographically signed
sudo apt install -y python3-vcstool python3-colcon-common-extensions ros-jazzy-desktop

echo "=== 5. Setting Up Shell Environment (.bashrc) ==="
# Adds the global ROS environment to bash profile if not already there
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi
# Source it for the current script process
source /opt/ros/jazzy/setup.bash

echo "=== 6. Initializing and Updating rosdep ==="
if [ ! -f /etc/apt/sources.list.d/20-default.list ]; then
    sudo rosdep init
fi
# Critical Fix: Run as a regular user, never with sudo to preserve home permissions
rosdep update

echo "=== 7. Creating Workspace and Cloning Book Repository ==="
cd $HOME
mkdir -p bookros2_ws/src
cd bookros2_ws/src

# Clone the specific development branch for Jazzy
if [ ! -d "book_ros2" ]; then
    git clone -b jazzy-devel https://github.com/fmrico/book_ros2.git
fi

echo "=== 8. Importing Third Party Dependencies via vcstool ==="
vcs import . < book_ros2/third_parties.repos

echo "=== 9. Installing Missing Package Dependencies via rosdep ==="
cd $HOME/bookros2_ws
sudo apt update
rosdep install --from-paths src --ignore-src -r -y

echo "=== 10. Building Workspace using Colcon ==="
colcon build --symlink-install

echo "=== 11. Setting Up Overlay Environment (.bashrc) ==="
# Adds the built workspace environment to bash profile if not already there
if ! grep -q "source ~/bookros2_ws/install/setup.bash" ~/.bashrc; then
    echo "source ~/bookros2_ws/install/setup.bash" >> ~/.bashrc
fi

echo "=========================================================="
echo " SUCCESS: ROS 2 Jazzy & Workspace Setup is complete!"
echo " Please close this terminal and open a NEW one to start."
echo "=========================================================="
