#----------------------------------------------
#
# scripted install of weewx with rtldavis driver set to US units
# this assumes a v5 pip installation of weewx in the paths below
#
# tested on debian-13 based Raspi OS
# with a rtl-sdr.com RTL2832U dongle
#
# last modified
#   2025-1220 - use previously downloaded sources from here
#   2025-1208 - set GOPATH
#   2025-1207 - use os golang so no need for 1.15 any more (tested on 1.24)
#   2025-1117 - moved the install-v5pip.sh script in github
#               added pi variable to run under users other than 'pi'
#   2024-1002 - no 1.15 dpkg in deb12, install local go manually
#   2024-0323 - update to v5 weewx, pin golang version to 1.15
#   2022-0722 - original
#
# note: you might be able to install go-1.15 from dpkg
#       from old debian archives if you add a repo to /etc/apt/sources.list
#       ala:
#          # this is an old debian repo
#          deb http://ftp.de.debian.org/debian bullseye main 
#       then call /usr/lib/go-1.15/bin/go specifically in your scripts
#
#----------------------------------------------
# credits - thanks to another weewx user noticing that golang-1.15 still works
#           which was buried in their attachments in 
#            https://groups.google.com/g/weewx-user/c/bGiQPuOljqs/m/Mrvwe50UCQAJ
#----------------------------------------------

# set these to 1 to run that block of code below
#
# FWIW - I typically run this one step at a time one-by-one in testing
#        so the default is all set to 0 here to permit that
# 

EXTRACT_SOURCES=0          # extract src.tgz into a src tree
INSTALL_PREREQS=0          # package prerequisites to build the software
INSTALL_WEEWX=0            # weewx itself
INSTALL_LIBRTLSDR=0        # librtlsdr software
BUILD_RTLDAVIS=0           # build the go binary of rtldavis
INSTALL_RTLDAVIS=0         # weewx rtldavis driver
RUN_WEEWX_AT_BOOT=0        # enable weewx in systemctl to startup at boot

### IMPORTANT - THIS ASSUMES SOURCES ARE IN ${HOME}/src
### IMPORTANT - THIS ASSUMES SOURCES ARE IN ${HOME}/src
### IMPORTANT - THIS ASSUMES SOURCES ARE IN ${HOME}/src
### IMPORTANT - THIS ASSUMES SOURCES ARE IN ${HOME}/src

# extract src.tgz to ${HOME}/src
if [ "x${EXTRACT_SOURCES}" = "x1" ]
then
    echo "...... EXTRACT_SOURCES=1 - running ......."
    tar zxf src.tgz
else
    echo "...... EXTRACT_SOURCES=0 - skipping......."
fi

# fix up permissions since go is picky
MYUSER=`id -un`
MYGROUP=`id -gn`
sudo chown -R ${MYUSER}:${MYGROUP} ${HOME}/src

#----------------------------------------------
# ==> REMINDER - this expects a pip installation <==
# ==> REMINDER - this expects a pip installation <==
# ==> REMINDER - this expects a pip installation <==
# ==> REMINDER - this expects a pip installation <==
#----------------------------------------------
#
# install required packages to enable building/running the software suite
# some of these might actually not be needed for v5 pip installations in a venv
# but I'll leave them here just in case
#

if [ "x${INSTALL_PREREQS}" = "x1" ]
then
    echo "...... INSTALL_PREREQS=1 - running ......."
    sudo apt-get update 
    sudo apt-get -y install python3-configobj python3-pil python3-serial python3-usb python3-pip python3-ephem python3-cheetah
    sudo apt-get -y install git cmake librtlsdr-dev golang
else
    echo "...... INSTALL_PREREQS=0 - skipping ......"
fi

#-----------------------------------------------
#
# install weewx via the pip method
# and also nginx and hook them together
# then stop weewx (for now) so we can reconfigure it
#
# rather than duplicate the code here, this calls my other repo
# with the end-to-end script for this that can run standalone
#
# if piping wget to bash concerns you, please read the code there
# which hopefully is clear enough to put your mind at ease

if [ "x${INSTALL_WEEWX}" = "x1" ]
then
  # 2025-1117 - reorganized this github set of repos
  echo "...... INSTALL_WEEWX=1 - running ......."
  wget -qO - https://raw.githubusercontent.com/vinceskahan/weewx/refs/heads/main/weewx-pipinstall/install-v5pip.sh | bash
  sudo systemctl stop weewx
else
    echo "...... INSTALL_WEEWX=0 - skipping ......"
fi

#-----------------------------------------------
#
# build and install librtlsdr from scratch
#
# changes - on debian-11 raspi we set the cmake option below to =OFF
#           rather than using the instructions in the older link above so that
#           we suppress librtlsdr writing a conflicting udev rules file into place
#
# you might need to edit the udev rule below if you have different tuner hardware
# so you might want to plug it in and run 'lsusb' and check the vendor and product values
# before proceeding
#

