#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Add-on: ChirpStack 4.0 FULL TOMLQ VERSION
# CLEAN CONFIG GENERATION — NO SED — SECTIONS REMOVED (Option B)
# ==============================================================================

bashio::log.info "Starting ChirpStack 4.0 (FULL TOMLQ MODE)"

# ---------------------------------------------------------------------------
# Load HA Add-on config
# ---------------------------------------------------------------------------
mqtt_server=$(bashio::config 'mqtt.server')
mqtt_username=$(bashio::config 'mqtt.username')
mqtt_password=$(bashio::config 'mqtt.password')

chirpstack_log_level=$(bashio::config 'chirpstack.log_level')
chirpstack_api_bind=$(bashio::config 'chirpstack.api_bind')
chirpstack_api_secret=$(bashio::config 'chirpstack.api_secret')
chirpstack_network_id=$(bashio::config 'chirpstack.network_id')
chirpstack_database_dsn=$(bashio::config 'chirpstack.database_dsn')

gateway_bridge_log_level=$(bashio::config 'gateway_bridge.log_level')
basic_station_enabled=$(bashio::config 'gateway_bridge.basic_station.enabled')
basic_station_bind=$(bashio::config 'gateway_bridge.basic_station.bind')
packet_forwarder_enabled=$(bashio::config 'gateway_bridge.packet_forwarder.enabled')
packet_forwarder_bind=$(bashio::config 'gateway_bridge.packet_forwarder.bind')

bashio::log.info "MQTT: $mqtt_server"
bashio::log.info "Basic Station enabled: $basic_station_enabled"
bashio::log.info "Semtech UDP enabled: $packet_forwarder_enabled"

# ---------------------------------------------------------------------------
# Reset configuration directory
# ---------------------------------------------------------------------------
rm -rf /config/chirpstack
mkdir -p /config/chirpstack
mkdir -p /config/chirpstack-gateway-bridge

mkdir -p /tmp/chirpstack_temp_config

# ---------------------------------------------------------------------------
# Generate ChirpStack config template
# ---------------------------------------------------------------------------
/usr/local/bin/chirpstack --config /tmp/chirpstack_temp_config configfile > /tmp/chirpstack.toml

