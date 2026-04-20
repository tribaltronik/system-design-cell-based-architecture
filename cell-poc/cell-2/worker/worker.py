import pika
import time
import os
import sys

CELL_ID = os.getenv("CELL_ID", "unknown")
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "cell-2-rabbitmq")

print(f"[{CELL_ID}] Starting worker...")
print(f"[{CELL_ID}] Connecting to RabbitMQ at {RABBITMQ_HOST}")

connection = pika.BlockingConnection(pika.ConnectionParameters(host=RABBITMQ_HOST))
channel = connection.channel()
channel.queue_declare(queue="tasks", durable=True)


def callback(ch, method, properties, body):
    task_id = body.decode()
    print(f"[{CELL_ID}] Processing: {task_id}")
    sys.stdout.flush()
    time.sleep(2)
    print(f"[{CELL_ID}] Done: {task_id}")
    sys.stdout.flush()
    ch.basic_ack(delivery_tag=method.delivery_tag)


channel.basic_qos(prefetch_count=1)
channel.basic_consume(queue="tasks", on_message_callback=callback)

print(f"[{CELL_ID}] Worker started, waiting for tasks...")
sys.stdout.flush()
channel.start_consuming()
