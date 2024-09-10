from mfrc522 import MFRC522
import utime
from machine import Pin, Timer
import network
import time
from umqtt.simple import MQTTClient


LED = Pin("LED", Pin.OUT)
LED2 = Pin("GP16", Pin.OUT)
timer = Timer()
master_control = False
client = None


def uidToString(uid):
    mystring = ""
    for i in uid:
        mystring = "%02X" % i + mystring
    return mystring
    

def sub_cb(topic, msg):
    global master_control
    print("New message on topic {}".format(topic.decode('utf-8')))
    msg = msg.decode('utf-8')
    print(msg)
    if msg == "Turn Off":
        LED.value(0)
        master_control = False
        #MOTOR.value(0)
    elif msg == "Turn On":
        LED.value(1)
        master_control = True
        #MOTOR.value(1)


def mqtt_connect():
    global client
    client = MQTTClient(client_id, mqtt_server, keepalive=60)
    client.set_callback(sub_cb)
    # client.connect()
    # print('Connected to %s MQTT Broker'%(mqtt_server))
    
    client.connect()
    client.subscribe(topic_sub)
       
       
def CallMsg(timer):
    try:
        global client
        garbage = client.check_msg()
    except:
        print("An error as occured")
      
      
reader = MFRC522(spi_id=0,sck=6,miso=4,mosi=7,cs=5,rst=22)

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
# wlan.connect("GWN6B91D8","726KExNv")
wlan.connect("CNT-IoT", "")
while wlan.isconnected() == False:
    print("Waiting for connection")
    time.sleep(5)
print(wlan.isconnected())

LED = Pin("LED", Pin.OUT)
#MOTOR = Pin("GP22", Pin.OUT)

# '192.168.1.119' LAN doesn't work however online broker works fine
# 'test.mosquitto.org'
mqtt_server = 'test.mosquitto.org'
client_id = 'hambord'
topic_sub = b'Pi/Message'

PreviousCard = [0]
reader.init()

print("")
print("Please place card on reader")
print("")

mqtt_connect()

if not client.connect():
    client.subscribe(topic_sub)
    
try:
    timer.init(freq=10, mode=Timer.PERIODIC, callback=CallMsg)
    while True:
        # reader.init()
        
        (stat, tag_type) = reader.request(reader.REQIDL)
        #print('request stat:',stat,' tag_type:',tag_type)
        if stat == reader.OK:
            (stat, uid) = reader.SelectTagSN()
            if stat == reader.OK:
                print("Card detected {}  uid={}".format(hex(int.from_bytes(bytes(uid),"little",False)).upper(),reader.tohexstring(uid)))
                
                cardID = hex(int.from_bytes(bytes(uid),"little",False)).upper()
                print(cardID)
   
                if cardID == "0X9EF24FB8":
                    print("Not Authenticated")
                else:
                    # MTR.value(1)
                    LED.value(1)
                utime.sleep_ms(5000)
        elif stat != reader.OK and not master_control:
            # MTR.value(0)
            LED.value(0)
            PreviousCard=[0]               
except KeyboardInterrupt:
    pass

