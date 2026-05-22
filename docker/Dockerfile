#--------------------------------------------
# credits:
#    based on https://raw.githubusercontent.com/WeatheredScientist/weewx-rtldavis/refs/heads/main/Dockerfile
#--------------------------------------------
FROM debian:trixie-20260518 AS base
ENV DEBIAN_FRONTEND=noninteractive
#--------------------------------------------
# copy things into place first
#--------------------------------------------
COPY 98-rtlsdr.rules       /etc/udev/rules.d/98-rtlsdr.rules
COPY blacklist_rtlsdr.conf /etc/modprobe.d/blacklist_rtlsdr.conf
COPY logging.additions     /tmp/logging.additions
COPY 01_nodoc              /etc/dpkg/dpkg.cfg.d/01_nodoc
#--------------------------------------------
# blacklist the rtlsdr module
#--------------------------------------------
RUN mkdir -p /etc/modprobe.d && echo "blacklist dvb_usb_rtl28xxu" > /etc/modprobe.d/blacklist_rtlsdr.conf
#--------------------------------------------
# install packages
#--------------------------------------------
RUN apt-get update && apt-get install -y \
    tzdata \
    git cmake libusb-1.0-0-dev libusb-dev \
    python3-pip python3-venv \
    curl pkg-config busybox \
    golang vim usbutils udev sqlite3 && \
    rm -rf /var/lib/apt/lists/*
#--------------------------------------------
# set our timezone
#--------------------------------------------
RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
#--------------------------------------------
# TO DO - clean up things for size
#--------------------------------------------
#
#
#--------------------------------------------
# build and install librtlsdr then rtldavis
     #git clone https://github.com/steve-m/librtlsdr.git && \
#--------------------------------------------
RUN cd /tmp && \
    curl -L -o /tmp/src.tgz https://github.com/weewx-contrib/weewx-rtldavis/raw/refs/heads/main/src.tgz && \
      cd /tmp && tar zxf src.tgz && \
      cd /tmp/src/librtlsdr && \
        mkdir build && cd build && \
        cmake ../ -DINSTALL_UDEV_RULES=OFF -DDETACH_KERNEL_DRIVER=ON -DENABLE_ZEROCOPY=OFF && \
        make -j2 && make install && ldconfig && \
      cd /tmp/src/rtldavis/src/lheijst/rtldavis && \
        GOBIN=/usr/local/bin go install -buildvcs=false -v .
#--------------------------------------------
# install weewx
#  configure the station and rtldavis
#  set debug appropriately
#  tweak weewx logging for dockerizing
#  clean up previously downloaded sources
#
# note this uses --copies to hopefully put
# all the actual python files into the venv
# so we can copy the venv as a whole
#--------------------------------------------
RUN python3 -m venv --copies /opt/weewx-venv && \
    /opt/weewx-venv/bin/pip install -q weewx requests && \
    /opt/weewx-venv/bin/weectl station create /opt/weewx-data --no-prompt && \
    /opt/weewx-venv/bin/weectl extension install /tmp/src/weewx-rtldavis --yes --config=/opt/weewx-data/weewx.conf && \
    /opt/weewx-venv/bin/weectl station reconfigure --driver=user.rtldavis --no-prompt --config=/opt/weewx-data/weewx.conf && \
    sed -i 's/frequency = EU/frequency = US/' /opt/weewx-data/weewx.conf && \
    sed -i 's/rain_bucket_type = 1/rain_bucket_type = 0/' /opt/weewx-data/weewx.conf && \
    sed -i 's|cmd = /home/pi/work/bin/rtldavis|cmd = /usr/local/bin/rtldavis|' /opt/weewx-data/weewx.conf && \
    sed -i 's/cmd = \/usr\/local\/bin\/rtldavis \[options\]/cmd = \/usr\/local\/bin\/rtldavis/' /opt/weewx-data/weewx.conf &&  \
    sed -i 's/debug = 0/debug = 1/' /opt/weewx-data/weewx.conf && \
    cat /tmp/logging.additions >> /opt/weewx-data/weewx.conf && \
    rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#----------------------------------------------------------------
# create a small image based on the build artifacts above
# also recreating the venv and set our desired timezone
#
# also do a little cleanup on apt artifacts to minimize space
# and dial back rtlsdr logging a bit from the default '2' to '1'
#----------------------------------------------------------------
FROM debian:trixie-20260518 AS minimal
COPY --from=base /opt/weewx-venv /opt/weewx-venv
COPY --from=base /opt/weewx-data /opt/weewx-data
COPY --from=base /usr/local      /usr/local
COPY --from=base /entrypoint.sh  /entrypoint.sh
RUN apt update \
    && apt install -y busybox libexpat1 libusb-1.0-0 python3 python3-venv tzdata \
    && apt-get clean autoclean                \
    && apt-get autoremove --yes               \
    && rm -rf /var/lib/{apt,dpkg,cache,log}   \
    && rm -rf /usr/share/{doc,man,info}       \
    && rm /opt/weewx-venv/bin/python3         \
    && python3 -m venv /opt/weewx-venv        \
    && rm /etc/localtime                      \
    && ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime \
    && sed -i 's/debug_rtld = 2/debug_rtld = 1/' /opt/weewx-data/weewx.conf \
    && chmod +x /entrypoint.sh

CMD ["/opt/weewx-venv/bin/weewxd", "/opt/weewx-data/weewx.conf"]

