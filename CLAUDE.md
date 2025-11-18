# ChirpStack Home Assistant Add-on

## Project Overview

This project provides a complete Home Assistant Add-on for ChirpStack 4.15.0, a modern LoRaWAN Network Server. The add-on integrates seamlessly with Home Assistant, providing a self-contained LoRaWAN infrastructure with GUI-configurable settings.

## Development Context

This add-on was developed to solve connectivity issues with an existing ChirpStack Docker setup and evolved into a complete Home Assistant integration. The project prioritizes ease of use, self-contained deployment, and proper integration with Home Assistant's ecosystem.

## Architecture

### Core Components
- **ChirpStack 4.15.0**: LoRaWAN Network Server (SQLite variant)
- **Gateway Bridge 4.1.1**: Protocol bridge for LoRaWAN gateways  
- **Redis**: Required for ChirpStack operation (embedded)
- **SQLite**: Self-contained database (no external PostgreSQL)
- **MQTT**: Integration with Home Assistant's Mosquitto broker

### Container Structure
```
/usr/local/bin/chirpstack              # ChirpStack binary
/usr/local/bin/chirpstack-gateway-bridge # Gateway Bridge binary
/config/chirpstack/                    # Configuration directory
├── chirpstack.toml                    # Generated ChirpStack config
└── chirpstack-gateway-bridge.toml     # Generated Gateway Bridge config
/data/chirpstack/                      # SQLite database storage
/run.sh                               # Main startup script
```

## Key Technical Decisions

### SQLite Over PostgreSQL
- **Rationale**: Self-contained deployment without external database dependencies
- **Benefits**: Simpler setup, no database management, perfect for home use
- **Trade-offs**: Less scalable than PostgreSQL for enterprise deployments

### Embedded Redis
- **Rationale**: ChirpStack requires Redis for web interface and session management
- **Implementation**: Redis runs as daemon within the container
- **Benefits**: No external dependencies, automatic lifecycle management

### Directory-based Configuration
- **Issue**: ChirpStack expects `--config <DIR>` not `--config <FILE>`
- **Solution**: Generate configurations in `/config/chirpstack/` directory
- **Learning**: Always check binary expectations, not just documentation

### Organized GUI Configuration
- **Structure**: Three main sections (MQTT, ChirpStack, Gateway Bridge)
- **Benefits**: Logical grouping, easier user experience
- **Implementation**: Bash script processes Home Assistant config into TOML

## Common Commands

### Development
```bash
# Build container locally
docker build --build-arg BUILD_FROM=ghcr.io/hassio-addons/base:15.0.7 -t local/chirpstack:latest chirpstack/

# Test configuration generation
docker run --rm -v $(pwd)/test-config:/config local/chirpstack:latest cat /config/chirpstack/chirpstack.toml

# Check logs
ha addons logs local_chirpstack-fixed
```

### Git Operations
```bash
# Standard development workflow
git add .
git commit -m "Description of changes"
git push

# Force Home Assistant to update (bump version in config.yaml)
```

### Troubleshooting
```bash
# Check if ChirpStack binary works
docker run --rm local/chirpstack:latest /usr/local/bin/chirpstack --help

# Verify Gateway Bridge version
docker run --rm local/chirpstack:latest /usr/local/bin/chirpstack-gateway-bridge version

# Test Redis connectivity
docker exec -it <container> redis-cli ping
```

## Configuration Management

### Home Assistant Add-on Config
The add-on uses Home Assistant's configuration schema in `config.yaml`:
- **Schema validation**: Ensures proper data types
- **Default values**: Sensible defaults for quick setup
- **Optional fields**: Advanced users can customize extensively

### TOML Generation
The `run.sh` script processes Home Assistant config into ChirpStack TOML:
```bash
# Example: MQTT server configuration
mqtt_server=$(bashio::config 'mqtt.server')
echo "server=\"${mqtt_server}\"" >> config.toml
```

### Advanced Configuration
Users can add custom TOML sections via the `advanced_config` fields:
- **ChirpStack**: Additional regions, integrations, etc.
- **Gateway Bridge**: Custom backends, protocols, etc.

## Known Patterns and Solutions

### Home Assistant Caching
- **Problem**: Home Assistant aggressively caches add-on builds
- **Solutions**:
  - Bump version number in config.yaml
  - Change slug to force complete rebuild
  - Use cache-breaking comments in Dockerfile

