
pro bt_nika_beam_guess, noplot=noplot, absurd=absurd

common bt_maps_common

w1 = where( kidpar.type eq 1, nw1)

;; method = "mpfit"                ; "myfit"
method = 'GAUSS2D'
beam_guess, disp.map_list, $
            disp.xmap, $
            disp.ymap, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=disp.rebin_factor, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method=method

;; Update COMMON variables
kidpar.x_peak  = x_peaks_1
kidpar.y_peak  = y_peaks_1
kidpar.x_peak_azel  = x_peaks_1
kidpar.y_peak_azel  = y_peaks_1

ww = where( sigma_y_1 ne 0., nww)
if nww ne 0 then kidpar[ww].ellipt = sigma_x_1[ww]/sigma_y_1[ww]

;; ;; discard outlyers
;; w = where( kidpar.fwhm gt 50, nw)
;; if nw ne 0 then kidpar[w].type = 5
;; w = where( kidpar.ellipt gt 3, nw)
;; if nw ne 0 then kidpar[w].type = 5
;; w = where( kidpar.type ne 1, nw)
;; if nw ne 0 then kidpar[w].plot_flag = 1

disp.beam_list = beam_list_1

;; Compute also in Nasmyth to avoid pixelization errors that sometimes finds
;; beams way out of the Focal Plane
beam_guess, disp.map_list_nasmyth, $
            disp.xmap_nasmyth, $
            disp.ymap_nasmyth, kidpar, $
            x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
            beam_list_1, theta_1, rebin=disp.rebin_factor, $
            verbose=verbose, parinfo=parinfo, noplot=noplot, $
            method=method

;; Update COMMON variables
kidpar.x_peak_nasmyth = x_peaks_1
kidpar.y_peak_nasmyth = y_peaks_1
kidpar.a_peak  = a_peaks_1
kidpar.sigma_x = sigma_x_1
kidpar.sigma_y = sigma_y_1
kidpar.fwhm    = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
kidpar.theta   = theta_1

if keyword_set(absurd) then begin
   w = where( finite(kidpar.fwhm) ne 1 or kidpar.fwhm gt 1e3, nw)
   if nw ne 0 then begin
      kidpar[w].type = 8
      kidpar[w].plot_flag = 1
   endif
   w = where( finite(kidpar.a_peak) ne 1 or abs(kidpar.a_peak) gt 10*median( kidpar[w1].a_peak), nw)
   if nw ne 0 then begin
      kidpar[w].type = 8
      kidpar[w].plot_flag = 1
   endif
   w = where( finite(kidpar.x_peak_nasmyth) ne 1 or abs(kidpar.x_peak_nasmyth) gt 300, nw)
   if nw ne 0 then begin
      kidpar[w].type = 8
      kidpar[w].plot_flag = 1
   endif
   w = where( finite(kidpar.y_peak_nasmyth) ne 1 or abs(kidpar.y_peak_nasmyth) gt 300, nw)
   if nw ne 0 then begin
      kidpar[w].type = 8
      kidpar[w].plot_flag = 1
   endif

   w = where( finite(kidpar.x_peak_azel) ne 1 or abs(kidpar.x_peak_azel) gt 300, nw)
   if nw ne 0 then begin
      kidpar[w].type = 8
      kidpar[w].plot_flag = 1
   endif
   w = where( finite(kidpar.y_peak_azel) ne 1 or abs(kidpar.y_peak_azel) gt 300, nw)
   if nw ne 0 then begin
      kidpar[w].type = 8
      kidpar[w].plot_flag = 1
   endif
endif

w1 = where( kidpar.type eq 1)
wind, 1, 1, /f, xs=900
!p.multi=[0,2,1]
plot, kidpar[w1].x_peak_azel,    kidpar[w1].y_peak_azel, /iso, psym=1, title='Az,el'
plot, kidpar[w1].x_peak_nasmyth, kidpar[w1].y_peak_nasmyth, /iso, psym=1, title='Nasmyth'
!p.multi=0

;; Checklist status
operations.beam_guess_done = 1

end

