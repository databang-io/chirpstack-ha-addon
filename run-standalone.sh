#!/bin/bash

echo "🧪 Creating standalone ChirpStack test environment..."

# Function to create a mock bashio environment
create_mock_bashio() {
    mkdir -p /tmp/mock-bashio
    cat > /tmp/mock-bashio/bashio << 'EOF'
#!/bin/bash

# Mock bashio functions for standalone testing
bashio::log.info() { echo "[INFO] $*"; }
bashio::log.error() { echo "[ERROR] $*"; }
bashio::log.warning() { echo "[WARNING] $*"; }

bashio::config() {
    case "$1" in
        'log_level') echo "info" ;;
        'mqtt.server') echo "tcp://mosquitto-test:1883" ;;
        'mqtt.username') echo "chirpstack" ;;
        'mqtt.password') echo "testpass" ;;
        'basic_station.enabled') echo "true" ;;
        'basic_station.bind') echo "0.0.0.0:3001" ;;
        'packet_forwarder.enabled') echo "true" ;;
        'packet_forwarder.bind') echo "0.0.0.0:1700" ;;
        'chirpstack_config') cat << 'CONFIG_EOF'
[logging]
level="info"
json=false

[postgresql]
dsn="postgres://chirpstack:chirpstack@postgres-test:5432/chirpstack?sslmode=disable"

[redis]
servers=["redis://redis-test:6379"]

[network]
net_id="000000"

[api]
bind="0.0.0.0:8080"
secret="test-secret-key-change-in-production"

[integration.mqtt]
server="tcp://mosquitto-test:1883"
username="chirpstack"
password="testpass"
event_topic="application/{{application_id}}/device/{{device_eui}}/event/{{event}}"

[regions.eu868]
name="eu868"
CONFIG_EOF
        ;;
        'gateway_bridge_config') cat << 'GW_CONFIG_EOF'
[general]
log_level=4

[backend.basic_station]
bind="0.0.0.0:3001"

[backend.semtech_udp]
udp_bind="0.0.0.0:1700"

[integration]
marshaler="protobuf"

[integration.mqtt]
event_topic_template="gateway/{{ .GatewayID }}/event/{{ .EventType }}"
state_topic_template="gateway/{{ .GatewayID }}/state/{{ .StateType }}"
command_topic_template="gateway/{{ .GatewayID }}/command/#"

[integration.mqtt.auth]
type="generic"

[integration.mqtt.auth.generic]
servers=["tcp://mosquitto-test:1883"]
username="chirpstack"
password="testpass"
qos=0
clean_session=true
GW_CONFIG_EOF
        ;;
        *) echo "" ;;
    esac
}

bashio::var.true() {
    [[ "$1" == "true" ]]
}

# Execute the function passed as argument
"$@"
EOF

    chmod +x /tmp/mock-bashio/bashio
}

# Create test network
echo "🌐 Creating test network..."
docker network create chirpstack-test 2>/dev/null || echo "Network already exists"

# Start supporting services
echo "🗄️  Starting PostgreSQL..."
docker run -d --name postgres-test --network chirpstack-test \
    -e POSTGRES_PASSWORD=chirpstack \
    -e POSTGRES_USER=chirpstack \
    -e POSTGRES_DB=chirpstack \
    postgres:14-alpine 2>/dev/null || echo "PostgreSQL already running"

echo "📦 Starting Redis..."
docker run -d --name redis-test --network chirpstack-test \
    redis:7-alpine 2>/dev/null || echo "Redis already running"

echo "📡 Starting MQTT Broker..."
docker run -d --name mosquitto-test --network chirpstack-test \
    -p 1883:1883 \
    eclipse-mosquitto:2 2>/dev/null || echo "MQTT already running"

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Create a modified run script for standalone testing
echo "📝 Creating standalone run script..."
cat > /tmp/run-standalone.sh << 'EOF'
#!/bin/bash

# Setup mock bashio
export PATH="/tmp/mock-bashio:$PATH"
source /tmp/mock-bashio/bashio

echo "[INFO] Starting ChirpStack 4.0 standalone test..."

# Parse configuration using mock bashio
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

echo "[INFO] Log level: ${log_level}"
echo "[INFO] MQTT server: ${mqtt_server}"
echo "[INFO] Basic Station enabled: ${basic_station_enabled}"
echo "[INFO] Packet Forwarder enabled: ${packet_forwarder_enabled}"

