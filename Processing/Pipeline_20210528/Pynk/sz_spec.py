import numpy as np
from scipy import interpolate
import os
import astropy.constants as cst
import pdb


TCMB = 2.725
mec2 = 510.998910
kB   = cst.k_B.value
h    = cst.h.value
c    = cst.c.value
I0 = 2.0*(kB*TCMB)**3.0/(h*c)**2.0
 

def tsz_spec_tab(in_freq,in_Tkev):
  
    """
    Computes thermal SZ power spectrum including relativistic corrections from
    interpolation of tabulated values in Itoh & Nozawa 2014, 
    https://arxiv.org/pdf/astro-ph/0307519.pdf
    
    Input:
      in_freq: frequency in GHz (numpy array)
      in_Tkev: electron temperature in keV (numpy array) > 1 keV
      
    Output:
      delta_I_over_y: thermal SZ spectrum in 
    
    """
    
    theta_e = in_Tkev/mec2

    data_dir = os.getenv('NIKA_SOFT_DIR')+'/Pipeline/IDLtools/SZspec/'
    d1 = np.loadtxt(data_dir + 'sztable1.dat')
    d2 = np.loadtxt(data_dir + 'sztable2.dat')
    d3 = np.loadtxt(data_dir + 'sztable3.dat')
    d4 = np.loadtxt(data_dir + 'sztable4.dat')
    d5 = np.loadtxt(data_dir + 'sztable5.dat')

    d = np.zeros((50,101))
    d[0:10] = (d1.T)[1:,:]
    d[10:20] = (d2.T)[1:,:]
    d[20:30] = (d3.T)[1:,:]
    d[30:40] = (d4.T)[1:,:]
    d[40:] = (d5.T)[1:,:]

    freq = d1[:,0] * cst.k_B.value * TCMB/cst.h.value/1.0e9
    Tkev = np.array([0.002, 0.004, 0.006, 0.008, 0.010, 0.012, 0.014, 0.016, 0.018, 0.020, 
          0.022, 0.024, 0.026, 0.028, 0.030, 0.032, 0.034, 0.036, 0.038, 0.040, 
          0.042, 0.044, 0.046, 0.048, 0.050, 0.052, 0.054, 0.056, 0.058, 0.060, 
          0.062, 0.064, 0.066, 0.068, 0.070, 0.072, 0.074, 0.076, 0.078, 0.080,
          0.082, 0.084, 0.086, 0.088, 0.090, 0.092, 0.094, 0.096, 0.098, 0.100])*mec2
  
    f = interpolate.interp2d(freq, Tkev, d, kind='cubic')
    
    delta_I_over_y = f(in_freq, in_Tkev)/theta_e

    return delta_I_over_y*I0
  
def tsz_spec(in_freq):
    """
    Computes thermal SZ spectrum, no relativistic corrections  based on Carlstrong et al 2002
    
    Input:
      in_freq: 
	input observation frequency in GHz
    Output:
        tsz_spec 
    """
    x = h*in_freq*1e9/kB/TCMB
    f1 = x**4.*np.exp(x)/((np.exp(x)-1.0)**2.0)
    xtil = x*((np.cosh(x/2.0))/(np.sinh(x/2.0)))
    mtsz_spec = (xtil-4.0)*f1*I0
    
    return mtsz_spec

def tsz_spec_relcorr(in_freq,Tkev):
    """   
    Computes the thermal SZ spectrum including relativistic corrections using analytic formula from
    
    """
    if Tkev < 0.002*mec2:
	mtsz_spec = tsz_spec(in_freq)
    else:
	mtsz_spec = tsz_spec_tab(in_freq,Tkev)
   
    return mtsz_spec
  
    
