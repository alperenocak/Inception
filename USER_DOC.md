# User Documentation — Inception

This document explains how to use and manage the Inception infrastructure as an end user or administrator.

## Services Overview

The Inception stack provides a fully functional WordPress website with the following services:

| Service | Description | Access |
|---|---|---|
| **NGINX** | Web server and reverse proxy with SSL/TLS encryption | `https://yuocak.42.fr` (port 443) |
| **WordPress** | Content management system for creating and managing website content | Accessed through NGINX |
| **MariaDB** | Relational database that stores all WordPress data (posts, users, settings) | Internal only — not accessible from outside |

## Starting and Stopping the Project

### Start the Stack

```bash
make
```

This command creates the necessary data directories and builds/starts all three containers in the correct order (MariaDB → WordPress → NGINX).

### Stop the Stack (Preserve Containers)

```bash
make stop
```

Pauses all containers. Data is preserved and containers can be resumed.

### Resume the Stack

```bash
make start
```

Resumes previously stopped containers.

### Stop and Remove Containers

```bash
make down
```

Stops and removes all containers and the Docker network. **Data is preserved** in the volumes.

### Full Restart

```bash
make restart
```

Restarts all containers.

### Complete Cleanup and Rebuild

```bash
make re
```

Removes everything (containers, images, volumes, data) and rebuilds from scratch.

## Accessing the Website

### WordPress Website

1. Open your browser
2. Navigate to: **https://yuocak.42.fr**
3. A self-signed certificate warning will appear — click "Accept the Risk" or "Continue" to proceed
4. You will see the WordPress website homepage

> **Note:** The site is only accessible via HTTPS (port 443). HTTP (port 80) is not available.

### WordPress Admin Panel

1. Navigate to: **https://yuocak.42.fr/wp-admin**
2. Log in with the administrator credentials (see below)
3. From the dashboard, you can:
   - Create and edit posts/pages
   - Manage users
   - Change themes and install plugins
   - Modify site settings

### User Accounts

The system has two pre-configured WordPress users:

| Role | Username | Purpose |
|---|---|---|
| **Administrator** | `chief_yuocak` | Full control: manage content, users, themes, plugins, and settings |
| **Author** | `author_yuocak` | Write and publish posts only |

## Locating and Managing Credentials

### Where Credentials Are Stored

Credentials are stored as files in the `secrets/` directory at the project root:

| File | Content |
|---|---|
| `secrets/db_password.txt` | MariaDB database user password |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/wp_admin_password.txt` | WordPress administrator password |
| `secrets/wp_user_password.txt` | WordPress author password |

### Changing Passwords

1. Edit the relevant file in `secrets/`
2. Rebuild the stack:
   ```bash
   make re
   ```

> **Important:** The `secrets/` directory and `srcs/.env` are excluded from Git via `.gitignore`. Never commit passwords to the repository.

### Environment Configuration

Non-sensitive settings are stored in `srcs/.env`:

| Variable | Description |
|---|---|
| `DOMAIN_NAME` | Website domain name |
| `MYSQL_DATABASE` | Database name |
| `MYSQL_USER` | Database user |
| `WP_TITLE` | WordPress site title |
| `WP_ADMIN_USER` | WordPress admin username |
| `WP_ADMIN_EMAIL` | WordPress admin email |
| `WP_USER` | WordPress author username |
| `WP_USER_EMAIL` | WordPress author email |

## Checking That Services Are Running

### Quick Status Check

```bash
make status
```

All three containers should show `Up`:

```
NAME        STATUS
mariadb     Up
wordpress   Up
nginx       Up
```

### View Live Logs

```bash
make logs
```

Press `Ctrl+C` to stop following logs.

### Check Individual Services

```bash
# Check if NGINX is serving HTTPS
curl -k https://yuocak.42.fr

# Check if MariaDB is accepting connections (from inside the WordPress container)
docker exec wordpress mysqladmin ping -h mariadb -u wp_user -p<password> --silent

# Check if PHP-FPM is running
docker exec wordpress ps aux | grep php-fpm
```

### Verify After Reboot

After rebooting the virtual machine:

1. Containers should restart automatically (`restart: unless-stopped`)
2. Run `make status` to confirm all services are `Up`
3. Open `https://yuocak.42.fr` to verify the website loads
4. Any content created before the reboot should still be present (data persists in volumes)
