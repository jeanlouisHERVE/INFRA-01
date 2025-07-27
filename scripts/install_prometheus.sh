#!/bin/bash

#touch install_prometheus.sh ; sudo chmod +x install_prometheus.sh ; sudo vim install_prometheus.sh

#variables
# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PROMETHEUS_SERVICE_PATH="/etc/systemd/system/prometheus.service"
PROMETHEUS_YML_PATH="/etc/prometheus/prometheus.yml"
ANSIBLE_SERVER_IP=""
GRAFANA_SERVER_IP="34.235.114.80"
LB_SERVER_IP=""
POSTGRES_SERVER_IP=""
PGWATCH_SERVER_IP=""
SERVERS_IP=("" "" "")

ALERTMANAGER_VERSION="0.28.0"

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

extract_shortname() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Usage: extract_shortname <ip_address>.${NC}"
        return 1
    fi

    regex='^([0-9]+\.[0-9]+)\..*'
    
    if [[ "$1" =~ $regex ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        echo "Invalid IP address format"
        return 1
    fi
}

timer() {
  echo -e "${YELLOW}INFO : Timer started for $1 seconds.${NC}"
  sleep "$1"
  echo -e "${GREEN}OK : Timer finished.${NC}"
}

ANSIBLE_SERVER_SHORTNAME=$(extract_shortname $ANSIBLE_SERVER_IP)
GRAFANA_SERVER_SHORTNAME=$(extract_shortname $GRAFANA_SERVER_IP)
LB_SERVER_SHORTNAME=$(extract_shortname $LB_SERVER_IP)
POSTGRES_SERVER_SHORTNAME=$(extract_shortname $POSTGRES_SERVER_IP)
PGWATCH_SERVER_SHORTNAME=$(extract_shortname $PGWATCH_SERVER_IP)

# Update package lists
sudo apt update
sudo apt install -y awscli
sudo apt install -y prometheus

if [ -e "$PROMETHEUS_YML_PATH" ]; then
    echo -e "${RED} : File $PROMETHEUS_YML_PATH already exists. Exiting.${NC}"
else 
    touch $PROMETHEUS_YML_PATH
fi

cat <<EOF | sudo tee $PROMETHEUS_YML_PATH > /dev/null
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'example'

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "prometheus.rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.

  - job_name: "prometheus"
    metrics_path: /metrics
    scrape_interval: 60s
    scheme: http
    static_configs:
      - targets: ["localhost:9090"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
  - job_name: 'Pushgateway'
    honor_labels: true
    static_configs:
      - targets: ['localhost:9091']
EOF

if [ -n "$GRAFANA_SERVER_IP" ]; then
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'grafana'
    static_configs:
      - targets: ["$GRAFANA_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

if [ -n "$GRAFANA_ALLOY_SERVER_IP" ]; then
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'grafanaalloy'
    static_configs:
      - targets: ["$GRAFANA_ALLOY_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [__address__]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

if [ -n "$ANSIBLE_SERVER_IP" ]; then
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'ansible'
    static_configs:
      - targets: ["$ANSIBLE_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

if [ -n "$LB_SERVER_IP" ]; then
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'loadbalancer'
    static_configs:
      - targets: ["$LB_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

if [ -n "$POSTGRES_SERVER_IP" ]; then
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'postgres'
    static_configs:
      - targets: ["$POSTGRES_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
  - job_name: 'postgres'
    static_configs:
      - targets: ["$POSTGRES_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

if [ -n "$PGWATCH_SERVER_IP" ]; then
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'pgwatch'
    static_configs:
      - targets: ["$PGWATCH_SERVER_IP:9100"]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [__address__]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

TARGETS=()
for ip in "${SERVERS_IP[@]}"; do
    if [ -n "$ip" ]; then
        TARGETS+=("\"$ip:9100\"")
    fi
done

if [ ${#TARGETS[@]} -gt 0 ]; then
    # Joining the TARGETS array with commas
    targets_list=$(IFS=,; echo "${TARGETS[*]}")
    cat <<EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: 'servers'
    static_configs:
      - targets: [${targets_list}]
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):\d+'
        target_label: instance
        replacement: '\${1}'
      - source_labels: [instance]
        regex: '^(\d+\.\d+)\.\d+\.\d+'
        target_label: shortname
        replacement: '\${1}'
EOF
fi

cat <<EOF | sudo tee -a $PROMETHEUS_YML_PATH > /dev/null
remote_write:
  - url: "http://localhost:9090/receive"
EOF




if [ ! -f "$PROMETHEUS_SERVICE_PATH" ]; then
    echo -e "${YELLOW}INFO : Creating prometheus.service unit file...${NC}"
    sudo tee $PROMETHEUS_SERVICE_PATH > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
else
    echo -e "${GREEN}OK : prometheus.service already exists.${NC}"
fi

# Reload systemd daemon and start Prometheus service
sudo systemctl daemon-reload
timer 10
sudo systemctl restart prometheus

if isservicesactive prometheus; then
    echo -e "${GREEN}OK : Prometheus is active.${NC}"
else
    echo -e "${RED}KO : Prometheus is not active.${NC}"
    exit 1
fi

echo -e "${GREEN}Prometheus installation and configuration completed.${NC}"

#alertmanager 
# curl -LO https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION-rc.0/alertmanager-$ALERTMANAGER_VERSION-rc.0.linux-amd64.tar.gz
# tar -xzf alertmanager-$ALERTMANAGER_VERSION-rc.0.linux-amd64.tar.gz
# sudo tee /etc/systemd/system/alertmanager.service <<EOF
# [Unit]
# Description=Alertmanager
# After=network.target

# [Service]
# User=ubuntu
# ExecStart=/home/alertmanager-$ALERTMANAGER_VERSION-rc.0.linux-amd64/alertmanager --config.file=/home/alertmanager-$ALERTMANAGER_VERSION-rc.0.linux-amd64/alertmanager.yml
# Restart=always

# [Install]
# WantedBy=multi-user.target
# EOF

# sudo systemctl start alertmanager
# echo -e "${GREEN}Alertmanager installation and configuration completed.${NC}"