
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_harmonics_and_synchro
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;          nk_get_harmonics_and_synchro, param, info, data, kidpar
; 
; PURPOSE: 
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: FXD from synchro May 2021
;-

pro nk_get_harmonics_and_synchro2, param, info, data, kidpar, $
                                   coeff_arr, coeff_all

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_harmonics_and_synchro2, param, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)
param2 = param                  ; not to overwrite the input param filter options :)
param2.bandpass = 1
w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
w3 = where( kidpar.type eq 1 and kidpar.array eq 3, nw3)
nkid = n_elements( data[0].toi)

nharmonics = 4
phase_hwpss_a1 = dblarr(nharmonics)
phase_hwpss_a3 = dblarr(nharmonics)

toi = data.toi ; backup to prevent successive filtering in the main loop
array_list = [1, 3]
narrays = n_elements(array_list)
phase_hwpss = dblarr( narrays, nharmonics)

synchro = abs(data.synchro - median(data.synchro))
synchro /= max(synchro)
nrot=nint(!nika.f_sampling/info.hwp_rot_freq)

nsn = n_elements(data)
xra = [nsn/2,nsn/2+50]          ; [300,320]
cos_sin = dblarr(2,nsn)
coeff_all = dblarr(2*nharmonics, nkid)
coeff_arr = dblarr(2*nharmonics, narrays)

for iharm=0, nharmonics-1 do begin

   ;; restore original TOI
   data.toi = toi
   cos_sin[0,*] = cos( (iharm+1)*data.position)
   cos_sin[1,*] = sin( (iharm+1)*data.position)
   for ia=0, narrays-1 do begin
      iarray = array_list[ia]
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      if nw1 eq 0 then begin
         nk_error, info, "No valid kid for array "+strtrim(iarray,2)
         return
      endif
   
      ;; Select one harmonic
      ;; param2.freqlow  = (iharm+1)*info.hwp_rot_freq - 1.d0
      ;; param2.freqhigh = (iharm+1)*info.hwp_rot_freq + 1.d0
      ;; nk_bandpass_filter_2, param2, info, data, kidpar

      ;; Median mode
      med = median( data.toi[w1], dim=1)
      med = med-smooth(med, nrot)
      ;; Compute phase of the median mode vs the nominal HWP angle
      c = regress( cos_sin, med, /double)
      coeff_arr[iharm*2:(iharm*2+1), ia] = c
      norm = sqrt(c[0]^2+c[1]^2)
      phase_hwpss[ia,iharm] = atan(c[1]/norm,c[0]/norm)*!radeg

      for iw = 0, nw1-1 do coeff_all[iharm*2:(iharm*2+1), w1[iw]] = $
          regress( cos_sin, data.toi[w1[iw]], /double)
;;      ;; Display results
;;      make_ct, nw1, ct
;;      yra = minmax(data[xra[0]:xra[1]].toi[w1]) + [-1,1]*0.2*(max(data[xra[0]:xra[1]].toi[w1])-min(data[xra[0]:xra[1]].toi[w1]))
;;      loadct, 1
;;      if param.plot_ps eq 0 then wind, 1, 1, /free, /large
;;      outplot, file=param.plot_dir+'/harmonic'+strtrim(iharm+1,2)+'_A'+$
;;               strtrim(iarray,2)+'_'+param.scan, $
;;               png=param.plot_png, ps=param.plot_ps
;;      plot, data.toi[w1[0]], xra=xra, yra=yra, /ys, /xs
;;      for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;;      loadct, 39
;;      oplot, synchro*sqrt(c[0]^2+c[1]^2), col=150, thick=2
;;      oplot, c[0]*cos_sin[0,*] + c[1]*cos_sin[1,*], thick=2, col=250
;;      oplot, data.position/max(data.position)*abs(c[0]), col=200
;;      legendastro, [param.scan, "Array"+strtrim(iarray,2), $
;;                    "Harmonic # "+strtrim(iharm+1,2), 'data.position', $
;;                    'median regress', 'synchro'], $
;;                   textcol=[0,0,0,200,250,150]
;;      legendastro, 'A'+strtrim(iarray,2)+' phase['+strtrim(iharm+1,2)+'] (deg): '+$
;;                   strtrim(phase_hwpss[ia,iharm],2), /bottom
;;      outplot, /close
   ;;   if iharm eq 1 then stop
      
      ;; per kid
      for ik=0, nw1-1 do begin
         ikid = w1[ik]
         c = regress( cos_sin, data.toi[ikid], /double)
         kidpar[ikid].c0_4omega = c[0]
         kidpar[ikid].c1_4omega = c[1]
         norm = sqrt(c[0]^2+c[1]^2)
         phi = atan(c[1]/norm,c[0]/norm)*!radeg
;;         if ik eq 0 then begin
;;            print, ""
;;            print, "ikid, iharm, phi: ", ikid, iharm, phi
;;            print, kidpar[ikid].a_hwpss_phi_1, kidpar[ikid].a_hwpss_phi_2, kidpar[ikid].a_hwpss_phi_3, kidpar[ikid].a_hwpss_phi_4
;;         endif
         junk = execute( "kidpar[ikid].a_hwpss_phi_"+strtrim(iharm+1,2)+" = phi")
;;         if ik eq 0 then print, kidpar[ikid].a_hwpss_phi_1, kidpar[ikid].a_hwpss_phi_2, kidpar[ikid].a_hwpss_phi_3, kidpar[ikid].a_hwpss_phi_4
      endfor
      
;;       if iharm eq 1 then begin
;;          wind, 1, 1, /free, /large
;;          get_circular_color_table, rgb
;;          matrix_plot, kidpar[w1].nas_x, kidpar[w1].nas_y, kidpar[w1].a_hwpss_phi_2, /iso, rgb=rgb, zrange=[-180,180]
;;          stop
;;       endif
   endfor       
endfor

info.phase_hwpss_a1_1 = phase_hwpss[0,0]
info.phase_hwpss_a1_2 = phase_hwpss[0,1]
info.phase_hwpss_a1_3 = phase_hwpss[0,2]
info.phase_hwpss_a1_4 = phase_hwpss[0,3]

info.phase_hwpss_a3_1 = phase_hwpss[1,0]
info.phase_hwpss_a3_2 = phase_hwpss[1,1]
info.phase_hwpss_a3_3 = phase_hwpss[1,2]
info.phase_hwpss_a3_4 = phase_hwpss[1,3]

if param.cpu_time then nk_show_cpu_time, param

end

