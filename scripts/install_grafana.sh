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

sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl restart grafana-server

if isservicesactive grafana-server; then
    echo -e "${GREEN}OK : Grafana is active.${NC}"
else
    echo -e "${RED}KO : Grafana is not active.${NC}"
    exit 1
fi

echo -e "${GREEN}Grafana installation and configuration completed.${NC}"
