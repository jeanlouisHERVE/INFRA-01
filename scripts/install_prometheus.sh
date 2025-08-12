#!/bin/bash

#touch install_prometheus.sh ; sudo chmod +x install_prometheus.sh ; sudo vim install_prometheus.sh

#variables
# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

PROMETHEUS_SERVICE_PATH="/etc/systemd/system/prometheus.service"
PUSHGATEWAY_SERVICE_PATH="/etc/systemd/system/pushgateway.service"
ALERTMANAGER_SERVICE_PATH="/etc/systemd/system/alertmanager.service"

PROMETHEUS_YML_PATH="/etc/prometheus/prometheus.yml"
ALERTMANAGER_YML_PATH="/opt/alertmanager/alertmanager.yml"
ANSIBLE_SERVER_IP=""
GRAFANA_SERVER_IP=""
LB_SERVER_IP=""
POSTGRES_SERVER_IP=""
PGWATCH_SERVER_IP=""
SERVERS_IP=("" "" "")

ALERTMANAGER_VERSION="0.28.1"
PUSHGATEWAY_VERSION="1.11.1"

#functions 
check_and_restart_service() {
    local service_name="$1"
    local max_attempts=5
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if systemctl is-active --quiet "$service_name"; then
            echo -e "${GREEN}OK : $service_name is active.${NC}"
            return 0
        else
            echo -e "${RED}KO : $service_name is not active (Attempt $attempt/$max_attempts).${NC}"
            echo "Restarting $service_name..."
            systemctl restart "$service_name"
        fi

        sleep 2 # Give it some time to start
        ((attempt++))
    done

    # Final check
    if systemctl is-active --quiet "$service_name"; then
        echo -e "${GREEN}OK : $service_name is active after $((attempt-1)) attempt(s).${NC}"
        return 0
    else
        echo -e "${RED}ERROR : $service_name failed to start after $max_attempts attempts.${NC}"
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

GRAFANA_SERVER_SHORTNAME=$(extract_shortname $GRAFANA_SERVER_IP)

# Update package lists
sudo apt update
sudo apt install -y awscli
sudo apt install -y prometheus

cd /opt
wget https://github.com/prometheus/pushgateway/releases/download/v$PUSHGATEWAY_VERSION/pushgateway-$PUSHGATEWAY_VERSION.linux-amd64.tar.gz
tar -xzf pushgateway-$PUSHGATEWAY_VERSION.linux-amd64.tar.gz
ln -s pushgateway-$PUSHGATEWAY_VERSION.linux-amd64 pushgateway
useradd --no-create-home --shell /usr/sbin/nologin pushgateway
mkdir -p /var/lib/pushgateway
chown pushgateway:pushgateway /var/lib/pushgateway

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

if [ ! -f "$PUSHGATEWAY_SERVICE_PATH" ]; then
    echo -e "${YELLOW}INFO : Creating pushgateway.service unit file...${NC}"
    sudo tee $PUSHGATEWAY_SERVICE_PATH > /dev/null <<EOF
[Unit]
Description=Pushgateway
Wants=network-online.target
After=network-online.target

[Service]
User=pushgateway
Group=pushgateway
Type=simple
ExecStart=/opt/pushgateway/pushgateway \
  --web.listen-address=":9091" \
  --persistence.file="/var/lib/pushgateway/data"

[Install]
WantedBy=multi-user.target
EOF
else
    echo -e "${GREEN}OK : pushgateway.service already exists.${NC}"
fi


echo -e "${GREEN}Prometheus installation and configuration completed.${NC}"


if [ -e "$ALERTMANAGER_YML_PATH" ]; then
    echo -e "${RED} : File $ALERTMANAGER_YML_PATH already exists. Exiting.${NC}"
else 
    touch $ALERTMANAGER_YML_PATH
fi

cat <<EOF | sudo tee $ALERTMANAGER_YML_PATH > /dev/null
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'web.hook'
receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

cd /opt
wget https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
tar -xzf alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
ln -s alertmanager-$ALERTMANAGER_VERSION.linux-amd64 alertmanager
sudo mkdir -p /var/lib/alertmanager
sudo chmod 755 /var/lib/alertmanager
sudo useradd --system --no-create-home --shell /bin/false alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

if [ ! -f "$ALERTMANAGER_SERVICE_PATH" ]; then
    echo -e "${YELLOW}INFO : Creating alertmanager.service unit file...${NC}"
    sudo tee $ALERTMANAGER_SERVICE_PATH > /dev/null <<EOF
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/opt/alertmanager/alertmanager \
  --config.file=/opt/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
else
    echo -e "${GREEN}OK : alertmanager.service already exists.${NC}"
fi


# Reload systemd daemon and start Prometheus service
sudo systemctl daemon-reload
timer 10
sudo systemctl enable prometheus
sudo systemctl enable pushgateway
sudo systemctl enable alertmanager
check_and_restart_service prometheus
check_and_restart_service pushgateway
check_and_restart_service alertmanager
