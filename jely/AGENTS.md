# AGENTS.md — jely/

Django 2.1 backend. The project name is `jely`; the app module is also `jely/jely/`.

## Structure

```
jely/
  manage.py
  db.sqlite3           (dev only — gitignored in production)
  requirements.txt     (pinned versions — see golden rules)
  jely/
    settings.py.txt    (committed template — actual settings.py is gitignored)
    urls.py
    wsgi.py
  customer/            (customer app)
  static/              (Django static files root — Angular dist lands here in Docker)
  templates/
```

## Settings

`settings.py` is **gitignored**. The committed file is `jely/settings.py.txt`.

The Dockerfile bootstraps `settings.py` from this template at build time:
```sh
cp jely/settings.py.txt jely/settings.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ['*']/" jely/settings.py
```

For local development, copy it manually: `cp jely/settings.py.txt jely/settings.py`
and set `ALLOWED_HOSTS` and `SECRET_KEY` appropriately.

Key settings to know:
- `STATICFILES_DIRS = [BASE_DIR/static]` — Angular dist is copied to `static/dist/` during Docker build
- `STATIC_URL = '/static/'`
- `WSGI_APPLICATION = 'jely.wsgi.application'`
- Database defaults to SQLite for development; configure via env/settings for production

## Requirements

Versions are pinned. Do not upgrade without testing against Python 3.7:
- `Django==2.1.3`
- `djangorestframework==3.9.0`
- `django-cors-headers==2.4.0`
- `pytz==2018.7`
- `gunicorn` (unpinned — added at Docker build time)

## Golden rules

1. **Do not commit `settings.py`** — it contains `SECRET_KEY`. Only `settings.py.txt` is tracked.
2. **`/api/v1/health`** must remain a working endpoint — it is the Kubernetes readiness probe.
3. Pin new dependencies to exact versions in `requirements.txt`.
