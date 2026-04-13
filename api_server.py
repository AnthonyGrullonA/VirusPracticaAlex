from flask import Flask, request, Response, abort, jsonify
import hashlib, hmac, secrets

app = Flask(__name__)
print("🔥 API v5.0 - Stateless HMAC")

# =========================
# CONFIG
# =========================
SECRET = b"UltraSecretKey_ChangeThis"

# =========================
# HEALTH
# =========================
@app.route('/health')
def health():
    return jsonify({"status": "OK"})

# =========================
# AUTH (nonce + token)
# =========================
@app.route('/auth/key')
def auth_key():
    nonce = secrets.token_hex(16)

    token = hmac.new(
        SECRET,
        nonce.encode(),
        hashlib.sha256
    ).hexdigest()[:44]

    return jsonify({
        "nonce": nonce,
        "token": token
    })

# =========================
# PAYLOAD
# =========================
@app.route('/payload/encrypted')
def payload():
    nonce = request.headers.get('X-Nonce', '')
    token = request.headers.get('X-Token', '')

    if not nonce or not token:
        abort(401, "Missing headers")

    expected = hmac.new(
        SECRET,
        nonce.encode(),
        hashlib.sha256
    ).hexdigest()[:44]

    if token != expected:
        abort(401, "Invalid token")

    try:
        with open('artefacto.ps1', 'r', encoding='utf-8') as f:
            payload = f.read()

        return Response(payload, mimetype='text/plain')

    except FileNotFoundError:
        abort(404, "artefacto.ps1 not found")

# =========================
# RUN
# =========================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
