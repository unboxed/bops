FROM debian:bullseye-slim

# Run security updates and install packages
RUN bash -c "export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -qq && \
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && \
    apt-get install -y apt-utils curl locales dnsmasq && \
    apt-get upgrade -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*"

EXPOSE 53 53/udp

ENTRYPOINT ["dnsmasq", "-k"]