# Create configuration directory
mkdir -p /config/chirpstack

# Process the ChirpStack configuration from the GUI
echo "[INFO] Creating ChirpStack configuration..."
echo "${chirpstack_config}" > /config/chirpstack/chirpstack.toml

echo "[INFO] ChirpStack configuration file created:"
cat /config/chirpstack/chirpstack.toml

# Process Gateway Bridge configuration if enabled
if bashio::var.true "${basic_station_enabled}" || bashio::var.true "${packet_forwarder_enabled}"; then
    echo "[INFO] Creating Gateway Bridge configuration..."
    echo "${gateway_bridge_config}" > /config/chirpstack/chirpstack-gateway-bridge.toml
    
    echo "[INFO] Gateway Bridge configuration file created:"
    cat /config/chirpstack/chirpstack-gateway-bridge.toml
fi

# Wait for database to be ready
echo "[INFO] Testing database connectivity..."
until nc -z postgres-test 5432; do
    echo "[INFO] Waiting for PostgreSQL..."
    sleep 2
done
echo "[INFO] PostgreSQL is ready!"

# Wait for Redis
echo "[INFO] Testing Redis connectivity..."
until nc -z redis-test 6379; do
    echo "[INFO] Waiting for Redis..."
    sleep 2
done
echo "[INFO] Redis is ready!"

# Wait for MQTT
echo "[INFO] Testing MQTT connectivity..."
until nc -z mosquitto-test 1883; do
    echo "[INFO] Waiting for MQTT..."
    sleep 2
done
echo "[INFO] MQTT is ready!"

# Start ChirpStack
echo "[INFO] Starting ChirpStack Network Server..."
/usr/local/bin/chirpstack --config /config/chirpstack &
CHIRPSTACK_PID=$!

# Wait a bit for ChirpStack to start
sleep 10

# Start Gateway Bridge if configured
if bashio::var.true "${basic_station_enabled}" || bashio::var.true "${packet_forwarder_enabled}"; then
    echo "[INFO] Starting ChirpStack Gateway Bridge..."
    /usr/local/bin/chirpstack-gateway-bridge --config /config/chirpstack &
    GATEWAY_BRIDGE_PID=$!
fi

# Function to handle shutdown
cleanup() {
    echo "[INFO] Shutting down ChirpStack..."
    kill $CHIRPSTACK_PID 2>/dev/null
    if [[ -n $GATEWAY_BRIDGE_PID ]]; then
        kill $GATEWAY_BRIDGE_PID 2>/dev/null
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

echo "[INFO] ChirpStack is running!"
echo "[INFO] Web UI: http://localhost:8080"
echo "[INFO] Basic Station: ws://localhost:3001"  
echo "[INFO] UDP Packet Forwarder: localhost:1700"
echo "[INFO] Press Ctrl+C to stop"

# Wait for processes
wait
EOF

chmod +x /tmp/run-standalone.sh

# Create mock bashio
echo "🔧 Setting up mock Home Assistant environment..."
create_mock_bashio

# Start ChirpStack with standalone script
echo "🚀 Starting ChirpStack..."
docker run -d --name chirpstack-standalone-test \
    --network chirpstack-test \
    -p 8080:8080 \
    -p 1700:1700/udp \
    -p 3001:3001 \
    -v /tmp/run-standalone.sh:/run-standalone.sh \
    -v /tmp/mock-bashio:/tmp/mock-bashio \
    --entrypoint /run-standalone.sh \
    chirpstack-test

echo ""
echo "🎯 ChirpStack Test Environment Status:"
echo "======================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAME|test)"

echo ""
echo "📋 Checking ChirpStack logs..."
sleep 5
docker logs chirpstack-standalone-test --tail 20

echo ""
echo "🌐 Test URLs:"
echo "  Web Interface: http://localhost:8080"
echo "  MQTT: localhost:1883" 
echo "  Basic Station: ws://localhost:3001"
echo "  UDP Forwarder: localhost:1700"
echo ""
echo "📊 To monitor logs: docker logs -f chirpstack-standalone-test"
echo "🛑 To stop test: docker stop chirpstack-standalone-test postgres-test redis-test mosquitto-test"