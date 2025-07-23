import base64
# --- اصلاحیه اصلی اینجاست: کلمه request اضافه شده است ---
from flask import Flask, Response, request

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
    این تابع با دریافت شناسه کاربر (UUID) از URL،
    لیست کانفیگ‌های او را پیدا کرده و بر اساس نوع درخواست‌کننده،
    خروجی مناسب را برمی‌گرداند.
    """
    user_data = links.get(username)

    if not user_data or 'Configs' not in user_data:
        return Response("", status=404, mimetype='text/plain')

    selected_links = user_data['Configs']
    subscription_text = "\n".join(selected_links)

    # تشخیص مرورگر از اپلیکیشن
    user_agent = request.headers.get('User-Agent', '').lower()
    is_browser = 'mozilla' in user_agent or 'chrome' in user_agent or 'firefox' in user_agent or 'safari' in user_agent

    if is_browser:
        # اگر درخواست از مرورگر بود، متن ساده را برمی‌گردانیم
        return Response(subscription_text, mimetype='text/plain; charset=utf-8')
    else:
        # در غیر این صورت، برای اپلیکیشن‌ها، متن را به Base64 تبدیل می‌کنیم
        subscription_b64 = base64.b64encode(subscription_text.encode('utf-8')).decode('utf-8')
        return Response(subscription_b64, mimetype='text/plain')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
