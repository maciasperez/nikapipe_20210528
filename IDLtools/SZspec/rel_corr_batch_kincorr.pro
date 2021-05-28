;+
;PURPOSE: Compute the SZ spectrum including relativistic corrections
;to the tSZ and/or kSZ contributions
;
;INPUT: - the optical depth tau (= sigma_T \int n_e dl)
;       - the ICM temperature in keV
;       - The cluster peculiar velocity along z axis in km/s
;       - the CMB temperature (should be at the cluster redshift if
;         the frequency vector is scaled at the cluster redshift)
;       - type:
;          0: only tSZ
;          1: tSZ+corrections
;          2: only kSZ
;          3: kSZ+corrections
;          4: all
;          5: tSZ+kSZ without corrections
;
;KEYWORD: - freq_GHz the frequency vector (should be scaled at the
;           cluster redshift if Tcmb is given at the cluster redshift)
;
;REFERENCES: An improved formula for the relativistic corrections to the kine-
;            matical Sunyaev-Zeldovich effect for clusters of galaxies
;            Satoshi Nozawa, Naoki Itoh, Yasuhiko Suda and Yoichi Ohhata
;
;            For ICM temperature greater than 20-25 keV, use instead
;            the interpolation of the exact tSZ spectrum
;            (tabulated_numerical_sz_spectrum.pro)
;     
;            kSZ accuracy between 100-300 GHz:
;                      - 20 keV: (kSZ_order3-kSZ_order4)/kSZ_order4 < 3%
;                      - 25 keV: (kSZ_order3-kSZ_order4)/kSZ_order4 < 6%
;                      - 30 keV: (kSZ_order3-kSZ_order4)/kSZ_order4 < 12%
;                      - 40 keV: (kSZ_order3-kSZ_order4)/kSZ_order4 < 38%
;           The true accuracy is probably about half the given
;           numbers since order 4 is an overestimate and order 3 
;           is an underestimate.
;
;            tSZ accuracy between 100-300 GHz (except at the null where it
;            diverges):
;                      - 15 keV: (tSZ_order3-tSZ_numeric)/tSZ_numeric < 1.5%
;                      - 19 keV: (tSZ_order3-tSZ_numeric)/tSZ_numeric < 3%
;                      - 20 keV: (tSZ_order3-tSZ_numeric)/tSZ_numeric < 1%
;                      - 25 keV: (tSZ_order3-tSZ_numeric)/tSZ_numeric < 0.4%
;                      - 30 keV: (tSZ_order3-tSZ_numeric)/tSZ_numeric < 0.5%
;                      - 50 keV: (tSZ_order3-tSZ_numeric)/tSZ_numeric < 0.5%
;           At 20 keV, the analytical expression changes, so it is where
;           errors are maximal.
;
;AUTHOR: L. LAMAGNA (Luca.Lamagna@roma1.infn.it) & G. SAVINI
;        Modified by R. ADAM based on arXiv:astro-ph/0307519
;-

