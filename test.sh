#!/usr/bin/env bash

set -e

BASE="http://82.29.153.101:8080"

echo "[1] Health check..."
HEALTH=$(curl -s "$BASE/health")
echo "-> $HEALTH"

echo
echo "[2] Generando timestamp..."
TS=$(date +%s)
echo "-> TS=$TS"

echo
echo "[3] Obteniendo KEY..."
KEY=$(curl -s "$BASE/auth/key?ts=$TS")

if [ -z "$KEY" ]; then
  echo "[ERROR] No se obtuvo key"
  exit 1
fi

LEN=${#KEY}
echo "-> KEY=$KEY"
echo "-> LENGTH=$LEN"

if [ "$LEN" -ne 44 ]; then
  echo "[ERROR] Key inválida (esperado 44 chars)"
  exit 1
fi

echo
echo "[4] Solicitando payload..."
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "X-Decrypt-Key: $KEY" \
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
echo "[5] Validando contenido..."
if [[ "$BODY" == *"not found"* ]]; then
  echo "[ERROR] artefacto.ps1 no encontrado en contenedor"
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
