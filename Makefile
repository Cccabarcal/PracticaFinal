.PHONY: help build up down logs restart clean test db-shell stats-shell ps

help:
	@echo "╔════════════════════════════════════════╗"
	@echo "║   Práctica Final EAFIT - Makefile      ║"
	@echo "╚════════════════════════════════════════╝"
	@echo ""
	@echo "Comandos disponibles:"
	@echo ""
	@echo "  make build        - Construir imágenes Docker"
	@echo "  make up           - Iniciar servicios"
	@echo "  make down         - Detener servicios"
	@echo "  make restart      - Reiniciar servicios"
	@echo "  make logs         - Ver logs en tiempo real"
	@echo "  make ps           - Ver estado de servicios"
	@echo "  make clean        - Eliminar contenedores e imágenes"
	@echo ""
	@echo "  make db-shell     - Acceder a shell de MySQL"
	@echo "  make test         - Ejecutar tests básicos"
	@echo ""
	@echo "  make certs        - Generar certificados SSL"
	@echo "  make seed         - Agregar datos de prueba a BD"
	@echo "  make backup       - Hacer backup de BD"
	@echo ""
	@echo "Ejemplos:"
	@echo "  make up logs      - Iniciar y ver logs"
	@echo "  make restart web-es - Reiniciar solo web-es"

build:
	@echo "🔨 Construyendo imágenes Docker..."
	docker-compose build

up:
	@echo "🚀 Iniciando servicios..."
	docker-compose up -d
	@echo "✅ Servicios iniciados"
	@echo ""
	@echo "Acceder a:"
	@echo "  - https://localhost/es"
	@echo "  - https://localhost/en"
	@echo "  - https://localhost/stats"

down:
	@echo "⛔ Deteniendo servicios..."
	docker-compose down
	@echo "✅ Servicios detenidos"

restart:
	@echo "🔄 Reiniciando servicios..."
	docker-compose restart $(filter-out $@,$(MAKECMDGOALS))
	@echo "✅ Servicios reiniciados"

logs:
	docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

ps:
	docker-compose ps

clean:
	@echo "🧹 Limpiando..."
	docker-compose down -v
	docker system prune -a -f
	@echo "✅ Limpieza completada"

test:
	@echo "🧪 Ejecutando tests básicos..."
	@echo ""
	@echo "Test 1: Verificar aplicación en español"
	@curl -k -s -o /dev/null -w "Status: %{http_code}\n" https://localhost/es
	@echo ""
	@echo "Test 2: Verificar aplicación en inglés"
	@curl -k -s -o /dev/null -w "Status: %{http_code}\n" https://localhost/en
	@echo ""
	@echo "Test 3: Verificar estadísticas"
	@curl -k -s -o /dev/null -w "Status: %{http_code}\n" https://localhost/stats
	@echo ""
	@echo "Test 4: API de estadísticas"
	@curl -k -s https://localhost/api/statistics | head -n 5
	@echo ""
	@echo "✅ Tests completados"

db-shell:
	@echo "📊 Abriendo shell MySQL..."
	docker-compose exec db mysql -u root -p usuarios

db-backup:
	@echo "💾 Haciendo backup de BD..."
	docker-compose exec db mysqldump -u root -p usuarios > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup completado"

db-query:
	docker-compose exec -T db mysql -u root -peafit_2025_secure usuarios -e "$(filter-out $@,$(MAKECMDGOALS))"

seed:
	@echo "🌱 Agregando datos de prueba..."
	docker-compose exec -T db mysql -u root -peafit_2025_secure usuarios << EOF
	INSERT INTO registros (nombre, comuna, carrera, fecha) VALUES
	('Juan García López', 'Comuna 1', 'Medicina', NOW()),
	('María Rodríguez López', 'Comuna 2', 'Ingeniería', NOW()),
	('Carlos Martínez Pérez', 'Comuna 3', 'Abogacía', NOW()),
	('Ana Sánchez Torres', 'Comuna 4', 'Licenciatura', NOW()),
	('Luis González García', 'Comuna 5', 'Medicina', NOW()),
	('Claudia Fernández López', 'Comuna 6', 'Ingeniería', NOW());
	EOF
	@echo "✅ Datos agregados"

certs:
	@echo "🔐 Generando certificados SSL..."
	bash generate_certs.sh
	@echo "✅ Certificados generados"

stats:
	@echo "📊 Estadísticas de contenedores:"
	docker stats --no-stream

env-setup:
	@echo "⚙️ Configurando variables de entorno..."
	cp .env.example .env
	@echo "✅ Archivo .env creado"
	@echo "Por favor, edita .env con tus valores:"
	@echo "  nano .env"

install: build certs env-setup up
	@echo ""
	@echo "✅ Instalación completada!"
	@echo ""
	@echo "Próximos pasos:"
	@echo "  1. Esperar a que la BD se inicialice (10-15 segundos)"
	@echo "  2. Acceder a https://localhost/es"
	@echo "  3. Ver documentación en README.md"

%:
	@:
