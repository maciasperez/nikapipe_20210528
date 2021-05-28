
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_pps_time
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_pps_time, param, info, data, kidpar
; 
; PURPOSE: 
;        Improves the determination of UTC time.
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - data.X_T_UTC is modified, where "X" is any acquisition box.
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug 4th 2016: NP + AB
;-

pro nk_pps_time, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_pps_time, param, info, data, kidpar"
   return
endif

letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't']

;; ;; Sept. 16 : T box does not work and crashes this code that will help
;; ;; find the longest section between two tunings : remove if from the
;; ;; analysis for the moment
;; if !nika.run eq '18' then begin
;;    letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
;;              'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's']
;;    w = where( kidpar.acqbox eq 19, nw)
;;    if nw ne 0 then kidpar[w].type = 3
;; endif

nlett = n_elements(letter)
make_ct, nlett, ct
tags = tag_names(data)

thres = 10000 ; 1000
nsn = n_elements(data)
sample = data.sample - data[0].sample

if param.do_plot ne 0 then begin
   if param.plot_ps eq 0 and param.plot_z eq 0 and !nika.plot_window[0] lt 0 then wind, 1, 1, /free, /large, iconic = param.iconic
   my_multiplot, 5, 4, pp, pp1, /rev, gap_x=0.05, xmargin=0.05
endif

t_utc_ori_list = dblarr(nlett)
fit_list       = dblarr(nlett,2)

;outplot, file=param.plot_dir+"/diff_t_utc_raw", png=param.plot_png, ps=param.plot_ps
for j=0, nlett-1 do begin
   wtag = where( strupcase(tags) eq strupcase(letter[j])+"_PPS", nwtag)
   wutc = where( strupcase(tags) eq strupcase(letter[j])+"_T_UTC", nwutc)
   my_t_pps = dblarr(nsn)
   
   if nwtag ne 0 then begin
      ;; print, "pps time for "+letter[j]
      ;; le premier qui depasse fait origine pour n_per => c'est lui
      ;; l'origine du temps utc
      w = where( data.(wtag) gt thres, nw)

;;      if param.do_plot ne 0 then begin
;;         np_histo, data.(wutc)-data.a_t_utc, position=pp1[j,*], $
;;                   /noerase, title=strupcase(letter[j])+"_T_UTC - A_T_UTC", charsize=0.6
;;         legendastro, ['avg '+num2string( avg(data.(wutc)-data.a_t_utc)), $
;;                       'sigma '+num2string( stddev( data.(wutc)-data.a_t_utc))], $
;;                      box=0, charsize=0.6, /right
;;      endif
      
      if nw eq 0 then begin
         nk_error, info, "can't compute pps time for box "+strupcase(letter[j])
         return
      endif
      t_utc_ori_list[j] = long( (data[w[0]].(wutc)+0.5))      
      d = w - shift(w,1)
      d = d[1:*]
      np_histo, d, xhist, yhist, bin=1, xra=[-10, 80], /noplot
      tstep = min( xhist)
      nper = long( (d+tstep/2.)/tstep) ; seconds !

      my_t_pps(w(1L:*)) = my_t_pps(w(0L)) + total(nper, /cumulative)

      w2 = where( my_t_pps ne 0, nw2)
      my_t_pps[w2] -= data[w2].(wtag)*1e-6
      fit = linfit( sample[w2], my_t_pps[w2], sigma=1., chisqr=chi2)
      fit_list[j,*] = fit
;   print, ""
;   print, letter[j]
;   print, "chi2: ", chi2
;   print, "const. fit (msec): ", fit[0]*1e3
;   print, "slope (msec/sample): ", fit[1]*1e3
;      print, '1./!nika.f_sampling-fit[1] (micro sec/sample): ', (1./!nika.f_sampling-fit[1])*1e6

      ;; tester si (1./!nika.f_sampling-fit[1]) est bien tres petit
      ;; put a threshold to strawman value 0.1 msec (?)
      if (1./!nika.f_sampling-fit[1]) gt 1d-4 then begin
         txt = "pps time is not as accurate as expected for acq. box "+letter[j]
         nk_error, info, txt, status=2
      endif
   endif
endfor
outplot, /close

;; Corrected time
for j=0, nlett-1 do begin
   wtag = where( strupcase(tags) eq strupcase(letter[j])+"_PPS", nwtag)
   wutc = where( strupcase(tags) eq strupcase(letter[j])+"_T_UTC", nwutc)
;   my_t_pps = dblarr(nsn)
   
   if nwtag ne 0 then begin
      ;; subtract 0.5*sample because of Alain's convention
      new_time = t_utc_ori_list[j] + fit_list[j,0] + fit_list[j,1]*sample + 0.5*fit_list[j,1]

;;       if param.do_plot ne 0 then begin
;;          np_histo, new_time - data.a_t_utc, $
;;                    position=pp1[j,*], $
;;                    /noerase, title=strupcase(letter[j])+"_T_UTC - A_T_UTC", charsize=0.6, $
;;                    colorplot=150
;;          legendastro, ['avg '+num2string( avg(new_time - data.a_t_utc)), $
;;                        'sigma '+num2string( stddev( new_time-data.a_t_utc))], $
;;                       box=0, charsize=0.6
;;          legendastro, 'PPS correct.', /right, box=0, charsize=0.6
;;       endif

      data.(wutc) = new_time
   endif
endfor

;; ymin = 1d-2                     ; 10ms
;; ymax = 1d-2
;; if !nika.plot_window[0] lt 0 then begin
;;    wind, 2, 2, /free
;;    my_multiplot, 1, 1, pp, pp1, /rev
;;    outplot, file=param.plot_dir+"/diff_t_utc_PPSCorrected", png=param.plot_png, ps=param.plot_ps
;; endif else begin
;;    wshet, !nika.plot_window[0]
;;    my_multiplot, 1, 1, pp, pp1, /rev, $
;;                  xmin=0.03, xmax=0.4, xmargin=0.01, $
;;                  ymin=0.75, ymax=0.9, ymargin=0.01
;;    charsize = 0.6
;; endelse

;; for j=0, nlett-1 do begin
;;    wtag = where( strupcase(tags) eq strupcase(letter[j])+"_T_UTC", nwtag)
;;    wref = where( strupcase(tags) eq "A_T_UTC", nwref)
;;    if j eq 0 then begin
;;       plot, data.(wtag)-data.(wref), /xs, position=pp1[0,*], $
;;             /noerase, /ys, charsize=charsize, yra=[ymin, ymax], $
;;             title="time pps(box) - time pps(A)"
;;       nika_title, info, /all
;;    endif
;;    oplot, data.(wtag)-data.(wref), col=ct[j]
;; endfor
;; 

;; plot, data_copy.a_t_utc - data.a_t_utc
;; stop
;; plot, data_copy.d_t_utc - data.d_t_utc
;; stop
;; plot, data_copy.f_t_utc - data.f_t_utc
;; 
;; stop


end