def ksz_spec_relcorr(in_freq,v_pec,Tkev):
    """
    Computes kinetic SZ spectrum, no relativistic corrections
    
    Input:
      in_freq: 
	frequency in GHz
      v_pec:
	cluster peculiar velocity along the line-of-sight
      
    """
    x = h*in_freq*1e9/kB/TCMB
    f1 = x**4.*np.exp(x)/((np.exp(x)-1)**2.0)
    xtil = x*(np.cosh(x/2.0)/np.sinh(x/2.0))
    s = x/np.sinh(x/2.0)
    theta = Tkev/mec2
    Y0 = xtil-4.0
    y1a = -10.+47./2.*xtil-42./5.*xtil**(2.)
    y1b = 0.7*xtil**(3.)+s**(2.)*(-21./5.+7./5.*xtil)
    Y1 = y1a+y1b

    y2a = -15/2.+1023./8.*xtil-868./5.*xtil**(2.)
    y2b = 329./5.*xtil**(3.)-44./5.*xtil**(4.)
    y2c = 11./30.*xtil**(5.)
    y2d = -434./5.+658/5.*xtil-242./5.*xtil**(2.)+143./30.*xtil**(3.)
    y2e = -44./5.+187./60.*xtil
    Y2 = y2a+y2b+y2c+s**(2.)*y2d+s**(4.)*y2e

    y3a = 15./2.+2505./8.*xtil-7098./5.*xtil**(2.)
    y3b = 1425.3*xtil**(3.)-18594./35.*xtil**(4.)
    y3c = 12059./140.*xtil**(5.)-128./21.*xtil**(6.)+16./105.*xtil**(7.)
    y3d1 = -709.8+14253/5.*xtil-102267./35.*xtil**(2.)
    y3d2 = 156767./140.*xtil**(3.)-1216./7.*xtil**(4.)+64./7.*xtil**(5.)
    y3d = s**(2.)*(y3d1+y3d2)
    y3e1 = -18594./35.+205003./280.*xtil
    y3e2 = -1920./7.*xtil**(2.)+1024./35.*xtil**(3.)
    y3e = s**(4.)*(y3e1+y3e2)
    y3f = s**(6.)*(-544./21.+922./105.*xtil)
    Y3 = y3a+y3b+y3c+y3d+y3e+y3f
  
    beta = v_pec/(c*1e-3)

    S2 = s**2.

    C0 = 1.
    C1 = 10.+(7.*S2)/10.-(47.*xtil)/5.+(7.*xtil**2)/5.
    C2 = 25.+(11.*S2**2)/10.-(1117.*xtil)/10.+(847.*xtil**2)/10.-(183.*xtil**3)/10.+(11.*xtil**4)/10.+S2*(847./20.-(183.*xtil)/5.+(121.*xtil**2)/20.)
    C3 = 75./4.+(272.*S2**3)/105.-(21873.*xtil)/40.+(49161.*xtil**2)/40.-(27519.*xtil**3)/35.+(6684.*xtil**4)/35.-(3917.*xtil**5)/210.+(64.*xtil**6)/105.+S2**2*(6684./35.-(66589.*xtil)/420.+(192.*xtil**2)/7.)+S2*(49161./80.-(55038.*xtil)/35.+(36762.*xtil**2)/35.-(50921.*xtil**3)/210.+(608.*xtil**4)/35.)
    C4 = -75./4.+(341.*S2**4)/42.-(10443.*xtil)/8.+(359079.*xtil**2)/40.-(938811.*xtil**3)/70.+(261714.*xtil**4)/35.-(263259.*xtil**5)/140.+(4772.*xtil**6)/21.-(1336.*xtil**7)/105.+(11.*xtil**8)/42.+S2**3*(20281./21.-(82832.*xtil)/105.+(2948.*xtil**2)/21.)+S2**2*(261714./35.-(4475403.*xtil)/280.+(71580.*xtil**2)/7.-(85504.*xtil**3)/35.+(1331.*xtil**4)/7.)+S2*(359079./80.-(938811.*xtil)/35.+(1439427.*xtil**2)/35.-(3422367.*xtil**3)/140.+(45334.*xtil**4)/7.-(5344.*xtil**5)/7.+(2717.*xtil**6)/84.)

    D0 = -2./3.+(11.*xtil)/30.
    D1 = -4.+12.*xtil-6.*xtil**2+(19.*xtil**3)/30.+S2*(-3.+(19.*xtil)/15.)
    D2 = -10.+(542.*xtil)/5.-(843.*xtil**2)/5.+(10603.*xtil**3)/140.-(409.*xtil**4)/35.+(23.*xtil**5)/42.+S2**2*(-409./35.+(391.*xtil)/84.)+S2*(-843./10.+(10603.*xtil)/70.-(4499.*xtil**2)/70.+(299.*xtil**3)/42.)
    D3 = -15./2.+(4929.*xtil)/10.-(39777.*xtil**2)/20.+(1199897.*xtil**3)/560.-(4392.*xtil**4)/5.+(16364.*xtil**5)/105.-(3764.*xtil**6)/315.+(101.*xtil**7)/315.+S2**3*(-15997./315.+(6262.*xtil)/315.)+S2**2*(-4392./5.+(139094.*xtil)/105.-(3764.*xtil**2)/7.+(6464.*xtil**3)/105.)+S2*(-39777./40.+(1199897.*xtil)/280.-(24156.*xtil**2)/5.+(212732.*xtil**3)/105.-(35758.*xtil**4)/105.+(404.*xtil**5)/21.)

     
    fac00 = C0+theta*C1+theta**(2.)*C2+theta**3.*C3+theta**(4.)*C4
    fac01 = D0+theta*D1+theta**2.*D2+theta**3.*D3
    fac02 = 1.*Y0/3.+theta*(5.*Y0/6.+2.*Y1/3.)+theta**2*(5.*Y0/8.+3.*Y1/2.+Y2)+theta**3 *(-5.*Y0/8.+5.*Y1/4.+5.*Y2/2.+4.*Y3/3.)


    ksz_spec = -1*I0*f1*( beta*fac00 + beta**2.*fac02 + beta**2.*fac01)
