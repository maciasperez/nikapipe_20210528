
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_skydip_5
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_skydip_5, scan_num, day, param, info, kidpar, data
; 
; PURPOSE: 
;        Computes c0 and c1 coefficents of each kid on a DIY scan type.
;        These c0  and c1 coeffs will then be used in nk_get_opacity.pro
; 
; INPUT: 
;        - scan_num: scan number
;        - day: scan day
;        - param: the reduction parameters structure
;        - info: the pipeline information structure
;        - kidpar: the general NIKA structure containing kid related information
; 
; OUTPUT: 
;        - data: data.toi is modified
;        - kidpar is modified from the input kidpar (= read from data
;          or imposed with param.force_kidpar mechanism),
;           with c0 and c1 obtained from the skydip
;          one scan solution
;        - kidout is the solution with c1 fixed only (only c0 is
;          modified with respect to the input kidpar)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Jan 2017 FXD: start from skydip_4 and
;        allow for change of background (Run7 vs
;          Run6), include keyword kidout with c1 fixed option
;-
pro nk_skydip_5, scan_num, day, param, info, kidpar, data, dred, $
                 input_kidpar_file = input_kidpar_file, $
                 raw_acq_dir=raw_acq_dir,  kidout = kidout, $
                 medc1_1mm, medc1_2mm


;Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/Logbook/Scans/"+day+"s"+strtrim(scan_num,2)
if file_test( /dir, output_dir) eq 0 then spawn, "mkdir -p "+output_dir
Tatm = 270.D0 ; K
;
; read data
scanname = strtrim(day, 2)+ 's' + strtrim(scan_num, 2)
if not keyword_set( param) then nk_default_param, param
if not keyword_set( info) then nk_default_info, info
;;nk_init_info, param, info

; Use now
info.status = 0
;param.silent= 1
;param.do_plot=0 ; no plot
param.math = 'RF' ; 'CF' is not appropriate for skydips as it flags a lot of kids (there is one circle per subscan, that is why). FXD Apr 2021
param.make_imbfits = 0
; Keep iq
param.fine_pointing =  0
param.imbfits_ptg_restore =  1  ; 0=default
param.skydip = 1
;; Update param for the current scan
;nk_update_scan_param, scanname, param, info
param.scan = strtrim(day,2)+"s"+strtrim(scan_num,2)
nk_update_param_info, param.scan, param, info, xml=xml, katana=katana, raw_acq_dir=raw_acq_dir

;; Compute df_tone in the latest way
param.renew_df = 2  ;2 default

;; Get the data and KID parameters
if keyword_set(input_kidpar_file) then begin
   param.file_kidpar =  input_kidpar_file
   param.force_kidpar =  1
endif

nk_getdata, param, info, data, kidpar, polar=param.polar

if info.status eq 2 then info.status = 0  ; reset status (changed to 2 by nk_deal_with_pps_time, FXD April 30 2020)

kidout = kidpar

;; if info.status ne 0 then return
if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif


indkid1 = where( kidpar.type eq 1 and kidpar.lambda lt 1.5)
indkid2 = where( kidpar.type eq 1 and kidpar.lambda gt 1.5)

; Recompute the angle between i,q and di,dq +pi/2
ang = nk_angleiq_didq(data)

w1 = where(kidpar.type eq 1)

;;--------------------------------------
;; Plot Ftone and tunings
;; Count electronic boxes
nbox=0
for i=0, 30 do begin
   w = where( kidpar.acqbox eq i, nw)
   if nw ne 0 then nbox++
endfor

;; display only one electronic box for clarity in RTA
if param.plot_ps eq 0 and !nika.plot_window[0] lt 0 then wind, 1, 1, /free, /large, iconic=param.iconic
dy = max(data.el) - min(data.el)
yra = minmax(data.el) + [-0.2, 0.2]*dy
y1 = min(yra)
y2 = min(yra) + 0.5*(max(yra)-min(yra))
messages = ['scanLoaded:1']                & dy = [y1]     & ct = [!p.color]       & line = [0]
messages = [messages, 'scanStarted:2']     & dy = [dy, y2] & ct = [ct, !p.color]   & line = [line, 0]
messages = [messages, 'scanDone:3']        & dy = [dy, y1] & ct = [ct, !p.color]   & line = [line, 0]
messages = [messages, 'subscanStarted:4']  & dy = [dy, y2] & ct = [ct, 200]        & line = [line, 0]
messages = [messages, 'subscanDone:5']     & dy = [dy, y2] & ct = [ct, 70]         & line = [line, 0]
messages = [messages, 'scanbackOnTrack:6'] & dy = [dy, y1] & ct = [ct, 150]        & line = [line, 0]
messages = [messages, 'subscan_tuning:7']  & dy = [dy, y1] & ct = [ct, 250]        & line = [line, 0]
messages = [messages, 'scan_tuning:8']     & dy = [dy, y2] & ct = [ct, 250]        & line = [line, 2]
messages = [messages, 'scan_new_file:9']   & dy = [dy, y1] & ct = [ct, !p.color]   & line = [line, 0]

nplots = 3
nsn = n_elements(data)
index = lindgen(nsn)

;; Check that ftone varies correctly
if !nika.plot_window[0] lt 0 then begin
   my_multiplot, 5, 4, pp, pp1, /rev
   outplot, file=output_dir+"/ftone_"+param.scan, png=param.plot_png, ps=param.plot_ps
endif else begin
   my_multiplot, 5, 4, pp, pp1, /rev, $
                 xmin=0.45, xmax=0.98, xmargin=1d-3, $
                 ymin=0.03, ymax=0.95, ymargin=1d-3, /full, /dry
