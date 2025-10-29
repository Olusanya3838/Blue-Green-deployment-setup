
# Blue/Green Deployment with Nginx

Automated Blue/Green deployment strategy for Node.js services using Nginx with zero-downtime failover.

## Features

- ✅ Automatic failover on service failure
- ✅ Zero failed client requests during failover
- ✅ Health-based routing
- ✅ Configurable via environment variables

## Quick Start

1. **Configure environment variables:**
```bash
   cp .env.example .env
   # Edit .env with your image URLs
```

2. **Start services:**
```bash
   chmod +x entrypoint.sh test-simple.sh
   docker-compose up -d
```

3. **Run tests:**
```bash
   ./test-simple.sh
```

## Configuration

Edit `.env`:
```bash
BLUE_IMAGE=your-registry/nodejs-app:blue
GREEN_IMAGE=your-registry/nodejs-app:green
ACTIVE_POOL=blue
RELEASE_ID_BLUE=v1.0.0-blue
RELEASE_ID_GREEN=v1.0.0-green
PORT=3000
```

## Architecture
```
Client → Nginx (8080) → Blue (8081) [PRIMARY]
                     → Green (8082) [BACKUP]
```

## Files

- `docker-compose.yml` - Service orchestration
- `nginx.conf.template` - Nginx configuration with failover logic
- `entrypoint.sh` - Nginx startup script
- `test-simple.sh` - Automated failover tests
- `.env` - Environment configuration (not tracked in git)

## Testing Failover
```bash
# Check services
curl http://localhost:8080/version

# Trigger failure on Blue
curl -X POST http://localhost:8081/chaos/start?mode=error

# Watch traffic switch to Green
curl http://localhost:8080/version

# Stop chaos
curl -X POST http://localhost:8081/chaos/stop
```
EOF

