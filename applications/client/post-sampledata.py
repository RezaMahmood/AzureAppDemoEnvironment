#!/usr/bin/env python3

import http.client
import json
import datetime
from random import randrange
import time

while True:

    connection = http.client.HTTPSConnection(
        'dataingestapp.azurewebsites.net')

    headers = {'Content-type': 'application/json'}

    currenttime = datetime.datetime.now().isoformat()
    currenttemp = randrange(15, 40)
    sampledata = {'Date': currenttime,
                  'TemperatureC': currenttemp, 'Location': 'Singapore'}

    sampledata_json = json.dumps(sampledata)

    connection.request('POST', '/weatherforecast', sampledata_json, headers)

    response = connection.getresponse()
    print(sampledata)
    print(response.status, response.reason)

    # Run every 1 minute
    time.sleep(60)
