import network
import time
from machine import Pin
from umqtt.simple import MQTTClient

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
# wlan.connect("GWN6B91D8","726KExNv")
wlan.connect("CNT-IoT", "")
while wlan.isconnected() == False:
    print("Waiting for connection")
    time.sleep(5)
print(wlan.isconnected())

LED = Pin("LED", Pin.OUT)
MOTOR = Pin("GP22", Pin.OUT)

# '192.168.1.119' LAN doesn't work however online broker works fine
# 'test.mosquitto.org'
mqtt_server = 'test.mosquitto.org'
client_id = 'hambord'
topic_sub = b'Pi/Message'


def sub_cb(topic, msg):
    print("New message on topic {}".format(topic.decode('utf-8')))
    msg = msg.decode('utf-8')
    print(msg)
    if msg == "Turn Off":
        LED.value(0)
        MOTOR.value(0)
    elif msg == "Turn On":
        LED.value(1)
        MOTOR.value(1)


def mqtt_connect():
    client = MQTTClient(client_id, mqtt_server, keepalive=60)
    client.set_callback(sub_cb)
    # client.connect()
    # print('Connected to %s MQTT Broker'%(mqtt_server))
    
    if not client.connect():
        client.subscribe(topic_sub)
    while True:
        client.check_msg()
        time.sleep(1)

    
mqtt_connect()
