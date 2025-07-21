import base64
from flask import Flask, Response

app = Flask(__name__)

#===================================================================
# *** ساختار جدید و هوشمندتر برای ذخیره کاربران ***
# شما خروجی اسکریپت پاورشل را در اینجا کپی خواهید کرد
#===================================================================
links = {
    # مثال از ساختار جدید:
    # 'uuid-1': {
    #     'DisplayName': 'ali',
    #     'Configs': [
    #         "vless://...",
    #         "hysteria2://..."
    #     ]
    # },
    # 'uuid-2': {
    #     'DisplayName': 'sara',
    #     'Configs': [
    #         "vless://..."
    #     ]
    # }
}
#===================================================================

@app.route('/<username>')
def get_subscription(username):
    """
    این تابع با دریافت شناسه کاربر (UUID) از URL،
    لیست کانفیگ‌های او را پیدا کرده و به صورت Base64 برمی‌گرداند.
    """
    # جستجو در بین کاربران برای پیدا کردن UUID مورد نظر
    user_data = links.get(username)

    if not user_data or 'Configs' not in user_data:
        # اگر کاربر پیدا نشد یا لیست کانفیگ نداشت، پاسخ خالی برمی‌گرداند
        return Response("", status=404, mimetype='text/plain')

    # استخراج لیست کانفیگ‌ها از ساختار جدید
    selected_links = user_data['Configs']

    # تبدیل لیست کانفیگ‌ها به یک رشته که با خط جدید از هم جدا شده‌اند
    subscription_text = "\n".join(selected_links)

    # انکد کردن رشته به فرمت Base64
    subscription_b64 = base64.b64encode(subscription_text.encode('utf-8')).decode('utf-8')

    # برگرداندن پاسخ نهایی با هدر مناسب
    return Response(subscription_b64, mimetype='text/plain')

if __name__ == "__main__":
    # این بخش فقط برای تست مستقیم است و در حالت سرویس استفاده نمی‌شود
    app.run(host='0.0.0.0', port=8080)