endelse
charsize = 0.6
col_ch_freq         = 250
col_tuning_en_cours = 200
time = dindgen(nsn)/!nika.f_sampling
;;;for ibox=0, 19 do begin  ; FXD Apr 2021 (Adapt)
ibmin = min(kidpar.acqbox)
ibmax = max(kidpar.acqbox)
for ibox=ibmin, ibmax do begin
   w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox, nw1)
   if ((ibox-ibmin) mod 5) eq 0 then ytitle='Scaled ftone' else ytitle=''
   if nw1 eq 0 then begin
      plot, [0,1], [0,1], /nodata, position=pp1[ibox-ibmin,*], /noerase, $
            ytitle=ytitle, charsize=charsize
      xyouts, 0.1, 0.4, "No valid kid in box "+strtrim(ibox,2)
      if ibox eq ibmin then nika_title, info, /scan, charsize=charsize, title='skydip'
   endif else begin
      my_ftone = median( data.f_tone[w1], dim=1)
      my_ftone -= min(my_ftone)
      xcharsize = 1d-10
      ycharsize = 1d-10
      if ((ibox-ibmin) mod 5) eq 0 then begin
         ytitle='Scaled Ftone'
         ycharsize = 0.8
      endif else begin
         ytitle=''
         ycharsize = 1d-10
      endelse
      if (ibox-ibmin) ge 15 then begin
         xtitle='Time (s)'
         xcharsize = 0.8
      endif else begin
         xtitle=''
         xcharsize = 1d-10
      endelse
      plot,  time, my_ftone, /xs, position=pp1[ibox-ibmin,*], /noerase, /ys, $
             ytitle=ytitle, charsize=charsize, xtitle=xtitle, $
             xcharsize=xcharsize, ycharsize=ycharsize
      oplot, time, data.fpga_change_frequence*max(my_ftone)/10., col=col_ch_freq
      oplot, time, data.tuning_en_cours*max(my_ftone)/10., col=col_tuning_en_cours
      legendastro, ['Box '+strtrim(ibox,2), 'change freq', 'tuning en cours'], $
                   textcol=[0,col_ch_freq, col_tuning_en_cours], chars=0.7
      if ibox-ibmin eq 0 then nika_title, info, /scan, charsize=charsize, title='skydip'
      if total(finite(my_ftone))/n_elements(my_ftone) lt 0.5 then $
         xyouts, time[0], avg(my_ftone), "NO TUNING ?!", chars=2, col=250, charthick=2
      if max(my_ftone) eq 0 then $
         xyouts, time[0], avg(my_ftone), "NO TUNING ?!", col=250, charthick=2
   endelse
endfor
outplot, /close

if info.polar ne 0 then begin
   tiling_period = 5.           ; sec
   param.hwp_harmonics_only = 1 ; not to subtract the elevation drift

   do_plot = param.do_plot
   param.do_plot = 0 ; to skip plots in hwp_rm in this case

   ;; Treat one box at a time to match nsotto (not really necessary anymore)
   for lambda=1, 2 do begin
      nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1

      if nw1 ne 0 then begin
         ;; To select kids only of the current box in nk_hwp_rm
         kidpar_temp          = kidpar
         kidpar_temp.type     = 3
         kidpar_temp[w1].type = 1
         ; FXD nov 2020, corrected the index of nsotto
         itotsotto = n_elements( data[0].nsotto)-1
         ph_min = min( data.nsotto[itotsotto,*])
         ph_max = max( data.nsotto[itotsotto,*])
         print, minmax(data.nsotto[itotsotto,*])
         
        ;;  ph_min = min( data.nsotto[lambda-1,*])
        ;;  ph_max = max( data.nsotto[lambda-1,*])
        ;;  print, minmax(data.nsotto[lambda-1,*])
        ;;  stop
          
        for iph=ph_min>0, ph_max do begin
            w = where( data.nsotto[itotsotto,*] eq iph, nw)
            ;; w = where( data.nsotto[lambda-1,*] eq iph, nw)
            
            if nw ne 0 then begin
               data1     = data[w]
               data1.toi = ang[*,w]
               ;;if iph eq 20 and lambda eq 2 then stop
               ;; if iph eq 19 and lambda eq 1 then stop
               ;;nk_hwp_rm, param, kidpar_temp, data1
               nk_hwp_rm_tiling, param, kidpar_temp, data1, amplitudes, tiling_period
               nk_hwp_rm_tiling, param, kidpar_temp, data1, amplitudes, tiling_period, /df_tone

               ;; Must loop on kids otherwise all kids of the other box are
               ;; overwritten by nk_hwp_rm_tiling's output
               for j=0, nw1-1 do begin
                  ikid = w1[j]
                  ang[ikid,w] = data1.toi[ikid]
               endfor
            endif
         endfor
      endif
   endfor
   param.do_plot = do_plot      ; restore user's choice
endif

;; ;;-------------------------------
;; message, /info, "fix me:"
;; k406 = (where( kidpar.numdet eq 406))[0]
;; k235 = (where( kidpar.numdet eq 435))[0]
;; k78  = (where( kidpar.numdet eq  78))[0]
;; 
;; wind, 1, 1, /free, /large
;; !p.multi=[0,1,2]
;; plot,  ang_ori[k406,*]
;; oplot, ang[k406,*], col=250
;; for i=0, max(data.nsotto[1,*]) do begin
;;    w = where( data.nsotto[1,*] eq i, nw )
;;    if nw ne 0 then xyouts, avg( w), 0.5, strtrim( (data.nsotto)[1,w[0]],2), col=70
;; endfor
;; w = where( data.nsotto[1] eq 20, nw)
;; oplot, w, ang[k406,w], col=150
;; w7 = where( data.nsotto[1] eq 20 and data.subscan eq 7)
;; w8 = where( data.nsotto[1] eq 20 and data.subscan eq 8)
;; oplot, w7, ang[k406,w7], col=70
;; oplot, w8, ang[k406,w8], col=100
;; 
;; plot,  ang_ori[k78,*]
;; oplot, ang[k78,*], col=250
;; for i=0, max(data.nsotto[0,*]) do begin &$
;;    w = where( data.nsotto[0,*] eq i, nw )&$
;;    if nw ne 0 then xyouts, avg( w), 0.5, strtrim( (data.nsotto)[0,w[0]],2), col=70 &$
;; endfor
;; w = where( data.nsotto[0] eq 19, nw)
;; oplot, w, ang[k78,w], col=150
;; w7 = where( data.nsotto[0] eq 19 and data.subscan eq 7)
;; w8 = where( data.nsotto[0] eq 19 and data.subscan eq 8)
;; oplot, w7, ang[k78,w7], col=70
;; oplot, w8, ang[k78,w8], col=100
;; !p.multi=0
;; stop
;; ;;------------------------------

