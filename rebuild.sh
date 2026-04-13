# 1. Baja todo (contenedores + red)
docker compose down

# 2. Mata imágenes viejas de ese compose
docker compose down --rmi all --volumes --remove-orphans

# 3. Build SIN cache (clave)
docker compose build --no-cache

# 4. Levanta nuevamente
docker compose up -d
