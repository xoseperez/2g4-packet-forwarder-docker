#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Balena.io specific functions
# -----------------------------------------------------------------------------

function push_variables {
    if [[ "$BALENA_DEVICE_UUID" != "" ]]
    then

        ID=$(curl -sX GET "https://api.balena-cloud.com/v5/device?\$filter=uuid%20eq%20'$BALENA_DEVICE_UUID'" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $BALENA_API_KEY" | \
            jq ".d | .[0] | .id")

        TAG=$(curl -sX POST \
            "https://api.balena-cloud.com/v5/device_tag" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $BALENA_API_KEY" \
            --data "{ \"device\": \"$ID\", \"tag_key\": \"EUI\", \"value\": \"$GATEWAY_EUI\" }" > /dev/null)

    fi
}

function idle {
   [[ "$BALENA_DEVICE_UUID" != "" ]] && balena-idle || exit 1
}

# -----------------------------------------------------------------------------
# Server
# -----------------------------------------------------------------------------

TTN_REGION=${TTN_REGION:-"eu1"}
SERVER_HOST=${SERVER_HOST:-"${TTN_REGION}.cloud.thethings.network"} 
SERVER_PORT=${SERVER_PORT:-1700}

# -----------------------------------------------------------------------------
# Gateway EUI
# -----------------------------------------------------------------------------

if [[ -z $GATEWAY_EUI ]]; then
    GATEWAY_EUI_NIC=${GATEWAY_EUI_NIC:-"eth0"}
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="eth0"
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="wlan0"
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        GATEWAY_EUI_NIC="usb0"
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        # Last chance: get the most used NIC based on received bytes
        GATEWAY_EUI_NIC=$(cat /proc/net/dev | tail -n+3 | sort -k2 -nr | head -n1 | cut -d ":" -f1 | sed 's/ //g')
    fi
    if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
        echo -e "\033[91mERROR: No network interfaces found. Cannot set gateway EUI.\033[0m"
        idle
    fi
    GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
fi
GATEWAY_EUI=${GATEWAY_EUI^^}

# -----------------------------------------------------------------------------
# Device (port) configuration
# -----------------------------------------------------------------------------

# Default device
DEVICE=${DEVICE:-"/dev/ttyACM0"}

# -----------------------------------------------------------------------------
# Debug
# -----------------------------------------------------------------------------

echo ""
echo "------------------------------------------------------------------"
echo "Device:        $DEVICE"
echo "Server:        $SERVER_HOST:$SERVER_PORT"
if [[ ! -z $GATEWAY_EUI_NIC ]]; then
echo "Main NIC:      $GATEWAY_EUI_NIC"
fi
echo "Gateway EUI:   $GATEWAY_EUI"
echo "------------------------------------------------------------------"
echo ""

# Push variables to Balena
push_variables

# -----------------------------------------------------------------------------
# Generate dynamic configuration files
# -----------------------------------------------------------------------------

sed -i "s#\"tty_path\":\s*.*,#\"tty_path\": \"$DEVICE\",#" global_conf.json
sed -i "s#\"gateway_ID\":\s*.*,#\"gateway_ID\": \"$GATEWAY_EUI\",#" global_conf.json
sed -i "s#\"server_address\":\s*.*,#\"server_address\": \"$SERVER_HOST\",#" global_conf.json
sed -i "s#\"serv_port_up\":\s*.*,#\"serv_port_up\": $SERVER_PORT,#" global_conf.json
sed -i "s#\"serv_port_down\":\s*.*,#\"serv_port_down\": $SERVER_PORT,#" global_conf.json

# -----------------------------------------------------------------------------
# Start packet forwarders
# -----------------------------------------------------------------------------

./lora_pkt_fwd
