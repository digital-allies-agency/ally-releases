# Ally-Chat-Bot (Matrix-Listener): wie Stefans Live-Server /root/matrix/listener-bot-docker (Stand 01.11.2026).
# matrix-nio wie live fest; übrige Pakete hier fest auf die Fassungen vom 01.11.2026 (live ohne feste Version gebaut, dort nicht geprüft).
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libolm-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN pip install --no-cache-dir "matrix-nio[e2e]==0.25.2" "aiohttp==3.14.5" "signedjson==1.1.4" "requests==2.34.2" "markdown==3.11.1" "pillow==12.3.0" "pillow-heif==1.8.1"

COPY listener.py bootstrap_cross_signing.py ./

CMD ["python", "listener.py"]
