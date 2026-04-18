# Stage 1: build Angular frontend
FROM node:10-alpine AS frontend
WORKDIR /build
COPY website/package*.json ./
RUN npm ci --quiet
COPY website/ ./
ARG NODE_ENV=production
RUN npm run build

# Stage 2: Django + gunicorn runtime
FROM python:3.7-slim
WORKDIR /app
COPY jely/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn
COPY jely/ ./
# settings.py is gitignored; bootstrap from the committed template
RUN cp jely/settings.py.txt jely/settings.py && \
    sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ['*']/" jely/settings.py
COPY --from=frontend /build/dist/ ./static/dist/
ENV PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=jely.settings
EXPOSE 3005
CMD ["gunicorn", "jely.wsgi:application", "--bind", "0.0.0.0:3005", "--workers", "3"]
