# ChirpStack 4.0 Add-on Deployment Guide

Complete deployment guide for the ChirpStack 4.0 Home Assistant Add-on.

## 📋 Overview

This add-on provides a complete ChirpStack 4.0 LoRaWAN Network Server installation for Home Assistant, including:

- **ChirpStack Network Server 4.15.0** - Latest stable release
- **ChirpStack Gateway Bridge 4.1.1** - Latest gateway bridge
- **Multi-protocol support** - Basic Station + UDP Packet Forwarder
- **GUI Configuration** - Edit TOML configs directly in Home Assistant
- **MQTT Integration** - Native Home Assistant integration

## 🚀 Quick Start

### 1. Install Add-on

#### Option A: From Repository (Recommended)
1. Add repository: `https://github.com/yourusername/chirpstack-addon-repository`
2. Install **ChirpStack** add-on
3. Configure and start

#### Option B: Local Installation
1. Copy `chirpstack/` folder to `/addons/`
2. Reload add-ons
3. Install from local add-ons

### 2. Basic Configuration

```yaml
log_level: info
mqtt:
  server: "tcp://core-mosquitto:1883"
  username: "chirpstack" 
  password: "your-secure-password"
basic_station:
  enabled: true
packet_forwarder:
  enabled: true
```

### 3. Start Add-on

1. Click **Start**
2. Access ChirpStack: `http://homeassistant.local:8080`
3. Login: `admin` / `admin`

---

## 🔧 Configuration

### MQTT Setup

The add-on requires an MQTT broker. Recommended setup with Mosquitto:

#### Install Mosquitto Add-on
1. Install **Mosquitto broker** add-on
2. Create MQTT user:
   ```yaml
   logins:
     - username: chirpstack
       password: your-secure-password
   ```
3. Start Mosquitto add-on

#### Configure ChirpStack MQTT
```yaml
mqtt:
  server: "tcp://core-mosquitto:1883"
  username: "chirpstack"
  password: "your-secure-password"
```

### Database Setup

The add-on automatically configures PostgreSQL. No manual setup required.

**Note**: For production, ensure PostgreSQL persistence is configured in Home Assistant.

### Advanced Configuration

#### ChirpStack Main Config
Edit the `chirpstack_config` TOML directly in the GUI:

```toml
[logging]
level="info"

[postgresql]
dsn="postgres://chirpstack:chirpstack@core-postgres:5432/chirpstack?sslmode=disable"

[redis]
servers=["redis://core-redis:6379"]

[network]
net_id="000000"

[api]
bind="0.0.0.0:8080"
secret="change-this-secret-key"
cors_allow_origin="*"

[integration.mqtt]
server="tcp://core-mosquitto:1883"
username="chirpstack"
password="your-password"
event_topic="application/{{application_id}}/device/{{device_eui}}/event/{{event}}"

[regions.eu868]
name="eu868"
```

#### Gateway Bridge Config
```toml
[general]
log_level=4

[backend.basic_station]
bind="0.0.0.0:3001"
stats_interval="30s"

[backend.semtech_udp]  
udp_bind="0.0.0.0:1700"

[integration.mqtt.auth]
type="generic"

[integration.mqtt.auth.generic]
servers=["tcp://core-mosquitto:1883"]
username="chirpstack"
password="your-password"
qos=0
clean_session=true
```

---

## 🌐 Network Configuration

### Ports

The add-on exposes these ports:

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | ChirpStack Web Interface |
| 1700 | UDP | Semtech Packet Forwarder |
| 3001 | TCP/WS | Basic Station WebSocket |

### Firewall

Ensure these ports are accessible from your gateways:

```bash
# Allow Basic Station (if using)
ufw allow 3001/tcp

# Allow UDP Packet Forwarder (if using)  
ufw allow 1700/udp

# Web interface (local access only)
ufw allow from 192.168.0.0/16 to any port 8080
```

---

## 🔗 Gateway Configuration

### Basic Station Gateways

Configure your Basic Station gateway:

```json
{
  "station_conf": {
    "routerid": "your-gateway-id",
    "log_level": "INFO",
    "log_file": "stderr"
  },
  "CUPS": {
    "uri": "https://your-domain:443",
    "trust": "path/to/ca.crt",
    "key": "path/to/gateway.key",
    "crt": "path/to/gateway.crt"
  },
  "LNS": {
    "uri": "ws://homeassistant.local:3001"
  }
}
```

### UDP Packet Forwarder Gateways

Configure `global_conf.json`:

```json
{
  "gateway_conf": {
    "gateway_ID": "YOUR_GATEWAY_EUI",
    "server_address": "homeassistant.local",
    "serv_port_up": 1700,
    "serv_port_down": 1700,
    "keepalive_interval": 10,
    "stat_interval": 30,
    "push_timeout_ms": 100,
    "forward_crc_valid": true,
    "forward_crc_error": false,
    "forward_crc_disabled": false
  }
}
```

---

## 🏠 Home Assistant Integration

### MQTT Discovery

ChirpStack automatically publishes device data via MQTT. To integrate with Home Assistant:

#### Option 1: MQTT Discovery (Automatic)
Enable MQTT discovery in Home Assistant configuration:

```yaml
mqtt:
  discovery: true
  discovery_prefix: homeassistant
```

#### Option 2: Manual Sensors
Create manual sensors for your devices:

```yaml
sensor:
  - platform: mqtt
    name: "LoRa Device Battery"
    state_topic: "application/1/device/0102030405060708/event/up"
    value_template: "{{ value_json.object.battery }}"
    unit_of_measurement: "%"
    
  - platform: mqtt  
    name: "LoRa Device Temperature"
    state_topic: "application/1/device/0102030405060708/event/up"
    value_template: "{{ value_json.object.temperature }}"
    unit_of_measurement: "°C"
```

