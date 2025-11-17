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

# Create configuration directory
mkdir -p /config/chirpstack

# Process the ChirpStack configuration from the GUI
bashio::log.info "Creating ChirpStack configuration from GUI settings..."
echo "${chirpstack_config}" > /tmp/chirpstack_base.toml

# Update MQTT settings from GUI
sed -i "s|tcp://core-mosquitto:1883|${mqtt_server}|g" /tmp/chirpstack_base.toml
sed -i "s|username=\"chirpstack\"|username=\"${mqtt_username}\"|g" /tmp/chirpstack_base.toml
sed -i "s|password=\"\"|password=\"${mqtt_password}\"|g" /tmp/chirpstack_base.toml
sed -i "s|level=\"info\"|level=\"${log_level}\"|g" /tmp/chirpstack_base.toml

cp /tmp/chirpstack_base.toml /config/chirpstack/chirpstack.toml

bashio::log.info "ChirpStack configuration file created at /config/chirpstack/chirpstack.toml"

# Gateway Bridge temporarily disabled due to build issues
bashio::log.warning "Gateway Bridge is temporarily disabled due to installation issues"
bashio::log.info "You can connect gateways directly to ChirpStack via external Gateway Bridge"

# Display final configuration files for debugging
bashio::log.info "Final ChirpStack configuration:"
cat /config/chirpstack/chirpstack.toml

# Start ChirpStack only (Gateway Bridge disabled)
bashio::log.info "Starting ChirpStack Network Server..."
/usr/local/bin/chirpstack --config /config/chirpstack/chirpstack.toml &
CHIRPSTACK_PID=$!

# Function to handle shutdown
cleanup() {
    bashio::log.info "Shutting down ChirpStack..."
    kill $CHIRPSTACK_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Wait for processes to exit
wait