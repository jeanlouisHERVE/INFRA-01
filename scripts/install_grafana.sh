#!/bin/bash

#touch install_grafana.sh ; sudo chmod +x install_grafana.sh ; sudo vim install_grafana.sh

#variables
# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

#functions 
isservicesactive () {
    if systemctl is-active --quiet $1; then
        echo -e "${GREEN}$1 is running.${NC}"
        return 0
    else
        echo -e "${RED}$1 is not running.${NC}"
        return 1
    fi
}

#script
sudo apt update
sudo apt install -y awscli
sudo apt install -y jq
sudo apt install -y apt-transport-https software-properties-common wget libfontconfig1
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://packages.grafana.com/gpg.key | gpg --dearmor | sudo tee /usr/share/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt -y install grafana
sudo chown grafana:grafana /etc/grafana/grafana.ini
sudo chmod 640 /etc/grafana/grafana.ini

if [ ! -f "$PROMETHEUS_SERVICE_PATH" ]; then
    echo -e "${YELLOW}INFO : Creating grafana.service unit file...${NC}"
    sudo tee $PROMETHEUS_SERVICE_PATH > /dev/null <<EOF
[Unit]
Description=Grafana instance
Documentation=http://docs.grafana.org
Wants=network-online.target
After=network-online.target

[Service]
User=grafana
Group=grafana
Type=simple
ExecStart=/usr/sbin/grafana-server \
  --config=/etc/grafana/grafana.ini \
  --homepath=/usr/share/grafana \
  --packaging=deb cfg:default.paths.data=/var/lib/grafana \
  cfg:default.paths.logs=/var/log/grafana \
  cfg:default.paths.plugins=/var/lib/grafana/plugins
Restart=on-failure
LimitNOFILE=10000
TimeoutStopSec=20
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
else
    echo -e "${GREEN}OK : grafana.service already exists.${NC}"
fi


sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

isservicesactive grafana-server

echo -e "${GREEN}Grafana installation and configuration completed.${NC}"
