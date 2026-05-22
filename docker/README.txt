
Dockerizing  weewx-rtldavis
===========================

To build:
   docker build -t weertlsdr .

To run:
   docker compose up -d

To log into a running container to look around:
   docker exec -it weertlsdr bash
   (run 'exit' to log out of the running container)

Contents here
=============

docker-compose.yml    - runs the built image, passing the USB device through
                        and creating persistent storage under /mnt/weertlsdr

Dockerfile            - builds a rtlsdr reasonably minimal weewx-rtldavis image

000-howto             - odds and ends for getting the RTL-SDR running and tested

01_nodoc              - suppresses apt from installing documentation files (for size)
98-rtlsdr.rules       - udev rules to create 
blacklist_rtlsdr.conf - blacklist the detected module from the kernel
entrypoint.sh         - this is the actual file that executes things
logging.additions     - cause weewx to log to stdout and not need syslog


Credits
=======
Based on https://github.com/weatheredscientist/weewx-rtldavis
Thank you for blazing the trail !!!


