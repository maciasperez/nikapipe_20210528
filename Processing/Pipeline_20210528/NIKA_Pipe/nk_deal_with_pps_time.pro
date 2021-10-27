;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_deal_with_pps_time
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_deal_with_pps_time, param, info, data, kidpar
; 
; PURPOSE: 
;        Reconstruct the correct time if needed
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - grid
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 5th, 2018: to cope with the new acquisition version
;-

pro nk_deal_with_pps_time, param, info, data, kidpar


letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u']
nboxes = n_elements(letter)
tags = tag_names(data)

if strupcase(!nika.acq_version) eq "V1" or strupcase(!nika.acq_version) eq "ISA" then begin
   ;; unpolarized version of the acquisition and before March 2018 (< run29)
   ;; used to be in nk_getdata
   ;;
   ;; Must be done before restore pointing because t_utc is used for
   ;; interpolation in restore_pointing
   if param.pps_time eq 1 then begin
      if !nika.run gt 22 then begin
         for ibox =0, nboxes-1 do begin
            wpps = where( strupcase(tags) eq strupcase(letter[ibox])+"_O_PPS", npps)
            wutc = where( strupcase(tags) eq strupcase(letter[ibox])+"_T_UTC", nwutc)
            if nwutc ne 0 and npps ne 0 then begin
               data.(wutc) = data.A_O_PPS
               if param.scanamnika ne 0 then begin
                  message, /info, "fix me: this section should not be bypassed"
                  message, /info, "this is a temporary test on old data"
                  stop
               endif else begin
                  ;; stop if we have time differences above 100 micro seconds
                  if max(abs(data.(wpps) - data.A_O_PPS))*1e6 gt 100.0 then begin
                     txt_message = 'Large differences in the PPS time between boxes'
                     message, /info, txt_message
                     nk_error, info, txt_message, status=2
                  endif
               endelse
            endif
         endfor
      endif else begin
         nk_pps_time, param, info, data, kidpar
      endelse
   endif
endif else begin
;; Acquisitions V2 and V3
   wtime  = where( strupcase(tags) eq "A_TIME", nwtime)
   if nwtime eq 0 then begin
      message, /info, "Missing A_TIME in data ?! I can't go on from here."
      stop
   endif
   wutc   = where( strupcase(tags) eq "A_T_UTC", nwutc)
   if nwutc eq 0 then begin
      message, /info, "Missing A_T_UTC in data ?! I can't go on from here."
      stop
   endif
   data.(wutc) = data.(wtime)
endelse

letter = ['b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't','u']
nlett = n_elements(letter)
make_ct, nlett, ct
tags = tag_names(data)

for j=0, nlett-1 do begin
   if strupcase(!nika.acq_version) eq "V1" then begin
      wtag = where( strupcase(tags) eq strupcase(letter[j])+"_O_PPS", nwtag)
      wref = where( strupcase(tags) eq "A_O_PPS", nwref)
   endif else begin
      wtag = where( strupcase(tags) eq strupcase(letter[j])+"_TIME_PPS", nwtag)
      wref = where( strupcase(tags) eq "A_TIME_PPS", nwtag)
   endelse
   if nwtag ne 0 then begin
      dt_max = max( abs( data.(wtag)-data.(wref)))
      ww = where( tag_names(info) eq "BOX_TIME_DIFF_MSEC_A"+strupcase(letter[j]), nww)
      info.(ww) = dt_max*1000
   endif
endfor

if param.do_plot ne 0 and strupcase(!nika.acq_version) ne "ISA" then begin
   
   if param.plot_ps eq 0 and param.plot_z eq 0 then begin
      ymin = -1d-4               ; 100 micro secondes
      ymax =  1d-4
      if !nika.plot_window[0] lt 0 then begin
         if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 2, 2, /free
         my_multiplot, 1, 1, pp, pp1, /rev
      endif else begin
         if param.plot_ps eq 0 and param.plot_z eq 0 then wset, !nika.plot_window[0]
         my_multiplot, 1, 1, pp, pp1, /rev, $
                       xmin=0.03, xmax=0.4, xmargin=0.01, $
                       ymin=0.85, ymax=0.95, ymargin=0.01
         charsize = 0.6
         wshow, !nika.plot_window[0], icon = param.iconic  ; FXD
      endelse
      for j=0, nlett-1 do begin
         if strupcase(!nika.acq_version) eq "V1" then begin
            wtag = where( strupcase(tags) eq strupcase(letter[j])+"_O_PPS", nwtag)
            wref = where( strupcase(tags) eq "A_O_PPS", nwref)
         endif else begin
            wtag = where( strupcase(tags) eq strupcase(letter[j])+"_TIME_PPS", nwtag)
            wref = where( strupcase(tags) eq "A_TIME_PPS", nwtag)
         endelse
         if j eq 0 then begin
            plot, (data.(wtag)-data.(wref))*1000, /xs, position=pp1[0,*], $
                  /noerase, /ys, charsize=charsize, yra=[ymin, ymax]*1000
            legendastro, "time pps(box) - time pps(A) (msec)"
            nika_title, info, /all
         endif
         if nwtag ne 0 then begin
            oplot, data.(wtag)-data.(wref), col=ct[j]
            dt_max = max( abs( data.(wtag)-data.(wref)))
            if dt_max gt 0.1 then begin
               legendastro, 'Box '+strtrim(letter[j],2)+" shows "+string( dt_max*1d3,form='(F6.2)')+" ms diff", $
                            charthick=2, textcol=250, /right
            endif
         endif
      endfor
   endif
endif

;; Commented by JFMP. I am not sure of what is the problem
;if param.do_plot ne 0 and param.plot_z eq 0 then wshow,!window, icon = param.iconic

end
