import base64
from flask import Flask, Response

app = Flask(__name__)

#===================================================================
# *** شما خروجی نهایی اسکریپت پاورشل را در اینجا کپی خواهید کرد ***
#===================================================================
links = {
    # این یک مثال است و باید با خروجی شما جایگزین شود
    # 'a1b2c3d4-e5f6-7890-1234-567890abcdef': {
    #     'DisplayName': 'example-user',
    #     'Configs': [
    #         "vless://example-link..."
    #     ]
    # }
}
#===================================================================

@app.route('/<username>')
def get_subscription(username):
    """
    این تابع همیشه لیست کانفیگ‌ها را به صورت رمزنگاری شده (Base64) برمی‌گرداند.
    """
    user_data = links.get(username)

    if not user_data or 'Configs' not in user_data:
        return Response("", status=404, mimetype='text/plain')

    selected_links = user_data['Configs']
    subscription_text = "\n".join(selected_links)

    # تبدیل متن به Base64 و برگرداندن آن
    subscription_b64 = base64.b64encode(subscription_text.encode('utf-8')).decode('utf-8')
    return Response(subscription_b64, mimetype='text/plain')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
