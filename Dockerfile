FROM osrf/ros:iron-desktop-full

RUN sudo apt-get update -y

# Install pip
RUN sudo apt-get install python3-pip -y

# Install Video for Linux
RUN sudo apt-get install v4l-utils -y

# Install lsusb
RUN sudo apt-get install usbutils -y

# Install nano
RUN sudo apt-get install nano -y

RUN sudo apt-get update -y
RUN sudo apt-get upgrade -y

# Remove build warnings
RUN echo "$export PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources" >> ~/.bashrc ;

# Setup Ardupilot Gazebo
RUN --mount=type=bind,source=src/surface/rov_gazebo/scripts/ardupilot_gazebo.sh,target=/tmp/src/surface/rov_gazebo/scripts/ardupilot_gazebo.sh \
  . /tmp/src/surface/rov_gazebo/scripts/ardupilot_gazebo.sh

# Setup Ardusub
RUN --mount=type=bind,source=src/surface/rov_gazebo/scripts/ardusub.sh,target=/tmp/src/surface/rov_gazebo/scripts/ardusub.sh \
  . /tmp/src/surface/rov_gazebo/scripts/ardusub.sh

# Remove identity file generated by action/checkout
# Start by finding all files ending in config
# Then removes file paths without "git"
# Then removes the 'sshCommand' line from each file
RUN  find . -name "*config" | grep git | while read -r line; do sed -i '/sshCommand/d' $line; done

WORKDIR /root/rov-24

COPY . .

# TODO for future nerd to do this via ENTRYPOINT which be better but, I could not get ENTRYPOINT to play with VsCODE.
RUN . /root/rov-24/.vscode/rov_setup.sh

# Setup Models and Gazebo Environment
RUN . /root/rov-24/src/surface/rov_gazebo/scripts/add_models_and_worlds.sh

# Installs ROS and python dependencies
RUN . /root/rov-24/.vscode/install_dependencies.sh

RUN . /opt/ros/iron/setup.sh \
    && PYTHONWARNINGS=ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources; export PYTHONWARNINGS \
    && colcon build --symlink-install
