# syntax=docker/dockerfile-upstream:master-labs
# Done so --parents flag works

FROM osrf/ros:iron-desktop-full

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
  && apt-get upgrade -y \
  # Clean for better performance
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Done here because file needs sudo perms
# Switch to bash so the process subsition works. aka <()
# Runs MAVROS helper install script
SHELL ["/bin/bash", "-c"]
RUN . <(wget -qO- https://raw.githubusercontent.com/mavlink/mavros/ros2/mavros/scripts/install_geographiclib_datasets.sh)

#Set up rov user
ARG USER_NAME=rov
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd ${USER_NAME} --gid ${USER_GID} \
    && useradd -l -m ${USER_NAME} -u ${USER_UID} -g ${USER_GID} -s /bin/bash

# Gives Sudo perms to USER
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
  && chmod 0440 /etc/sudoers.d/${USER_NAME}

# Adds $USER to environment
ENV USER ${USER_NAME}
# Switches to rov user
USER ${USER_NAME}

WORKDIR /home/${USER_NAME}

# Setup Ardusub
COPY src/surface/rov_gazebo/scripts/ardusub.sh .
RUN ./ardusub.sh \
 && rm ardusub.sh

# Setup Ardupilot Gazebo
COPY src/surface/rov_gazebo/scripts/ardupilot_gazebo.sh .
RUN ./ardupilot_gazebo.sh \
    && rm ardupilot_gazebo.sh
# Update Pip
RUN pip install --no-cache-dir --upgrade  pip==24.0 

WORKDIR /home/${USER_NAME}/rov-25

# One might wonder why the following is done.
# It is done so that the dependencies can be cached without needing to be reinstalled
# each and everytime. Since these do not change too often this improves performance in most cases.
# Copies in Python deps
COPY pyproject.toml .
# Copies in ROS deps
# https://docs.docker.com/engine/reference/builder/#copy---parents
COPY --parents --chown=${USER_NAME}:${USER_NAME} ./*/*/package.xml ./*/*/*/package.xml ./*/*/*/*/package.xml ./
# Copies in Install Script
COPY .vscode/install_dependencies.sh .

# Installs ROS and python dependencies
RUN ./install_dependencies.sh \
  # Clean up
  && rm install_dependencies.sh

# Remove build warnings
ENV PYTHONWARNINGS ignore:::setuptools.command.install,ignore:::setuptools.command.easy_install,ignore:::pkg_resources

# TODO for future nerd to do this via ENTRYPOINT which be better but, I could not get ENTRYPOINT to play with VsCODE.
COPY .vscode/rov_setup.sh .
RUN ./rov_setup.sh \
  && rm rov_setup.sh

COPY --chown=${USER_NAME}:${USER_NAME}  .git .git
# Remove identity file generated by action/checkout
# Start by finding all files ending in config
# Then removes file paths without "git"
# Then removes the 'sshCommand' line from each file
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN  find . -name "*config" | grep git | while read -r line; do sed -i "/sshCommand/d" "$line"; done

# Do full copy and build as last step
COPY --chown=${USER_NAME}:${USER_NAME} . .

ARG EXPECTED_OUTPUT="All system dependencies have been satisfied"

# Checks that all rosdeps are installed.
RUN if [[ $(rosdep check -r --from-paths src --ignore-src) != "${EXPECTED_OUTPUT}" ]]; \ 
  then echo "ROS deps not all installed. Try adding another /* directory layer to the COPY instruction labeled 'Copies in ROS deps'."; \
  rosdep check -r --from-paths src --ignore-src; \
  exit 1; \
  fi

RUN . /opt/ros/iron/setup.sh \
  && colcon build --symlink-install

# Setup Models and Gazebo Environment
RUN ./src/surface/rov_gazebo/scripts/add_models_and_worlds.sh