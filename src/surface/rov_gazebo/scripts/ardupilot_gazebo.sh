#!/bin/bash

sudo apt-get update
sudo apt-get install rapidjson-dev libignition-gazebo6-dev -y
git clone -b fortress  git@github.com:cwruRobotics/rov-ardupilot-gazebo-fortress.git ~/ardupilot_gazebo
cd ~/ardupilot_gazebo
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4

# Add IGN_GAZEBO_SYSTEM_PLUGIN_PATH to .bashrc only if it isn't already there
ROS_LINE='export IGN_GAZEBO_SYSTEM_PLUGIN_PATH=$HOME/ardupilot_gazebo/build:$IGN_GAZEBO_SYSTEM_PLUGIN_PATH'
if ! grep -qF "$ROS_LINE" ~/.bashrc ; 
    then echo "$ROS_LINE" >> ~/.bashrc ;
fi

ROS_LINE='export IGN_GAZEBO_RESOURCE_PATH=$HOME/ardupilot_gazebo/models:$HOME/ardupilot_gazebo/worlds:IGN_GAZEBO_RESOURCE_PATH'
if ! grep -qF "$ROS_LINE" ~/.bashrc ; 
    then echo "$ROS_LINE" >> ~/.bashrc ;
fi

. ~/.bashrc