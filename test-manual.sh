#!/bin/bash

echo "🧪 ChirpStack Add-on Manual Test"
echo "================================="

echo "1. 🐳 Testing container startup..."
docker run --rm -d \
  --name chirpstack-manual-test \
  -e log_level="info" \
  -e mqtt_server="tcp://localhost:1883" \
  -e mqtt_username="chirpstack" \
  -e mqtt_password="testpass" \
  -e basic_station_enabled="true" \
  -e packet_forwarder_enabled="true" \
  -e chirpstack_config="$(cat << 'EOF'
[logging]
level="info"

[postgresql]
dsn="postgres://chirpstack:chirpstack@localhost:5432/chirpstack?sslmode=disable"

[redis]
servers=["redis://localhost:6379"]

[api]
bind="0.0.0.0:8080"
secret="test-secret"

[network]
net_id="000000"

[regions.eu868]
name="eu868"
EOF
)" \
  -e gateway_bridge_config="$(cat << 'EOF'
[general]
log_level=4

[backend.basic_station]
bind="0.0.0.0:3001"

[backend.semtech_udp]
udp_bind="0.0.0.0:1700"

[integration.mqtt.auth]
type="generic"

[integration.mqtt.auth.generic]
servers=["tcp://localhost:1883"]
username="chirpstack"
password="testpass"
EOF
)" \
  chirpstack-test

echo "2. ⏱️  Waiting 5 seconds for startup..."
sleep 5

echo "3. 📋 Checking container logs..."
docker logs chirpstack-manual-test 2>&1 | head -20

echo ""
echo "4. 🔍 Checking if container is still running..."
if docker ps | grep chirpstack-manual-test > /dev/null; then
  echo "✅ Container is running!"
  echo ""
  echo "5. 📂 Checking generated config files..."
  docker exec chirpstack-manual-test sh -c "
    echo '=== ChirpStack Config ==='
    cat /config/chirpstack/chirpstack.toml 2>/dev/null || echo 'Config not found'
    echo ''
    echo '=== Gateway Bridge Config ==='
    cat /config/chirpstack/chirpstack-gateway-bridge.toml 2>/dev/null || echo 'Config not found'
  "
else
  echo "❌ Container stopped. Check logs above for errors."
fi

echo ""
echo "6. 🧹 Cleaning up..."
docker stop chirpstack-manual-test 2>/dev/null
docker rm chirpstack-manual-test 2>/dev/null

echo ""
echo "✨ Manual test complete!"