### Multi-Architecture Support
- **Challenge**: Different binary architectures for ARM/x86
- **Solution**: Dynamic architecture detection in Dockerfile
- **Mappings**: 
  - `aarch64` → `arm64`
  - `x86_64` → `amd64` 
  - `armv7l` → `armv7hf`

### Binary Version Management
- **Issue**: ChirpStack releases have different naming conventions
- **Solution**: Hardcoded URLs with explicit version strings
- **Example**: `chirpstack_4.15.0_sqlite_linux_amd64.tar.gz`

## Integration Points

### MQTT Topics
ChirpStack and Gateway Bridge communicate via MQTT using these topics:
- **Uplink**: `gateway/+/event/up`
- **Downlink**: `gateway/+/command/down`
- **Statistics**: `gateway/+/event/stats`
- **Connection**: `gateway/+/state/conn`

### Home Assistant Integration
- **Ingress**: Web UI accessible through Home Assistant interface
- **Configuration**: GUI-based TOML editing
- **Logging**: Structured logs via bashio
- **Health**: Proper startup/shutdown handling

### Port Configuration
- **8080**: ChirpStack web interface (ingress)
- **1700/UDP**: Semtech UDP Packet Forwarder protocol
- **3001/TCP**: Basic Station WebSocket protocol
- **6379**: Internal Redis (not exposed)

## Security Considerations

### Network Isolation
- **Ingress**: Web traffic routed through Home Assistant proxy
- **MQTT**: Internal communication with Home Assistant's Mosquitto
- **API Secret**: Configurable secret for ChirpStack API access

### Privileges
- **SYS_RAWIO**: Required for USB device access (LoRa concentrators)
- **Device Access**: `/dev/ttyUSB0`, `/dev/ttyACM0`, etc.
- **Host Network**: Disabled for proper ingress operation

## Testing Strategy

### Functional Testing
1. **Container Build**: Verify all binaries download and install
2. **Configuration Generation**: Test TOML output with various inputs
3. **Service Startup**: Ensure ChirpStack, Gateway Bridge, and Redis start
4. **Web Interface**: Verify ingress access and functionality
5. **Gateway Communication**: Test packet reception and processing

### Integration Testing
1. **Home Assistant**: Add-on installs and configures properly
2. **MQTT**: Gateway Bridge connects to ChirpStack via MQTT
3. **Database**: SQLite database creation and migrations
4. **Persistence**: Configuration and data survive restarts

## Future Improvements

### Potential Enhancements
- **Backup/Restore**: Automated SQLite database backups
- **Metrics**: Prometheus integration for monitoring
- **Multi-tenant**: Support for multiple LoRaWAN networks
- **Certificate Management**: TLS/SSL configuration options
- **Gateway Discovery**: Automatic gateway registration

### Code Quality
- **Error Handling**: More robust error checking in run.sh
- **Logging**: Structured logging with proper log levels
- **Documentation**: In-line documentation for configuration options
- **Testing**: Automated testing framework

## Resources

### ChirpStack Documentation
- **Official Docs**: https://www.chirpstack.io/docs/
- **Configuration**: https://www.chirpstack.io/docs/chirpstack/configuration/
- **Architecture**: https://www.chirpstack.io/docs/chirpstack/architecture/

### Home Assistant Add-on Development
- **Developer Guide**: https://developers.home-assistant.io/docs/add-ons/
- **Configuration**: https://developers.home-assistant.io/docs/add-ons/configuration/
- **Best Practices**: https://developers.home-assistant.io/docs/add-ons/tutorial/

### LoRaWAN Resources
- **LoRaWAN Specification**: https://www.lora-alliance.org/
- **Regional Parameters**: ISM band configurations by region
- **Gateway Protocols**: Semtech UDP vs Basic Station comparison

## Maintainer Notes

### Release Process
1. Update version in `config.yaml`
2. Update `CHANGELOG.md` with changes
3. Commit and push to main branch
4. Test on Home Assistant instance
5. Create GitHub release if significant changes

### Support Information
- **Primary Contact**: bernard.rodriguez@databang.io
- **Repository**: https://github.com/databang-io/chirpstack-ha-addon
- **Issues**: GitHub Issues for bug reports and feature requests
- **License**: MIT License (consistent with ChirpStack project)

---

*This documentation was generated with assistance from Claude AI to ensure comprehensive coverage of the project architecture and development context.*