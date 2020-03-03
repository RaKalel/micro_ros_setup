# Reminder: Zephyr recommended dependecies are: git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget python3-pip python3-setuptools python3-tk python3-wheel xz-utils file make gcc gcc-multilib software-properties-common -y

sudo apt install --no-install-recommends software-properties-common -y # Remove when merged: https://github.com/ros/rosdistro/pull/23950

wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | sudo apt-key add -
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
sudo apt update
sudo apt install cmake -y

pip3 install --user -U west # Remove when merged: https://github.com/ros/rosdistro/pull/23934

export PATH=~/.local/bin:"$PATH"

pushd $FW_TARGETDIR >/dev/null
   
    west init zephyrproject
    pushd zephyrproject >/dev/null
        west update
    popd >/dev/null

    pip3 install -r zephyrproject/zephyr/scripts/requirements.txt

    export TOOLCHAIN_VERSION=zephyr-toolchain-arm-0.11.2-setup.run
    wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.11.2/$TOOLCHAIN_VERSION
    chmod +x $TOOLCHAIN_VERSION
    ./$TOOLCHAIN_VERSION -- -d $(pwd)/zephyr-sdk -y

    rm -rf $TOOLCHAIN_VERSION


    # Temporal until driver in mainstream
    pushd zephyrproject/zephyr >/dev/null
        git remote add eprosima https://github.com/eProsima/zephyr
        git fetch --all
        git checkout remotes/eprosima/feature/driver_vl53l1
    popd >/dev/null

    export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
    export ZEPHYR_SDK_INSTALL_DIR=$FW_TARGETDIR/zephyr-sdk

    # Import repos
    vcs import --input $PREFIX/config/$RTOS/generic/board.repos >/dev/null

    # ignore broken packages
    touch mcu_ws/ros2/rcl_logging/rcl_logging_log4cxx/COLCON_IGNORE
    touch mcu_ws/ros2/rcl/COLCON_IGNORE

    rosdep install -y --from-paths mcu_ws -i mcu_ws --rosdistro dashing --skip-keys="$SKIP"
popd >/dev/null