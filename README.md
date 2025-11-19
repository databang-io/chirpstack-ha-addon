# ChirpStack 4.0 Home Assistant Add-on Repository

A Home Assistant add-on repository for ChirpStack 4.0 LoRaWAN Network Server.

## About

This repository provides a Home Assistant add-on for running ChirpStack 4.0, an open-source LoRaWAN Network Server. ChirpStack enables you to set up LoRaWAN networks with full device management, data visualization, and seamless Home Assistant integration.

## Installation

### Adding the Repository

1. Go to **Supervisor** → **Add-on Store** in your Home Assistant instance
2. Click the three dots menu (⋮) in the top right
3. Select **Repositories**
4. Add this repository URL:
   ```
   https://github.com/databang-io/chirpstack-ha-addon
   ```
5. Click **Add**

### Installing the Add-on

1. Find "ChirpStack" in the add-on store
2. Click **Install**
3. Configure the add-on (see configuration below)
4. Start the add-on

## Features

- **ChirpStack Network Server 4.15.0** - Latest stable release
- **ChirpStack Gateway Bridge 4.0.12** - Gateway communication bridge
- **Multi-protocol support** - Basic Station (WebSocket) and UDP Packet Forwarder
- **Regional support** - EU868, US915, AU915, AS923, and more
- **MQTT Integration** - Native Home Assistant integration
- **Web Interface** - Full-featured management portal
- **Multi-architecture** - Supports ARM64, AMD64, ARMv7, ARMhf, and i386

## Configuration

Basic configuration example:

```yaml
log_level: info
integration:
  mqtt:
    server: "tcp://core-mosquitto:1883" 
    username: "chirpstack"
    password: "your-secure-password"
network:
  net_id: "000000"
regions:
  - "eu868"
basic_station:
  enabled: true
  bind: "0.0.0.0:3001"
packet_forwarder:
  enabled: true
  bind: "0.0.0.0:1700"
```

## Default Access

After installation, access the ChirpStack web interface at:
- **URL**: `http://homeassistant.local:8080`
- **Username**: admin
- **Password**: admin

**⚠️ Remember to change the default password after first login!**

## Gateway Configuration

### Basic Station Gateways
- **Server Address**: `ws://homeassistant.local:3001`
- **Protocol**: WebSocket (no TLS in default config)

### UDP Packet Forwarder Gateways  
- **Server Address**: `homeassistant.local`
- **Port**: `1700` (UDP)

## Home Assistant Integration

Device data automatically flows to Home Assistant via MQTT:

- **Uplink Data**: `application/{id}/device/{eui}/event/up`
- **Device Status**: `application/{id}/device/{eui}/event/status`
- **Downlink**: `application/{id}/device/{eui}/command/down`

## Support

- **Documentation**: [ChirpStack Docs](https://www.chirpstack.io/docs/)
- **Community**: [ChirpStack Forum](https://forum.chirpstack.io/)
- **Issues**: [GitHub Issues](https://github.com/databang-io/chirpstack-addon-repository/issues)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

**Bernard Rodriguez** <bernard.rodriguez@databang.io>  
Databang.io