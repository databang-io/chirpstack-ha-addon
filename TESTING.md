# ChirpStack 4.0 Add-on Testing Guide

This guide provides comprehensive testing instructions for the ChirpStack 4.0 Home Assistant Add-on.

## 🧪 Local Testing (Development/PC)

### Prerequisites
- Docker installed
- Git repository cloned
- Linux/macOS/WSL environment

### Quick Start
```bash
cd /path/to/chirpstack-addon
chmod +x run-standalone.sh
./run-standalone.sh
```

This will create a complete test environment with:
- ✅ PostgreSQL database
- ✅ Redis cache  
- ✅ MQTT broker (Mosquitto)
- ✅ ChirpStack Network Server 4.15.0
- ✅ ChirpStack Gateway Bridge 4.1.1

### Test Environment URLs
- **ChirpStack Web UI**: http://localhost:8080
- **MQTT Broker**: localhost:1883
- **Basic Station**: ws://localhost:3001
- **UDP Packet Forwarder**: localhost:1700

### Default Login
- **Username**: `admin`
- **Password**: `admin`

### Monitoring
```bash
# View ChirpStack logs
docker logs -f chirpstack-standalone-test

# Check all services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep test

# Stop all test services
docker stop chirpstack-standalone-test postgres-test redis-test mosquitto-test
docker rm chirpstack-standalone-test postgres-test redis-test mosquitto-test
docker network rm chirpstack-test
```

---

## 🏠 Home Assistant Testing

### Method 1: Local Add-on Installation

#### Step 1: Copy to Home Assistant
```bash
# Copy addon to your Home Assistant system
scp -P 2222 -r chirpstack root@homeassistant.local:/addons/
```

#### Step 2: Install via GUI
1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click **⋮** (three dots) → **Reload**
3. Find **"ChirpStack"** under **Local add-ons**
4. Click **Install**

#### Step 3: Configuration
Navigate to the **Configuration** tab and configure:

```yaml
log_level: info
mqtt:
  server: "tcp://core-mosquitto:1883"
  username: "chirpstack"
  password: "your-mqtt-password"
basic_station:
  enabled: true
  bind: "0.0.0.0:3001"
packet_forwarder:
  enabled: true
  bind: "0.0.0.0:1700"
chirpstack_config: |
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
  
  [integration.mqtt]
  server="tcp://core-mosquitto:1883"
  username="chirpstack"
  password="your-mqtt-password"
  
  [regions.eu868]
  name="eu868"
gateway_bridge_config: |
  [general]
  log_level=4
  
  [backend.basic_station]
  bind="0.0.0.0:3001"
  
  [backend.semtech_udp]
  udp_bind="0.0.0.0:1700"
  
  [integration.mqtt.auth]
  type="generic"
  
  [integration.mqtt.auth.generic]
  servers=["tcp://core-mosquitto:1883"]
  username="chirpstack"
  password="your-mqtt-password"
```

#### Step 4: Start & Access
1. Click **Start** in the add-on
2. Access ChirpStack at: `http://homeassistant.local:8080`
3. Login with `admin` / `admin`

### Method 2: Repository Installation

#### Step 1: Create GitHub Repository
1. Create repository: `chirpstack-addon-repository`
2. Push your code:
   ```bash
   git remote add origin https://github.com/yourusername/chirpstack-addon-repository.git
   git push -u origin master
   ```

#### Step 2: Add to Home Assistant
1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click **⋮** → **Repositories**
3. Add: `https://github.com/yourusername/chirpstack-addon-repository`
4. Find and install **ChirpStack** add-on

---

## 🔧 Configuration Testing

### TOML Configuration Validation
```bash
# Test configuration syntax
python3 -c "
import toml
with open('chirpstack/config.yaml', 'r') as f:
    import yaml
    config = yaml.safe_load(f)
    
# Test ChirpStack config
toml.loads(config['options']['chirpstack_config'])
print('✅ ChirpStack config valid')

# Test Gateway Bridge config  
toml.loads(config['options']['gateway_bridge_config'])
print('✅ Gateway Bridge config valid')
"
```

