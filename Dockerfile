# Start from the pre-built ROS 2 image
FROM osrf/ros:jazzy-desktop-full-noble

# Prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# ---> EVERYTHING BELOW HAPPENS ONLY ONCE <---

# 1. Install tools
RUN apt-get update && apt-get install -y \
    git python3-vcstool python3-colcon-common-extensions python3-rosdep

# 2. Setup rosdep
RUN rosdep update || true

# 3. Create workspace and clone
WORKDIR /ros2_ws
RUN mkdir -p src && \
    cd src && \
    git clone -b jazzy-devel https://github.com/fmrico/book_ros2.git && \
    vcs import . < book_ros2/third_parties.repos --skip-existing

# 4. Remove ghost dependencies
RUN find src -name "package.xml" -exec sed -i -e '/pal_gazebo_plugins/d' -e '/gazebo_planar_move_plugin/d' -e '/pal_gazebo_worlds/d' {} +

# 5. Install dependencies and Build
RUN /bin/bash -c "source /opt/ros/jazzy/setup.bash && \
    apt-get update && \
    rosdep install --from-paths src --ignore-src -r -y --rosdistro jazzy && \
    colcon build --symlink-install"

# 6. Auto-source the environment
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
    echo "source /ros2_ws/install/setup.bash" >> ~/.bashrc

# ---> THIS HAPPENS EVERY TIME THE POD BOOTS <---
CMD ["sleep", "infinity"]
