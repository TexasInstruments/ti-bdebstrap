#!/bin/bash

source ${topdir}/scripts/common.sh

function setup_log_file() {
    filename=$1

    # create the log directory if it doesn't already exist
    LOG_DIR="${topdir}/logs"
    mkdir -p "${LOG_DIR}"

    LOG_FILE="$LOG_DIR/${filename}.log"

    # if log file already exists, replace it with a new one for this build
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
    fi

    touch "${LOG_FILE}"
}

function setup_build_tools() {
    setup_log_file "setup"
    if [ "${host_arch}" != "arm" ]; then
        log "> Arm Toolchain: checking .."
        if [ ! -d "${topdir}/tools/arm-gnu-toolchain-13.2.Rel1-${host_arch}-arm-none-linux-gnueabihf/bin" ]; then
            mkdir -p ${topdir}/tools/
            cd ${topdir}/tools/
    
            log "> Arm Toolchain: not found. Downloading .." 
    	wget https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-${host_arch}-arm-none-linux-gnueabihf.tar.xz &>>/dev/null
            if [ $? -eq 0 ]; then
                log "> Arm Toolchain: downloaded .."
    	    tar -Jxf arm-gnu-toolchain-13.2.rel1-${host_arch}-arm-none-linux-gnueabihf.tar.xz &>>"${LOG_FILE}"
    	    rm arm-gnu-toolchain-13.2.rel1-${host_arch}-arm-none-linux-gnueabihf.tar.xz
            else
                log "> Arm Toolchain: Failed to download. Exit code: $?"
            fi
        else
            log "> Arm Toolchain: available"
        fi
        export PATH=${topdir}/tools/arm-gnu-toolchain-13.2.Rel1-${host_arch}-arm-none-linux-gnueabihf/bin:$PATH
    fi

    if [ "${host_arch}" != "aarch64" ]; then
        log "> Aarch64 Toolchain: checking .."
        if [ ! -d "${topdir}/tools/arm-gnu-toolchain-13.2.Rel1-${host_arch}-aarch64-none-linux-gnu/bin" ]; then
            mkdir -p ${topdir}/tools/
            cd ${topdir}/tools/
     
            log "> Aarch64 Toolchain: not found. downloading .." 
            wget https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/arm-gnu-toolchain-13.2.rel1-${host_arch}-aarch64-none-linux-gnu.tar.xz &>>/dev/null
            if [ $? -eq 0 ]; then
                log "> Aarch64 Toolchain: downloaded .." 
                tar -Jxf arm-gnu-toolchain-13.2.rel1-${host_arch}-aarch64-none-linux-gnu.tar.xz &>>"${LOG_FILE}"
                rm arm-gnu-toolchain-13.2.rel1-${host_arch}-aarch64-none-linux-gnu.tar.xz
            else
                log "> Aarch Toolchain: Failed to download. Exit code: $?"
            fi
        else
            log "> Aarch64 Toolchain: available"
        fi
        export PATH=${topdir}/tools/arm-gnu-toolchain-13.2.Rel1-${host_arch}-aarch64-none-linux-gnu/bin:$PATH
    fi
}

