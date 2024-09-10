import bluetooth
import random
import struct
import time
import network
import ubinascii
from ble_advertising import advertising_payload
from mfrc522 import MFRC522
import utime
from machine import Pin, Timer
from umqtt.simple import MQTTClient
from micropython import const

_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)

_FLAG_READ = const(0x0002)
_FLAG_WRITE_NO_RESPONSE = const(0x0004)
_FLAG_WRITE = const(0x0008)
_FLAG_NOTIFY = const(0x0010)

_UART_UUID = bluetooth.UUID("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
_UART_TX = (
    bluetooth.UUID("6E400003-B5A3-F393-E0A9-E50E24DCCA9E"),
    _FLAG_READ | _FLAG_NOTIFY,
)
_UART_RX = (
    bluetooth.UUID("6E400002-B5A3-F393-E0A9-E50E24DCCA9E"),
    _FLAG_WRITE | _FLAG_WRITE_NO_RESPONSE,
)
_UART_SERVICE = (
    _UART_UUID,
    (_UART_TX, _UART_RX),
)

class BLESimplePeripheral:
    def __init__(self, ble, name="PleaseHelp"):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)
        ((self._handle_tx, self._handle_rx),) = self._ble.gatts_register_services((_UART_SERVICE,))
        self._connections = set()
        self._write_callback = None
        self._payload = advertising_payload(name=name, services=[_UART_UUID])
        self._advertise()

    def _irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            conn_handle, _, _ = data
            print("New connection", conn_handle)
            self._connections.add(conn_handle)
        elif event == _IRQ_CENTRAL_DISCONNECT:
            conn_handle, _, _ = data
            print("Disconnected", conn_handle)
            self._connections.remove(conn_handle)
            self._advertise()
        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            value = self._ble.gatts_read(value_handle)
            if value_handle == self._handle_rx and self._write_callback:
                self._write_callback(value)

    def send(self, data):
        for conn_handle in self._connections:
            self._ble.gatts_notify(conn_handle, self._handle_tx, data)

    def is_connected(self):
        return len(self._connections) > 0

    def _advertise(self, interval_us=500000):
        print("Starting advertising")
        blue_mac = ubinascii.hexlify(self._ble.config('mac')[1],':').decode().upper()
        print(f"Bluetooth MAC Address of Pico: {blue_mac}")
        # print(self._payload)
        self._ble.gap_advertise(interval_us, adv_data=self._payload)

    def on_write(self, callback):
        self._write_callback = callback
        
        
LED = Pin("LED", Pin.OUT)
LED2 = Pin("GP16", Pin.OUT)
timer = Timer()
master_control = False
ble_control = False
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
    client = MQTTClient(client_id, mqtt_server, keepalive=7600)
    client.set_callback(sub_cb)
    # client.connect()
    # print('Connected to %s MQTT Broker'%(mqtt_server))
    
    client.connect()
    client.subscribe(topic_sub)
       
       
def CallMsg(timer):
    try:
        global client
        garbage = client.check_msg()
    except Exception as err:
        print(f"An error as occured {err}")
        client.connect()
      
      
reader = MFRC522(spi_id=0,sck=6,miso=4,mosi=7,cs=5,rst=22)

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
time.sleep(5)
# wlan.connect("GWN6B91D8","726KExNv")
# wlan.connect("SM-S908W1168", "7rcj5e6vzj75")
wlan.connect("CNT-IoT", "")
print("Waiting for connection")
while wlan.isconnected() == False:
    time.sleep(5)
print(wlan.isconnected())
mac = ubinascii.hexlify(network.WLAN().config('mac'),':').decode()
print(f"MAC Address of Pico: {mac}")

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
    
    ble = bluetooth.BLE()
    p = BLESimplePeripheral(ble)
    while True:
        # reader.init()
        
        (stat, tag_type) = reader.request(reader.REQIDL)
        #print('request stat:',stat,' tag_type:',tag_type)
        if stat == reader.OK and not ble_control:
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
        elif p.is_connected():
            LED.on()
            ble_control = True
        elif (stat != reader.OK or not p.is_connected()) and not master_control:
            # MTR.value(0)
            LED.value(0)
            PreviousCard=[0]
            ble_control = False
except KeyboardInterrupt:
    pass