if [ "x${INSTALL_LIBRTLSDR}" = "x1" ]
then
    echo "...... INSTALL_LIBRTLSDR=1 - running ......."
    # set up udev rules
    #
    # for my system with 'lsusb' output containing:
    #    Bus 001 Device 003: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T

    echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", GROUP="adm", MODE="0666", SYMLINK+="rtl_sdr"' > /tmp/udevrules
    sudo mv /tmp/udevrules /etc/udev/rules.d/20.rtsdr.rules

    # install librtlsdr from previously downloaded sources
    cd ${HOME}/src/librtlsdr
    mkdir build
    cd build
    cmake ../ -DINSTALL_UDEV_RULES=OFF -DDETACH_KERNEL_DRIVER=ON
    make
    sudo make install
    sudo ldconfig
else
    echo "...... INSTALL_LIBRTLSDR=0 - skipping ......"
fi

#-----------------------------------------------
#
# build rtldavis (ref:https://github.com/lheijst/rtldavis)
#

if [ "x${BUILD_RTLDAVIS}" = "x1" ]
then
    echo "...... BUILD_RTLDAVIS=1 - running ......."

    # cd there
    cd ${HOME}/src/rtldavis/src/lheijst/rtldavis

    # build and install it
    echo "....building and installing go binaries..."
    sudo GOBIN=/usr/local/bin go install -v .

    # for US users, to test rtldavis, run:
    #    $GOPATH/bin/rtldavis -tf US
    #
    # if you get device busy errors, add to the modprobe blacklisted modules
    # (doing this requires a reboot for the blacklist to take effect)
    #
    # again, for lsb output containing:
    #   Bus 001 Device 003: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T
    #
    echo "....blacklisting driver..."
    echo "blacklist dvb_usb_rtl28xxu" > /tmp/blacklist
    sudo cp /tmp/blacklist /etc/modprobe.d/blacklist_dvd_usb_rtl28xxu
    #
    # then reboot and try 'rtldavis -tf US' again
    #
    # ref: https://forums.raspberrypi.com/viewtopic.php?t=81731
    #
else
    echo "...... BUILD_RTLDAVIS=0 - skipping ......"
fi

#-----------------------------------------------
#
# install the rtldavis weewx driver
# this assumes you did a venv pip installation

if [ "x${INSTALL_RTLDAVIS}" = "x1" ]
then
    echo "...... INSTALL_RTLDAVIS=1 - running ......."
    echo "   activate venv"
    source ${HOME}/weewx-venv/bin/activate
    echo "   install extension"
    weectl extension install -y ${HOME}/src/weewx-rtldavis

    echo "   enable driver"
    weectl station reconfigure --driver=user.rtldavis --no-prompt

    # remove the template instruction from the config file
    echo "editing options..."
    sudo sed -i -e s/\\[options\\]// ${HOME}/weewx-data/weewx.conf

    # US frequencies and imperial units
    echo "editing US settings..."
    echo "  setting frequency"
    echo "  setting rain_bucket_type"
    sed -i -e s:frequency\ =\ EU:frequency\ =\ US:             ${HOME}/weewx-data/weewx.conf
    sed -i -e s:rain_bucket_type\ =\ 1:rain_bucket_type\ =\ 0: ${HOME}/weewx-data/weewx.conf

    # we install rtldavis to a different place than Luc so patch the "cmd =" line
    echo "changing path to rtldavis"
    sed -i -e s:/home/pi/work/bin/rtldavis:/usr/local/bin/rtldavis: ${HOME}/weewx-data/weewx.conf

    # for very verbose logging of readings
    echo "editing debug to set very verbose logging..."
    sed -i -e s:debug_rtld\ =\ 2:debug_rtld\ =\ 3:             ${HOME}/weewx-data/weewx.conf

else
    echo "...... INSTALL_RTLDAVIS=0 - skipping ......"
fi

#-----------------------------------------------

if [ "x${RUN_WEEWX_AT_BOOT}" = "x1" ]
then
    # enable weewx for next reboot
    echo "...... RUN_WEEWX_AT_BOOT=1 - running ......."
    sudo systemctl enable weewx
else
    echo "...... RUN_WEEWX_AT_BOOT=0 - skipping ......"
fi

#-----------------------------------------------
#
# at this point you can run 'sudo systemctl start weewx' to start weewx using the installed driver
# be sure to 'sudo tail -f /var/log/syslog' to watch progress (^C to exit)
#
# patience is required - on a pi4 running a RTL-SDR.COM RTL2832U dongle,
#    it takes over a minute for it to acquire the signal
#
# you might want to set the various driver debug settings to 0
# after you get it working to quiet things down especially if
# you use debug=1 for other reasons in your weewx configuration
#
# if you want to run 'rtldavis' as a non-privileged user, you should reboot here
#
#-----------------------------------------------

