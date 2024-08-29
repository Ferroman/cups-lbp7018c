FROM debian:stable-slim

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "America/New_York"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password

LABEL org.opencontainers.image.source="https://github.com/ferroman/cups-lbp7018c"
LABEL org.opencontainers.image.description="CUPS Printer Server with preconfigured LBP7018C"
LABEL org.opencontainers.image.author="Bohdan Frankovskyi <bfrankovskyi@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/ferroman/cups-lbp7018c/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT

# Install dependencies
RUN apt-get update -qq  && apt-get upgrade -qqy \
    && apt-get install -qqy \
    apt-utils \
    usbutils \
    cups \
    cups-filters \
    printer-driver-all \
    printer-driver-cups-pdf \
    printer-driver-foo2zjs \
    foomatic-db-compressed-ppds \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    avahi-daemon \
    libglade2-0 \
    libatk1.0-0 \
    libcairo2 \
    libgtk2.0-0 \
    libpango1.0-0 \
    libc6 \
    libjpeg62 \
    libxml2 \
    libstdc++6 \
    libpopt0 \
    wget

EXPOSE 631
EXPOSE 5353/udp

# Download the Canon CAPT driver tarball
RUN wget https://gdlp01.c-wss.com/gds/6/0100004596/05/linux-capt-drv-v271-uken.tar.gz -O /tmp/linux-capt-drv.tar.gz

# COPY ./linux-capt-drv.tar.gz /tmp/linux-capt-drv.tar.gz
RUN tar -xzf /tmp/linux-capt-drv.tar.gz -C /tmp && \
  dpkg -i /tmp/linux-capt-drv-v271-uken/32-bit_Driver/Debian/cndrvcups-common_3.21-1_i386.deb && \
  dpkg -i /tmp/linux-capt-drv-v271-uken/32-bit_Driver/Debian/cndrvcups-capt_2.71-1_i386.deb

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

# back up cups configs in case used does not add their own
RUN cp -rp /etc/cups /etc/cups-bak
VOLUME [ "/etc/cups" ]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
