import urequests
import network
import time

active_tags = []
active_phones = []

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


# Function to make a GET request to the server and retrieve data
def get_data_from_server(url):
    modified_url = f"{url}?Locks=true"
    print(modified_url)
    response = urequests.get(modified_url)
    if response.status_code == 200:
        data = response.json()  # Assuming response data is in JSON format
        #data = response.text
        return data
    else:
        print("Failed to retrieve data from the server")
        return None

# Function to send data to the server via a POST request
def send_data_to_server(url, data):
    headers = {'Content-Type': 'application/json'}
    response = urequests.post(url, json=data, headers=headers)
    if response.status_code == 200:
        print("Data sent successfully to the server")
        return True
    else:
        print("Failed to send data to the server")
        return False

# Example usage
server_url = "http://192.168.70.120/Capstone/db.php"
data_to_send = {"key": "value", "Hello": "World"}

# Getting data from the server
server_data = get_data_from_server(server_url)
if server_data:
    print("Data retrieved from the server:", server_data)
    
    for data in server_data['Locks']:
        active_tags.append(data[0])
        active_phones.append(data[1])
        print(f"Tag Address: {data[0]}, Phone Address: {data[1]}") 

# If data is set
if active_tags:
    data_to_send = ("0X9EF24FB8", "Open")

# Sending data to the server
if data_to_send:
    send_success = send_data_to_server(server_url, data_to_send)
    if send_success:
        print("Data sent successfully to the server")
    else:
        print("Failed to send data to the server")
