import boto3
from fastapi import FastAPI, Request
from datetime import datetime
import json
import logging
from kafka import KafkaProducer
import os
import socket
import time

app = FastAPI()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='{"time": "%(asctime)s", "level": "%(levelname)s", "message": %(message)s}'
)
logger = logging.getLogger(__name__)

def get_bootstrap_brokers(cluster_name):
    """Fetch MSK bootstrap brokers with retry logic"""
    client = boto3.client('kafka')
    max_retries = 3
    retry_delay = 5
    
    for attempt in range(max_retries):
        try:
            response = client.get_bootstrap_brokers(
                ClusterArn=cluster_name
            )
            return response['BootstrapBrokerStringSaslIam']
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            logger.warning(f"Failed to get brokers (attempt {attempt + 1}): {str(e)}")
            time.sleep(retry_delay)

# Kafka producer setup with IAM authentication
producer = None
kafka_topic = os.getenv("KAFKA_EVENTS_TOPIC")
msk_cluster_name = os.getenv("MSK_CLUSTER_NAME")

if msk_cluster_name:
    try:
        bootstrap_servers = get_bootstrap_brokers(msk_cluster_name)
        
        producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers.split(','),
            security_protocol='SASL_SSL',
            sasl_mechanism='AWS_MSK_IAM',
            sasl_jaas_config='software.amazon.msk.auth.iam.IAMLoginModule required;',
            ssl_check_hostname=True,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            retry_backoff_ms=1000,
            request_timeout_ms=30000
        )
        logger.info("Successfully connected to MSK cluster")
    except Exception as e:
        logger.error(f"Failed to initialize Kafka producer: {str(e)}")
        producer = None

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
    if producer and kafka_topic:
        try:
            future = producer.send(kafka_topic, value=response_data)
            # Wait for message to be delivered
            future.get(timeout=10)
            logger.info(f"Published message to {kafka_topic}")
        except Exception as e:
            logger.error(f"Failed to publish to Kafka: {str(e)}")
    
    return response_data

@app.get("/healthcheck")
async def healthcheck():
    kafka_status = "connected" if producer else "disconnected"
    return {
        "status": "healthy", 
        "host": socket.gethostname(),
        "kafka": kafka_status
    }