; Apply it to one kid at a time
nkid = n_elements( kidpar)
frbarr  = dblarr( nkid)
fr2Karr = dblarr( nkid)
tauarr = dblarr( nkid)
rmsarr = dblarr( nkid)
taufarr = tauarr
rmsfarr = rmsarr
tauarrc1 = tauarr
rmsarrc1 = rmsarr
frbarrc1 = frbarr
dtarrc1 = frbarr

nsotto = data.nsotto
; Cut the small phases
pha = histogram( nsotto[0, *], reverse_ind = rpha,  locations = iloc)
for iph = 0, max( iloc) do $
   if rpha[iph] ne rpha[iph+1] and pha[ iph] lt 200 then  $
      nsotto[0, rpha[rpha[iph]: rpha[iph+1]-1]] = -1
pha = histogram( nsotto[1, *], reverse_ind = rpha,  locations = iloc)
for iph = 0, max( iloc) do $
   if rpha[iph] ne rpha[iph+1] and pha[ iph] lt 200 then  $
      nsotto[1, rpha[rpha[iph]: rpha[iph+1]-1]] = -1
itotsotto = n_elements( data[0].nsotto)-1
pha = histogram( nsotto[itotsotto, *], reverse_ind = rpha,  locations = iloc)
;;for iph = 0, max( iloc) do $
;; bug fixed, NP, June 12th, 2017
for iph = 0, n_elements(pha)-1 do $
   if rpha[iph] ne rpha[iph+1] and pha[ iph] lt 200 then  $
      nsotto[itotsotto, rpha[rpha[iph]: rpha[iph+1]-1]] = -1

usot = nsotto[ itotsotto, *]
susot = usot[ sort( usot)]
unsusot = susot[ uniq( susot)]
if n_elements( unsusot) gt 1 then begin
   unsusot = unsusot[1:*]       ; remove -1
   ndred = n_elements( unsusot)
endif else begin
   message, /info, 'Not enough subscans?'
   stop
   info.status = 1
   return
endelse

