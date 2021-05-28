from numpy import *
from scipy import optimize
import numpy as np
 
def gaussian(height, center_x, center_y, width_x, width_y,zerolevel):
     """Returns a gaussian function with the given parameters"""
     width_x = float(width_x)
     width_y = float(width_y)
     return lambda x,y: zerolevel+ height*exp(
                 -(((center_x-x)/width_x)**2+((center_y-y)/width_y)**2)/2)
 
def moments(data):
     """Returns (height, x, y, width_x, width_y)
     the gaussian parameters of a 2D distribution by calculating its
     moments """
     total = data.sum()
     X, Y = indices(data.shape)
     x = (X*data).sum()/total
     y = (Y*data).sum()/total
     col = data[:, int(y)]
     width_x = sqrt(abs((arange(col.size)-y)**2*col).sum()/col.sum())
     row = data[int(x), :]
     width_y = sqrt(abs((arange(row.size)-x)**2*row).sum()/row.sum())
     height = data.max()
     zerolevel = np.median(data)
     return height, x, y, width_x, width_y,zerolevel


def fitgaussian(data,inpar=None,err=None):
     """
     Returns (height, x, y, width_x, width_y,zerolevel)
     the gaussian parameters of a 2D distribution found by a fit
     """
     if inpar is None:
         params = moments(data)
     else:
         params = inpar
     if err is None:
         errorfunction = lambda p: ravel(gaussian(*p)(*indices(data.shape)) - data)
     else:
         errorfunction = lambda p: ravel((gaussian(*p)(*indices(data.shape)) - data)/err)
     res = optimize.leastsq(errorfunction, params,full_output =True)
     par = res[0]
     eparr = np.sqrt(np.diagonal(np.asarray(res[1])))
     cov   = res[1]
     return par, eparr, cov

