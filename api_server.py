from flask import Flask, request, Response, abort, jsonify
import os, base64, hashlib, time
from cryptography.fernet import Fernet

app = Flask(__name__)
print("🔥 Ciberdefensa API v3.0 - Payload en texto plano")

# =========================
# CONFIG
# =========================
SECRET_SALT = "CyberDefense2024_FixedSalt_32charsExactly!!"

DATA_PATH = '/data/keys.txt'
os.makedirs('/data', exist_ok=True)

# =========================
# MASTER KEY (persistente)
# =========================
def load_or_create_master_key():
    try:
        with open(DATA_PATH) as f:
            master_b64 = f.read().strip()
        master_key = base64.urlsafe_b64decode(master_b64)
        print("✅ Master key cargada")
        return master_key
    except:
        master_key = Fernet.generate_key()
        with open(DATA_PATH, 'w') as f:
            f.write(base64.b64encode(master_key).decode())
        print("🆕 Master key generada")
        return master_key

MASTER_KEY = load_or_create_master_key()

# =========================
# HEALTH
# =========================
@app.route('/health')
def health():
    return jsonify({
        "status": "OK",
        "keys_loaded": os.path.exists(DATA_PATH),
        "salt_fixed": True
    })

# =========================
# AUTH KEY (sin cifrado)
# =========================
@app.route('/auth/key')
def auth_key():
    ts = request.args.get('ts', '')

    if not ts.isdigit() or abs(int(ts) - int(time.time())) > 600:
        abort(401, "Invalid or expired timestamp")

    temp_key_raw = hashlib.sha256(f"{SECRET_SALT}{ts}".encode()).digest()
    payload_key = hashlib.sha256(MASTER_KEY + temp_key_raw).hexdigest()[:44]

    return Response(payload_key, mimetype='text/plain')

# =========================
# PAYLOAD (PLANO)
# =========================
@app.route('/payload/encrypted')
def payload():
    key = request.headers.get('X-Decrypt-Key', '')

    if len(key) != 44:
        abort(401, "Invalid key")

    try:
        with open('artefacto.ps1', 'r', encoding='utf-8') as f:
            payload = f.read()

        return Response(payload, mimetype='text/plain')

    except FileNotFoundError:
        abort(404, "artefacto.ps1 not found")

# =========================
# DEBUG
# =========================
@app.route('/salt')
def salt():
    return jsonify({
        "salt": SECRET_SALT,
        "warning": "debug only"
    })

# =========================
# RUN
# =========================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
