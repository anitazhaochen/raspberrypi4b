import os
import prometheus_client
import time
from prometheus_client import CollectorRegistry,Gauge,generate_latest

# temputrue=os.popen('vcgencmd measure_temp').read().split("=")[1].split("'")[0]
prometheus_client.start_http_server(int(8210))
temputrue_prom = Gauge("Temputrue", "rpi-temp", ["temputrue"])

while True:
    temputrue=os.popen('vcgencmd measure_temp').read().split("=")[1].split("'")[0]
    temputrue_prom.labels("temputrue").set(temputrue)
    time.sleep(int(5))