dred = replicate( data[0], ndred)
; reduced skydip to be saved 11 steps nowadays.
dred.f_tone = !values.d_nan  ; default values
dred.df_tone = !values.d_nan
dred.el = !dpi/2
drel = dblarr( ndred, nkid)
;aa = 0
;pi = dblarr(nkid,
nsn = n_elements(data)
index = lindgen(nsn)
;save, file='bidon.save'
;stop

;; Restrict to samples at constant elevation and in-between tunings
;; delvarx, ind
;; for isubscan=min(data.subscan), max(data.subscan) do begin
;;    ;; last sample to consider: last sample of the subscan
;;    ;; without tuning: start from the end, then go back as far as
;;    ;; needed (if needed...)
;;    wsub   = where( data.subscan eq isubscan, nwsub)
;;    i2     = wsub[nwsub-1]
;;    status = data[i2].tuning_en_cours
;;    while status ne 0 and i2 gt wsub[0] do begin
;;       status = data[i2].tuning_en_cours
;;       i2--
;;    endwhile
;;    
;;    ;; 1st sample to consider: last tuning of the subscan
;;    wsub_tune = where( data.subscan eq isubscan and data.tuning_en_cours ne 0, nwsub_tune)
;;    if nwsub_tune eq 0 then begin
;;       i1 = wsub[0]
;;    endif else begin
;;       i1 = wsub_tune[nwsub_tune-1]
;;       i1 += 1                   ; take margin
;;    endelse
;;    
;;    if i2 gt i1 then begin
;;       if defined(ind) eq 0 then ind = indgen(i2-i1+1)+i1 else ind = [ind, indgen(i2-i1+1)+i1]
;;    endif
;; endfor
;; nind = n_elements(ind)
;; if nind lt 200 then begin
;;    message, /info, "Less than 200 samples without tunings for this scan"
;;    message, /info, "I can't reduce it"
;;    return
;; endif
;; 
;; wind, 1, 1, /free
;; plot, index, data.el, /xs, /ys, yra=[-0.02, 1.2]
;; oplot, index, data.tuning_en_cours, col=70
;; oplot, index[ind], data[ind].el, psym=1, col=250
;; oplot, index, data.subscan/max(data.subscan), col=150, thick=2
;; stop

;save, file='bidon.save'
;stop

;; ; skydip_debug_plot, param, info, data, kidpar, ang, nsotto, itotsotto
;; wind, 1, 1, /free, /large
;; nkid = n_elements(kidpar)
;; nsn = n_elements(data)
;; index = dindgen(nsn)
;; for idet = 0, nkid-1 do begin
;;    if kidpar[ idet].type eq 1 then begin
;;       ;; restrict to stable elevation plateaux in between tunings
;;       ind = where( data.scan_valid[itotsotto] eq 0 and $
;;                    finite(data.f_tone[ idet]) and $
;;                    finite(data.df_tone[ idet]) and $
;;                    data.tuning_en_cours eq 0 and $
;;                    nsotto[itotsotto, *] ge 0 and $
;;                    abs( ang[idet, *]) le param.flag_sat_val, nind)
;; 
;;       ind = where( data.scan_valid[itotsotto] eq 0 and $
;;                    finite(data.f_tone[ idet]) and $
;;                    finite(data.df_tone[ idet]) and $
;;                    data.tuning_en_cours eq 0 and $
;;                    nsotto[itotsotto, *] ge 0, nind)
;; 
;;       print, "idet, nind: ", idet, nind
;;       !p.multi=[0,1,2]
;;       plot, index, data.el, /xs, /ys, yra=[-0.02, 1.2], title=strtrim(idet,2)
;;       oplot, index, data.tuning_en_cours, col=70
;;       oplot, index, data.scan_valid[itotsotto], col=150
;;       w = where( finite(data.f_tone[ idet]),nw)
;;       if nw ne 0 then oplot, index[w], dblarr(nw)+1, col=200 else print, "All f_tone = NaN"
;;       w = where( finite(data.df_tone[idet]),nw)
;;       if nw ne 0 then oplot, index[w], dblarr(nw)+1, col=250 else print, "All df_tone = NaN"
;;       oplot, index, data.subscan/max(data.subscan), col=150, thick=2
;;       if nind ne 0 then oplot, index[ind], data[ind].el, psym=1, col=250
;;       
;;       plot, index, /xs, abs(ang[idet,*]), title='abs(ang)'
;;       if nind ne 0 then oplot, index[ind], abs(ang[idet,ind]), psym=1, col=150
;;       !p.multi=0
;;       stop
;;    endif
;; endfor
;; 
;; message, /info, "HERE: REMOVED PREVious tests"
;; stop


for idet = 0, nkid-1 do begin
   if kidpar[ idet].type eq 1 then begin
      ;; restrict to stable elevation plateaux in between tunings
      ind = where( data.scan_valid[itotsotto] eq 0 and $
                   finite(data.f_tone[ idet]) and $
                   finite(data.df_tone[ idet]) and $
                   data.tuning_en_cours eq 0 and $
                   nsotto[itotsotto, *] ge 0 and $
                   abs( ang[idet, *]) le param.flag_sat_val, nind)

      ind = where( data.scan_valid[itotsotto] eq 0 and $
                   finite(data.f_tone[ idet]) and $
                   finite(data.df_tone[ idet]) and $
                   data.tuning_en_cours eq 0 and $
                   nsotto[itotsotto, *] ge 0, nind)

;      print, "idet, nind: ", idet, nind
      
      if nind ge 200 then begin
         am = 1/sin(data[ind].el)
         freso = data[ind].f_tone[ idet]+data[ind].df_tone[ idet]
         for iph = 0, ndred-1 do begin
            u = where( nsotto[ itotsotto, ind] eq unsusot[ iph], nu)
            if nu gt 2 then begin
               dred[iph].f_tone[ idet] = median( data[ind[ u]].f_tone[ idet])
               dred[iph].df_tone[ idet] = median( data[ind[ u]].df_tone[ idet])
               drel[iph, idet] = median( data[ind[ u]].el)
; awkward               dred[iph].el = median( data[ind[ u]].el)
            endif
            
         endfor
         taufit, am, freso, frb, fr2K, tau, frfit, rms, /silent
;         wind, 1, 1, /f
;         plot, data.f_tone[idet] + data.df_tone[idet], /xs, /ys, psym=-8
;stop
;;         ;;--------------------
;;         ;; New method
;;         ;; **** WARNING I CHANGE HERE THE KIDPAR COEFFS
;;         ;; INSTEAD OF KEEPING THEM UNCHANGED UNTIL THE END LIKE IN
;;         ;; THE STANDARD CODE ****
;;         kidpar[idet].c0_skydip = frb
;;         kidpar[idet].c1_skydip = fr2k
;;         ;;--------------------
         
         frbarr[idet] = frb
         fr2Karr[idet] = fr2K
         tauarr[idet] = tau
         rmsarr[idet] = rms
; Compute tau with c0 and c1 known
         if kidpar[idet].c1_skydip ne 0 then begin
            taufit2, am, freso, $
                     -kidpar[ idet].c0_skydip, $
                     kidpar[ idet].c1_skydip, $
                     taumedk, taumeank, frfit, rmsk, tau = tau2, /silent
            dfc1 = kidpar[ idet].c1_skydip
            taufitc1fix, am, freso, $
                         fr0, $
                         dfc1, $
                         tauc1, frfitc1, rmsfitc1, /silent

;            if idet eq 1000 then stop
            taufarr[ idet] = taumedk
            rmsfarr[ idet] = rmsk
            tauarrc1[ idet] = tauc1
            rmsarrc1[ idet] = rmsfitc1
            frbarrc1[ idet] = fr0
            dtarrc1[ idet] = -(kidpar[idet].c0_skydip+fr0)/dfc1
                                ; DeltaT in Kelvin, going from the
                                ; kidpar standard to the actual value
         endif
      endif
   endif
endfor

;plot, rmsarr
;stop
dred.el = median(drel, dim = 2)
      
; Select good kids in each band
meantau1 = 0.
meanftau1 = 0.
medtau1 = 0.
good1=where( rmsarr gt 0 and kidpar.type eq 1 and kidpar.lambda lt 1.5, ngood1)
if param.silent eq 0 then message, /info, info.scan
if ngood1 ge 2 then begin
  medtau1 = median( tauarr[ good1])
  rgood1 = where( rmsarr gt 0 and kidpar.type eq 1 and $
                  kidpar.lambda lt 1.5 and $
                  abs( tauarr-medtau1) le 0.1 and $
                  rmsarr lt 3.*median( rmsarr[ good1]), nrgood1)
  if param.silent eq 0 then message, /info, $
                                     'Number of good kids1 before/after selection '+strtrim(ngood1, 2)+', '+strtrim(nrgood1, 2)
  if nrgood1 ge 2 then begin
     meantau1 = mean( tauarr[ rgood1])
   endif
endif else begin
   nrgood1 = 0
endelse

if nrgood1 lt 0.6*ngood1 then begin
;   message, /info, 'Trouble in finding a solution for one scan '+ scanname

; Do a looser (loser) selection if too many kids are kicked out
   if ngood1 ge 2 then begin
      medtau1 = median( tauarr[ good1])
      rgood1 = where( rmsarr gt 0 and kidpar.type eq 1 and $
                      kidpar.lambda lt 1.5 and $
                      abs( tauarr-medtau1) le (medtau1+0.1) and $
                      rmsarr lt 5.*median( rmsarr[ good1]), nrgood1)
      if param.silent eq 0 then message, /info, $
                                         'Number of good kids1 before/after loose selection '+strtrim(ngood1, 2)+', '+strtrim(nrgood1, 2)
      if nrgood1 ge 2 then begin
         meantau1 = mean( tauarr[ rgood1])
      endif
   endif else begin
      nrgood1 = 0
   endelse
endif

if nrgood1 lt 0.6*ngood1 then $
   message, /info, 'Trouble in finding a solution for one scan '+ scanname


fgood1=where( rmsfarr gt 0 and kidpar.type eq 1 and $
              kidpar.lambda lt 1.5, nfgood1)
if nfgood1 ge 2 then meanftau1 = mean( taufarr[ fgood1])

cgood1=where( rmsarrc1 gt 0 and kidpar.type eq 1 and $
              kidpar.lambda lt 1.5, ncgood1)
if ncgood1 ge 2 then begin
   meanctau1 = mean( tauarrc1[ cgood1])
   meandt1 = mean( dtarrc1[ cgood1])
   dispdt1 = stddev( dtarrc1[ cgood1])
endif else begin
   meanctau1 = 0.
   meandt1 = 0.
   dispdt1 = 0.
endelse

meantau2 = 0.
meanftau2 = 0.
medtau2 = 0.
good2=where( rmsarr gt 0 and kidpar.type eq 1 and kidpar.lambda gt 1.5, ngood2)

if ngood2 ge 2 then begin
  medtau2 = median( tauarr[ good2])
  rgood2 = where( rmsarr gt 0 and kidpar.type eq 1 and $
                  kidpar.lambda gt 1.5 and $
                  abs( tauarr-medtau2) le 0.05 and $
                  rmsarr lt 3.*median( rmsarr[ good2]), nrgood2)
  if param.silent eq 0 then message, /info, $
                                     'Number of good kids2 before/' + $
                                     'after selection '+ $
                                     strtrim(ngood2, 2)+', '+ $
                                     strtrim(nrgood2, 2)
  if nrgood2 ge 2 then begin
     meantau2 = mean( tauarr[ rgood2])
  endif
endif else begin
   nrgood2 = 0
endelse 

if nrgood2 lt 0.6*ngood2 then begin
   ; message, /info, 'Trouble in finding a solution for one scan '+ scanname
   if ngood2 ge 2 then begin
      medtau2 = median( tauarr[ good2])
      rgood2 = where( rmsarr gt 0 and kidpar.type eq 1 and $
                      kidpar.lambda gt 1.5 and $
                      abs( tauarr-medtau2) le (medtau2/2+0.05) and $
                      rmsarr lt 5.*median( rmsarr[ good2]), nrgood2)
      if param.silent eq 0 then message, /info, $
                                         'Number of good kids2 before/' + $
                                         'after loose selection '+ $
                                         strtrim(ngood2, 2)+', '+ $
                                         strtrim(nrgood2, 2)
      if nrgood2 ge 2 then begin
         meantau2 = mean( tauarr[ rgood2])
      endif
   endif else begin
      nrgood2 = 0
   endelse
endif

if nrgood2 lt 0.6*ngood2 then message, /info, 'Trouble in finding a solution for one scan '+ scanname


fgood2 = where( rmsfarr gt 0 and kidpar.type eq 1 and kidpar.lambda gt 1.5, nfgood2)
if nfgood2 ge 2 then meanftau2 = mean( taufarr[ fgood2])

cgood2=where( rmsarrc1 gt 0 and kidpar.type eq 1 and $
              kidpar.lambda gt 1.5, ncgood2)
if ncgood2 ge 2 then begin
   meanctau2 = mean( tauarrc1[ cgood2])
   meandt2 = mean( dtarrc1[ cgood2])
   dispdt2 = stddev( dtarrc1[ cgood2])
endif else begin
   meanctau2 = 0.
   meandt2 = 0.
   dispdt2 = 0.
endelse

;message, /info, "fix me: forcing param.silent for a few problematic skydips ?"
;param.silent = 1

if param.silent eq 0 then begin
   message, /info, $
            'Zenith opacities are found at 1 and 2mm (&tau225):         '
   message, /info, strjoin( string(meantau1, meantau2, format = '(1F8.3)')+ ' ')+ $
            string( info.tau225, format = '(1F8.3)')

   ;; Check if there were actually non zero c0 and c1 coeff to begin with
   ;; or if it's the first call of this routine (NP, March 26th, 2015)
   if nfgood1 ne 0 or nfgood2 ne 0 then begin
      message, /info, $
               '[Input kidpar coefficients] opa. at 1 and 2mm: '
      message, /info, strjoin( string(meanftau1, meanftau2, format = '(1F8.3)')+ ' ')
      if nfgood1 ne 0 then mrms1 =  median( rmsarr[ good1]) else mrms1 = 0.
      if nfgood1 ne 0 then frms1 =  median( rmsfarr[ fgood1]) else frms1 = 0.
      if nfgood2 ne 0 then mrms2 =  median( rmsarr[ good2]) else mrms2 = 0.
      if nfgood2 ne 0 then frms2 =  median( rmsfarr[ fgood2]) else frms2 = 0.
;      if nfgood1 ne 0 then print, 'Median rms1 = ',, median( rmsfarr[ fgood1])
;      if nfgood2 ne 0 then print, 'Median rms2 = ', median( rmsarr[ good2]), median( rmsfarr[ fgood2])
   endif else begin
      mrms1 = 0.
      frms1 = 0.
      mrms2 = 0.
      frms2 = 0.
   endelse

   if ncgood1 ne 0 or ncgood2 ne 0 then begin
      message, /info, $
               '[Input kidpar coefficients] opa. at 1 and 2mm: (C1 fixed)'
      message, /info, strjoin( string(meanctau1, meanctau2, format = '(1F8.3)')+ ' ')
;      if ncgood1 ne 0 then print, 'Median rms1 = ', median( rmsarrc1[ cgood1])
;      if ncgood2 ne 0 then print, 'Median rms2 = ', median( rmsarrc1[ cgood2])
      if ncgood1 ne 0 then print, 'Mean/Disp. dt1 [K] = ', meandt1, dispdt1
      if ncgood2 ne 0 then print, 'Mean/Disp. dt2 [K] = ', meandt2, dispdt2
      crms1 =  median( rmsarrc1[ cgood1])
      crms2 =  median( rmsarrc1[ cgood2])
   endif else begin
      crms1 =  0.
      crms2 =  0.
   endelse

   print, 'Median rms fit 1 [Hz] ', mrms1, frms1, crms1
   print, 'Median rms fit 2 [Hz] ', mrms2, frms2, crms2
endif

; Update kidout with proper c0
gd1 = where( kidpar.c0_skydip ne 0. and $
             kidpar.type eq 1 and $
             kidpar.lambda lt 1.5, ngd1)
gd2 = where( kidpar.c0_skydip ne 0. and $
             kidpar.type eq 1 and $
             kidpar.lambda gt 1.5, ngd2)
medc1init_1mm = 0.
medc1init_2mm = 0.
if ngd1 ne 0 then begin
   medc1init_1mm = median( kidpar[ gd1].c1_skydip)
   kidout[ gd1].c0_skydip = $
   kidpar[ gd1].c0_skydip + $
      meandt1 * kidpar[ gd1].c1_skydip
endif

if ngd2 ne 0 then begin
   medc1init_2mm = median( kidpar[ gd2].c1_skydip)
   kidout[ gd2].c0_skydip = $
   kidpar[ gd2].c0_skydip + $
   meandt2 * kidpar[ gd2].c1_skydip
endif

if param.do_plot eq 1 then begin
   if param.rta then begin
      wind, 1, 1, /free, /large, iconic=param.iconic
      !nika.plot_window[1] = !d.window
      my_multiplot, 1, 2, pp, pp1, ymargin=0.001, xmargin=0.001, $
                    xmin=0.02, xmax=0.5, ymin=0.05, ymax=0.95
   endif
   if param.plot_ps eq 0 and !nika.plot_window[1] lt 0 then begin
      wind, 1, 1, xs = 1000, ys = 600, title = 'Opacity measurements', iconic = param.iconic
      outplot, file=output_dir+"/plot_"+param.scan, png=param.plot_png, ps=param.plot_ps
      my_multiplot, 2, 1, pp, pp1, ymargin=0.1, xmargin=0.1, xmin=0.1
   endif
   !p.multi = 0
   if nrgood1+nrgood2 ne 0 then begin
;;       plot, kidpar[[rgood1, rgood2]].numdet, tauarr[ [rgood1, rgood2]], psym = 4, $
;;             title = info.scan, $
;;             subtitle = 'Tau225 = '+string( info.tau225, format = '(1F10.3)'), $
;;             xtitle = 'Kid NumDet', ytitle = 'Zenith opacity', ysty = 1, xsty = 0, yra=[0,1.5]
;;       oplot, kidpar[indkid1].numdet, meantau1*(indkid1*0+1), psym = -3, col = 100, thick = 2
;;       oplot, kidpar[indkid2].numdet, meantau2*(indkid2*0+1), psym = -3, col = 200, thick = 2
;;       if (nfgood1 ne 0) and (nfgood2 ne 0) then $
;;          oplot, kidpar[[fgood1, fgood2]].numdet, taufarr[ [fgood1, fgood2]], psym = 2
;;       oplot, kidpar[indkid1].numdet, meanftau1*(indkid1*0+1), psym = -3, col = 100
;;       oplot, kidpar[indkid2].numdet, meanftau2*(indkid2*0+1), psym = -3, col = 200
;;       xyouts, kidpar[indkid1[0]].numdet+10, meantau1*0.7, col = 100, $
;;               'Tau1mm = '+ string(meantau1, format = '(1F8.3)')
;;       xyouts, kidpar[indkid2[0]].numdet+10, meantau2*0.7, col = 200, $
;;               'Tau2mm = '+ string(meantau2, format = '(1F8.3)')
;;       xyouts, kidpar[indkid1[0]].numdet+10, meanftau1*0.6, col = 100, $
;;               'Input kidpar coeff Tau1mm = '+ string(meanftau1, format = '(1F8.3)')
;;       xyouts, kidpar[indkid2[0]].numdet+10, meanftau2*0.6, col = 200, $
;;               'Input kidpar coeff Tau2mm = '+ string(meanftau2, format = '(1F8.3)')
     ;;;FXD 1Jul2016 wind, 1, 1, /free, /large, iconic=param.iconic
      if fix(!nika.run) le 12 then numrange = [0, 1000] else numrange = [0, 3600]
      p = 0                     ; plot init

      if nrgood1 gt 2 then begin
         plot, kidpar[rgood1].numdet, tauarr[rgood1], psym = 4, $
               title = info.scan, subtitle = 'Tau225 = '+string(info.tau225, format = '(1F10.3)'), xra = numrange, $
               xtitle = 'Kid NumDet', ytitle = 'Zenith opacity', ysty = 1, xsty = 0, yra=[0,1.5], $
               position=pp1[0,*], /nodata, /noerase
         oplot, kidpar[rgood1].numdet, tauarr[rgood1], psym = 1, col=70
         legendastro, ['Tau (input C0-C1) = '+string(meanftau1,form='(F4.2)'), $
                       'Tau (current C0-C1) = '+string(meantau1,form='(F4.2)'), $
                       'Tau (fixed C1) = '+string(meanctau1,form='(F4.2)')], $
                      textcol=[!p.color,70, 150], box=0, /right, /trad
         legendastro, '1mm', box=0, /trad
         oplot, kidpar[indkid1].numdet, meantau1*(indkid1*0+1), psym = -3, col = 100, thick = 2
         if (nfgood1 ne 0) then oplot, [kidpar[fgood1].numdet], [taufarr[fgood1]], psym=2
         oplot, kidpar[indkid1].numdet, meanftau1*(indkid1*0+1), psym = -3, col = 100

         if (ncgood1 ne 0) then oplot, kidpar[ cgood1].numdet, tauarrc1[ cgood1], psym = 5, col=150
         oplot, kidpar[indkid1].numdet, meanctau1*(indkid1*0+1), psym = -3, col = 200
;;          xyouts, kidpar[indkid1[0]].numdet+10, meantau1*0.7, col = 100, $
;;                  'Tau1mm = '+ string(meantau1, format = '(1F8.3)')
;;          xyouts, kidpar[indkid1[0]].numdet+10, meanftau1*0.6, col = 100, $
;;                  'Input kidpar coeff Tau1mm = '+ string(meanftau1, format = '(1F8.3)')

         p=1
      endif else begin
         message, /info, "nrgood1 < 2 !!"
      endelse

;      if p eq 0 then wind, 1, 1, /free, /large, iconic=param.iconic

      if nrgood2 gt 2 then begin
;         if p eq 0 then begin
         plot, kidpar[rgood2].numdet, tauarr[rgood2], psym = 4, $
               xra = numrange,$
               title = info.scan, subtitle = 'Tau225 = '+string(info.tau225, format = '(1F10.3)'), $
               xtitle = 'Kid NumDet', ysty = 1, xsty = 0, yra=[0,1.5], $ ; ytitle = 'Zenith opacity', 
               position=pp1[1,*], /noerase, /nodata, ycharsize=1e-10
         legendastro, ['Tau (input C0-C1) = '+string(meanftau2,form='(F4.2)'), $
                       'Tau (current C0-C1) = '+string(meantau2,form='(F4.2)'), $
                       'Tau (fixed C1) = '+string(meanctau2,form='(F4.2)')], $
                      textcol=[!p.color,70,150], box=0, /right, /trad
         legendastro, '2mm', box=0, /trad
;         endif else begin
            oplot, kidpar[rgood2].numdet, tauarr[rgood2], psym = 1, col=70
;         endelse
         oplot, kidpar[indkid2].numdet, meantau2*(indkid2*0+1), psym = -3, col = 100, thick = 2
         if nfgood2 gt 1 then oplot, kidpar[fgood2].numdet, taufarr[fgood2], psym=2
         
         oplot, kidpar[indkid2].numdet, meanftau2*(indkid2*0+1), psym = -3, col = 200
         if ncgood2 gt 1 then oplot, kidpar[ cgood2].numdet, tauarrc1[ cgood2], psym = 5, col=150
         oplot, kidpar[indkid2].numdet, meanctau2*(indkid2*0+1), psym = -3, col = 200         
;         xyouts, kidpar[indkid2[0]].numdet+10, meantau2*0.7, col = 200, $
;                 'Tau2mm = '+ string(meantau2, format = '(1F8.3)')
;         xyouts, kidpar[indkid2[0]].numdet+10, meanftau2*0.6, col = 200, $
;                 'Input kidpar coeff Tau2mm = '+ string(meanftau2, format = '(1F8.3)')
      endif else begin
         message, /info, "nrgood2 < 2 !!"
      endelse
   endif
   outplot, /close
endif


; Determine all linear coefficients assuming tau is now correct (linear
; correlation)
frbsarr  = dblarr( nkid)
fr2Ksarr = dblarr( nkid)
rmssarr = dblarr( nkid)

if param.do_plot eq 1 then begin
   if !nika.plot_window[2] lt 0 then begin
      my_multiplot, 2, 2, pp, pp1, /rev
      if param.plot_ps eq 0 then $
         wind, 2, 1, xs = 1400, ys = 900, title = 'c0 and c1 measurements for '+info.scan, iconic = param.iconic
      !nika.plot_window[2] = !d.window
      outplot, file=output_dir+"/plot_correl_"+param.scan, png=param.plot_png, ps=param.plot_ps
   endif else begin
      my_multiplot, 2, 2, pp, pp1, /rev, $
                    xmin=0.52, xmax=0.98, xmargin=1d-3, $
                    ymin=0.02, ymax=0.95, ymargin=1d-3
   endelse
endif


nostop = 1-param.do_plot
itot = -1
noplot = 1-param.do_plot
charsize = 0.7
erase  ; FXD Apr 30, 2020 ; was missing
for idet = 0, nkid-1 do begin
   if kidpar[ idet].type eq 1 then begin
      ind = where( finite(data.f_tone[ idet]) and $
                   finite(data.df_tone[ idet]) and $
                   nsotto[itotsotto, *] ge 0, nind)
      if kidpar[idet].lambda lt 1.5 then begin
         tau0 = meantau1    
         ftau0 = meanftau1
      endif else begin
         tau0 = meantau2
         ftau0 = meanftau2
      endelse

      if nind ge 200 then begin
         itot = itot+1
         if !nika.plot_window[2] ge 0 and (itot le 3) then begin
            position=pp1[itot,*]
         endif else begin
            delvarx, position
         endelse
         am = 1/sin(data[ind].el)
         freso =  data[ind].f_tone[ idet]+data[ind].df_tone[ idet]
;         save, file='bidon.save'
;;;         stop
         plot_correl, (1-exp(-tau0*am)), freso/1D9, $
                      title = 'Numdet = '+strtrim(kidpar[idet].numdet, 2)+ $
                      ' Color line= Reference', $
                      sl, a0, sigma, rcorr, chisqr, ycorr, $
                      /nostop, noplot = noplot , xtitle = '(1-exp(-tau0*am))', $
                      ytitle = 'Resonance frequency [GHz]', psym = 4, $
                      position=position, /noerase, charsize=charsize
         oplot, (1-exp(-ftau0*am)), $
                (-kidpar[ idet].c1_skydip*Tatm*(1-exp(-ftau0*am))- $
                kidpar[ idet].c0_skydip)/1D9, $
                col = 100, psym = -3, thick = 2
         legendastro, ['Expect. (current tau + input C0-C1)'], $
                      line=0, thick=2, col=100, box=0, /bottom, chars=0.6
         frbsarr[idet]  = a0*1D9
         fr2Ksarr[idet] = sl*1D9
         rmssarr[idet]  = stddev( ycorr)

         ;;---------------------
         ;; plot for the commissioning report
         if param.commissioning_plot eq 1 then begin
            nparams = 3
            parinfo = replicate({fixed:0, limited:[1,1], $
                                 limits:[0.,0.D0]}, nparams)
            p_start = [1., 1., 0.3]
            delvarx, e_r
            parinfo[0].limits=[-10, 10]
            parinfo[1].limits=[-1,1]*10
            parinfo[2].limits=[0,2]
            silent=1
            delvarx, myfit
            myfit = mpfitfun("my_tau_model_2", 1.d0/sin(data[ind].el), -freso/1d9, $
                             e_r, p_start, quiet = silent, $
                             parinfo=parinfo)
            wind, 1, 1, /free, /large
            ps = 1
            !p.multi=0
            outplot, file='skydip_report', ps=ps
            !p.thick=2
            elev_fit = dindgen(90)
            plot, data[ind].el*!radeg, freso/1d9, $
                  xtitle='Elevation (deg)', ytitle='F!dtone!n + dF!dtone!n (GHz)', $
                  /xs, /ys, psym=8, position=[0.2,0.1,0.95,0.95]
            oplot, elev_fit, -my_tau_model_2( 1.d0/sin(elev_fit*!dtor), myfit), col=250
            outplot, /close, /verb
            stop
         endif
         ;;---------------------
         
         ;;--------------------------------------------------
         ;; New method, fixing tau like in the standard one
         nparams = 3
         parinfo = replicate({fixed:0, limited:[1,1], $
                              limits:[0.,0.D0]}, nparams)
         p_start = [kidpar[idet].c0_skydip/1d9, kidpar[idet].c1_skydip/1d9, tau0]
         delvarx, e_r
         parinfo[0].limits=[-10, 10]
         parinfo[1].limits=[-1,1]*10
         parinfo[2].fixed = 1
         silent=1
         delvarx, myfit
         myfit = mpfitfun("my_tau_model_2", 1.d0/sin(data[ind].el), -freso/1d9, $
                          e_r, p_start, quiet = silent, $
                          parinfo=parinfo)
         ;; add sign and tatm to match convention below
         frbsarr[idet]  = -myfit[0]
         fr2Ksarr[idet] = -myfit[1]*Tatm
         ;;--------------------------------------------------

      endif
   endif
   if itot mod 4 eq 3 then noplot = 1 ;cont_plot, nostop = nostop
endfor
outplot,/close
if param.do_plot eq 1 then !p.multi = 0

; Can now update info and parameters
medc1_1mm = 0.
medc1_2mm = 0.
info.result_tau_1mm = meantau1
info.result_tau_2mm = meantau2
allkid = where( rmssarr ne 0, nallkid)
if nallkid ne 0 then begin
   okkid = where( rmssarr lt 3.*median( rmssarr[ allkid]) and $
                                    rmssarr gt 0, nokkid)
   
   if nokkid ne 0 then begin
      kidpar.c0_skydip =0D0
      kidpar.c1_skydip =0D0
      
      if nrgood1 ne 0 then begin
         kidpar[rgood1].c0_skydip = -frbsarr[  rgood1]
         kidpar[rgood1].c1_skydip = -fr2Ksarr[ rgood1]/Tatm
         medc1_1mm = median( kidpar[ rgood1].c1_skydip)
      endif
      if nrgood2 ne 0 then begin
         kidpar[rgood2].c0_skydip = -frbsarr[  rgood2]
         kidpar[rgood2].c1_skydip = -fr2Ksarr[ rgood2]/Tatm
         medc1_2mm = median( kidpar[ rgood2].c1_skydip)
      endif      
     endif else begin
        message, /info, 'Not enough valid kids to change c0 and c1'
     endelse
endif else begin
   message, /info, 'Not enough valid kids to change c0 and c1'
endelse

if not keyword_set( param.silent) then begin
; last 2 columns are identical because c1 is not fitted in the last 2 methods
   print, 'Median c1 (Hz/K) 1mm (found, init) ', medc1_1mm*1D9, medc1init_1mm, medc1init_1mm
   print, 'Median c1 (Hz/K) 2mm (found, init) ', medc1_2mm*1D9, medc1init_2mm, medc1init_2mm
endif

;save, kidpar, file='kidpar_skydip_'+param.scan+'.save'
;stop

;; Get useful information for the logbook
;; nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
nk_get_log_info, param, info, data, log_info
log_info.scan_type = info.obs_type
log_info.tau_1mm = string(info.result_tau_1mm, format='(F5.2)')
log_info.tau_2mm = string(info.result_tau_2mm, format='(F5.2)')
log_info.ut = info.ut
log_info.az = info.azimuth_deg
log_info.el = info.result_elevation_deg
save, file=output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day


end
