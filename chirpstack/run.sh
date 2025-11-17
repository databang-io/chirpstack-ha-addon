#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: ChirpStack 4.0 - ORGANIZED CONFIG VERSION - FIXED v3
# Runs ChirpStack LoRaWAN Network Server with Gateway Bridge 4.1.1
# FIXED: Config directory instead of config file
# ==============================================================================

bashio::log.info "Starting ChirpStack 4.0..."

# Parse configuration
declare mqtt_server
declare mqtt_username  
declare mqtt_password
declare chirpstack_log_level
declare chirpstack_api_bind
declare chirpstack_api_secret
declare chirpstack_network_id
declare chirpstack_database_dsn
declare chirpstack_integrations_enabled
declare chirpstack_regions
declare chirpstack_advanced_config
declare gateway_bridge_log_level
declare basic_station_enabled
declare basic_station_bind
declare packet_forwarder_enabled
declare packet_forwarder_bind
declare gateway_bridge_advanced_config

# MQTT Settings (shared)
mqtt_server=$(bashio::config 'mqtt.server')
mqtt_username=$(bashio::config 'mqtt.username')
mqtt_password=$(bashio::config 'mqtt.password')

# ChirpStack Settings
chirpstack_log_level=$(bashio::config 'chirpstack.log_level')
chirpstack_api_bind=$(bashio::config 'chirpstack.api_bind')
chirpstack_api_secret=$(bashio::config 'chirpstack.api_secret')
chirpstack_network_id=$(bashio::config 'chirpstack.network_id')
chirpstack_database_dsn=$(bashio::config 'chirpstack.database_dsn')
chirpstack_integrations_enabled=$(bashio::config 'chirpstack.integrations_enabled')
chirpstack_regions=$(bashio::config 'chirpstack.regions')
chirpstack_advanced_config=$(bashio::config 'chirpstack.advanced_config')

# Gateway Bridge Settings
gateway_bridge_log_level=$(bashio::config 'gateway_bridge.log_level')
basic_station_enabled=$(bashio::config 'gateway_bridge.basic_station.enabled')
basic_station_bind=$(bashio::config 'gateway_bridge.basic_station.bind')
packet_forwarder_enabled=$(bashio::config 'gateway_bridge.packet_forwarder.enabled')
packet_forwarder_bind=$(bashio::config 'gateway_bridge.packet_forwarder.bind')
gateway_bridge_advanced_config=$(bashio::config 'gateway_bridge.advanced_config')

bashio::log.info "MQTT server: ${mqtt_server}"
bashio::log.info "ChirpStack log level: ${chirpstack_log_level}"
bashio::log.info "Gateway Bridge log level: ${gateway_bridge_log_level}"
bashio::log.info "Basic Station enabled: ${basic_station_enabled}"
bashio::log.info "Packet Forwarder enabled: ${packet_forwarder_enabled}"

# Clean up any conflicting files and create proper directories
rm -f /config/chirpstack-config 2>/dev/null || true
rm -rf /config/chirpstack 2>/dev/null || true
mkdir -p /config/chirpstack
mkdir -p /data/chirpstack
mkdir -p /share/chirpstack

bashio::log.info "Cleaned up conflicting files and created directories"

# Generate ChirpStack configuration from organized settings
bashio::log.info "Generating ChirpStack configuration from organized settings..."
cat > /tmp/chirpstack_base.toml << EOF
[logging]
level="${chirpstack_log_level}"
json=false

[database]
dsn="${chirpstack_database_dsn}"

[redis]
servers = []

[integration]
enabled = ["${chirpstack_integrations_enabled}"]

[network]
net_id="${chirpstack_network_id}"

[api]
bind="${chirpstack_api_bind}"
secret="${chirpstack_api_secret}"

[integration.mqtt]
server="${mqtt_server}"
username="${mqtt_username}"
password="${mqtt_password}"

${chirpstack_regions}

# Advanced configuration from user
${chirpstack_advanced_config}
EOF

# Generate Gateway Bridge configuration if enabled
if bashio::var.true "${basic_station_enabled}" || bashio::var.true "${packet_forwarder_enabled}"; then
    bashio::log.info "Generating Gateway Bridge configuration from organized settings..."
    
    # Convert log level to numeric value for Gateway Bridge
    case "${gateway_bridge_log_level}" in
        "trace") log_num=5 ;;
        "debug") log_num=5 ;;
        "info")  log_num=4 ;;
        "warn")  log_num=3 ;;
        "error") log_num=2 ;;
        "fatal") log_num=1 ;;
        *) log_num=4 ;;
    esac
    
    cat > /tmp/gateway_bridge_base.toml << EOF
