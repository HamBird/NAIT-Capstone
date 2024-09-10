import bluetooth
import random
import struct
import time
import urequests
import network
import ubinascii
import ujson
import os
from ble_advertising import advertising_payload
from mfrc522 import MFRC522
import utime
from machine import Pin, Timer
from umqtt.simple import MQTTClient
from micropython import const

LED2 = Pin("GP16", Pin.OUT)
LED2.value(0)
time.sleep(9)

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
    handle = 0
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
        global pairing
        
        try:
            # print(f"Data: {data[0]}, active Phones: {active_phones}, Pairing: {pairing}, In active Phones?: {str(data[0]) in active_phones}")
            if str(data[0]) in active_phones and not pairing:
                if event == _IRQ_CENTRAL_CONNECT:
                    conn_handle, _, _ = data
                    handle = conn_handle
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
            elif pairing:
                send_tag(pairing_details[1], data[0], "Phone")
                utime.sleep_ms(5000)
                process_data()
                pairing = False
            else:
                print("Not Authorized")
        except:
            print("Error while connecting with Bluetooth")
            

    def send(self, data):
        for conn_handle in self._connections:
            self._ble.gatts_notify(conn_handle, self._handle_tx, data)

    def is_connected(self):
        return len(self._connections) > 0

    def _advertise(self, interval_us=500000):
        print("Starting advertising")
        # blue_mac = ubinascii.hexlify(self._ble.config('mac')[1],':').decode().upper()
        # print(f"Bluetooth MAC Address of Pico: {blue_mac}")
        # print(self._payload)
        self._ble.gap_advertise(interval_us, adv_data=self._payload)

    def on_write(self, callback):
        self._write_callback = callback
        
        
LED = Pin("LED", Pin.OUT)
# LED2 = Pin("GP16", Pin.OUT)
timer = Timer()
lan_timer = Timer()
# Define the file path
file_path = "tags.txt"
master_control = False
ble_control = False
client = None
pairing_details = []
pairing = False


def uidToString(uid):
    mystring = ""
    for i in uid:
        mystring = "%02X" % i + mystring
    return mystring
    

def sub_cb(topic, msg):
    global master_control, pairing, pairing_details, MOTOR
    print("New message on topic {}".format(topic.decode('utf-8')))
    msg = msg.decode('utf-8')
    
    msg_split = msg.split(" ")
    
    print(msg)
    if msg == "Turn Off":
        LED.value(0)
        MOTOR.value(1)
        master_control = False
        #MOTOR.value(0)
    elif msg == "Turn On":
        LED.value(1)
        MOTOR.value(0)
        master_control = True
        send_data_to_server(server_url, 0, 0, "Master Control")
        #MOTOR.value(1)
    elif msg == "Update":
        print("Updating data")
        process_data()
    elif msg_split[0] == "UpdateTag":
        print("Updating Tag")
        # the split 1 and 2 is tagid and lockid respectively
        pairing_details = []
        pairing_details.append("Tag")
        pairing_details.append(msg_split[1])
        pairing_details.append(msg_split[2])
        print(f"LockID Server: {pairing_details}, LockID Client: {lock_id}, True?: {pairing_details[2] == str(lock_id)}")
        if pairing_details[2] == str(lock_id):
            pairing = True
    elif msg_split[0] == "UpdatePhone":
        print("Updating Phone")
        # the split 1 and 2 is tagid and lockid respectively
        pairing_details = []
        pairing_details.append("Phone")
        pairing_details.append(msg_split[1])
        pairing_details.append(msg_split[2])
        if pairing_details[2] == str(lock_id):
            pairing = True


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
      
      
# Function to make a GET request to the server and retrieve data
def get_data_from_server(url):
    try:
        modified_url = f"{url}?Locks={lock_id}"
        print(modified_url)
        response = urequests.get(modified_url)
        if response.status_code == 200:
            data = response.json()  # Assuming response data is in JSON format
            #data = response.text
            return data
        else:
            print("Failed to retrieve data from the server")
            return None
    except Exception as err:
        print(f"Could not search URL {err}")


# Function to send data to the server via a POST request
def send_data_to_server(url, tag, phone, master):
    try:
        data = {'Activity': [lock_id, tag, phone, master]}
        headers = {'Content-Type': 'application/json'}
        response = urequests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print("Data sent successfully to the server")
            return True
        else:
            print("Failed to send data to the server")
            return False
    except Exception as err:
        print(f"Could not send data to server")
      
  
def send_tag(tagid, tagaddress, typetag):
    global server_url
    try:
        data = {'TagData': [tagid, tagaddress, typetag]}
        
        headers = {'Content-Type': 'application/json'}
        response = urequests.post(server_url, json=data, headers=headers)
        if response.status_code == 200:
            print("Data sent successfully to the server")
            return True
        else:
            print("Failed to send data to the server")
            return False
    except Exception as err:
        print(f"Could not send data to server! {err}")

  
def process_data():
    global file_path, active_tags, active_phones
    active_tags = []
    active_phones = []
    try:
        server_data = get_data_from_server(server_url)
        if server_data:
            print("Data retrieved from the server:", server_data)
            for data in server_data['Locks']:
                active_tags.append(data[0])
                active_phones.append(data[1])
                print(f"Tag Address: {data[0]}, Phone Address: {data[1]}")
                # print(active_tags)
                # print(active_phones)
            write_data()
    except Exception as err:
        print("Could not seperate the data")
        