### Build Testing
```bash
# Test AMD64 build
docker build --build-arg BUILD_FROM="ghcr.io/home-assistant/amd64-base:3.19" -t chirpstack-test-amd64 chirpstack/

# Test ARM64 build (if on ARM64 system)
docker build --build-arg BUILD_FROM="ghcr.io/home-assistant/aarch64-base:3.19" -t chirpstack-test-arm64 chirpstack/
```

---

## 🌐 Network Testing

### MQTT Testing
```bash
# Install MQTT client
apt-get install mosquitto-clients

# Subscribe to gateway events
mosquitto_sub -h localhost -p 1883 -u chirpstack -P testpass -t "gateway/+/event/+"

# Publish test message
mosquitto_pub -h localhost -p 1883 -u chirpstack -P testpass -t "gateway/test/command/down" -m '{"test": true}'
```

### Basic Station Testing
```bash
# Test WebSocket connection
curl -v -H "Connection: Upgrade" -H "Upgrade: websocket" http://localhost:3001
```

### UDP Packet Forwarder Testing
```bash
# Test UDP port
nc -u localhost 1700
```

---

## 📊 Verification Checklist

### ✅ Startup Verification
- [ ] All containers start successfully
- [ ] No critical errors in logs
- [ ] Web UI accessible
- [ ] Database connection established
- [ ] MQTT connection established

### ✅ Configuration Verification
- [ ] ChirpStack config generated correctly
- [ ] Gateway Bridge config generated correctly
- [ ] MQTT credentials applied
- [ ] Port bindings working

### ✅ Functionality Verification
- [ ] Web UI login works (admin/admin)
- [ ] Can create tenants/applications
- [ ] MQTT messages flow
- [ ] Basic Station port responds
- [ ] UDP port responds

### ✅ Integration Verification
- [ ] MQTT discovery in Home Assistant
- [ ] Device data appears in HA
- [ ] Downlink commands work
- [ ] Gateway status visible

---

## 🐛 Troubleshooting

### Common Issues

#### Container Exits Immediately
```bash
# Check logs
docker logs chirpstack-standalone-test

# Common causes:
# 1. Configuration file syntax error
# 2. Database connection failure
# 3. Missing environment variables
```

#### Database Connection Failed
```bash
# Check PostgreSQL
docker logs postgres-test

# Test connection
docker exec -it postgres-test psql -U chirpstack -d chirpstack
```

#### MQTT Connection Issues
```bash
# Check MQTT broker
docker logs mosquitto-test

# Test MQTT connection
docker exec -it mosquitto-test mosquitto_sub -t "test"
```

#### Web UI Not Accessible
```bash
# Check port mapping
docker port chirpstack-standalone-test

# Check ChirpStack process
docker exec chirpstack-standalone-test ps aux | grep chirpstack
```

### Log Analysis
```bash
# Full startup logs
docker logs chirpstack-standalone-test

# Real-time monitoring
docker logs -f chirpstack-standalone-test

# Filter for errors
docker logs chirpstack-standalone-test 2>&1 | grep -i error
```

---

## 📈 Performance Testing

### Load Testing
```bash
# Test multiple concurrent connections
for i in {1..10}; do
  curl http://localhost:8080 &
done
```

### Resource Monitoring
```bash
# Monitor container resources
docker stats chirpstack-standalone-test

# Check memory usage
docker exec chirpstack-standalone-test ps aux --sort=-%mem
```

---

## 🚀 Production Testing

### Security Testing
- [ ] Change default passwords
- [ ] Configure TLS/SSL
- [ ] Review exposed ports
- [ ] Check file permissions

### Backup Testing
- [ ] Database backup/restore
- [ ] Configuration backup
- [ ] Disaster recovery

### Scale Testing
- [ ] Multiple gateways
- [ ] High device count
- [ ] Message throughput

---

## 📝 Test Report Template

```markdown
## ChirpStack 4.0 Add-on Test Report

**Date**: 
**Tester**: 
**Environment**: 

### Test Results
- [ ] Local build successful
- [ ] Container startup: PASS/FAIL
- [ ] Web UI access: PASS/FAIL
- [ ] MQTT connectivity: PASS/FAIL
- [ ] Database connectivity: PASS/FAIL

### Issues Found
1. 

### Recommendations
1. 

### Next Steps
1. 
```