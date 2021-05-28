
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_improve_deglitch
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
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
; MODIFICATION HISTORY: 

pro nk_improve_deglitch, param, info, data, kidpar
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_improve_deglitch'
   return
endif

nsn   = n_elements( data)
nkids = n_elements( kidpar)

nppw = 16

;; back up input kidpar
kidpar1 = kidpar

if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
my_multiplot, 2, 3, pp, pp1, /rev, gap_x=0.05, xmin=0.03, xmargin=0.001
outplot, file=param.plot_dir+"/CM_power_spec_"+strtrim(param.scan), $
         png=param.plot_png, ps=param.plot_ps, zbuffer=param.plot_z
index = lindgen(nsn)
time = double(index)/!nika.f_sampling

for iarray=1, 3 do begin
   w1 = where( kidpar1.type eq 1 and kidpar1.array eq iarray, nw1)
   if nw1 ne 0 then begin
      ;; 1st rough estimate with all valid kids
;      myflag = data.flag[w1]
;      nk_get_cm_sub_2, param, info, data.toi[w1], myflag, $
;                       data.off_source[w1], kidpar1[w1], atm_cm
;      data.flag[w1] = myflag 
;;      atm_cm = median( data.toi[w1], dim=1)
;;     
;;      ;; Look for tiny glitches that have not been detected on
;;      ;; individual TOI's
;;      sigma2cm = dblarr(n_elements(kidpar1)) - 1 ; init to negative to make ensure the "where sigma gt ..."
;;      for i=0, nw1-1 do begin
;;         ikid = w1[i]
;;         woff = where( data.off_source[ikid] eq 1, nwoff)
;;         fit = linfit( atm_cm[woff], data[woff].toi[ikid])
;;         y = data[woff].toi[ikid] - fit[0] - fit[1]*atm_cm[woff]
;;;         np_histo, y, xh, yh, gpar, /fit, /noplot, /noprint, /force, status=status
;;;         if status eq 0 then begin
;;;            sigma2cm[ikid] = gpar[2]
;;;         endif else begin
;;         sigma2cm[ikid] = stddev(y)
;;;         endelse
;;         w = where( abs(y-avg(y)) gt 3*sigma2cm[ikid], nw)
;;         ;; Take margin w.r.t to pure gaussian noise that
;;         ;; would call for only 1% data at more than 3sigma
;;         if float(nw)/nwoff gt 0.02 then kidpar1[ikid].type=12
;;
;;         if (i mod nppw) eq 0 then wind, 1, 1, /free, /large
;;         yra = array2range(data.toi[ikid])
;;         plot,  index, data.toi[ikid], /xs, /ys, yra=yra, position=pp1[i mod nppw,*], /noerase
;;         oplot, index, fit[0] + fit[1]*atm_cm, col=150
;;         legendastro, ['ikid '+strtrim(ikid,2), $
;;                       'frac off 3sigma: '+string( float(nw)/nwoff, form='(F5.2)')], col=250
;;         if kidpar1[ikid].type eq 12 then begin
;;            oplot, [0,nsn], yra, col=250
;;            oplot, [0,nsn], reverse(yra), col=250
;;         endif
;;         if ikid eq 1103 then stop
;;      endfor
;;stop
;;      ww = where( sigma2cm[w1] gt (avg(sigma2cm[w1])+3*stddev(sigma2cm[w1])), nww)
;;      if nww ne 0 then kidpar1[w1[ww]].type = 12


      ;; Discard kids that are too far from the median mode
      iter_std = 0
      iter_std_max = 0          ; 3
;      wind, 1, 1, /free, /large
;      ww1 = !d.window
;      my_multiplot, 1, 1, ntot=iter_std_max+1, pps, pps1, /rev, gap_x=0.05, xmargin=0.001
;      my_multiplot, 1, 1, ntot=16, pp, pp1, /rev
      while iter_std le iter_std_max do begin
         w1 = where( kidpar1.type eq 1 and kidpar1.array eq iarray, nw1)
         cm = median( data.toi[w1], dim=1)
         std2cm = dblarr(nw1)
         std_red = dblarr(nw1)
         for i=0, nw1-1 do begin
;            if (i mod nppw) eq 0 then wind, 1, 1, /free, /large
            ikid = w1[i]
            fit = linfit( cm, data.toi[ikid])
            std2cm[i] = stddev( data.toi[ikid] - (fit[0]+fit[1]*cm))
            std_red[i] = std2cm[i]/stddev(data.toi[ikid])
            kidpar1[ikid].std_red = std_red[i]
            kidpar1[ikid].std2cm  = std2cm[i]
