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

# Enable eu868 region
tomlq -it '.network.enabled_regions=["eu868"]' /tmp/chirpstack.toml



# ---------------------------------------------------------------------------
# Regions - configured in separate eu868.toml file
# ---------------------------------------------------------------------------

# Create EU868 region configuration file  
cat > /config/chirpstack/region_eu868.toml << 'EOF'
# This file contains EU868 configuration.
[[regions]]

  # Name is an user-defined identifier for this region.
  name="eu868"

  # Common-name refers to the common-name of this region as defined by
  # the LoRa Alliance.
  common_name="EU868"


  # Gateway configuration.
  [regions.gateway]

    # Force gateways as private.
    #
    # If enabled, gateways can only be used by devices under the same tenant.
    force_gws_private=false


    # Gateway backend configuration.
    [regions.gateway.backend]

      # The enabled backend type.
      enabled="mqtt"

      # MQTT configuration.
      [regions.gateway.backend.mqtt]

        # Event topic template.
        event_topic="eu868/gateway/+/event/+"

        # Command topic template.
        command_topic="eu868/gateway/{{ gateway_id }}/command/{{ command }}"

        # MQTT server (e.g. scheme://host:port where scheme is tcp, ssl or ws)
        server="tcp://localhost:1883"

        # Connect with the given username (optional)
        username=""

        # Connect with the given password (optional)
        password=""

        # Quality of service level
        #
        # 0: at most once
        # 1: at least once
        # 2: exactly once
        #
        # Note: an increase of this value will decrease the performance.
        # For more information: https://www.hivemq.com/blog/mqtt-essentials-part-6-mqtt-quality-of-service-levels
        qos=0

        # Clean session
        #
        # Set the "clean session" flag in the connect message when this client
        # connects to an MQTT broker. By setting this flag you are indicating
        # that no messages saved by the broker for this client should be delivered.
        clean_session=true

        # Client ID
        #
        # Set the client id to be used by this client when connecting to the MQTT
        # broker. A client id must be no longer than 23 characters. When left blank,
        # a random id will be generated. This requires clean_session=true.
        client_id=""

        # CA certificate file (optional)
        #
        # Use this when setting up a secure connection (when server uses ssl://...)
        # but the certificate used by the server is not trusted by any CA certificate
        # on the server (e.g. when self generated).
        ca_cert=""

        # TLS certificate file (optional)
        tls_cert=""

        # TLS key file (optional)
        tls_key=""


    # Gateway channel configuration.
    #
    # Note: this configuration is only used in case the gateway is using the
    # ChirpStack Concentratord daemon. In any other case, this configuration 
    # is ignored.
    [[regions.gateway.channels]]
      frequency=868100000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=868300000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=868500000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=867100000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=867300000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=867500000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=867700000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]

    [[regions.gateway.channels]]
      frequency=867900000
      bandwidth=125000
      modulation="LORA"
      spreading_factors=[7, 8, 9, 10, 11, 12]
  
    [[regions.gateway.channels]]
      frequency=868300000
      bandwidth=250000
      modulation="LORA"
      spreading_factors=[7]
    
    [[regions.gateway.channels]]
      frequency=868800000
      bandwidth=125000
      modulation="FSK"
      datarate=50000


  # Region specific network configuration.
  [regions.network]
    
    # Installation margin (dB) used by the ADR engine.
    #
    # A higher number means that the network-server will keep more margin,
    # resulting in a lower data-rate but decreasing the chance that the
    # device gets disconnected because it is unable to reach one of the
    # surrounded gateways.
    installation_margin=10

    # RX window (Class-A).
    #
    # Set this to:
    # 0: RX1 / RX2
    # 1: RX1 only
    # 2: RX2 only
    rx_window=0

    # RX1 delay (1 - 15 seconds).
    rx1_delay=1

    # RX1 data-rate offset
    rx1_dr_offset=0

    # RX2 data-rate
    rx2_dr=0

    # RX2 frequency (Hz)
    rx2_frequency=869525000

    # Prefer RX2 on RX1 data-rate less than.
    #
    # Prefer RX2 over RX1 based on the RX1 data-rate. When the RX1 data-rate
    # is smaller than the configured value, then the Network Server will
    # first try to schedule the downlink for RX2, failing that (e.g. the gateway
    # has already a payload scheduled at the RX2 timing) it will try RX1.
    rx2_prefer_on_rx1_dr_lt=0

    # Prefer RX2 on link budget.
    #
    # When the link-budget is better for RX2 than for RX1, the Network Server will first
    # try to schedule the downlink in RX2, failing that it will try RX1.
    rx2_prefer_on_link_budget=false

    # Downlink TX Power (dBm)
    #
    # When set to -1, the downlink TX Power from the configured band will
    # be used.
    #
    # Please consult the LoRaWAN Regional Parameters and local regulations
    # for valid and legal options. Note that the configured TX Power must be
    # supported by your gateway(s).
    downlink_tx_power=-1

    # ADR is disabled.
    adr_disabled=false

    # Minimum data-rate.
    min_dr=0

    # Maximum data-rate.
    max_dr=5


    # Rejoin-request configuration (LoRaWAN 1.1)
    [regions.network.rejoin_request]

      # Request devices to periodically send rejoin-requests.
      enabled=false

      # The device must send a rejoin-request type 0 at least every 2^(max_count_n + 4)
      # uplink messages. Valid values are 0 to 15.
      max_count_n=0

      # The device must send a rejoin-request type 0 at least every 2^(max_time_n + 10)
      # seconds. Valid values are 0 to 15.
      #
      # 0  = roughly 17 minutes
      # 15 = about 1 year
      max_time_n=0
    

    # Class-B configuration.
    [regions.network.class_b]

      # Ping-slot data-rate. 
      ping_slot_dr=0

      # Ping-slot frequency (Hz)
      #
      # set this to 0 to use the default frequency plan for the configured region
      # (which could be frequency hopping).
      ping_slot_frequency=0


    # Below is the common set of extra channels. Please make sure that these
    # channels are also supported by the gateways.
    [[regions.network.extra_channels]]
    frequency=867100000
    min_dr=0
    max_dr=5

    [[regions.network.extra_channels]]
    frequency=867300000
    min_dr=0
    max_dr=5

    [[regions.network.extra_channels]]
    frequency=867500000
    min_dr=0
    max_dr=5

    [[regions.network.extra_channels]]
    frequency=867700000
    min_dr=0
    max_dr=5

    [[regions.network.extra_channels]]
    frequency=867900000
    min_dr=0
    max_dr=5

