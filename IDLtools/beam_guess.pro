pro beam_guess, map_list, xmap, ymap, kidpar, x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, beam_list, theta, const, $
                rebin=rebin_factor, noplot=noplot, verbose=verbose, method=method, p_start=p_start, err=err, parinfo=parinfo, $
                circular=circular, type=type, nhits=nhits, riemann=riemann, $
                cpu_time=cpu_time, silent=silent, map_list_nhits=map_list_nhits

t0 = systime(0,/sec)
if not keyword_set(type) then type = [1]

if not keyword_set(rebin_factor) then rebin_factor = 1
nkids = n_elements( map_list[*,0,0])

if not keyword_set(nhits) then nhits = xmap*0.d0 + 1.d0

x_peaks  = replicate(!values.d_nan, nkids) ; dblarr( nkids) + !undef
y_peaks  = replicate(!values.d_nan, nkids) ; dblarr( nkids) + !undef
a_peaks  = replicate(!values.d_nan, nkids) ; dblarr( nkids)
sigma_x  = replicate(!values.d_nan, nkids) ; dblarr( nkids)
sigma_y  = replicate(!values.d_nan, nkids) ; dblarr( nkids)
theta    = replicate(!values.d_nan, nkids) ; dblarr( nkids)
const    = replicate(!values.d_nan, nkids) ; dblarr( nkids)
beam_snr = replicate(!values.d_nan, nkids) ; dblarr( nkids)
flux_1   = replicate(!values.d_nan, nkids) ; dblarr( nkids)

nx_raw = n_elements( map_list[0,*,0])
ny_raw = n_elements( map_list[0,0,*])

if not keyword_set(method) then method = 'NIKA'

beam_list = dblarr( nkids, nx_raw, ny_raw)

xx   = reform(xmap[*,0])
yy   = reform(ymap[0,*])

reso = xmap[1,0] - xmap[0,0]

;; place holder
nk_default_info, info

w1 = where( kidpar.type eq 1, nw1)
;save, file='beammap.save'
;stop
for i=0, nw1-1 do begin
   ikid = w1[i]
   if not keyword_set(silent) then percent_status, ikid, nw1, 5, bar=bar, title='Beam fitting...'

   if keyword_set(map_list_nhits) then nhits = reform( map_list_nhits[ikid,*,*], nx_raw, ny_raw)
   
   map_raw        = reform( map_list[ikid,*,*], nx_raw, ny_raw)
   wgood = where( finite(map_raw) eq 1 and nhits ne 0, compl=wundef, ncompl=nwundef)
   map2fit        = xmap*0.d0
   map2fit[wgood] = map_raw[wgood]
   
   measure_errors = map2fit*0.d0
   measure_errors[wgood] = 1./sqrt(nhits[wgood])
   if nwundef ne 0 then measure_errors[wundef] = 1000.*max(measure_errors[wgood])
   
   case strupcase(method) of
      "MPFIT":begin
         ;; Force circular to correct for the wire in lab data
         fit  = mpfit2dpeak( map2fit, a, xx, yy, /tilt, /gauss, /circular)
      end
      "GAUSS2D":begin
         ;; set to 0 the undef values to maintain compatibility with gauss2dfit
         fit = gauss2dfit( map2fit, a, xx, yy, /tilt)
      end
      "NIKA":begin
         junk = nika_gauss2dfit( map2fit[wgood], xmap[wgood], ymap[wgood], measure_errors[wgood], a, parinfo=parinfo)
      end
   endcase
   
   const[  ikid] = a[0]
   a_peaks[ikid] = a[1]
   x_peaks[ikid] = a[4]
   y_peaks[ikid] = a[5]
   sigma_x[ikid] = a[2]
   sigma_y[ikid] = a[3]
   theta[  ikid] = a[6]

   ;;====================
   ;; junk = nika_gauss2dfit( map2fit[wgood], xmap[wgood], ymap[wgood], measure_errors[wgood], a, parinfo=parinfo)
   ;; iter1 = map_raw*0.d0
   ;; iter1[wgood] = junk

   ;; delvarx, parinfo
   ;; junk = nika_gauss2dfit( (map2fit-iter1)[wgood], xmap[wgood], ymap[wgood], measure_errors[wgood], a, parinfo=parinfo)
   ;; iter2 = iter1*0.d0
   ;; iter2[wgood] = junk
   
   ;; wind, 1, 1, /free, /large
   ;; my_multiplot, 1, 1, ntot=6, pp, pp1, /rev
   ;; dp = {noerase:1, xmap:xmap, ymap:ymap, imrange:[-1,1]*100}
   ;; imview, map_raw,       dp=dp, position=pp1[0,*]
   ;; imview, iter1,         dp=dp, position=pp1[1,*], title='1st fit'
   ;; imview, iter1-map_raw, dp=dp, position=pp1[2,*], title='diff'
   ;; imview, iter2,         dp=dp, position=pp1[3,*], title='2nd fit'
   ;; imview, iter1+iter2-map_raw, dp=dp, position=pp1[4,*], title='1+2-raw'

   ;;====================
















   