function rel_corr_batch_kincorr, tau, tkev, v_pec, tcmb, freq_GHz=freq_GHz, type, temp=temp

  if n_elements(tkev) ne 1 then message, 'Tkev must be a scalar'
  if n_elements(v_pec) ne 1 then message, 'V_pec must be a scalar'

  kb = double(1.380650e-23)     ;Boltzmann
  h = double(6.62607e-34)       ;h
  c = double(2.99792e10)
  hc = h*c                      ;h*c
  me = 510.99890                ;keV
  t0 = 2.725                    ;K

  tkev = float(tkev)
  tcmb = float(tcmb)
  v_pec = float(v_pec)
  theta = tkev/me
  beta = v_pec/(c*1e-5)

  ;;========== In case no frequency is supplied, define one
  if not keyword_set(freq_GHz) then begin
     tcmb = t0                                  
     ni_min = 0.5                               	      	   
     ni_max = 35.                               
     step_ni = 0.03                             
     n_ni = round((ni_max-ni_min)/step_ni)      
     ni = dblarr(n_ni)                          
     x = dblarr(n_ni)                           
     for i = 0,n_ni-1 do ni(i) = ni_min+i*step_ni 
     x = (hc/kb)*(ni/tcmb)                      

     print, 'REL_CORR_BATCH - Frequency not supplied, using standard range'
     print, 'REL_CORR_BATCH - Supplied Tcmb has been ignored.'
  endif else begin
     x = h*freq_Ghz*1e9/kb/tcmb
  endelse

  f1 = x^(4.)*exp(x)/(exp(x)-1.)^(2.)
  xtil = x*((cosh(x/2.0))/(sinh(x/2.0)))
  s = x/(sinh(x/2.0))

  ;;========== thermal SZ terms
  ;;---------- Region where x < 1.2
  y0 = xtil-4.

  y1a = -10.+47./2.*xtil-42./5.*xtil^(2.)
  y1b = 0.7*xtil^(3.)+s^(2.)*(-21./5.+7./5.*xtil)
  y1 = y1a+y1b

  y2a = -15/2.+1023./8.*xtil-868./5.*xtil^(2.)
  y2b = 329./5.*xtil^(3.)-44./5.*xtil^(4.)
  y2c = 11./30.*xtil^(5.)
  y2d = -434./5.+658/5.*xtil-242./5.*xtil^(2.)+143./30.*xtil^(3.)
  y2e = -44./5.+187./60.*xtil
  y2 = y2a+y2b+y2c+s^(2.)*y2d+s^(4.)*y2e

  y3a = 15./2.+2505./8.*xtil-7098./5.*xtil^(2.)
  y3b = 1425.3*xtil^(3.)-18594./35.*xtil^(4.)
  y3c = 12059./140.*xtil^(5.)-128./21.*xtil^(6.)+16./105.*xtil^(7.)
  y3d1 = -709.8+14253/5.*xtil-102267./35.*xtil^(2.)
  y3d2 = 156767./140.*xtil^(3.)-1216./7.*xtil^(4.)+64./7.*xtil^(5.)
  y3d = s^(2.)*(y3d1+y3d2)
  y3e1 = -18594./35.+205003./280.*xtil
  y3e2 = -1920./7.*xtil^(2.)+1024./35.*xtil^(3.)
  y3e = s^(4.)*(y3e1+y3e2)
  y3f = s^(6.)*(-544./21.+922./105.*xtil)
  y3 = y3a+y3b+y3c+y3d+y3e+y3f

  y4a = -135./32.+30375./128.*xtil-6239.1*xtil^(2.)
  y4b = 61472.7/4.*xtil^(3.)-12438.9*xtil^(4.)
  y4c = 35570.3/8.*xtil^(5.)-16568./21.*xtil^(6.)
  y4d = 7516./105.*xtil^(7.)-22./7.*xtil^(8.)+11./210.*xtil^(9.)
  y4e1 = -62391./20.+614727./20.*xtil
  y4e2 = -1368279./20.*xtil^(2.)+4624139./80.*xtil^(3.)
  y4e3 = -157396./7.*xtil^(4.)+30064./7.*xtil^(5.)
  y4e4 = -2717./7.*xtil^(6.)+2761./210.*xtil^(7.)
  y4e = s^(2.)*(y4e1+y4e2+y4e3+y4e4)
  y4f1 = -12438.9+6046951./160.*xtil
  y4f2 = -248520./7.*xtil^(2.)+481024./35.*xtil^(3.)
  y4f3 = -15972./7.*xtil^(4.)+18689./140.*xtil^(5.)
  y4f = s^(4.)*(y4f1+y4f2+y4f3)
  y4g1 = -70414./21.+465992./105.*xtil
  y4g2 = -11792./7.*xtil^(2.)+19778./105.*xtil^(3.)
  y4g = s^(6.)*(y4g1+y4g2)
  y4h = s^(8.)*(-682./7.+7601./210.*xtil)
  y4 = y4a+y4b+y4c+y4d+y4e+y4f+y4g+y4h

  DI_over_tau_over_theta_lt12 = f1 * (y0+theta*y1+theta^(2.)*y2+theta^(3.)*y3+theta^(4.)*y4)
  
  ;;---------- Region where x > 1.2 if T > 20.0 keV
  Tlim = 20.0
  if TkeV ge Tlim then begin
     x_0 = 3.830 * (1.0 + 1.1674*theta - 0.8533*theta^2.)
     
     a_ij = transpose([[[-1.81317E+1+x*0],[ 9.97038E+1+x*0],[-6.07438E+1+x*0],[ 1.05143E+3+x*0],[-2.86734E+3+x*0],[ 7.73353E+3+x*0],[-8.16644E+3+x*0],[-5.37712E+3+x*0],[ 1.52226E+4+x*0],[ 7.18726E+3+x*0],[-1.39548E+4+x*0],[-2.08464E+4+x*0],[ 1.79040E+4+x*0]],$
                       [[ 1.68733E+2+x*0],[-6.07829E+2+x*0],[ 1.14933E+3+x*0],[-2.42382E+2+x*0],[-7.73030E+2+x*0],[ 5.33993E+3+x*0],[-4.03443E+3+x*0],[ 3.00692E+3+x*0],[ 9.58809E+3+x*0],[ 8.16574E+3+x*0],[-6.13322E+3+x*0],[-1.48117E+4+x*0],[ 3.43816E+4+x*0]],$
                       [[-6.69883E+2+x*0],[ 1.59654E+3+x*0],[-3.33375E+3+x*0],[-2.13234E+3+x*0],[-1.80812E+2+x*0],[ 3.75605E+3+x*0],[-4.75180E+3+x*0],[-4.50495E+3+x*0],[ 5.38753E+3+x*0],[ 5.03355E+3+x*0],[-1.18396E+4+x*0],[-8.58473E+3+x*0],[ 3.96316E+4+x*0]],$
                       [[ 1.56222E+3+x*0],[-1.78598E+3+x*0],[ 5.13747E+3+x*0],[ 4.10404E+3+x*0],[ 5.54775E+2+x*0],[-3.89994E+3+x*0],[-1.22455E+3+x*0],[ 1.03747E+3+x*0],[ 4.32237E+3+x*0],[ 1.03805E+3+x*0],[-1.47172E+4+x*0],[-1.23591E+4+x*0],[ 1.77290E+4+x*0]],$
                       [[-2.34712E+3+x*0],[ 2.78197E+2+x*0],[-5.49648E+3+x*0],[-5.94988E+2+x*0],[-1.47060E+3+x*0],[-2.84032E+2+x*0],[-1.15352E+3+x*0],[-1.17893E+3+x*0],[ 7.01209E+3+x*0],[ 4.75631E+3+x*0],[-5.13807E+3+x*0],[-8.73615E+3+x*0],[ 9.41580E+3+x*0]],$
                       [[ 1.92894E+3+x*0],[ 1.17970E+3+x*0],[ 3.13650E+3+x*0],[-2.91121E+2+x*0],[-1.15006E+3+x*0],[ 4.17375E+3+x*0],[-3.31788E+2+x*0],[ 1.37973E+3+x*0],[-2.48966E+3+x*0],[ 4.82005E+3+x*0],[-1.06121E+4+x*0],[-1.19394E+4+x*0],[ 1.34908E+4+x*0]],$
                       [[ 6.40881E+2+x*0],[-6.81789E+2+x*0],[ 1.20037E+3+x*0],[-3.27298E+3+x*0],[ 1.02988E+2+x*0],[ 2.03514E+3+x*0],[-2.80502E+3+x*0],[ 8.83880E+2+x*0],[ 1.68409E+3+x*0],[ 4.26227E+3+x*0],[-6.37868E+3+x*0],[-1.11597E+4+x*0],[ 1.46861E+4+x*0]],$
                       [[-4.02494E+3+x*0],[-1.37983E+3+x*0],[-1.65623E+3+x*0],[ 7.36120E+1+x*0],[ 2.66656E+3+x*0],[-2.30516E+3+x*0],[ 5.22182E+3+x*0],[-8.53317E+3+x*0],[ 3.75800E+2+x*0],[ 8.49249E+2+x*0],[-6.88736E+3+x*0],[-1.01475E+4+x*0],[ 4.75820E+3+x*0]],$
                       [[ 4.59247E+3+x*0],[ 3.04203E+3+x*0],[-2.11039E+3+x*0],[ 1.32383E+3+x*0],[ 1.10646E+3+x*0],[-3.53827E+3+x*0],[-1.12073E+3+x*0],[-5.47633E+3+x*0],[ 9.85745E+3+x*0],[ 5.72138E+3+x*0],[ 6.86444E+3+x*0],[-5.72696E+3+x*0],[ 1.29053E+3+x*0]],$
                       [[-1.61848E+3+x*0],[-1.83704E+3+x*0],[ 2.06738E+3+x*0],[ 4.00292E+3+x*0],[-3.72824E+1+x*0],[ 9.10086E+2+x*0],[ 3.72526E+3+x*0],[ 3.41895E+3+x*0],[ 1.31241E+3+x*0],[ 6.68089E+3+x*0],[-4.34269E+3+x*0],[-5.42296E+3+x*0],[ 2.83445E+3+x*0]],$
                       [[-1.00239E+3+x*0],[-1.24281E+3+x*0],[ 2.46998E+3+x*0],[-4.25837E+3+x*0],[-1.83515E+2+x*0],[-6.47138E+2+x*0],[-7.35806E+3+x*0],[-1.50866E+3+x*0],[-2.47275E+3+x*0],[ 9.09399E+3+x*0],[-2.75851E+3+x*0],[-6.75104E+3+x*0],[ 7.00899E+2+x*0]],$
                       [[ 1.04911E+3+x*0],[ 2.07475E+3+x*0],[-3.83953E+3+x*0],[ 7.79924E+2+x*0],[-4.08658E+3+x*0],[ 4.43432E+3+x*0],[ 3.23015E+2+x*0],[ 6.16180E+3+x*0],[-1.00851E+4+x*0],[ 7.65063E+3+x*0],[ 1.52880E+3+x*0],[-6.08330E+3+x*0],[ 1.23369E+3+x*0]],$
                       [[-2.61041E+2+x*0],[-7.22803E+2+x*0],[ 1.34581E+3+x*0],[ 5.90851E+2+x*0],[ 3.32198E+2+x*0],[ 2.58340E+3+x*0],[-5.97604E+2+x*0],[-4.34018E+3+x*0],[-3.58925E+3+x*0],[ 2.59165E+3+x*0],[ 6.76140E+3+x*0],[-6.22138E+3+x*0],[ 4.40668E+3+x*0]]])


     theta_ei = transpose([[[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]],$
                           [[x*0+(10*theta)^0.],[x*0+(10*theta)^1.],[x*0+(10*theta)^2.],[x*0+(10*theta)^3.],[x*0+(10*theta)^4.],[x*0+(10*theta)^5.],[x*0+(10*theta)^6.],[x*0+(10*theta)^7.],[x*0+(10*theta)^8.],[x*0+(10*theta)^9.],[x*0+(10*theta)^10.],[x*0+(10*theta)^11.],[x*0+(10*theta)^12.]]], [1,2,0])

     Zj = transpose([[[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]], $
                     [[(0.05*x)^0.],[(0.05*x)^1.],[(0.05*x)^2.],[(0.05*x)^3.],[(0.05*x)^4.],[(0.05*x)^5.],[(0.05*x)^6.],[(0.05*x)^7.],[(0.05*x)^8.],[(0.05*x)^9.],[(0.05*x)^10.],[(0.05*x)^11.],[(0.05*x)^12.]]])
     
     G_theta_x = total(total(a_ij*theta_ei*Zj, 1), 1)

     DI_over_tau_over_theta_gt12 = x^2.0 * exp(-x) * (x-x_0) * G_theta_x
  endif

  ;;---------- Pick the region
  DI_over_tau_over_theta = DI_over_tau_over_theta_lt12
  w_gt12 = where(x gt 1.2, nw_gt12)
  
  if (nw_gt12 ne 0 and TkeV ge Tlim) then DI_over_tau_over_theta[w_gt12] = DI_over_tau_over_theta_gt12[w_gt12]

  ;;========== kinetic SZ terms
  S2 = s^2.

  C0 = 1.
  C1 = 10.+(7.*S2)/10.-(47.*xtil)/5.+(7.*xtil^2)/5.
  C2 = 25.+(11.*S2^2)/10.-(1117.*xtil)/10.+(847.*xtil^2)/10.-(183.*xtil^3)/10.+(11.*xtil^4)/10.+S2*(847./20.-(183.*xtil)/5.+(121.*xtil^2)/20.)
  C3 = 75./4.+(272.*S2^3)/105.-(21873.*xtil)/40.+(49161.*xtil^2)/40.-(27519.*xtil^3)/35.+(6684.*xtil^4)/35.-(3917.*xtil^5)/210.+(64.*xtil^6)/105.+S2^2*(6684./35.-(66589.*xtil)/420.+(192.*xtil^2)/7.)+S2*(49161./80.-(55038.*xtil)/35.+(36762.*xtil^2)/35.-(50921.*xtil^3)/210.+(608.*xtil^4)/35.)
  C4 = -75./4.+(341.*S2^4)/42.-(10443.*xtil)/8.+(359079.*xtil^2)/40.-(938811.*xtil^3)/70.+(261714.*xtil^4)/35.-(263259.*xtil^5)/140.+(4772.*xtil^6)/21.-(1336.*xtil^7)/105.+(11.*xtil^8)/42.+S2^3*(20281./21.-(82832.*xtil)/105.+(2948.*xtil^2)/21.)+S2^2*(261714./35.-(4475403.*xtil)/280.+(71580.*xtil^2)/7.-(85504.*xtil^3)/35.+(1331.*xtil^4)/7.)+S2*(359079./80.-(938811.*xtil)/35.+(1439427.*xtil^2)/35.-(3422367.*xtil^3)/140.+(45334.*xtil^4)/7.-(5344.*xtil^5)/7.+(2717.*xtil^6)/84.)

  D0 = -2./3.+(11.*xtil)/30.
  D1 = -4.+12.*xtil-6.*xtil^2+(19.*xtil^3)/30.+S2*(-3.+(19.*xtil)/15.)
  D2 = -10.+(542.*xtil)/5.-(843.*xtil^2)/5.+(10603.*xtil^3)/140.-(409.*xtil^4)/35.+(23.*xtil^5)/42.+S2^2*(-409./35.+(391.*xtil)/84.)+S2*(-843./10.+(10603.*xtil)/70.-(4499.*xtil^2)/70.+(299.*xtil^3)/42.)
  D3 = -15./2.+(4929.*xtil)/10.-(39777.*xtil^2)/20.+(1199897.*xtil^3)/560.-(4392.*xtil^4)/5.+(16364.*xtil^5)/105.-(3764.*xtil^6)/315.+(101.*xtil^7)/315.+S2^3*(-15997./315.+(6262.*xtil)/315.)+S2^2*(-4392./5.+(139094.*xtil)/105.-(3764.*xtil^2)/7.+(6464.*xtil^3)/105.)+S2*(-39777./40.+(1199897.*xtil)/280.-(24156.*xtil^2)/5.+(212732.*xtil^3)/105.-(35758.*xtil^4)/105.+(404.*xtil^5)/21.)


  fac00 = C0+theta*C1+theta^(2.)*C2+theta^3.*C3+theta^(4.)*C4
  fac01 = D0+theta*D1+theta^2.*D2+theta^3.*D3
  fac02 = 1.*Y0/3.+theta*(5.*Y0/6.+2.*Y1/3.)+theta^2*(5.*Y0/8.+3.*Y1/2.+Y2)+theta^3 *(-5.*Y0/8.+5.*Y1/4.+5.*Y2/2.+4.*Y3/3.)

  ;;Considere only vz, so P1 = vz/v = 1 and P2 = 1/2 [3 (vz/v)^2 - 1] = 1

  ;;========== Provide the results
  CASE type OF
     ;;tSZ only
     0: g_rel = f1*y0
     ;;tSZ + relativistic corrections
     1: g_rel = DI_over_tau_over_theta
     ;;kSZ only
     2: g_rel = f1*(beta/theta)
     ;;kSZ + relativistic corrections
     3: g_rel = f1*((beta^(2.)/theta)*fac02+(beta/theta)*fac00+(beta^(2.)/theta)*fac01)
     ;;tSZ + kSZ +relativistic corrections
     4: g_rel = DI_over_tau_over_theta + f1*((beta^(2.)/theta)*fac02+(beta/theta)*fac00+(beta^(2.)/theta)*fac01)
     ;;tSZ + kSZ
     5: g_rel = f1*(y0+beta/theta)
  ENDCASE

  if keyword_set(temp) then begin
     dt_sz = t0*tau*theta*g_rel/f1*1e6 ;Thermodynamic Delta_T (muKelvin) observed at z=0 (thus t0 is used)
     return, dt_sz
  endif
  
  di_sz = 2*(kb*t0)^3/hc^2*tau*theta*g_rel

  return, di_sz
end
