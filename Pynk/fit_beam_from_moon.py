 
# gaussfitter.py
# created by Adam Ginsburg (adam.ginsburg@colorado.edu or keflavich@gmail.com) 3/17/08)
import numpy
from numpy.ma import median
from numpy import pi
#from scipy import optimize,stats,pi
from mpfit import mpfit
from scipy import signal

""" Note about mpfit/leastsq: I switched everything over to the Markwardt mpfit
routine for a few reasons, but foremost being the ability to set limits on
parameters, not just force them to be fixed.  As far as I can tell, leastsq
does not have that capability.  """

"""
To do:
    -turn into a class instead of a collection of objects
    -implement WCS-based gaussian fitting with correct coordinates
"""

def moments(data,circle,rotate,vheight,estimator=median,**kwargs):
    """Returns (height, amplitude, x, y, width_x, width_y, rotation angle)
    the gaussian parameters of a 2D distribution by calculating its
    moments.  Depending on the input parameters, will only output 
    a subset of the above.
    
    If using masked arrays, pass estimator=numpy.ma.median
    """
    total = numpy.abs(data).sum()
    Y, X = numpy.indices(data.shape) # python convention: reverse x,y numpy.indices
    y = numpy.argmax((X*numpy.abs(data)).sum(axis=1)/total)
    x = numpy.argmax((Y*numpy.abs(data)).sum(axis=0)/total)
    col = data[int(y),:]
    # FIRST moment, not second!
    width_x = numpy.sqrt(numpy.abs((numpy.arange(col.size)-y)*col).sum()/numpy.abs(col).sum())
    row = data[:, int(x)]
    width_y = numpy.sqrt(numpy.abs((numpy.arange(row.size)-x)*row).sum()/numpy.abs(row).sum())
    width = ( width_x + width_y ) / 2.
    height = estimator(data.ravel())
    amplitude = data.max()-height
    mylist = [amplitude,x,y]
    if numpy.isnan(width_y) or numpy.isnan(width_x) or numpy.isnan(height) or numpy.isnan(amplitude):
        raise ValueError("something is nan")
    if vheight==1:
        mylist = [height] + mylist
    if circle==0:
        mylist = mylist + [width_x,width_y]
        if rotate==1:
            mylist = mylist + [0.] #rotation "moment" is just zero...
            # also, circles don't rotate.
    else:  
        mylist = mylist + [width]
    return mylist



def moonmodel(inpars,x,y, vheight=1, shape=None):
    """
        Returns a 2d gaussian function of the form:
        x' = numpy.cos(rota) * x - numpy.sin(rota) * y
        y' = numpy.sin(rota) * x + numpy.cos(rota) * y
        (rota should be in degrees)
        g = b + a * numpy.exp ( - ( ((x-center_x)/width_x)**2 +
        ((y-center_y)/width_y)**2 ) / 2 )

        inpars = [b,a,center_x,center_y,width_x,width_y,rota]
                 (b is background height, a is peak amplitude)

        where x and y are the input parameters of the returned function,
        and all other parameters are specified by this function

        However, the above values are passed by list.  The list should be:
        inpars = (height,amplitude,center_x,center_y,width_x,width_y,rota)

        You can choose to ignore / neglect some of the above input parameters 
            unumpy.sing the following options:
                an image with the gaussian defined by inpars
    """
    inpars_old = inpars
    inpars = list(inpars)
    if vheight == 1:
        height = inpars.pop(0)
        height = float(height)
    else:
        height = float(0)

    amplitude, center_y, center_x = inpars.pop(0),inpars.pop(0),inpars.pop(0)
    amplitude = float(amplitude)
    center_x = float(center_x)
    center_y = float(center_y)

    width_x, width_y = inpars.pop(0),inpars.pop(0)
    width_x = float(width_x)
    width_y = float(width_y)
        
    x0 = numpy.median(x[:,0])
    y0 = numpy.median(y[0,:])
    gfunc = numpy.exp(-(((x-x0)/width_x)**2  +  ((y-y0)/width_y)**2)/2.)

    msize = inpars.pop(0)
    mdist = numpy.sqrt((x-center_x)**2.0 + (y-center_y)**2.0)
    moon  = numpy.zeros(x.shape)
    moon[mdist <= msize/2.0] = 1.0
    g = height+ amplitude* signal.fftconvolve(moon,gfunc,mode='same')    

    return g
    
