# Changelog

## [4.0.1] - 2025-11-17

### Added
- Initial release of ChirpStack 4.0 Home Assistant Add-on
- ChirpStack Network Server 4.15.0
- ChirpStack Gateway Bridge 4.0.12
- Support for Basic Station protocol (WebSocket)
- Support for UDP Packet Forwarder protocol
- MQTT integration with Home Assistant
- Multi-architecture support (amd64, aarch64, armv7, armhf, i386)
- Configurable regions (EU868, US915, AU915, AS923, etc.)
- Web-based management interface
- Multi-tenancy support

### Features
- Automatic MQTT discovery for Home Assistant
- Real-time device data visualization
- Gateway and device management
- Application management
- User and organization management
- API access for custom integrations

### Configuration
- Flexible MQTT broker configuration
- Configurable network settings
- Region-specific configurations
- Protocol-specific settings

### Dependencies
- Requires Home Assistant Core
- Requires MQTT broker (Mosquitto recommended)
- Optional: PostgreSQL (uses built-in SQLite by default)
- Optional: Redis (uses built-in memory cache by default)