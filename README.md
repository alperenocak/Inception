*This project has been created as part of the 42 curriculum by yuocak.*

# Inception

## Description

Inception is a system administration project that introduces Docker and containerization concepts. The goal is to set up a small infrastructure composed of different services running inside Docker containers, all orchestrated via Docker Compose inside a virtual machine.

The infrastructure consists of three main services:
- **NGINX** — A web server configured with TLSv1.2/TLSv1.3, serving as the sole entry point on port 443.
- **WordPress** — A content management system running with PHP-FPM (without NGINX), connected to the database.
- **MariaDB** — A relational database storing all WordPress data.

Each service runs in its own dedicated container, built from a custom Dockerfile based on Debian Bookworm. The containers communicate over a private Docker network and persist their data through Docker volumes.

## Instructions

### Prerequisites

- A virtual machine running a Debian-based Linux distribution
- Docker and Docker Compose installed
- `make` installed
- Add your user to the `docker` group to avoid using `sudo`:
  ```bash
  sudo usermod -aG docker $USER
  ```
  Then log out and log back in.

### DNS Configuration

Add the following entry to your `/etc/hosts` file:
```bash
echo "127.0.0.1 yuocak.42.fr" | sudo tee -a /etc/hosts
```

### Setup and Run

```bash
# Clone the repository
git clone <repository-url>
cd Inception

# Create secret files in the secrets/ directory
echo "your_db_password" > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt

# Create the .env file in srcs/
cp srcs/.env.example srcs/.env  # or create manually

# Build and start everything
make
```

### Available Commands

| Command | Description |
|---|---|
| `make` | Set up directories and build/start all containers |
| `make down` | Stop and remove containers (data preserved) |
| `make stop` | Pause containers without removing them |
| `make start` | Resume paused containers |
| `make restart` | Restart all containers |
| `make logs` | Follow live container logs |
| `make status` | Show container statuses |
| `make clean` | Stop and remove containers |
| `make fclean` | Full cleanup: containers, images, volumes, and data |
| `make re` | Full cleanup then rebuild from scratch |

### Accessing the Website

Open your browser and navigate to:
```
https://yuocak.42.fr
```
A self-signed certificate warning will appear — this is expected.

## Resources

### References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [Docker Secrets Documentation](https://docs.docker.com/engine/swarm/secrets/)
- [OpenSSL Manual](https://www.openssl.org/docs/)

### AI Usage

AI tools were used during this project for:
- **Debugging**: Diagnosing Docker networking issues, container startup order problems, and PHP-FPM configuration.
- **Learning**: Understanding Docker concepts such as secrets, networking, volume management, and the differences between `depends_on` and health checks.
- **Documentation**: Assisting in structuring and writing the project documentation (README, USER_DOC, DEV_DOC).

All Dockerfiles, configuration files, and scripts were written and understood by the student. AI was not used to generate the core infrastructure code directly.

## Project Description

### Docker Usage in This Project

This project uses Docker to create an isolated, reproducible infrastructure. Each service (NGINX, WordPress, MariaDB) runs in its own container, built from a custom Dockerfile based on `debian:bookworm`. Docker Compose orchestrates the multi-container setup, managing networking, volumes, secrets, and startup dependencies.

The architecture follows the principle of **one process per container**, with each container responsible for a single service.

### Virtual Machines vs Docker

| Aspect | Virtual Machine | Docker Container |
|---|---|---|
| **Isolation level** | Full OS-level isolation with its own kernel | Process-level isolation sharing the host kernel |
| **Resource usage** | Heavy — each VM runs a complete OS (GBs of RAM) | Lightweight — shares host kernel, uses only MBs |
| **Startup time** | Minutes (full OS boot) | Seconds (just process startup) |
| **Portability** | VM images are large and platform-dependent | Container images are small and portable across any Docker host |
| **Use case** | When full OS isolation is required (e.g., running different OS) | When application isolation is sufficient (microservices, CI/CD) |

In this project, a VM provides the host environment, while Docker containers provide service-level isolation within that VM.

### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets |
|---|---|---|
| **Visibility** | Visible via `docker inspect`, process listing, and logs | Only accessible inside the container at `/run/secrets/` |
| **Storage** | Stored in memory, passed to all child processes | Mounted as read-only files in a tmpfs filesystem |
| **Security** | Anyone with Docker access can read them | Encrypted at rest, only available to authorized containers |
| **Use case** | Non-sensitive configuration (domain name, database name) | Sensitive data (passwords, API keys, certificates) |

In this project, non-sensitive values like `DOMAIN_NAME` and `MYSQL_DATABASE` are set via `.env`, while all passwords are stored as Docker secrets.

### Docker Network vs Host Network

| Aspect | Docker Bridge Network | Host Network |
|---|---|---|
| **Isolation** | Containers are isolated in their own network namespace | Containers share the host's network stack directly |
| **DNS resolution** | Containers can reach each other by name (e.g., `mariadb`, `wordpress`) | No automatic DNS between containers |
| **Port conflicts** | Each container has its own port space — no conflicts | Containers compete for the same ports as the host |
| **Security** | Only explicitly exposed ports are accessible from outside | All container ports are directly accessible on the host |
| **Use case** | Multi-container applications needing isolation (recommended) | Performance-critical applications needing zero network overhead |

This project uses a custom bridge network named `inception`. Only NGINX exposes port 443 to the outside; MariaDB (3306) and WordPress/PHP-FPM (9000) are only accessible within the Docker network.

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|---|---|---|
| **Management** | Managed by Docker (`docker volume` commands) | Managed manually — just a host directory |
| **Location** | Stored in Docker's internal storage (`/var/lib/docker/volumes/`) | Any directory on the host filesystem |
| **Portability** | Easy to back up, migrate, and share between containers | Tied to a specific host path |
| **Performance** | Optimized by Docker for I/O | Depends on host filesystem performance |
| **Use case** | General purpose data persistence | When you need direct host filesystem access |

This project uses **named volumes with bind mount options** — a hybrid approach. The volumes are managed by Docker but mapped to specific host directories (`/home/yuocak/data/mariadb` and `/home/yuocak/data/wordpress`), satisfying the project requirement that data persists at `/home/login/data/`.