### Downlink Commands

Send commands to LoRaWAN devices:

```yaml
script:
  lorawan_command:
    sequence:
      - service: mqtt.publish
        data:
          topic: "application/1/device/0102030405060708/command/down"
          payload: >
            {
              "confirmed": false,
              "fPort": 1,
              "data": "SGVsbG8gV29ybGQ="
            }
```

---

## 📊 Monitoring

### Logs

Monitor add-on logs:
1. Go to **Add-ons** → **ChirpStack** → **Logs**
2. Or use: `ha addon logs chirpstack`

### MQTT Topics

Monitor MQTT traffic:

```bash
# Subscribe to all gateway events
mosquitto_sub -h homeassistant.local -u chirpstack -P password -t "gateway/+/event/+"

# Subscribe to all application events  
mosquitto_sub -h homeassistant.local -u chirpstack -P password -t "application/+/device/+/event/+"
```

### Web Interface

Access ChirpStack web interface:
- URL: `http://homeassistant.local:8080`
- Default login: `admin` / `admin`

**⚠️ Change default password immediately!**

### Metrics

ChirpStack provides built-in metrics at:
- Gateway statistics
- Device frame counters  
- Application data rates
- System health

---

## 🔐 Security

### Essential Security Steps

1. **Change Default Passwords**
   ```yaml
   # In ChirpStack web interface
   admin_user: "your-username"
   admin_password: "secure-password"
   ```

2. **Secure MQTT**
   ```yaml
   # Enable authentication in Mosquitto
   mqtt:
     authentication: true
     users:
       - username: chirpstack
         password: secure-password
   ```

3. **Network Security**
   ```bash
   # Restrict web interface access
   ufw deny 8080
   ufw allow from 192.168.1.0/24 to any port 8080
   ```

4. **API Keys**
   - Create dedicated API keys for integrations
   - Use least privilege principle
   - Rotate keys regularly

### TLS/SSL Configuration

For production deployments, enable TLS:

```toml
[api]
bind="0.0.0.0:8080"
tls_cert="path/to/cert.pem"
tls_key="path/to/key.pem"
```

---

## 🔄 Backup & Recovery

### Configuration Backup

Backup add-on configuration:
```bash
# Backup configuration
ha addon restart chirpstack
cp /addons/chirpstack/config.yaml ~/chirpstack-config-backup.yaml
```

### Database Backup

Setup automated PostgreSQL backups:

```yaml
# Home Assistant configuration.yaml
automation:
  - alias: "ChirpStack DB Backup"
    trigger:
      - platform: time
        at: "02:00:00"
    action:
      - service: shell_command.chirpstack_backup
        
shell_command:
  chirpstack_backup: "docker exec postgres-addon pg_dump -U chirpstack chirpstack > /backups/chirpstack-$(date +%Y%m%d).sql"
```

### Disaster Recovery

1. **Stop add-on**
2. **Restore configuration**: Copy backup config
3. **Restore database**: Import SQL backup
4. **Start add-on**
5. **Verify functionality**

---

## 🚨 Troubleshooting

### Common Issues

#### Add-on Won't Start
```bash
# Check logs
ha addon logs chirpstack

# Common causes:
# 1. MQTT broker not running
# 2. Database connection failed
# 3. Configuration syntax error
```

#### Web Interface Inaccessible
```bash
# Check if port is accessible
netstat -tlnp | grep 8080

# Check Home Assistant firewall
ufw status
```

#### Gateways Not Connecting
```bash
# Check gateway bridge logs
ha addon logs chirpstack | grep gateway

# Test ports
nc -zv homeassistant.local 3001  # Basic Station
nc -zuv homeassistant.local 1700 # UDP Forwarder
```

#### MQTT Connection Issues
```bash
# Test MQTT connectivity
mosquitto_sub -h homeassistant.local -p 1883 -u chirpstack -P password -t "test"
```

### Log Analysis

```bash
# View all logs
ha addon logs chirpstack

# Filter for errors
ha addon logs chirpstack | grep -i error

# Filter for MQTT issues
ha addon logs chirpstack | grep -i mqtt
```

### Performance Issues

```bash
# Check system resources
ha info

# Monitor add-on resources
ha addon info chirpstack
```

---

## 📈 Scaling

### High Availability

For production deployments:

1. **External Database**
   - Use external PostgreSQL cluster
   - Configure connection pooling
   - Enable backups

2. **Load Balancing**
   - Multiple ChirpStack instances
   - Load balancer for web interface
   - Shared database/Redis

3. **Monitoring**
   - Prometheus metrics
   - Grafana dashboards  
   - Alerting rules

### Performance Tuning

```toml
[postgresql]
max_open_connections=100
max_idle_connections=25

[redis]
pool_size=50
max_active_connections=100
```

---

## 📞 Support

### Documentation
- [ChirpStack Documentation](https://www.chirpstack.io/docs/)
- [LoRaWAN Specification](https://lora-alliance.org/resource_hub/lorawan-specification-v1-0-3/)
- [Home Assistant Add-on Development](https://developers.home-assistant.io/docs/add-ons/)

### Community
- [ChirpStack Forum](https://forum.chirpstack.io/)
- [Home Assistant Community](https://community.home-assistant.io/)
- [GitHub Issues](https://github.com/yourusername/chirpstack-addon-repository/issues)

### Commercial Support
- ChirpStack commercial support
- LoRaWAN consulting services
- Custom integration development

---

## 📄 License

This add-on is released under the MIT License. See [LICENSE](LICENSE) for details.

ChirpStack is released under the MIT License.
LoRaWAN® is a trademark of the LoRa Alliance®.