;            if ikid eq 1236 then begin
;               print, "std2cm[i], std_red[i]: ", std2cm[i], std_red[i]
;               wind, 1, 1, /f
;               plot, data.toi[ikid], /noerase, yra=array2range(data.toi[ikid]), /ys, $
;                     ytitle='iter_std '+strtrim(iter_std,2);, position=pp1[i mod nppw,*]
;               oplot, fit[0]+fit[1]*cm, col=250
;               legendastro, strtrim( [std2cm[i], std_red[i]],2), col=250
;            endif
         endfor
;         my_multiplot, 2, 2, pp, pp1, /rev, xmin=pps1[iter_std,0], xmax=pps1[iter_std,2], $
;                       ymin=pps1[iter_std,1], ymax=pps1[iter_std,3], xmargin=0.001, ymargin=0.001, /full, /dry

;         w = where( s gt (avg(std2cm) + 3*stddev(std2cm)), nw)
;         if nw ne 0 then kidpar1[w1[w]].type = 12 ; 3
         nsig_threshold_std2cm  = 3 ; 4 ; 3
         nsig_threshold_std_red = 3 ; 2 ; 3
         w = where( std2cm gt (avg(std2cm) + nsig_threshold_std2cm*stddev(std2cm)) or $
                    std_red gt (avg(std_red) + nsig_threshold_std_red*stddev(std_red)), nw)
         if nw ne 0 then kidpar1[w1[w]].type = 12 ; 3

;        wset, ww1
;        plot, std2cm, /xs, position=pp[0,0,*], title='A '+strtrim(iarray,2)+' iter_std '+strtrim(iter_std,2), /noerase, col=70
;        legendastro, 'nw1 = '+strtrim(nw1,2)
;        oplot, std2cm*0 + avg(std2cm)
;        oplot, w, std2cm[w], psym=8, col=150, syms=0.5
;        for i=-3, 3 do oplot, std2cm*0 + avg(std2cm) + i*stddev(std2cm), line=2
;        np_histo, std2cm, position=pp[0,1,*], /noerase, /fill
;
;        plot, std_red, /xs, position=pp[1,0,*], title='iter_std '+strtrim(iter_std,2), /noerase
;        oplot, std_red, col=250
;        oplot, std_red*0 + avg(std_red)
;        oplot, w, std_red[w], psym=8, col=150, syms=0.5
;        for i=-3, 3 do oplot, std_red*0 + avg(std_red) + i*stddev(std_red), line=2
;        np_histo, std_red, position=pp[1,1,*], /noerase, /fill, fcol=250, /fit
;        print, "kidpar1[1236].type: ", kidpar1[1236].type
         iter_std++
      endwhile

      junk = where(kidpar1.type eq 12, njunk) ;  or sigma2cm gt (gpar[1]+3*gpar[2]), njunk)
      message, /info, "rejected "+strtrim(njunk,2)+"/"+strtrim(nw1,2)+" kids for array "+strtrim(iarray,2)+" to derive atm_cm"
      
      ;; Improved derivation of the atmosphere template
      w11 = where( kidpar1.type eq 1 and kidpar1.array eq iarray, nw11)
      if nw11 eq 0 then begin
         message, /info, "A"+strtrim(iarray,2)+" No valid kid to compute atm_cm1 and improve deglitch => Do nothing"
      endif else begin
         myflag = data.flag[w11]
         nk_get_cm_sub_2, param, info, data.toi[w11], myflag, $
                          data.off_source[w11], kidpar1[w11], atm_cm1 ;, $w8_source=myw8
;         data.flag[w11] = myflag
         
         delvarx, deglitch_input_flag
         for myiter=0, 1 do begin
            message, /info, "myiter = "+strtrim(myiter,2)+", A"+strtrim(iarray,2)

            qd_deglitch_median, atm_cm1, param.glitch_width, param.glitch_nsigma, atm_cm_out, output_flag, $
                                deglitch_nsamples_margin=param.deglitch_nsamples_margin, debug=param.mydebug, $
                                input_flag=deglitch_input_flag
            ;;  ;           stop
;x = [-120, -60, 190, 127,  15]
;y = [  40, -20,  30, -45, -65]
            
            ;;            w0 = where( output_flag ne 0, nw0)
            ;;            wind, 2, 2, /free, /large
            ;;            nplots = 2
            ;;            my_multiplot, 1, nplots, pp, pp1, /rev
            ;;            p=0
            ;;            index = lindgen(n_elements(atm_cm1))
            ;;            xra = [3500,4500] ; [-50,100]
            ;;            plot, index, atm_cm1, /xs, /ys, position=pp1[p,*], xra=xra, title='iter on cm '+strtrim(myiter,2)
            ;;            oplot, index, atm_cm_out, col=250
            ;;            if nw0 ne 0 then oplot, index[w0], atm_cm1[w0], psym=1, col=70
            