# Fix duplicate "json" keys inside [logging] section
awk '
  BEGIN { in_logging=0; json_seen=0 }
  /^\[logging\]/ { in_logging=1; }
  /^\[/ && !/^\[logging\]/ { in_logging=0; json_seen=0 }
  in_logging && $0 ~ /^ *json *=/ {
      if (json_seen == 1) next;
      json_seen=1
  }
  { print }
' /tmp/chirpstack.toml > /tmp/chirpstack_fixed.toml

mv /tmp/chirpstack_fixed.toml /tmp/chirpstack.toml


# APPLY USER LOG LEVEL
tomlq -it \
  --arg lvl "$chirpstack_log_level" \
  '.logging.level=$lvl' \
  /tmp/chirpstack.toml

# ---------------------------------------------------------------------------
# Apply ChirpStack settings using tomlq
# ---------------------------------------------------------------------------
tomlq -it \
  --arg lvl "$chirpstack_log_level" \
  '.logging.level=$lvl' \
  /tmp/chirpstack.toml

tomlq -it \
  --arg bind "$chirpstack_api_bind" \
  '.api.bind=$bind' \
  /tmp/chirpstack.toml

tomlq -it \
  --arg secret "$chirpstack_api_secret" \
  '.api.secret=$secret' \
  /tmp/chirpstack.toml

tomlq -it \
  --arg nid "$chirpstack_network_id" \
  '.network.net_id=$nid' \
  /tmp/chirpstack.toml

# ---------------------------------------------------------------------------
# DATABASE: SQLite ONLY — ChirpStack 4.x correct schema
# Remove all other DB sections, rebuild storage.sqlite
# ---------------------------------------------------------------------------

# Remove all DB blocks that may exist
tomlq -it 'del(.storage)' /tmp/chirpstack.toml   2>/dev/null || true
tomlq -it 'del(.postgresql)' /tmp/chirpstack.toml   2>/dev/null || true
tomlq -it 'del(.sqlite)' /tmp/chirpstack.toml   2>/dev/null || true

# Create empty [storage] table
tomlq -it '.storage = {}' /tmp/chirpstack.toml

# Create empty [storage.sqlite] table
tomlq -it '.storage.sqlite = {}' /tmp/chirpstack.toml

# Assign SQLite path
tomlq -it \
  --arg dsn "$chirpstack_database_dsn" \
  '.storage.sqlite.path = $dsn' \
  /tmp/chirpstack.toml

# Add max_open_connections
tomlq -it \
  '.storage.sqlite.max_open_connections = 4' \
  /tmp/chirpstack.toml

# Add SQLite PRAGMAs
tomlq -it \
  '.storage.sqlite.pragmas = ["busy_timeout = 1000", "foreign_keys = ON"]' \
  /tmp/chirpstack.toml

# ---------------------------------------------------------------------------
# MQTT
# ---------------------------------------------------------------------------
tomlq -it \
  --arg srv "$mqtt_server" \
  '.integration.mqtt.server=$srv' \
  /tmp/chirpstack.toml

tomlq -it \
  --arg un "$mqtt_username" \
  '.integration.mqtt.username=$un' \
  /tmp/chirpstack.toml

tomlq -it \
  --arg pw "$mqtt_password" \
  '.integration.mqtt.password=$pw' \
  /tmp/chirpstack.toml

# Enable MQTT integration
tomlq -it '.integration.enabled=["mqtt"]' /tmp/chirpstack.toml

# Set ChirpStack MQTT client ID
tomlq -it '.integration.mqtt.client_id="chirpstack-ns"' /tmp/chirpstack.toml

# ---------------------------------------------------------------------------
# Gateway Backend Configuration - Enable MQTT for gateway communication
# ---------------------------------------------------------------------------
tomlq -it '.gateway.backend.mqtt.event_topic="gateway/+/event/+"' /tmp/chirpstack.toml
tomlq -it '.gateway.backend.mqtt.command_topic="gateway/{gateway_id}/command/{command}"' /tmp/chirpstack.toml
tomlq -it \
  --arg srv "$mqtt_server" \
  '.gateway.backend.mqtt.server=$srv' \
  /tmp/chirpstack.toml
tomlq -it \
  --arg un "$mqtt_username" \
  '.gateway.backend.mqtt.username=$un' \
  /tmp/chirpstack.toml
tomlq -it \
  --arg pw "$mqtt_password" \
  '.gateway.backend.mqtt.password=$pw' \
  /tmp/chirpstack.toml

# ---------------------------------------------------------------------------
# Regions (replace array)
# ---------------------------------------------------------------------------
tomlq -it '.network.enabled_regions=["eu868"]' /tmp/chirpstack.toml

# ---------------------------------------------------------------------------
# SAVE FINAL CHIRPSTACK CONFIG
# ---------------------------------------------------------------------------
cp /tmp/chirpstack.toml /config/chirpstack/chirpstack.toml

bashio::log.info "Generated chirpstack.toml:"
cat /config/chirpstack/chirpstack.toml


# ==============================================================================
#  GATEWAY BRIDGE CONFIGURATION — SEPARATE FOLDER
# ==============================================================================

if bashio::var.true "$basic_station_enabled" || bashio::var.true "$packet_forwarder_enabled"; then

    /usr/local/bin/chirpstack-gateway-bridge configfile > /tmp/chirpstack-gateway-bridge.toml

    # LOG LEVEL convert to number
    case "$gateway_bridge_log_level" in
        "trace") log_lvl=5 ;;
        "debug") log_lvl=5 ;;
        "info")  log_lvl=4 ;;
        "warn")  log_lvl=3 ;;
        "error") log_lvl=2 ;;
        "fatal") log_lvl=1 ;;
        *) log_lvl=4 ;;
    esac

    tomlq -it \
      --argjson lvl "$log_lvl" \
      '.general.log_level=$lvl' \
      /tmp/chirpstack-gateway-bridge.toml

    # -----------------------------------------------------------------------
    # Set marshaler to JSON to match ChirpStack expectation
    # -----------------------------------------------------------------------
    tomlq -it '.integration.marshaler="json"' /tmp/chirpstack-gateway-bridge.toml

    # -----------------------------------------------------------------------
    # fake_rx_time=true
    # -----------------------------------------------------------------------

    tomlq -it '.backend.semtech_udp.fake_rx_time=true' /tmp/chirpstack-gateway-bridge.toml


    # -----------------------------------------------------------------------
    # Backend handling — remove disabled backends
    # -----------------------------------------------------------------------
    if bashio::var.true "$basic_station_enabled"; then

        tomlq -it \
          --arg b "$basic_station_bind" \
          '.backend.basic_station.bind=$b' \
          /tmp/chirpstack-gateway-bridge.toml

        if ! bashio::var.true "$packet_forwarder_enabled"; then
            tomlq -it 'del(.backend.semtech_udp)' /tmp/chirpstack-gateway-bridge.toml
        fi

    elif bashio::var.true "$packet_forwarder_enabled"; then

        tomlq -it \
          --arg b "$packet_forwarder_bind" \
          '.backend.semtech_udp.udp_bind=$b' \
          /tmp/chirpstack-gateway-bridge.toml

        tomlq -it 'del(.backend.basic_station)' /tmp/chirpstack-gateway-bridge.toml
    fi

    # -----------------------------------------------------------------------
    # MQTT parameters
    # -----------------------------------------------------------------------
    tomlq -it \
      --arg srv "$mqtt_server" \
      '.integration.mqtt.auth.generic.servers=[ $srv ]' \
      /tmp/chirpstack-gateway-bridge.toml

    tomlq -it \
      --arg un "$mqtt_username" \
      '.integration.mqtt.auth.generic.username=$un' \
      /tmp/chirpstack-gateway-bridge.toml

    tomlq -it \
      --arg pw "$mqtt_password" \
      '.integration.mqtt.auth.generic.password=$pw' \
      /tmp/chirpstack-gateway-bridge.toml

    # Set Gateway Bridge MQTT client ID
    tomlq -it '.integration.mqtt.auth.generic.client_id="chirpstack-gateway-bridge"' /tmp/chirpstack-gateway-bridge.toml

    # SAVE CONFIG TO SEPARATE FOLDER
    cp /tmp/chirpstack-gateway-bridge.toml /config/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml

    bashio::log.info "Generated Gateway Bridge TOML:"
    cat /config/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml
fi

# ==============================================================================
# START SERVICES
# ==============================================================================

bashio::log.info "Starting Redis..."
redis-server --daemonize yes --port 6379 --bind 127.0.0.1

sleep 2

bashio::log.info "Starting ChirpStack..."
cat /config/chirpstack/chirpstack.toml | grep -i sqlite -n -A2 -B2

/usr/local/bin/chirpstack --config /config/chirpstack &

CH_PID=$!

sleep 3
if kill -0 $CH_PID; then
    bashio::log.info "ChirpStack running. PID=$CH_PID"

    if [[ -f /config/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml ]]; then
        bashio::log.info "Starting Gateway Bridge..."
        /usr/local/bin/chirpstack-gateway-bridge \
            --config /config/chirpstack-gateway-bridge/chirpstack-gateway-bridge.toml &
    fi
else
    bashio::log.error "ChirpStack failed to start!"
fi

wait
