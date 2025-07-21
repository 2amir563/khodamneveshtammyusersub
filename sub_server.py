import base64
from flask import Flask, Response

app = Flask(__name__)

#===============================================================
#============ کانفیگ‌های خود را اینجا وارد کنید =================
#===============================================================
links = {
    'user1': [
        "vless://...",
        "hysteria2://..."
    ],
    'user2': [
        "vless://...",
        "trojan://..."
    ],
    'default': [
        "vless://default-config..."
    ]
}
#===============================================================

@app.route('/<username>')
def get_subscription(username):
    selected_links = links.get(username, links.get('default', []))
    if not selected_links:
        return Response("User not found and no default config is set.", status=404, mimetype='text/plain')
    
    subscription_text = "\n".join(selected_links)
    subscription_b64 = base64.b64encode(subscription_text.encode('utf-8')).decode('utf-8')
    return Response(subscription_b64, mimetype='text/plain')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