;;       ;;-------------------------------
;;       ;; try to iterate on 4G
;;       message, /info, "fix me: fitting 4 gaussians per kid"
;;       map_var = map2fit*0.d0
;;       map_var[wgood] = 1.d0/nhits[wgood]
;; 
;;       ;; restrict to a fraction of the map close to the 1st estimate
;;       rmax = 15.d0 ; 70.d0              ; to try
;;       w = where( abs(xmap[*,0]-a[4]) le rmax)
;;       x1 = min(w)
;;       x2 = max(w)
;;       w = where( abs(ymap[0,*]-a[5]) le rmax)
;;       y1 = min(w)
;;       y2 = max(w)
;; 
;;       ngauss = 4
;; 
;;       map2fit = map2fit[x1:x2,y1:y2]
;;       map_var = map_var[x1:x2,y1:y2]
;;       map_tot = map2fit*0.d0
;;       xmapfit = xmap[   x1:x2,y1:y2]
;;       ymapfit = ymap[   x1:x2,y1:y2]
;;       map_list = dblarr(ngauss,x2-x1+1,y2-y1+1)
;; 
;; 
;;       gauss_params = dblarr(3,ngauss,7)
;;       iarray = 1 ; place holder
;;       wind, 1, 1, /free, /large
;;       my_multiplot, 1, 1, pp, pp1, /rev, ntot=ngauss+3
;;       print, "HERE"
;;       stop
;;       for i=0, ngauss-1 do begin
;;          map = map2fit - map_tot
;;          nk_fitmap, map, map_var, xmapfit, ymapfit, output_fit_par
;;          map1 = nika_gauss2( xmapfit, ymapfit, output_fit_par)
;;          fwhm = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
;;          imview, map1,  xmap=xmapfit, ymap=ymapfit, title=strtrim(i+1,2)+"th gaussian", /noerase, xra=xra, yra=yra, $
;;                  legend_text = ['A'+strtrim(iarray,2), $
;;                                 'Const: '+strtrim(output_fit_par[0],2), $
;;                                 'Ampl: '+strtrim(output_fit_par[1],2), $
;;                                 'FWHM: '+strtrim(fwhm,2)], leg_color=255, position=pp1[i,*], charsize=charsize
;;          map_tot += map1
;;          map_list[i,*,*] = map1
;;          gauss_params[iarray-1,i,*] = output_fit_par
;;          stop
;;       endfor
;;       imview, map_tot, xmap=xmapfit, ymap=ymapfit, title="total", /noerase, xra=xra, yra=yra, $
;;               position=pp1[ngauss,*], imrange=[-1,5]
;;       imview, input_map, xmap=xmapfit, ymap=ymapfit, title="raw", /noerase, xra=xra, yra=yra, $
;;               position=pp1[ngauss+1,*], imrange=[-1,5]
;;       imview, input_map-map_tot, xmap=xmapfit, ymap=ymapfit, title="raw-total", /noerase, xra=xra, yra=yra, $
;;               position=pp1[ngauss+2,*]
;;       my_multiplot, /reset
;;       message, /info, "First fit in 4 gaussians done"
;;       stop
;; 
;;       ;;--------------------------------------
;; 

endfor

if not keyword_set(noplot) then matrix_display, beam_list, kidpar=kidpar
t1 = systime(0,/sec)
cpu_time = t1-t0

end
