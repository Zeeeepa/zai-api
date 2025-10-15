# FlareProx Integration Guide

FlareProx provides dynamic IP rotation and load balancing through Cloudflare Workers.

## Quick Start

### 1. Get Cloudflare Credentials

1. Sign up at [cloudflare.com](https://cloudflare.com)
2. Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
3. Create Token → Use "Edit Cloudflare Workers" template
4. Set resources to **All** → Create Token
5. Copy API token and Account ID from dashboard

### 2. Configure

Add to `.env`:

```bash
ENABLE_FLAREPROX=true
CLOUDFLARE_API_TOKEN=your_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
```

### 3. Start

```bash
bash scripts/start.sh
```

## Features

- **Auto-scaling**: 2-10 workers based on load
- **Load balancing**: Weighted random selection
- **Health monitoring**: Auto-failover on failures
- **IP rotation**: Different IP per request

## How It Works

```
Client → ZAI-API → FlareProx → Worker 1 → chat.z.ai
                             ├→ Worker 2 → chat.z.ai  
                             └→ Worker 3 → chat.z.ai
```

## Logs

```bash
tail -f server.log | grep FLAREPROX
```

## Limits

Cloudflare Free Tier:
- 100,000 requests/day
- < 50ms latency overhead

## Troubleshooting

### "FlareProx not configured"
Check `.env` has valid credentials and `ENABLE_FLAREPROX=true`

### "No workers available"
Enable debug logging: `export LOG_LEVEL=debug`

API token needs these permissions:
- Account > Workers Scripts > Edit
- Account > Account Settings > Read
