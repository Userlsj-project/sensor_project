import paho.mqtt.client as mqtt
import random
import time

BROKER = "localhost"
PORT = 1883
TOPIC = "temp1"

client = mqtt.Client()
client.connect(BROKER, PORT)

print(f"MQTT 브로커 연결 완료. 5초마다 topic '{TOPIC}'에 난수를 발행합니다. (종료: Ctrl+C)")

try:
    while True:
        value = random.randint(0, 100)
        client.publish(TOPIC, value)
        print(f"발행됨: topic={TOPIC}, value={value}")
        time.sleep(5)
except KeyboardInterrupt:
    print("종료")
    client.disconnect()