def moonmodelfit(data,err=None,params=[],Msize=1,autoderiv=1,return_all=0,
#        fixed=numpy.repeat(False,7),limitedmin=[False,False,False,False,True,True,True],
        fixed=[False,False,False,False,False,False,True],limitedmin=[False,False,False,False,True,True,True],
        limitedmax=[False,False,False,False,False,False,False],
        usemoment=numpy.array([],dtype='bool'),
        minpars=numpy.repeat(0,7),maxpars=[0,0,0,0,0,0,0.0],
        vheight=1,quiet=True,returnmp=False,
        returnfitimage=False,**kwargs):
    """
    Moon model
    2-dimensional gaussian.
    
    Input Parameters:
        data - 2-dimensional data array
        err=None - error array with same size as data array
        params=[] - initial input parameters for Gaussian function.
            (height, amplitude, x, y, width_x, width_y, moonsize)
            if not input, these will be determined from the moments of the system, 
            assuming no rotation
        autoderiv=1 - use the autoderiv provided in the lmder.f function (the
            alternative is to us an analytic derivative with lmdif.f: this method
            is less robust)
        return_all=0 - Default is to return only the Gaussian parameters.  
                   1 - fit params, fit error
        returnfitimage - returns (best fit params,best fit image)
        returnmp - returns the full mpfit struct
        vheight=1 - default allows a variable height-above-zero, i.e. an
            additive constant for the Gaussian function.  Can remove first
            parameter by setting this to 0
        usemoment - can choose which parameters to use a moment estimation for.
            Other parameters will be taken from params.  Needs to be a boolean
            array.

    Output:
        Default output is a set of Gaussian parameters with the same shape as
            the input parameters

        Can also output the covariance matrix, 'infodict' that contains a lot
            more detail about the fit (see scipy.optimize.leastsq), and a message
            from leastsq telling what the exit status of the fitting routine was

        Warning: Does NOT necessarily output a rotation angle between 0 and 360 degrees.
    """
    
    usemoment=numpy.array(usemoment,dtype='bool')
    params=numpy.array(params,dtype='float')
    if usemoment.any() and len(params)==len(usemoment):
        moment = numpy.array(moments(data,0,0,vheight,**kwargs),dtype='float')
        params[usemoment] = moment[usemoment]
    elif params == [] or len(params)==0:
        params = (moments(data,0,0,vheight,**kwargs))
    if vheight==0:
        vheight=1
        params = numpy.concatenate([[0],params])
        fixed[0] = 1

    circle = 0
    params = numpy.concatenate([params,[Msize]])
    
    
    # mpfit will fail if it is given a start parameter outside the allowed range:
    for i in xrange(len(params)): 
        if params[i] > maxpars[i] and limitedmax[i]: params[i] = maxpars[i]
        if params[i] < minpars[i] and limitedmin[i]: params[i] = minpars[i]

    x,y = numpy.indices(data.shape)    
    
    
    if isinstance(err,numpy.ndarray):
        errorfunction = lambda p: numpy.ravel((moonmodel(p,x,y,vheight) - data)/err)
    else:
        errorfunction = lambda p: numpy.ravel((moonmodel(p,x,y,vheight) - data))

    def mpfitfun(data,err,x,y):
        
        if isinstance(err,numpy.ndarray):
            def f(p,fjac=None): return [0,numpy.ravel((data - moonmodel(p,x,y,vheight))/err)]
        else:
            def f(p,fjac=None): return [0, numpy.ravel(data-moonmodel(p,x,y,vheight)       )]
        """
        if err == None:
            def f(p,fjac=None): return [0, numpy.ravel(data-moonmodel(p,x,y,vheight)       )]
        else:
            def f(p,fjac=None): return [0,numpy.ravel((data - moonmodel(p,x,y,vheight))/err)]
        """
        
        return f

                    
    parinfo = [ 
                {'n':1,'value':params[1],'limits':[minpars[1],maxpars[1]],'limited':[limitedmin[1],limitedmax[1]],'fixed':fixed[1],'parname':"AMPLITUDE",'error':0},
                {'n':2,'value':params[2],'limits':[minpars[2],maxpars[2]],'limited':[limitedmin[2],limitedmax[2]],'fixed':fixed[2],'parname':"XSHIFT",'error':0},
                {'n':3,'value':params[3],'limits':[minpars[3],maxpars[3]],'limited':[limitedmin[3],limitedmax[3]],'fixed':fixed[3],'parname':"YSHIFT",'error':0},
                {'n':4,'value':params[4],'limits':[minpars[4],maxpars[4]],'limited':[limitedmin[4],limitedmax[4]],'fixed':fixed[4],'parname':"XWIDTH",'error':0} ]
    if vheight == 1:
        parinfo.insert(0,{'n':0,'value':params[0],'limits':[minpars[0],maxpars[0]],'limited':[limitedmin[0],limitedmax[0]],'fixed':fixed[0],'parname':"HEIGHT",'error':0})
    if circle == 0:
        parinfo.append({'n':5,'value':params[5],'limits':[minpars[5],maxpars[5]],'limited':[limitedmin[5],limitedmax[5]],'fixed':fixed[5],'parname':"YWIDTH",'error':0})
    parinfo.append({'n':6,'value':params[6],'limits':[minpars[6],maxpars[6]],'limited':[limitedmin[6],limitedmax[6]],'fixed':fixed[6],'parname':"ROTATION",'error':0})

    if autoderiv == 0:
        # the analytic derivative, while not terribly difficult, is less
        # efficient and useful.  I only bothered putting it here because I was
        # instructed to do so for a class project - please ask if you would
        # like this feature implemented
        raise ValueError("I'm sorry, I haven't implemented this feature yet.")
    else:
#        p, cov, infodict, errmsg, success = optimize.leastsq(errorfunction,\
#                params, full_output=1)
        mp = mpfit(mpfitfun(data,err,x,y),parinfo=parinfo,quiet=quiet)


    if returnmp:
        returns = (mp)
    elif return_all == 0:
        returns = mp.params
    elif return_all == 1:
        returns = mp.params,mp.perror
    if returnfitimage:
        fitimage = moonmodel(mp.params,x,y, vheight)
        returns = (returns,fitimage)
    return returns


