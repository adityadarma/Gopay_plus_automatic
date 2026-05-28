FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    WA_GRPC_PORT=50056

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
COPY plus_gopay_links/requirements.txt ./plus_gopay_links/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir -r plus_gopay_links/requirements.txt

COPY to_whatsapp/package*.json ./to_whatsapp/
RUN cd to_whatsapp && npm ci --omit=dev

COPY . .
RUN chmod +x /app/docker/start.sh

EXPOSE 8800 50051 50056

CMD ["/app/docker/start.sh"]
