# Changelog

All notable changes to the ChirpStack Home Assistant Add-on will be documented in this file.

## [4.15.0-5] - 2025-11-17

### Added
- Complete Home Assistant Add-on for ChirpStack 4.15.0 LoRaWAN Network Server
- ChirpStack Gateway Bridge 4.1.1 integration for gateway communication
- SQLite database backend for self-contained deployment
- Redis server integration (required for ChirpStack operation)
- MQTT integration with Home Assistant's Mosquitto broker
- Multi-architecture support (ARM64, AMD64, ARMv7, ARMhf)
- GUI-configurable TOML settings through Home Assistant interface
- Organized configuration sections (MQTT, ChirpStack, Gateway Bridge)
- Ingress support for seamless web UI access
- Official ChirpStack logo integration

### Fixed
- Config directory vs file issue (ChirpStack expects directory, not file)
- Redis configuration causing index out of bounds panic
- Ingress URL not working (disabled host_network for proper reverse proxy)
- Add-on icon not displaying (added icon.png with proper colorspace)
- Gateway not appearing in ChirpStack despite receiving packets (MQTT topic prefix)
- Docker build cache issues with Gateway Bridge version detection
- Invalid Redis parameters in configuration

### Technical Details
- **ChirpStack Version**: 4.15.0 (SQLite variant)
- **Gateway Bridge Version**: 4.1.1 (latest)
- **Database**: SQLite (self-contained, no external PostgreSQL needed)
- **Redis**: Embedded Redis server (required for ChirpStack operation)
- **MQTT**: Integrates with Home Assistant's core-mosquitto
- **Protocols Supported**: 
  - LoRaWAN Basic Station (WebSocket on port 3001)
  - UDP Packet Forwarder (UDP on port 1700)

### Configuration
The add-on provides organized configuration through Home Assistant GUI:

#### MQTT Settings (shared)
- Server: `tcp://core-mosquitto:1883`
- Username/Password: Configurable
- Topic prefix: `gateway`

#### ChirpStack Settings
- Log level: info/debug/warn/error
- API bind: `0.0.0.0:8080`
- API secret: Configurable
- Network ID: `000000`
- Database DSN: SQLite with mode=rwc
- Regions: EU868 (configurable)

#### Gateway Bridge Settings
- Log level: info/debug/warn/error
- Basic Station: Enabled on `0.0.0.0:3001`
- Packet Forwarder: Enabled on `0.0.0.0:1700`
- Advanced configuration: User-customizable TOML

### Breaking Changes
- Removed PostgreSQL dependency (now uses SQLite)
- Redis is now embedded and required (cannot be disabled)
- Changed from file-based to directory-based configuration

### Migration
If upgrading from a previous version:
1. Stop the old add-on
2. Update the repository
3. Start the new add-on (configuration will be migrated automatically)

### Known Issues
- None currently

### Contributors
- Bernard Rodriguez <bernard.rodriguez@databang.io>
- Claude AI Assistant (development support)

### Repository
- **GitHub**: https://github.com/databang-io/chirpstack-ha-addon
- **Docker Images**: Built automatically by Home Assistant
- **License**: MIT (same as ChirpStack project)