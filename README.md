# Minecraft Server with Docker

A simple Docker-based Minecraft server setup for Ubuntu systems.

## Quick Start

### Prerequisites

- Ubuntu system (18.04 or newer)
- Docker and Docker Compose installed
- Root or sudo access

### Installation

1. Clone this repository:
```bash
git clone <your-repo-url>
cd minecraft_server_on_docker
```

2. Start the server:
```bash
docker compose up -d
```

3. View logs:
```bash
docker compose logs -f minecraft
```

4. Connect to your server at `localhost:25565` (local) or `YOUR_SERVER_IP:25565` (remote)

## Configuration

Edit the `docker-compose.yml` file to customize your server:

- **ONLINE_MODE**: Set to "FALSE" to allow TLauncher/cracked clients (default: FALSE)
- **MEMORY**: RAM allocation (default: 2G)
- **VERSION**: Minecraft version (default: LATEST)
- **TYPE**: Server type (VANILLA, FORGE, FABRIC, PAPER, SPIGOT, etc.)
- **DIFFICULTY**: Game difficulty (peaceful, easy, normal, hard)
- **MODE**: Game mode (survival, creative, adventure, spectator)
- **MAX_PLAYERS**: Maximum players (default: 20)
- **RCON_PASSWORD**: Remote console password (default: minecraft)

### Allowing Cracked/TLauncher Players

By default, this server allows unverified players (TLauncher, cracked clients) with `ONLINE_MODE: "FALSE"`.

**Warning**: Disabling online mode means:
- Players don't need official Minecraft accounts
- Username authentication is not verified
- Player skins may not work properly
- Less secure (anyone can join with any username)

To require official Minecraft accounts, set `ONLINE_MODE: "TRUE"` in docker-compose.yml.

## Server Management

### Basic Commands

```bash
# Start server
docker compose start

# Stop server
docker compose stop

# Restart server
docker compose restart

# View logs
docker compose logs -f minecraft

# Stop and remove container
docker compose down
```

### Execute Server Commands

```bash
# List players
docker exec minecraft-server rcon-cli list

# Send message to players
docker exec minecraft-server rcon-cli say Hello players!

# Access server console
docker attach minecraft-server
# Press Ctrl+P then Ctrl+Q to detach
```

## Backup

Server data is stored in the `./data` directory. To create a backup:

```bash
docker compose stop
tar -czf minecraft-backup-$(date +%Y%m%d).tar.gz data/
docker compose start
```

## Firewall Configuration

Allow Minecraft port through UFW:

```bash
sudo ufw allow 25565/tcp
sudo ufw reload
```

## Updating

Update to the latest Minecraft version:

```bash
docker compose pull
docker compose up -d
```

## Troubleshooting

### Server won't start
Check logs: `docker compose logs minecraft`

### Can't connect
- Verify container is running: `docker ps`
- Check firewall rules
- Verify port forwarding on your router (if hosting from home)

### Performance issues
Increase memory in `docker-compose.yml`:
```yaml
MEMORY: "4G"
```

## Resources

- [Docker Image Documentation](https://hub.docker.com/r/itzg/minecraft-server)
- [Official Minecraft Server](https://www.minecraft.net/en-us/download/server)

## License

This project is open source and available for use.
