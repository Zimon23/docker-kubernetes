FROM python:3.9-slim-buster

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# CMD는 docker-compose.yml에서 command로 오버라이드됩니다.
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
