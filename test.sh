#!/usr/bin/env bash

set -e

BASE="http://82.29.153.101:8080"

echo "[1] Health check..."
HEALTH=$(curl -s "$BASE/health")
echo "-> $HEALTH"

echo
echo "[2] Obteniendo nonce + token..."
AUTH=$(curl -s "$BASE/auth/key")

NONCE=$(echo "$AUTH" | grep -oP '"nonce"\s*:\s*"\K[^"]+')
TOKEN=$(echo "$AUTH" | grep -oP '"token"\s*:\s*"\K[^"]+')

if [ -z "$NONCE" ] || [ -z "$TOKEN" ]; then
  echo "[ERROR] No se pudo obtener nonce/token"
  echo "$AUTH"
  exit 1
fi

echo "-> NONCE=$NONCE"
echo "-> TOKEN=$TOKEN"

echo
echo "[3] Solicitando payload..."

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "X-Nonce: $NONCE" \
  -H "X-Token: $TOKEN" \
  "$BASE/payload/encrypted")

BODY=$(echo "$RESPONSE" | sed '$d')
STATUS=$(echo "$RESPONSE" | tail -n1 | cut -d: -f2)

echo "-> STATUS=$STATUS"

if [ "$STATUS" != "200" ]; then
  echo "[ERROR] Payload falló"
  echo "$BODY"
  exit 1
fi

echo
echo "[4] Validando contenido..."

if [[ "$BODY" == *"not found"* ]]; then
  echo "[ERROR] artefacto.ps1 no encontrado"
  exit 1
fi

if [[ -z "$BODY" ]]; then
  echo "[ERROR] Payload vacío"
  exit 1
fi

echo "-> Payload recibido correctamente"
echo
echo "===== PREVIEW ====="
echo "$BODY" | head -n 10
echo "==================="

echo
echo "[OK] API funcionando correctamente"