;;              for ii=0, nw11-1 do begin &$
;;                 myikid = w11[ii] &$
;;                 print, myikid &$
;; ;;                 w = where( sqrt( (data.dra[myikid]-190)^2 + (data.ddec[myikid]-30)^2) le 25 and index le 1500, nw) &$
;;                 w = where( sqrt( (data.dra[myikid]-(-10))^2 + (data.ddec[myikid]-50)^2) le 25 and index le 1500, nw) &$
;;                 if nw ne 0 then begin &$
;;                 oplot, index[w], atm_cm1[w], psym=1, col=200, syms=0.3 &$
;;                 endif &$
;;                 endfor
;stop

            ;;             p++
            ;;             plot, atm_cm1-atm_cm_out, /xs, /ys, position=pp1[p,*], /noerase, xra=xra
            ;;             if nw0 ne 0 then oplot, w0, (atm_cm1-atm_cm_out)[w0], psym=8, col=250, syms=0.5
            ;;             plot, data.subscan, /xs, col=70, /noerase, position=pp1[p,*]

            atm_cm1 = atm_cm_out
            deglitch_input_flag = output_flag
         endfor

         ;; Now treat TOI's where glitches have been found on
         ;; the common mode

;;          message, /info, "fix me: adding a glitch"
;;          output_flag[200] = 1
;;          data[200].toi += 4
;;          stop
         
         wflag = where( output_flag ne 0, nwflag)
         if nwflag ne 0 then begin
            for i=0, nw1-1 do begin
               ikid = w1[i]
               ;; Do not deglitch bright sources ! => use the mask to
               ;; locate them on each kid toi
               wflag_k = where( output_flag ne 0 and data.off_source[ikid] eq 1, nwflag_k, compl=wk)
               if nwflag_k ne 0 then begin
                  message, /info, "found a glitch on the cm outside the mask"
               ;   stop
                  nk_add_flag, data, 0, wsample=wflag_k, wkid=ikid
                  
                  y = interpol( data[wk].toi[ikid], index[wk], index)
                  y_smooth = smooth( y, long(!nika.f_sampling)/2)

;                   delvarx, xra
;                   plot, index, data.toi[ikid], /xs, xra=xra
;                   oplot, [index[wflag_k]], [data[wflag_k].toi[ikid]], psym=1, col=250
;                   oplot, index, y, col=150
;                   oplot, index, y_smooth, col=200
;                   message, /info, "here plot"
;                   stop

                  
                  ;; Add constrained noise
                  sigma = stddev( y[wk]-y_smooth[wk])
                  data[wflag_k].toi[ikid] = y_smooth[wflag_k] + randomn( seed, nwflag_k)*sigma
               endif
            endfor
         endif
      endelse


;;       ;; Restore kidpar1.type 12 to 1 to recover all of them and try
;;       ;; to improve their decorrelation with other modes
;;       w12 = where( kidpar1.type eq 12, nw12)
;;       if nw12 ne 0 then kidpar1[w12].type = 1
   endif

   power_spec, atm_cm_out - my_baseline(atm_cm_out, base=0.01), !nika.f_sampling, pw, freq

   ;; monitor weather on a minute time scale +- 10 sec
   watm_band_1 = where( freq ge (1./(60+10)) and freq le (1./(60-10)), nwatm_band_1)
   delta_f = freq[1]-freq[0]
;   print, delta_f
;stop
   if nwatm_band_1 ne 0 then begin
      case iarray of
         1: info.result_ATM_POWER_60SEC_A1 = avg( pw[watm_band_1])
         2: info.result_ATM_POWER_60SEC_A2 = avg( pw[watm_band_1])
         3: info.result_ATM_POWER_60SEC_A3 = avg( pw[watm_band_1])
      endcase
   endif

   watm_band_2 = where( freq ge 4., nwatm_band_2)
   if nwatm_band_2 ne 0 then begin
      case iarray of
         1: info.result_ATM_POWER_4Hz_A1 = avg( pw[watm_band_2])
         2: info.result_ATM_POWER_4Hz_A2 = avg( pw[watm_band_2])
         3: info.result_ATM_POWER_4Hz_A3 = avg( pw[watm_band_2])
      endcase
   endif

   plot, time, atm_cm_out, /xs, /ys, position=pp[0,iarray-1,*], /noerase
   if defined(wflag) then begin
      if nwflag ne 0 then oplot, time[wflag], atm_cm_out[wflag], psym=1, col=250
   endif
   nika_title, info, /scan
   legendastro, 'A'+strtrim(iarray,2)

   plot_oo, freq, pw, /xs, position=pp[1,iarray-1,*], /noerase
   if nwatm_band_1 ne 0 then oplot, freq[watm_band_1], pw[watm_band_1], col=250, psym=1
   if nwatm_band_2 ne 0 then oplot, freq[watm_band_2], pw[watm_band_2], col=70,  psym=1
   legendastro, 'A'+strtrim(iarray,2)
endfor

outplot, /close, /verb


if param.cpu_time then nk_show_cpu_time, param

end
