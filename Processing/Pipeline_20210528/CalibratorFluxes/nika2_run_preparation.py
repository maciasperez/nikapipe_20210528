import photometry as pt
from astropy.time import Time, TimeDelta
from astropy import units as u
from astropy.table import Table
import numpy as np
import os
import re

# get the planet objects
uranus = pt.GiantPlanet('Uranus', model_version='esa4')
neptune = pt.GiantPlanet('Neptune', model_version='esa5')
mars = pt.Mars()
# and the NIKA2 passbands
nika2mm = pt.Passband(file='2mm.NIKA2.pb')
nika1mmH = pt.Passband(file='1mmH.NIKA2.pb')
nika1mmV = pt.Passband(file='1mmV.NIKA2.pb')

# Table with the run informations
workdir = './'
runinfo = os.path.join(workdir, 'runinfo.txt')

# Time step for the computations, we use 1 day.
deltat = TimeDelta(1, format='jd')

tabrun = Table.read(runinfo, comment='#', format='ascii')

#tabrun

tabrun['StartDate'] = Time(tabrun['StartDate'])
tabrun['EndDate'] = Time(tabrun['EndDate'])
tabrun['Duration'] = tabrun['EndDate'] - tabrun['StartDate']

alldates = []
for row in tabrun:
    dates = row['StartDate'] + deltat * np.arange(0, 
                                                  row['Duration'].value + 1,
                                                  1)
    alldates = np.append(alldates, dates.value)
alldates = Time(alldates, format='iso')

# print(alldates)
# compute the Neptune and Uranus Fluxes at the reference frequencies of each band
neptune.set_dates(alldates)
uranus.set_dates(alldates)
spec_uranus = uranus.spectral_irradiance()
spec_neptune = neptune.spectral_irradiance()

fluxes_1mm_uranus= spec_uranus.fnu_nu(nika1mmH.xref(u.GHz)).to(u.Jy)
fluxes_1mm_neptune = spec_neptune.fnu_nu(nika1mmH.xref(u.GHz)).to(u.Jy)
fluxes_2mm_uranus = spec_uranus.fnu_nu(nika2mm.xref(u.GHz)).to(u.Jy)
fluxes_2mm_neptune = spec_neptune.fnu_nu(nika2mm.xref(u.GHz)).to(u.Jy)

# compute Mars fluxes at the reference frequencies for each run
mars.set_beam('Iram30m')
mars.set_instrument('NIKA2')

#Fnu150GHzMars = np.zeros(len(alldates))
#Fnu260GHzMars = np.zeros(len(alldates))
#for i, date in enumerate(alldates):
#    Fnu150GHzMars[i] = mars.fnu(150 * u.GHz, date).value
#    Fnu260GHzMars[i] = mars.fnu(260 * u.GHz, date).value

ymd = re.compile('(\d\d\d\d)-(\d\d)-(\d\d)')

alldays = []
for date in alldates.value:
    m = ymd.match(date)
    if m:
        alldays.append('{}{}{}'.format(m.group(1), m.group(2), 
                                       m.group(3)))
    else:
        raise ValueError('Cannot parse date {}'.format(date))

# write the output for uranus
out_uranus = os.path.join(workdir, 'uranus.txt')
with open(out_uranus, 'w') as fout:
    fout.write("# Date Fnu_150GHz   Fnu_260GHz\n")
    for i, day in enumerate(alldays):
        fout.write("{} {:5.3f} {:5.3f}\n".format(day, 
                                                 fluxes_2mm_uranus[i].value, 
                                                 fluxes_1mm_uranus[i].value))
fout.close()

# write the output for neptune
out_neptune = os.path.join(workdir, 'neptune.txt')
with open(out_neptune, 'w') as fout:
    fout.write("# Date Fnu_150GHz   Fnu_260GHz\n")
    for i, day in enumerate(alldays):
        fout.write("{} {:5.3f} {:5.3f}\n".format(day, 
                                                 fluxes_2mm_neptune[i].value, 
                                                 fluxes_1mm_neptune[i].value))
fout.close()


# write the output for mars
#out_mars = os.path.join(workdir, 'mars.txt')
#with open(out_mars, 'w') as fout:
#    fout.write("# Date Fnu_150GHz   Fnu_260GHz\n")
#    for i, day in enumerate(alldays):
#        fout.write("{} {:5.3f} {:5.3f}\n".format(day, 
#                                                 Fnu150GHzMars[i], 
#                                                 Fnu260GHzMars[i]))
#fout.close()


