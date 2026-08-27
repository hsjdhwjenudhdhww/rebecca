Rebecca Panel — Railway Deployment

نصب و راه‌اندازی روی Railway

برای دیپلوی این پروژه روی Railway مراحل زیر را انجام دهید.

1. ساخت ایمیل

ابتدا وارد سایت Atomic Mail شوید و یک ایمیل دریافت کنید.

سپس با همان ایمیل، یک اکانت در GitHub بسازید.

2. Fork کردن پروژه

پس از ورود به GitHub، وارد صفحه این پروژه شوید و روی گزینه Fork بزنید تا پروژه در اکانت GitHub شما کپی شود.

3. ورود به Railway

وارد Railway شوید و با اکانت GitHub خود Login کنید.

سپس:

1. یک Project جدید ایجاد کنید.
2. گزینه Deploy from GitHub Repo را انتخاب کنید.
3. Repository مربوط به Fork خودتان را انتخاب کنید.
4. اجازه دسترسی Railway به Repository را تأیید کنید.
5. پروژه را Deploy کنید.

4. صبر برای کامل شدن Deployment

منتظر بمانید تا Build و Deployment پروژه کاملاً تمام شود و وضعیت Deployment به حالت موفق برسد.

5. ساخت Domain

پس از کامل شدن Deployment:

1. وارد سرویس پروژه شوید.
2. به بخش Networking / Public Networking بروید.
3. گزینه Generate Domain را بزنید.
4. پورت سرویس را روی 8080 قرار دهید.

دامنه‌ای مشابه زیر برای شما ساخته می‌شود:

```text
https://your-project.up.railway.app
```

6. Redeploy

پس از Generate Domain، در بخش Deployments روی سه‌نقطه عمودی (⋮) مربوط به آخرین Deployment کلیک کنید.

سپس گزینه Redeploy را انتخاب کنید.

منتظر بمانید تا Redeploy کاملاً انجام شود.

7. ورود به پنل

پس از موفقیت‌آمیز بودن Redeploy، دامنه Railway خود را باز کنید و در انتهای آن /dashboard اضافه کنید:

```text
https://your-project.up.railway.app/dashboard
```

به این ترتیب وارد Dashboard پنل Rebecca می‌شوید.

پورت

این پروژه برای Railway روی پورت زیر تنظیم شده است:

```text
8080
```

نکات مهم

• حتماً Repository را از اکانت GitHub خودتان Fork کنید.
• Railway باید به Repository شما دسترسی داشته باشد.
• قبل از Generate Domain صبر کنید Deployment کاملاً موفق شود.
• بعد از Generate Domain یک بار Redeploy انجام دهید.
• برای ورود به رابط Dashboard از /dashboard استفاده کنید.

کانال‌های ما

سازنده

https://t.me/amirsp1ider

کانال اصلی

https://t.me/SPiDER_VPN1

────────

Rebecca Panel — Railway Deployment