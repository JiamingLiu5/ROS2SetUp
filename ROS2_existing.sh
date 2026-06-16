#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Configuring Pre-Built ROS 2 Workspace ==="

# 1. Install missing build tools (Docker images usually lack these)
apt-get update && apt-get install -y \
    git python3-vcstool python3-colcon-common-extensions python3-rosdep

# 2. Setup environment and initialize rosdep
source /opt/ros/jazzy/setup.bash
[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ] && rosdep init
rosdep update || true # '|| true' ignores the root warning gracefully

# 3. Create workspace & clone repositories
mkdir -p /workspace/bookros2_ws/src
cd /workspace/bookros2_ws/src

[ ! -d "book_ros2" ] && git clone -b jazzy-devel https://github.com/fmrico/book_ros2.git
[ -f "book_ros2/third_parties.repos" ] && vcs import . < book_ros2/third_parties.repos --skip-existing

# 4. Remove unsupported legacy Gazebo dependencies to prevent build crashes
find . -name "package.xml" -exec sed -i -e '/pal_gazebo_plugins/d' -e '/gazebo_planar_move_plugin/d' -e '/pal_gazebo_worlds/d' {} +

# 5. Install ROS dependencies and build the workspace
cd /workspace/bookros2_ws
rosdep install --from-paths src --ignore-src -r -y --rosdistro jazzy
colcon build --symlink-install

# 6. Auto-source for all future terminal sessions
grep -qxF "source /opt/ros/jazzy/setup.bash" ~/.bashrc || echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
grep -qxF "source /workspace/bookros2_ws/install/setup.bash" ~/.bashrc || echo "source /workspace/bookros2_ws/install/setup.bash" >> ~/.bashrc

echo "=== Setup Complete! ==="
