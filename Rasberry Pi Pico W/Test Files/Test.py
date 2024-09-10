import machine
from machine import Pin, Timer
import network
import ubinascii


wlan = network.WLAN(network.STA_IF)
wlan.active(True)

mac = ubinascii.hexlify(network.WLAN().config('mac'),':').decode()
print(mac)

led = Pin("LED", Pin.OUT)
solenoid = Pin("GP16", Pin.OUT)

timer = Timer()

#  led_gpio = Pin("GP15", Pin.OUT)

# solenoid.value(1)
# led.value(1)
def blinkLED(timer):
    led.toggle()
    solenoid.toggle()
    """
    if led.value() == 1:
        led.value(0)
        led_gpio.value(1)
    else:
        led.value(1)
        led_gpio.value(0)
    """
    
    

timer.init(freq=10, mode=Timer.PERIODIC, callback=blinkLED)


"""
from machine import Pin, Timer

led = Pin("LED", Pin.OUT)
tim = Timer()
def tick(timer):
    global led
    led.toggle()

tim.init(freq=2.5, mode=Timer.PERIODIC, callback=tick)
"""