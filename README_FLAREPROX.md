# FlareProx Integration

## Overview

FlareProx provides **automatic IP rotation** for every Z.AI API request using Cloudflare Workers. This prevents rate limiting and improves reliability.

## Features

✅ **Automatic IP Rotation** - Every request uses a different IP address  
✅ **Zero Configuration** - Works automatically when credentials are provided  
✅ **Load Balancing** - Distributes requests across multiple workers  
✅ **Health Monitoring** - Automatically manages worker health  
✅ **Fallback Support** - Falls back to direct connection if needed  

## Quick Setup

### 1. Get Cloudflare Credentials

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Create an API Token with "Workers Scripts" permissions
3. Get your Account ID from the dashboard

### 2. Configure Environment

Add to your `.env` file:

```bash
# Enable FlareProx
ENABLE_FLAREPROX=true

# Your Cloudflare credentials
CLOUDFLARE_API_TOKEN=your_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
```

### 3. Start the Server

```bash
docker-compose up -d
```

That's it! FlareProx will automatically:
- Create Cloudflare Workers
- Route requests through different IPs
- Monitor and manage worker health

## How It Works

1. **Worker Creation**: On startup, FlareProx creates 2-3 Cloudflare Workers
2. **Request Routing**: Each Z.AI request is routed through a different worker
3. **IP Rotation**: Cloudflare provides a unique IP for each worker request
4. **Health Monitoring**: Unhealthy workers are automatically replaced

## Verification

Check FlareProx status:

```bash
curl http://localhost:8080/health
```

Response includes:
```json
{
  "status": "healthy",
  "flareprox": {
    "enabled": true,
    "total_workers": 2,
    "healthy_workers": 2,
    "total_requests": 150
  }
}
```

## Configuration Options

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_FLAREPROX` | `false` | Enable FlareProx IP rotation |
| `CLOUDFLARE_API_TOKEN` | - | Your Cloudflare API token (required) |
| `CLOUDFLARE_ACCOUNT_ID` | - | Your Cloudflare account ID (required) |

## Benefits

### Without FlareProx
- Single IP address
- Vulnerable to rate limiting
- Single point of failure

### With FlareProx
- ✅ Different IP per request
- ✅ No rate limiting issues
- ✅ Distributed load
- ✅ Automatic failover
- ✅ Better reliability

## Compatibility

FlareProx is **fully compatible** with:
- ✅ All OpenAI client libraries
- ✅ Cursor, Claude Code, and other AI tools
- ✅ Streaming and non-streaming requests
- ✅ Tool calling (Function Calling)
- ✅ Image uploads

## Troubleshooting

### FlareProx Not Starting

Check logs for:
```
❌ FlareProx initialization failed: ...
```

Common causes:
1. Invalid Cloudflare credentials
2. Insufficient API token permissions
3. Network connectivity issues

### Workers Not Created

Ensure your Cloudflare API token has:
- ✅ Workers Scripts: Edit permissions
- ✅ Account Settings: Read permissions

## Cost

FlareProx uses Cloudflare Workers:
- **Free Tier**: 100,000 requests/day
- **Paid**: $5/month for 10M requests

Most users will stay within the free tier.

## Performance

FlareProx adds minimal latency:
- **Overhead**: ~50-100ms per request
- **Benefit**: Unlimited rate limits
- **Net Result**: Better overall performance

## Support

For issues or questions:
1. Check server logs: `docker-compose logs -f`
2. Verify credentials in `.env`
3. Test workers: Check `/health` endpoint