def write_data():
    global active_tags, active_phones, file_path
    
    try:
        os.remove(file_path)
    except:
        print("File could not be deleted")
    # open(file_path, 'w').close()
    # Open the file in write mode
    file = open(file_path, "w+")
    
    for item in range(len(active_tags)):
        # Join the items in the list with commas
        line = f"{active_tags[item]}, {active_phones[item]}"
        # Write the line to the file
        file.write(line + "\n")
    file.close()
    #with open(file_path, "w+") as file:
    #    # Iterate over item in both lists
    #    for item in range(len(active_tags)):
    #        # Join the items in the list with commas
    #        line = f"{active_tags[item]}, {active_phones[item]}"
    #        # Write the line to the file
    #        file.write(line + "\n")
    #    file.close()
  

def read_data():
    global file_path, active_tags, active_phones
    active_tags = []
    active_phones = []
    with open(file_path, "r") as file:
        for line in file:
            data = line.strip('\n').split(", ")
            print(data)
            if len(data) > 1:
                active_tags.append(data[0])
                active_phones.append(data[1])
        file.close()      


def attempt_connection(timer):
    global wlan, lan_connect, host, ssid, topic_sub, mqtt_status
    print("Attempting to Re-connect")
    wlan.connect(host, ssid)
    if wlan.isconnected():
        print(f"Is Internet Connected? : {wlan.isconnected()}")
        process_data()
        lan_connect = False
        timer.deinit()
        if not mqtt_status:
            time.sleep(8)
            print("Entered")
            mqtt_connect()
            time.sleep(5)
            # if not client.connect():
                # client.subscribe(topic_sub)
            timer.init(freq=10, mode=Timer.PERIODIC, callback=CallMsg)
            mqtt_status = True
    

ble_status = False
lock_id = 1
active_tags = []
active_phones = []
data_to_send = []
reader = MFRC522(spi_id=0,sck=6,miso=4,mosi=7,cs=5,rst=22)

# read_data()

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
time.sleep(5)
# host = "CNT-IoT"
# ssid = ""

host = "SM-S908W1168"
ssid = "7rcj5e6vzj75"
# wlan.connect("CNT-IOT", ssid)
# wlan.connect(host, ssid)
print("Waiting for connection")
# while wlan.isconnected() == False:
time.sleep(8)
print(wlan.isconnected())
mqtt_status = wlan.isconnected()
mac = ubinascii.hexlify(network.WLAN().config('mac'),':').decode()
print(f"MAC Address of Pico: {mac}")

# Desired Server URL
server_url = "https://thor.cnt.sast.ca/~nrojas1/Capstone/db.php"

LED = Pin("LED", Pin.OUT)
MOTOR = Pin("GP26", Pin.OUT)

# '192.168.1.119' LAN doesn't work however online broker works fine
# 'test.mosquitto.org'
mqtt_server = 'test.mosquitto.org'
client_id = 'hambord'
topic_sub = b'Pi/Message'
lan_connect = False

PreviousCard = [0]
reader.init()
MOTOR.value(1)
print("")
print("Please place card on reader")
print("")

if wlan.isconnected():
    mqtt_connect()
    process_data()

    if not client.connect():
        client.subscribe(topic_sub)
    
try:
    if wlan.isconnected():
        timer.init(freq=10, mode=Timer.PERIODIC, callback=CallMsg)
    # process_data()
    # write_data()
    read_data()
    ble = bluetooth.BLE()
    p = BLESimplePeripheral(ble)
    LED2.value(1)
    while True:
        # reader.init()
        
        (stat, tag_type) = reader.request(reader.REQIDL)
        #print('request stat:',stat,' tag_type:',tag_type)
        # print(f"Wlan Status {wlan.isconnected()}, lan connect Status {lan_connect}, wlan if {wlan.isconnected() == False}")
        # print(f"Looping BLE Status: {ble_control} Reader Status: {stat == reader.OK}")
        if stat == reader.OK and not ble_control:
            (stat, uid) = reader.SelectTagSN()
            if stat == reader.OK:
                print("Card detected {}  uid={}".format(hex(int.from_bytes(bytes(uid),"little",False)).upper(),reader.tohexstring(uid)))
                
                cardID = hex(int.from_bytes(bytes(uid),"little",False)).upper()
                print(cardID)
   
                ## if cardID == "0X9EF24FB8":
                print(f"Inside the RFID Loop: pairing is: {pairing}")
                if pairing:
                    send_tag(pairing_details[1], cardID, "Tag")
                    utime.sleep_ms(5000)
                    process_data()
                    pairing = False
                elif cardID not in active_tags and not pairing:
                    print("Not Authenticated")
                else:
                    # MTR.value(1)
                    MOTOR.value(0)
                    LED.value(1)
                    if wlan.isconnected():
                        send_data_to_server(server_url, cardID, 0, 0)
                utime.sleep_ms(5000)
        elif p.is_connected():
            LED.on()
            MOTOR.value(0)
            ble_control = True
            if not ble_status:
                for item in p._connections:
                    if wlan.isconnected():
                        send_data_to_server(server_url, 0, item, 0)
                ble_status = True
        elif (stat != reader.OK or not p.is_connected()) and not master_control:
            # MTR.value(0)
            LED.value(0)
            MOTOR.value(1)
            PreviousCard=[0]
            ble_control = False
            ble_status = False
        if not wlan.isconnected() and not lan_connect:
            # client.disconnect()
            lan_connect = True
            mqtt_status = False
            print("Entered, Internet not Connected")
            lan_timer.init(period=20000, mode=Timer.PERIODIC, callback=attempt_connection)
            
except KeyboardInterrupt:
    pass


# For Adding New Phone Send MQTT message encrypted like "Phone Pairing", "Name of User" or ID of User who wants to have phone paired to account
# For Adding New Tag, See if Phone NFC can decrypt RFID cards into same format the MFRC522 module reads into

