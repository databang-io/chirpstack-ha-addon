#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: ChirpStack 4.0
# Runs ChirpStack LoRaWAN Network Server
# ==============================================================================

bashio::log.info "Starting ChirpStack 4.0..."

# Parse configuration
declare log_level
declare mqtt_server
declare mqtt_username  
declare mqtt_password
declare basic_station_enabled
declare basic_station_bind
declare packet_forwarder_enabled
declare packet_forwarder_bind
declare chirpstack_config
declare gateway_bridge_config

log_level=$(bashio::config 'log_level')
mqtt_server=$(bashio::config 'mqtt.server')
mqtt_username=$(bashio::config 'mqtt.username')
mqtt_password=$(bashio::config 'mqtt.password')
basic_station_enabled=$(bashio::config 'basic_station.enabled')
basic_station_bind=$(bashio::config 'basic_station.bind')
packet_forwarder_enabled=$(bashio::config 'packet_forwarder.enabled')
packet_forwarder_bind=$(bashio::config 'packet_forwarder.bind')
chirpstack_config=$(bashio::config 'chirpstack_config')
gateway_bridge_config=$(bashio::config 'gateway_bridge_config')

bashio::log.info "Log level: ${log_level}"
bashio::log.info "MQTT server: ${mqtt_server}"
bashio::log.info "Basic Station enabled: ${basic_station_enabled}"
bashio::log.info "Packet Forwarder enabled: ${packet_forwarder_enabled}"

# Clean up any conflicting files and create proper directories
rm -f /config/chirpstack-config 2>/dev/null || true
rm -rf /config/chirpstack 2>/dev/null || true
mkdir -p /config/chirpstack
mkdir -p /data/chirpstack
mkdir -p /share/chirpstack

bashio::log.info "Cleaned up conflicting files and created directories"

# Process the ChirpStack configuration from the GUI
bashio::log.info "Creating ChirpStack configuration from GUI settings..."
echo "${chirpstack_config}" > /tmp/chirpstack_base.toml

# Update MQTT settings from GUI
sed -i "s|tcp://core-mosquitto:1883|${mqtt_server}|g" /tmp/chirpstack_base.toml
sed -i "s|username=\"chirpstack\"|username=\"${mqtt_username}\"|g" /tmp/chirpstack_base.toml
sed -i "s|password=\"\"|password=\"${mqtt_password}\"|g" /tmp/chirpstack_base.toml
sed -i "s|level=\"info\"|level=\"${log_level}\"|g" /tmp/chirpstack_base.toml

# Process Gateway Bridge configuration if enabled
if bashio::var.true "${basic_station_enabled}" || bashio::var.true "${packet_forwarder_enabled}"; then
    bashio::log.info "Creating Gateway Bridge configuration from GUI settings..."
    
    echo "${gateway_bridge_config}" > /tmp/gateway_bridge_base.toml
    
    # Update MQTT settings from GUI
    sed -i "s|tcp://core-mosquitto:1883|${mqtt_server}|g" /tmp/gateway_bridge_base.toml
    sed -i "s|username=\"chirpstack\"|username=\"${mqtt_username}\"|g" /tmp/gateway_bridge_base.toml
    sed -i "s|password=\"\"|password=\"${mqtt_password}\"|g" /tmp/gateway_bridge_base.toml
    sed -i "s|bind=\"0.0.0.0:3001\"|bind=\"${basic_station_bind}\"|g" /tmp/gateway_bridge_base.toml
    sed -i "s|udp_bind=\"0.0.0.0:1700\"|udp_bind=\"${packet_forwarder_bind}\"|g" /tmp/gateway_bridge_base.toml
    
    # Set log level based on string values
    case "${log_level}" in
        "trace") log_num=5 ;;
        "debug") log_num=5 ;;
        "info")  log_num=4 ;;
        "warn")  log_num=3 ;;
        "error") log_num=2 ;;
        "fatal") log_num=1 ;;
        *) log_num=4 ;;
    esac
    sed -i "s|log_level=4|log_level=${log_num}|g" /tmp/gateway_bridge_base.toml
    
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
bashio::log.info "Starting ChirpStack with GUI configuration..."
/usr/local/bin/chirpstack --config /config/chirpstack/chirpstack.toml &
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