MYSQL_DB := php_cms
MYSQL_USER := root
MYSQL_PASSWORD := ""
MYSQL_PORT := 3306

up: 
	docker-compose -f docker_compose.yaml up -d vulnerable_app --build
	@echo "[wait please] roll up migrations ..."
	@sleep 10;
	docker-compose -f docker_compose.yaml up migration --build

down:
	docker-compose -f docker_compose.yaml down
