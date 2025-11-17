# Home Assistant Add-on: ChirpStack 4.0

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg

## About

ChirpStack is an open-source LoRaWAN Network Server which can be used to setup LoRaWAN networks. ChirpStack provides a web-interface for the management of gateways, devices and tenants as well as for visualizing data.

This add-on provides:

- **ChirpStack Network Server 4.0** - The core LoRaWAN network server
- **ChirpStack Gateway Bridge** - Bridge between LoRa gateways and the network server
- **Basic Station support** - Modern LoRaWAN gateway protocol via WebSocket
- **Packet Forwarder support** - Traditional UDP packet forwarder protocol
- **MQTT Integration** - Native integration with Home Assistant via MQTT

## Features

- **Multi-protocol support**: Both Basic Station (WebSocket) and traditional UDP packet forwarder
- **Region support**: EU868, US915, AU915, AS923, and more
- **Device management**: Web interface for managing gateways, applications, and devices
- **Data visualization**: Real-time data visualization and device status
- **MQTT integration**: Seamless integration with Home Assistant MQTT broker
- **Multi-tenancy**: Support for multiple organizations and users

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "ChirpStack" add-on
3. Configure the add-on (see configuration section below)
4. Start the add-on

## Configuration

### Basic Configuration

```yaml
log_level: info
integration:
  mqtt:
    server: "tcp://core-mosquitto:1883"
    username: "chirpstack"
    password: "your-mqtt-password"
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

### Configuration Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `log_level` | No | `info` | Log level (trace, debug, info, warn, error, fatal) |
| `integration.mqtt.server` | Yes | `tcp://core-mosquitto:1883` | MQTT broker URL |
| `integration.mqtt.username` | Yes | `chirpstack` | MQTT username |
| `integration.mqtt.password` | Yes | - | MQTT password |
| `network.net_id` | No | `000000` | LoRaWAN Network ID |
| `regions` | No | `["eu868"]` | Enabled LoRaWAN regions |
| `basic_station.enabled` | No | `true` | Enable Basic Station support |
| `basic_station.bind` | No | `0.0.0.0:3001` | Basic Station bind address |
| `packet_forwarder.enabled` | No | `true` | Enable UDP packet forwarder |
| `packet_forwarder.bind` | No | `0.0.0.0:1700` | Packet forwarder bind address |

## Usage

1. After starting the add-on, access the ChirpStack web interface at `http://homeassistant.local:8080`
2. Default login credentials are:
   - **Username**: admin
   - **Password**: admin
3. Configure your first gateway and application
4. Add your LoRaWAN devices

### Gateway Configuration

**For Basic Station gateways:**
- Server address: `ws://homeassistant.local:3001`
- No TLS/authentication required in default configuration

**For UDP packet forwarder gateways:**
- Server address: `homeassistant.local`
- Port: `1700` (UDP)

## Integration with Home Assistant

ChirpStack automatically integrates with Home Assistant via MQTT. Device data will appear as MQTT messages that can be:

1. **Auto-discovered** using MQTT discovery
2. **Manually configured** as MQTT sensors
3. **Processed** using Node-RED or automations

### MQTT Topics

- **Uplink data**: `application/{application_id}/device/{device_eui}/event/up`
- **Device status**: `application/{application_id}/device/{device_eui}/event/status`
- **Downlink**: `application/{application_id}/device/{device_eui}/command/down`

## Support

For issues and feature requests:

1. Check the [ChirpStack documentation](https://www.chirpstack.io/docs/)
2. Visit the [ChirpStack Community Forum](https://forum.chirpstack.io/)
3. Report addon-specific issues on GitHub

## Changelog & Releases

See the [releases page](https://github.com/your-repo/chirpstack-addon/releases) for a detailed changelog.

## License

MIT License - see the [LICENSE](LICENSE) file for details.