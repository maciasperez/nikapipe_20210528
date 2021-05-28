

pro give_noise_estim

common ql_maps_common

logsm = 0.02

w1 = where( kidpar.type eq 1, nw1)

;;----------------------------------------------------------------------------------
;; Look for the most quiet minute of data on a few valid kids to estimate the noise 
n_2mn = 2*60.*!nika.f_sampling
nsn_noise = 2L^round( alog(n_2mn)/alog(2))

nkids_noise = 5 < nw1
nu_noise_ref = 5. ;; Hz

rms_res = [0.d0]
noise_ref_hz = [0.d0]

ixp = 0
while (ixp+nsn_noise-1) lt nsn do begin

   nn = 0.d0
   rr = 0.d0
   for i=0, nkids_noise-1 do begin
      ikid = w1[i]
      d = reform( toi[ikid,ixp:ixp+nsn_noise-1])
      power_spec, d, !nika.f_sampling, pw, freq, logsm=logsm
      w = where( abs(freq-nu_noise_ref) lt 0.05, nw)
      
      nn += avg(pw[w])
      rr += stddev( d)
   endfor

   noise_ref_hz = [noise_ref_hz, nn]
   rms_res      = [rms_res, rr]

   ixp += nsn_noise
endwhile

noise_ref_hz = noise_ref_hz[1:*]
rms_res      = rms_res[1:*]

;; w = where( noise_ref_hz eq min(noise_ref_hz))
;; print, "min noise_ref_hz: ", w

w = where( rms_res eq min(rms_res))
;; print, "min rms: ", w

;;----------------------------------------------------------------------------------
;; Compute noise estimates on this cleanest chunk
ixp = w[0]*nsn_noise
noise_estim_5hz_nodecorr  = dblarr(nkids)
noise_estim_05hz_nodecorr = dblarr(nkids)
noise_estim_decorr        = dblarr(nkids)

nfreq = n_elements(freq)
pw_nodecorr = dblarr( nw1, nfreq)
pw_decorr   = dblarr( nw1, nfreq)

for i=0, nw1-1 do begin
   ikid = w1[i]
   
   ;; Sans decorreler
   d = reform( toi[ikid,ixp:ixp+nsn_noise-1])
   d -= my_baseline(d)
   power_spec, d, !nika.f_sampling, pw, freq, logsm=logsm
   pw_nodecorr[i,*] = pw

   w = where( abs(freq-nu_noise_ref) lt 0.05, nw)
   noise_estim_5hz_nodecorr[ikid] = avg( pw[w])

   w = where( abs(freq-0.5) lt 0.05, nw)
   noise_estim_05hz_nodecorr[ikid] = avg( pw[w])

   ;; En decorrelant
   templates = dblarr( nw1-1, nsn_noise)
   p = 0
   for j=0, nw1-1 do begin
      if j ne i then begin
         templates[p,*] = toi[w1[j],ixp:ixp+nsn_noise-1]
         p +=1
      endif
   endfor
   c = regress( templates, d, /double, yfit=yfit)
   d -= yfit
   power_spec, d, !nika.f_sampling, pw, freq, logsm=logsm

   pw_decorr[i,*] = pw

   noise_estim_decorr[ikid] = avg( pw)
endfor

;;----------------------------------------------------------------------------------
;; Final result in meaningful units

response = 1000.*t_planet/a_peaks_1 ; mK/Hz

noise_estim_5hz_nodecorr *= response ; to go from Hz/sqrt(Hz) to K/sqrt(Hz)
noise_estim_decorr       *= response ; to go from Hz/sqrt(Hz) to K/sqrt(Hz)

wind, 1, 1, /free, ys=900
p_old = !p.charsize
!p.charsize = 2
!p.multi=[0,1,4]
n_histwork, response[w1], bin=0.3*stddev(response[w1]), xxg, yyg, gpar, /fill, fcol=250, /fit
legendastro, 'Response (mK/Hz)'
avg_response = gpar[1]
std_response = gpar[2]

n_histwork, noise_estim_5hz_nodecorr[w1], xxg, yyg, gpar, bin=0.3*stddev(noise_estim_5hz_nodecorr[w1]), /fill, /fit
legendastro, '5Hz no decorr mK/sqrt(Hz)'
avg_noise_estim_5hz_nodecorr = gpar[1]
std_noise_estim_5hz_nodecorr = gpar[2]

n_histwork, noise_estim_05hz_nodecorr[w1], xxg, yyg, gpar, bin=0.3*stddev(noise_estim_05hz_nodecorr[w1]), /fill, /fit
legendastro, '0.5hz no decorr mK/sqrt(Hz)'
avg_noise_estim_05hz_nodecorr = gpar[1]
std_noise_estim_05hz_nodecorr = gpar[2]

n_histwork, noise_estim_decorr[w1], bin=0.3*stddev(noise_estim_decorr[w1]), xxg, yyg, gpar, /fill, /fit
legendastro, 'Avg decorr mK/sqrt(Hz)'
avg_noise_estim_decorr = gpar[1]
std_noise_estim_decorr = gpar[2]
!p.multi=0
!p.charsize = p_old

;; Diagramme des spectres de bruit

xmap_x = pw_decorr*0.
ymap_x = pw_decorr*0.
for i=0, nw1-1 do xmap_x[i,*] = i
for j=0, nfreq-1 do ymap_x[*,i] = freq[i]

xtitle='Valid kids'
ytitle='Freq'

my_multiplot, 2, 1, pp, pp1, /rev
wind, 1, 1, /free, /large

;imview, pw_nodecorr, xmap=xmap_x, ymap=ymap_x, position=pp1[0,*], title='No Decorr'
;imview, pw_decorr,   xmap=xmap_x, ymap=ymap_x, position=pp1[1,*], title='No Decorr', /noerase

imview, pw_nodecorr, position=pp1[0,*], title='No Decorr', imrange=minmax( pw_nodecorr[0,*]), $
        xtitle=xtitle, ytitle=ytitle
imview, pw_decorr,   position=pp1[1,*], title='Decorr', imrange=minmax( pw_decorr[0,*]), /noerase, $
        xtitle=xtitle, ytitle=ytitle




end
