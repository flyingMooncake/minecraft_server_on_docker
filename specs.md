# Minecraft Server with Docker on Ubuntu

This guide will help you set up a Minecraft server using Docker on Ubuntu.

## Prerequisites

- Ubuntu system (18.04 or newer)
- Root or sudo access
- Basic command line knowledge

## Step 1: Install Docker

First, update your package list and install Docker:

```bash
# Update package list
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add your user to the docker group (optional, to run docker without sudo)
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

Verify Docker installation:

```bash
docker --version
```

## Step 2: Create Minecraft Server Directory

Create a directory to store your Minecraft server data:

```bash
mkdir -p ~/minecraft-server
cd ~/minecraft-server
```

## Step 3: Create Docker Compose File

Create a `docker-compose.yml` file:

```yaml
version: "3.8"

services:
  minecraft:
    image: itzg/minecraft-server:latest
    container_name: minecraft-server
    ports:
      - "25565:25565"
    environment:
      EULA: "TRUE"
      TYPE: "VANILLA"
      VERSION: "LATEST"
      MEMORY: "2G"
      SERVER_NAME: "My Minecraft Server"
      MOTD: "Welcome to my Minecraft server!"
      DIFFICULTY: "normal"
      MODE: "survival"
      PVP: "true"
      MAX_PLAYERS: "20"
      VIEW_DISTANCE: "10"
      ENABLE_RCON: "true"
      RCON_PASSWORD: "minecraft"
      RCON_PORT: "25575"
    volumes:
      - ./data:/data
    stdin_open: true
    tty: true
    restart: unless-stopped
```

## Step 4: Configuration Options

You can customize the server by modifying the environment variables in the `docker-compose.yml` file:

- **EULA**: Must be "TRUE" to accept Minecraft's EULA
- **TYPE**: Server type (VANILLA, FORGE, FABRIC, PAPER, SPIGOT, BUKKIT, etc.)
- **VERSION**: Minecraft version (LATEST, 1.20.4, 1.19.4, etc.)
- **MEMORY**: Amount of RAM allocated (1G, 2G, 4G, etc.)
- **DIFFICULTY**: Game difficulty (peaceful, easy, normal, hard)
- **MODE**: Game mode (survival, creative, adventure, spectator)
- **MAX_PLAYERS**: Maximum number of players
- **VIEW_DISTANCE**: Server view distance (chunks)
- **ENABLE_RCON**: Enable remote console (true/false)
- **RCON_PASSWORD**: Password for RCON access

## Step 5: Start the Minecraft Server

Start the server using Docker Compose:

```bash
docker compose up -d
```

The `-d` flag runs the container in detached mode (background).

## Step 6: Check Server Status

View server logs:

```bash
docker compose logs -f minecraft
```

Press `Ctrl+C` to exit the logs view.

Check if the container is running:

```bash
docker ps
```

## Step 7: Connect to Your Server

Once the server is running, you can connect to it using:

- **Local connection**: `localhost:25565`
- **Remote connection**: `YOUR_SERVER_IP:25565`

To find your server's public IP:

```bash
curl ifconfig.me
```

## Managing Your Server

### Stop the server

```bash
docker compose stop
```

### Start the server

```bash
docker compose start
```

### Restart the server

```bash
docker compose restart
```

### Stop and remove the container

```bash
docker compose down
```

### Access server console

```bash
docker attach minecraft-server
```

To detach without stopping the server, press `Ctrl+P` then `Ctrl+Q`.

### Execute commands

```bash
docker exec minecraft-server rcon-cli <command>
```

Example:

```bash
docker exec minecraft-server rcon-cli list
docker exec minecraft-server rcon-cli say Hello players!
```

## Backup Your Server

Your server data is stored in the `~/minecraft-server/data` directory. To back it up:

```bash
# Stop the server first
docker compose stop

# Create a backup
tar -czf minecraft-backup-$(date +%Y%m%d).tar.gz data/

# Start the server again
docker compose start
```

## Configure Firewall

If you're using UFW (Uncomplicated Firewall), allow Minecraft port:

```bash
sudo ufw allow 25565/tcp
sudo ufw reload
```

## Updating the Server

To update to the latest Minecraft version:

```bash
docker compose pull
docker compose up -d
```

## Troubleshooting

### Server won't start

Check the logs for errors:

```bash
docker compose logs minecraft
```

### Can't connect to server

- Check if the container is running: `docker ps`
- Verify firewall rules
- Ensure port 25565 is accessible
- Check your router's port forwarding settings (if hosting from home)

### Performance issues

Increase the memory allocation in `docker-compose.yml`:

```yaml
MEMORY: "4G"  # or higher depending on available RAM
```

## Additional Resources

- [itzg/minecraft-server Docker Hub](https://hub.docker.com/r/itzg/minecraft-server)
- [Official Minecraft Documentation](https://www.minecraft.net/en-us/download/server)
- [Docker Documentation](https://docs.docker.com/)

## Notes

- The server will automatically accept the Minecraft EULA with `EULA: "TRUE"`
- Server data persists in the `./data` directory even if the container is removed
- The server automatically restarts unless explicitly stopped
- RCON is enabled by default for remote management

Enjoy your Minecraft server!