[general]
log_level=${log_num}

EOF

    # Add Basic Station backend if enabled
    if bashio::var.true "${basic_station_enabled}"; then
        cat >> /tmp/gateway_bridge_base.toml << EOF
[backend.basic_station]
bind="${basic_station_bind}"

EOF
    fi

    # Add Packet Forwarder backend if enabled
    if bashio::var.true "${packet_forwarder_enabled}"; then
        cat >> /tmp/gateway_bridge_base.toml << EOF
[backend.semtech_udp]
udp_bind="${packet_forwarder_bind}"

EOF
    fi

    # Add MQTT integration
    cat >> /tmp/gateway_bridge_base.toml << EOF
[integration.mqtt.auth]
type="generic"

[integration.mqtt.auth.generic]
servers=["${mqtt_server}"]
username="${mqtt_username}"
password="${mqtt_password}"

# Advanced configuration from user
${gateway_bridge_advanced_config}
EOF
    
    cp /tmp/gateway_bridge_base.toml /config/chirpstack/chirpstack-gateway-bridge.toml
    
    bashio::log.info "Gateway Bridge configuration file created at /config/chirpstack/chirpstack-gateway-bridge.toml"
fi

# Copy processed config to proper location
cp /tmp/chirpstack_base.toml /config/chirpstack/chirpstack.toml

bashio::log.info "ChirpStack configuration file created at /config/chirpstack/chirpstack.toml"

# Display final configuration files for debugging
bashio::log.info "Final ChirpStack configuration:"
cat /config/chirpstack/chirpstack.toml

if bashio::var.true "${basic_station_enabled}" || bashio::var.true "${packet_forwarder_enabled}"; then
    bashio::log.info "Final Gateway Bridge configuration:"
    cat /config/chirpstack/chirpstack-gateway-bridge.toml
fi

# Debug directory creation
bashio::log.info "Checking directories after cleanup..."
ls -la /config/ | grep chirpstack || bashio::log.info "No chirpstack entries in /config/"
ls -la /data/ | grep chirpstack || bashio::log.info "No chirpstack entries in /data/"

# Start ChirpStack and Gateway Bridge
bashio::log.info "Starting ChirpStack Network Server with Gateway Bridge..."
bashio::log.info "Working directory: $(pwd)"

# Test ChirpStack binary version
bashio::log.info "ChirpStack binary version:"
/usr/local/bin/chirpstack --help | head -3

# Start ChirpStack using GUI configuration
bashio::log.info "Starting ChirpStack with config directory..."
/usr/local/bin/chirpstack --config /config/chirpstack &
CHIRPSTACK_PID=$!

# Wait a bit and check if it started
sleep 3
if kill -0 $CHIRPSTACK_PID 2>/dev/null; then
    bashio::log.info "ChirpStack process is running (PID: $CHIRPSTACK_PID)"
    
    # Start Gateway Bridge now that ChirpStack is working
    if bashio::var.true "${basic_station_enabled}" || bashio::var.true "${packet_forwarder_enabled}"; then
        bashio::log.info "Starting ChirpStack Gateway Bridge v4.1.1..."
        sleep 2
        /usr/local/bin/chirpstack-gateway-bridge --config /config/chirpstack/chirpstack-gateway-bridge.toml &
        GATEWAY_BRIDGE_PID=$!
        
        sleep 2
        if kill -0 $GATEWAY_BRIDGE_PID 2>/dev/null; then
            bashio::log.info "Gateway Bridge is running (PID: $GATEWAY_BRIDGE_PID)"
        else
            bashio::log.error "Gateway Bridge failed to start"
        fi
    else
        bashio::log.info "Gateway Bridge disabled in configuration"
    fi
else
    bashio::log.error "ChirpStack process died immediately"
fi

# Function to handle shutdown
cleanup() {
    bashio::log.info "Shutting down ChirpStack and Gateway Bridge..."
    kill $CHIRPSTACK_PID 2>/dev/null
    if [[ -n $GATEWAY_BRIDGE_PID ]]; then
        kill $GATEWAY_BRIDGE_PID 2>/dev/null
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Wait for processes to exit
wait