#    ksz_spec = -1.0*f1*beta*I0

    return ksz_spec
  
  
def sz_relcorr(in_freq,Tkev,v_pec,tau):
    """
      Computes thermal + kinetic SZ effect applying relativistic corrections
      in MJy/sr
      
      Input:
	in_freq: input observation frequency in GHz (numpy array)
	Tkev:    cluster temperature in keV
	v_pec  : peculiar cluster velocity in m/s
	tau :    sigma_T * \int n_e dl 

    """
    theta_e = Tkev/mec2
    ksz = tau * ksz_spec_relcorr(in_freq,v_pec,Tkev)
    tsz = tau * theta_e * tsz_spec_relcorr(in_freq, Tkev)

    return (ksz+tsz)*1.0e20


def y2sz_relcorr(in_freq,Tkev,v_pec,y):
    """
      Computes thermal + kinetic SZ effect applying relativistic corrections
      in MJy/sr
      
      Input:
	in_freq: input observation frequency in GHz (numpy array)
	Tkev:    cluster temperature in keV
	v_pec  : peculiar cluster velocity in m/s
        y :      sigma_T * \int P_e dl
	tau :    sigma_T * \int n_e dl 

    """
    
    theta_e = Tkev/mec2
    tau = y/ theta_e

    if np.ndim(y) == 2:
        ksz = tau[None,:,:] * ksz_spec_relcorr(in_freq,v_pec,Tkev)[:,None,None]
        tsz = y[None,:,:] * tsz_spec_relcorr(in_freq, Tkev)[:,None,None]

    if np.ndim(y) == 1:
        ksz = tau[None,:] * ksz_spec_relcorr(in_freq,v_pec,Tkev)[:,None]
        tsz = y[None,:] * tsz_spec_relcorr(in_freq, Tkev)[:,None]
        
    return (ksz+tsz)*1.0e20
