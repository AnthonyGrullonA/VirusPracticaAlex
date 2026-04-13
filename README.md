# 🔥 API v5.0 - Stateless HMAC Payload Server

API ligera construida con Flask que implementa un mecanismo de
autenticación stateless basado en HMAC, diseñada para servir artefactos
(payloads) de forma controlada sin necesidad de sesiones persistentes.

## 🧠 Arquitectura

El flujo es simple y eficiente:

1.  Cliente solicita credenciales → /auth/key
2.  Servidor genera:
    -   nonce aleatorio
    -   token = HMAC(nonce, secret)
3.  Cliente usa ambos valores como headers para autenticarse
4.  Si el HMAC es válido → se entrega el payload (artefacto.ps1)

Sin estado. Sin base de datos. Sin sesiones.

## ⚙️ Endpoints

### Health Check

GET /health

### Generación de Token

GET /auth/key

### Descarga de Payload

GET /payload/encrypted

Headers: X-Nonce: `<nonce>`{=html} X-Token: `<token>`{=html}

## 🔐 Seguridad

-   HMAC-SHA256
-   Stateless
-   Token truncado

⚠️ Cambiar SECRET en producción.

## 📁 Estructura

. ├── app.py ├── artefacto.ps1 └── README.md

## 🚀 Ejecución

pip install flask python app.py

## 🧪 Ejemplo

curl http://localhost:5000/auth/key

curl -H "X-Nonce: `<nonce>`{=html}" -H "X-Token: `<token>`{=html}"
http://localhost:5000/payload/encrypted

## 🧠 TL;DR

HMAC + nonce = auth sin sesiones
