# Developer Documentation — Inception

This document describes how to set up, build, and manage the Inception infrastructure from a developer's perspective.

## Setting Up the Environment from Scratch

### 1. Prerequisites

Install the required software on your Debian-based virtual machine:

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y docker.io docker-compose-v2

# Add your user to the docker group (to avoid sudo)
sudo usermod -aG docker $USER

# Install make
sudo apt-get install -y make

# Log out and log back in for group changes to take effect
```

Verify the installation:

```bash
docker --version
docker compose version
make --version
```

### 2. DNS Configuration

Map the project domain to localhost:

```bash
echo "127.0.0.1 yuocak.42.fr" | sudo tee -a /etc/hosts
```

### 3. Secret Files

Create the `secrets/` directory and populate it with password files:

```bash
mkdir -p secrets

# Set your passwords (replace with actual values)
echo "your_db_password" > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt
```

These files are mounted into containers at `/run/secrets/` by Docker Compose.

### 4. Environment File

Create `srcs/.env` with the following variables:

```env
DOMAIN_NAME=yuocak.42.fr

# MariaDB settings
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

# WordPress settings
WP_TITLE=Inception
WP_ADMIN_USER=chief_yuocak
WP_ADMIN_EMAIL=yuocak@student.42kocaeli.com.tr
WP_USER=author_yuocak
WP_USER_EMAIL=author@student.42kocaeli.com.tr
```

> **Note:** Both `secrets/` and `srcs/.env` are listed in `.gitignore` and must never be committed.

## Building and Launching the Project

### Using the Makefile

```bash
# Build and start everything (primary command)
make

# This runs two targets in sequence:
#   1. make setup  → creates /home/yuocak/data/mariadb and /home/yuocak/data/wordpress
#   2. make up     → runs docker compose up -d --build
```

### Using Docker Compose Directly

If you need more control, you can use Docker Compose directly:

```bash
# Build and start
docker compose -f srcs/docker-compose.yml up -d --build

# Build without starting
docker compose -f srcs/docker-compose.yml build

# Start with visible logs (foreground)
docker compose -f srcs/docker-compose.yml up --build
```

### Build Order and Dependencies

Docker Compose starts containers in this order based on `depends_on`:

```
1. mariadb    → Starts first, runs init.sh to set up the database
2. wordpress  → Waits for mariadb container to start, then runs setup.sh
3. nginx      → Waits for wordpress container to start
```

> **Important:** `depends_on` only guarantees container start order, not service readiness. WordPress uses a `mysqladmin ping` loop in `setup.sh` to wait for MariaDB to actually accept connections.

## Managing Containers and Volumes

### Container Management

| Command | Description |
|---|---|
| `make status` | List containers and their statuses |
| `make logs` | Follow live logs from all containers |
| `make stop` | Stop containers (keep them) |
| `make start` | Start stopped containers |
| `make restart` | Restart all containers |
| `make down` | Stop and remove containers + network |
| `make clean` | Same as `down` with a confirmation message |
| `make fclean` | Full cleanup: containers, images, volumes, and host data |
| `make re` | `fclean` + `all` — complete rebuild from scratch |

### Inspecting Containers

```bash
# Enter a container shell
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# View a specific container's logs
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx

# Inspect container details
docker inspect mariadb
docker inspect wordpress
docker inspect nginx
```

### Volume Management

```bash
# List all volumes
docker volume ls

# Inspect a volume (verify the host path)
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data

# Remove all unused volumes (caution: destroys data)
docker volume prune

# Remove a specific volume
docker volume rm srcs_mariadb_data
docker volume rm srcs_wordpress_data
```

### Network Management

```bash
# List networks
docker network ls

# Inspect the project network
docker network inspect srcs_inception

# Verify container connectivity
docker exec wordpress ping -c 2 mariadb
docker exec nginx ping -c 2 wordpress
```

### Database Access

```bash
# Connect to MariaDB from inside the mariadb container
docker exec -it mariadb mysql -u wp_user -p wordpress

# Useful SQL commands once connected:
SHOW DATABASES;
SHOW TABLES;
SELECT user, host FROM mysql.user;
SELECT * FROM wp_users;
```

## Data Storage and Persistence

### Where Data Is Stored

| Data | Host Path | Container Path | Volume Name |
|---|---|---|---|
| MariaDB database files | `/home/yuocak/data/mariadb` | `/var/lib/mysql` | `mariadb_data` |
| WordPress site files | `/home/yuocak/data/wordpress` | `/var/www/wordpress` | `wordpress_data` |

### How Persistence Works

The project uses **named Docker volumes with bind mount options**. This means:

1. Docker manages the volumes (`docker volume ls` shows them)
2. The actual data resides on the host filesystem at `/home/yuocak/data/`
3. Both Nginx and WordPress share the `wordpress_data` volume

### What Survives What

| Event | Data Preserved? |
|---|---|
| `make stop` / `make start` | ✅ Yes — containers are just paused |
| `make down` / `make up` | ✅ Yes — volumes persist across container removal |
| VM reboot | ✅ Yes — `restart: unless-stopped` restarts containers, volumes remain |
| `make fclean` / `make re` | ❌ No — volumes and host data are deleted |
| `docker volume rm` | ❌ No — volume data is destroyed |

### First Run vs Subsequent Runs

Both MariaDB (`init.sh`) and WordPress (`setup.sh`) include first-run detection:

- **MariaDB:** Checks if the `mysql` system database directory exists
- **WordPress:** Checks if `wp-login.php` exists

On first run, full initialization is performed (database creation, user setup, WordPress installation). On subsequent runs, this is skipped because the data already exists in the volume.

## Project Structure

```
Inception/
├── Makefile                          # Build/run commands
├── README.md                         # Project overview
├── USER_DOC.md                       # User documentation
├── DEV_DOC.md                        # Developer documentation (this file)
├── secrets/                          # Password files (gitignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                          # Environment variables (gitignored)
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── 50-server.cnf     # MariaDB configuration
        │   └── tools/
        │       └── init.sh           # Database initialization script
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   ├── conf/
        │   │   └── www.conf          # PHP-FPM pool configuration
        │   └── tools/
        │       └── setup.sh          # WordPress setup script
        └── nginx/
            ├── Dockerfile
            ├── .dockerignore
            └── conf/
                └── nginx.conf        # NGINX site configuration
```
