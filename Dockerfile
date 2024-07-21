FROM osrf/ros:jazzy-desktop

ENV ROS_DISTRO jazzy
ENV USER_NAME root

RUN apt-get update -y \
  && apt-get install --no-install-recommends -y \
  # Install Video for Linux
  v4l-utils -y \
  # Install lsusb
  usbutils \
  # Install nano
  nano \
  # Install pip
  python3-pip \
  # Install geographiclib dependencies for mavros.
  geographiclib-tools \
  # For git
  ssh \
  && apt-get upgrade -y \
  # Clean for better performance
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Done here because file needs sudo perms
# Switch to bash so the process subsition works. aka <()
# Runs MAVROS helper install script
SHELL ["/bin/bash", "-c"]
RUN . <(wget -qO- https://raw.githubusercontent.com/mavlink/mavros/ros2/mavros/scripts/install_geographiclib_datasets.sh)

WORKDIR /home/ 
# Setup Ardusub
COPY src/surface/rov_gazebo/scripts/ardusub.sh .
RUN ./ardusub.sh \
 && rm ardusub.sh

# Setup Ardupilot Gazebo
COPY src/surface/rov_gazebo/scripts/ardupilot_gazebo.sh .
RUN ./ardupilot_gazebo.sh \
    && rm ardupilot_gazebo.sh

WORKDIR /home/${USER_NAME}/rov-25

# # Remove identity file generated by action/checkout
# # Start by finding all files ending in config
# # Then removes file paths without "git"
# # Then removes the 'sshCommand' line from each file
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# RUN  find . -name "*config" | grep git | while read -r line; do sed -i "/sshCommand/d" "$line"; done

COPY . .

RUN git submodule init && git submodule update

# TODO: for future nerd to do this via ENTRYPOINT which be better but, I could not get ENTRYPOINT to play with VsCODE.
RUN .vscode/install_dependencies.sh
RUN .vscode/rov_setup.sh

# Setup Models and Gazebo Environment
RUN ./src/surface/rov_gazebo/scripts/add_models_and_worlds.sh

# Do full build as last step
RUN source /opt/ros/${ROS_DISTRO}/setup.sh \
  && colcon build --symlink-install
