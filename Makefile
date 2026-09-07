DATA_DIR := /home/yuocak/data
COMPOSE := docker compose -f srcs/docker-compose.yml

all: setup up

setup:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

clean: down
	@echo "Containers stopped and removed."

fclean: clean
	@docker system prune -af
	@docker volume rm -f $$(docker volume ls -q) 2>/dev/null || true
	@sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all setup up down stop start restart logs status clean fclean re