EOF

# Configure MQTT settings using tomlq
tomlq -it \
  --arg srv "$mqtt_server" \
  '.regions[0].gateway.backend.mqtt.server=$srv' \
  /config/chirpstack/region_eu868.toml

tomlq -it \
  --arg un "$mqtt_username" \
  '.regions[0].gateway.backend.mqtt.username=$un' \
  /config/chirpstack/region_eu868.toml

tomlq -it \
  --arg pw "$mqtt_password" \
  '.regions[0].gateway.backend.mqtt.password=$pw' \
  /config/chirpstack/region_eu868.toml

# ---------------------------------------------------------------------------
# SAVE FINAL CHIRPSTACK CONFIG
# ---------------------------------------------------------------------------
cp /tmp/chirpstack.toml /config/chirpstack/chirpstack.toml

bashio::log.info "Generated chirpstack.toml:"
cat /config/chirpstack/chirpstack.toml

bashio::log.info "Generated region_eu868.toml:"
cat /config/chirpstack/region_eu868.toml


# ==============================================================================
#  GATEWAY BRIDGE CONFIGURATION — SEPARATE FOLDER
# ==============================================================================

if bashio::var.true "$basic_station_enabled" || bashio::var.true "$packet_forwarder_enabled"; then

    /usr/local/bin/chirpstack-gateway-bridge configfile > /tmp/chirpstack-gateway-bridge.toml

    # Update topic templates to include eu868 prefix to match ChirpStack expectations
    tomlq -it '.integration.mqtt.event_topic_template="eu868/gateway/{{ .GatewayID }}/event/{{ .EventType }}"' /tmp/chirpstack-gateway-bridge.toml
    tomlq -it '.integration.mqtt.state_topic_template="eu868/gateway/{{ .GatewayID }}/state/{{ .StateType }}"' /tmp/chirpstack-gateway-bridge.toml
    tomlq -it '.integration.mqtt.command_topic_template="eu868/gateway/{{ .GatewayID }}/command/#"' /tmp/chirpstack-gateway-bridge.toml

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
