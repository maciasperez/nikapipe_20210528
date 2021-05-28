#from astropy.time import Time
from astropy.table import Table
import numpy as np
import matplotlib.pyplot as plt  
#from astropy.io import ascii
import datetime
import matplotlib.dates as mdates
import re

tabflux = Table.read('uranus.txt', comment='#', format='ascii')
day = tabflux['Date'].data
flux1 = tabflux['Fnu_260GHz'].data
flux2 = tabflux['Fnu_150GHz'].data

ymd = re.compile('(\d\d\d\d)(\d\d)(\d\d)')

dates = []
for date in day:
    m = ymd.match(str(date))
    if m:
        d = datetime.datetime(int(m.group(1)), int(m.group(2)), int(m.group(3)))
        print(d)
        dates.append(d)
    else:
        raise ValueError('Cannot parse date {}'.format(date))

fig, ax = plt.subplots(constrained_layout=True, figsize=(12, 8))
locator = mdates.AutoDateLocator()
formatter = mdates.ConciseDateFormatter(locator)
ax.xaxis.set_major_locator(locator)
ax.xaxis.set_major_formatter(formatter)
plt.ylabel("Flux in NIKA2 bandpasses [Jy]")
ax.scatter(dates, flux1)
ax.scatter(dates, flux2)
ax.set_title('Uranus predicted flux')


plt.show()
