import json
import os
import logging
from kafka import KafkaConsumer
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_bootstrap_brokers(cluster_arn):
    client = boto3.client('kafka')
    response = client.get_bootstrap_brokers(
        ClusterArn=cluster_arn
    )
    return response['BootstrapBrokerStringSaslIam']

def lambda_handler(event, context):
    cluster_arn = os.getenv('MSK_CLUSTER_ARN')
    topic_name = os.getenv('TOPIC_NAME')
    
    try:
        bootstrap_servers = get_bootstrap_brokers(cluster_arn)
        
        consumer = KafkaConsumer(
            topic_name,
            bootstrap_servers=bootstrap_servers.split(','),
            security_protocol='SASL_SSL',
            sasl_mechanism='AWS_MSK_IAM',
            sasl_jaas_config='software.amazon.msk.auth.iam.IAMLoginModule required;',
            ssl_check_hostname=True,
            group_id='lambda-consumer-group',
            auto_offset_reset='earliest',
            enable_auto_commit=True
        )
        
        for message in consumer:
            logger.info(f"Received message: {message.value.decode('utf-8')}")
            # Process your message here
            
    except Exception as e:
        logger.error(f"Error processing messages: {str(e)}")
        raise
    
    return {
        'statusCode': 200,
        'body': json.dumps('Messages processed successfully')
    }