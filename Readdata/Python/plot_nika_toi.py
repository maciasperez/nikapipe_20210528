from pyqtgraph.Qt import QtGui, QtCore
import numpy as np
import pyqtgraph as pg
import pdb

pg.setConfigOption('background', 'w')
pg.setConfigOption('foreground', 'k')
pg.setConfigOptions(antialias=True)

def plot_nika_toi(nikadata,nmaxkids=20):
    #QtGui.QApplication.setGraphicsSystem('raster')
    app = QtGui.QApplication([])


    win = pg.GraphicsWindow(title="NIKA TOI PLOTS")
    win.resize(1000,900)
 
 
    # Enable antialiasing for prettier plots


    nkids,nsamples = nikadata.shape



    p8 = win.addPlot(title="Select region")
    p8.setLabel('bottom','Sample','TOI index')
    p8.setLabel('left','RF_DIDQ','')
    p8.showGrid(x=1,y=1,alpha=0.5)
    p8.plot(nikadata[0,0:].T, pen='b')
    if nsamples > 5000: p8.setDownsampling(ds=10, auto=1, mode='subsample')
    lr = pg.LinearRegionItem([0,nsamples-1])
    lr.setZValue(-10)
    p8.addItem(lr)

    win.nextRow()

    p9 = win.addPlot(title="Zoom on selected region")
    p9.setLabel('bottom','Sample','TOI index')
    p9.setLabel('left','RF_DIDQ','')
    p9.showGrid(x=1,y=1,alpha=0.5)
    if nsamples > 5000: p9.setDownsampling(ds=10, auto=1, mode='subsample')
    p9.plot(nikadata[0,0:].T)
    if nkids < nmaxkids:
        ntoplot = nkids
        toplot = np.arange(nkids)
    else:
        ntoplot = nmaxkids
        toplot = np.random.uniform(0,nkids-1,ntoplot)
        
        
    toplot = toplot.astype(long)
    for ikid in range(ntoplot): p9.plot(nikadata[toplot[ikid],0:],pen=ikid)
    win.nextRow()

    fr,pw=power_spectrum(nikadata[toplot,:])
    p10=win.addPlot(title="Power Spectra")
    p10.setLabel('bottom','Frequency','Arbitrary Units')
    p10.setLabel('left','PSD ','$Hz/Hz^{\frac{1}{2}}$')
    p10.showGrid(x=1,y=1,alpha=0.5)
    p10.setLogMode(x=1, y=1)
    for ikid in range(ntoplot): p10.plot(fr,pw[ikid,0:],pen=ikid)

    def updatePlot():
        p9.setXRange(*lr.getRegion(), padding=0)
       # p9.setYRange(, padding=0)
        reg  = lr.getRegion()
        begidx = np.long(reg[0]) 
        if begidx < 0: begidx = 0
        endidx = np.long(reg[1]) 
        if endidx > nsamples-1: endix = nsamples-1
#        fr,pw=power_spectrum(nikadata[toplot,begidx:endidx])
#        for ikid in range(ntoplot): p10.plot(fr,pw[ikid,0:],pen=ikid)


    def updateRegion():
        lr.setRegion(p9.getViewBox().viewRange()[0])

#    def mouseMoved(pos):
#        print "Plot position:", p8.mapFromScene(pos)
#        print "toto"

#    p8.scene().sigMouseMoved.connect(mouseMoved)

    lr.sigRegionChanged.connect(updatePlot)
    p9.sigXRangeChanged.connect(updateRegion)
    updatePlot()
    QtGui.QApplication.instance().exec_()
    
   


def power_spectrum(toi):
    from scipy import signal
    nikafs = 22.0
    freq, pw = signal.periodogram(toi, nikafs,scaling='density',axis=1)
    return freq,pw

