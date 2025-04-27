from fastapi import FastAPI, Request
from datetime import datetime
import json
import logging
from kafka import KafkaProducer
import os
import socket

app = FastAPI()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": %(message)s}'
)
logger = logging.getLogger(__name__)

# Kafka producer setup
producer = None
if os.getenv("KAFKA_BOOTSTRAP_SERVERS"):
    producer = KafkaProducer(
        bootstrap_servers=os.getenv("KAFKA_BOOTSTRAP_SERVERS").split(","),
        value_serializer=lambda v: json.dumps(v).encode('utf-8')
    )

@app.middleware("http")
async def log_requests(request: Request, call_next):
    response = await call_next(request)
    
    log_data = {
        "request": {
            "method": request.method,
            "url": str(request.url),
            "headers": dict(request.headers),
            "client": request.client.host if request.client else None
        },
        "response": {
            "status_code": response.status_code,
            "headers": dict(response.headers)
        }
    }
    
    logger.info(json.dumps(log_data))
    
    return response

@app.get("/hello")
async def hello():
    return {"message": "Hello World!"}

@app.get("/current_time")
async def current_time(name: str = "World"):
    timestamp = int(datetime.now().timestamp())
    message = f"Hello {name}"
    response_data = {
        "timestamp": timestamp,
        "message": message
    }
    
    # Publish to Kafka if configured
    if producer and os.getenv("KAFKA_EVENTS_TOPIC"):
        producer.send(os.getenv("KAFKA_EVENTS_TOPIC"), value=response_data)
    
    return response_data

@app.get("/healthcheck")
async def healthcheck():
    return {"status": "healthy", "host": socket.gethostname()}