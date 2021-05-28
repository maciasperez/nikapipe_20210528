
pro nk_hwp_rm_4_sub, param, info, kidpar, toi, my_interpol, flag, off_source, position

nkids = n_elements( kidpar)
nsn   = n_elements( position)
ncoeff = 2 + 4*param.polar_n_template_harmonics
time = dindgen(nsn)/!nika.f_sampling

w1     = where(kidpar.type eq 1, nw1)
if nw1 ne n_elements(kidpar) then begin
   message, /info, "Here, kidpar should have the same size as toi and all kids should be type 1"
   message, /info, "it's not the case, only "+strtrim(nw1,2)+" kids have type 1"
   stop
endif

;; Build model harmonics
amplitudes = dblarr( nkids, ncoeff-2)
outtemp = dblarr( ncoeff-2, nsn)
for i=0, param.polar_n_template_harmonics-1 do begin
   outtemp[ i*4,     *] =      cos( (i+1)*position)
   outtemp[ i*4 + 1, *] = time*cos( (i+1)*position)
   outtemp[ i*4 + 2, *] =      sin( (i+1)*position)
   outtemp[ i*4 + 3, *] = time*sin( (i+1)*position)
endfor


nk_get_cm_sub_2, param, info, my_interpol, flag, off_source, kidpar, common_mode

;;          if iarray eq 1 then begin

;; wind, 1, 1, /f, /large
;; !p.multi=[0,1,2]
;; plot, time, toi[0,*], /xs, xra=xra
;; oplot, time, my_interpol[0,*], col=70
;; legendastro, 'numdet '+strtrim(kidpar[i].numdet,2)
;; leg_col = [0,70]
;; legendastro, ['toi', 'my_interpol'], col=leg_col, textcol=leg_col, line=0
;; stop

;; Subtract my_interpol and the constant to prepare HWP
;; fit outside the source
;; The constant is computed on the correct range but
;; can be subtracted everywhere
toi1 = toi - my_interpol
wkeep = where( (flag eq 0 or flag eq 2L^11) and off_source eq 1, nwkeep, compl=wmask, ncompl=nwmask)
if nwkeep eq 0 then begin
   message, /info, "No valid sample ?!"
   stop
endif
if nwmask ne 0 then toi1[wmask] = !values.d_nan
a = avg( toi1, 1, /nan)
toi1 -= (dblarr(nsn)+1)##a
if nwmask ne 0 then toi1[wmask] = 0.d0 ; remove the NaN for the next loop

;; Fit the HWPSS outside the source and on valid samples
for ikid=0, nkids-1 do begin
   temp = outtemp               ; init
   w = where( (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11) and off_source[ikid,*] eq 1, nw, compl=wout)
   if nw eq 0 then begin
      kidpar[ikid].type = 3
   endif else begin
      temp[*,wout] = 0.d0
      ata   = matrix_multiply( temp, temp, /btranspose)
      atam1 = invert(ata)
      atd        = transpose(temp) ## toi1[ikid,*]
      amplitudes = atam1##atd
;      if kidpar[ikid].numdet eq 5624 then stop
      new_fit    = outtemp##amplitudes
;;      if ikid eq 0 then begin
;;         plot, time, toi1[i,*], xra=xra, /xs
;;         oplot, time, new_fit, col=150
;;         stop
;;      endif

;; ;;      ;;------------------------------------------------------
;; ;;      ;; for HDR
;; ;;      stop
;;       npts = 360
;;       mytemplates = dblarr(ncoeff-2, 360)
;;       myomega = dindgen(npts)/npts*2*!pi
;;       for i=0, param.polar_n_template_harmonics-1 do begin &$
;;          mytemplates[ i*4,     *] =      cos( (i+1)*myomega) &$
;;          mytemplates[ i*4 + 1, *] = time*cos( (i+1)*myomega) &$
;;          mytemplates[ i*4 + 2, *] =      sin( (i+1)*myomega) &$
;;          mytemplates[ i*4 + 3, *] = time*sin( (i+1)*myomega) &$
;;       endfor
;;       myfit = mytemplates##amplitudes
;; 
;;       y = reform( toi[ikid,*]-my_interpol[ikid,*])
;;       np_histo, position*!radeg, xhist, yhist, bin=5., reverse_ind=R
;;       yavg = xhist*0.d0
;;       xavg = xhist*0.d0
;;       sigma_yavg = xhist*0.d0
;;       for i=0, n_elements(xhist)-1 do begin &$
;;          IF R[i] NE R[i+1] THEN begin &$
;;          xavg[i] = avg( position[R[R[I] : R[i+1]-1]]*!radeg) &$
;;          yavg[i] = avg(y[R[R[I] : R[i+1]-1]]) &$
;;          sigma_yavg[i] = stddev( y[R[R[I] : R[i+1]-1]])/sqrt( r[i+1]-1 - r[i]+1) &$
;;          endif &$
;;       endfor
;;       
;; ;;      outplot, file='../Tex/Figures/hwpss_2pi', png=png, ps=ps
;; ;;      plot, position*!radeg, y, psym=4, $
;; ;;            xtitle='HWP angle (deg)', ytitle='TOI-Atm (Jy/beam)', xra=[0, 360], /xs
;; ;;      oplot, position*!radeg, new_fit + a[ikid], col=250, psym=1
;; ;;      oplot, myomega*!radeg, myfit + a[ikid], col=70, thick=2
;; ;;      outplot, /close, /verb
;; ;;      stop
;; ;;      ;;--------------------------------------------------------
      
      toi[ikid,*] = toi[ikid,*] - new_fit - a[ikid]
   endelse
endfor


;; Decorrelate atmosphere and low freq noise
;; like in nk_decor_5 in total power mode
nk_subtract_templates_3, param, info, my_interpol, flag, off_source, kidpar, $
                         common_mode, atm_temp

;; wind, 1, 1, /free, /large
;; !p.multi=[0,1,2]
;; plot, time, toi
;; plot, time, atm_temp
;; !p.multi=0
;; stop

;; Subtract the cross calibrated common mode from the TOIs
toi -= atm_temp

end

  
