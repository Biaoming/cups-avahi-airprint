FROM alpine:latest
#FROM alpine:3.13.6

# install foo2zjs
ADD /foo2zjs/foo2zjs.tar.gz /
ADD foo2zjs/sihp1020.dl /usr/share/foo2zjs/firmware/

# Install the packages we need. Avahi will be included
RUN echo -e "http://nl.alpinelinux.org/alpine/edge/testing\nhttp://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    apk add --update cups \
	cups-libs \
	cups-pdf \
	cups-client \
	cups-filters \
	cups-dev \
	ghostscript \
	avahi \
	inotify-tools \
	python3 \
	python3-dev \
	py3-pip \
	groff vim \
	build-base \
    wget \
	rsync \
	groff \
	vim && \
    cd /foo2zjs && \
	make && \
	make install && \
	make install-hotplug \
	&& pip3 --no-cache-dir install --upgrade pip \
	&& pip3 install pycups \
	&& rm -rf /var/cache/apk/*

RUN apk del --no-cache cups-dev build-base groff vim

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf
