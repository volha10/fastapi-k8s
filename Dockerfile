FROM python:3.12-alpine

WORKDIR /code

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

COPY . .

CMD ["fastapi", "run", "main.py", "--port", "80"]
