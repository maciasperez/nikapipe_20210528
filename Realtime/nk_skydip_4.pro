
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_skydip_4
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_skydip_4, scan_num, day, param, info, kidpar, data
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
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 2015: FXD: build on the previous routines, outputs the c0 and
;          c1 coefficients in the kidpar. info contains the new tau1 and tau2
;        - March 2015: NP added HWP template removal to reduce skydip scans
;          witha rotating HWP
;        - March 2016 add dred as output
;-


;; scan_num = 305
;; day      = '20151128'
;; nk_default_param, param
;; nk_default_info, info

pro nk_skydip_4, scan_num, day, param, info, kidpar, data, dred, $
                 input_kidpar_file = input_kidpar_file, $
                 raw_acq_dir=raw_acq_dir


;Prepare output directory for plots and logbook
output_dir = !nika.plot_dir+"/Logbook/Scans/"+day+"s"+strtrim(scan_num,2)
if file_test( /dir, output_dir) eq 0 then spawn, "mkdir -p "+output_dir

Tatm = 270.D0 ; K
;
; read data
scanname = strtrim(day, 2)+ 's' + strtrim(scan_num, 2)
if not keyword_set( param) then nk_default_param, param
nk_init_info, param, info
; Use now
info.status = 0
;param.silent= 1
;param.do_plot=0 ; no plot
param.math = 'RF'
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

nk_getdata, param, info, data, kidpar

if info.status ne 0 then return

indkid1 = where( kidpar.type eq 1 and kidpar.lambda lt 1.5)
indkid2 = where( kidpar.type eq 1 and kidpar.lambda gt 1.5)

; Recompute the angle between i,q and di,dq +pi/2
ang = nk_angleiq_didq(data)

;;--------------------------------------
;; Plot Ftone and tunings
;; Count electronic boxes
nbox=0
for i=0, 30 do begin
   w = where( kidpar.acqbox eq i, nw)
   if nw ne 0 then nbox++
endfor

;; display only one electronic box for clarity in RTA
wind, 1, 1, /free, /large, iconic=param.iconic
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
w1 = where(kidpar.type eq 1)
ikid = w1[0]
my_ftone = (data.f_tone[ikid]-min(data.f_tone[ikid]))
my_ftone *=max(data.el)/(max(my_ftone)>1.)  ; avoid a bug with >1.
!p.multi=[0,1,nplots]
for iplot=0, nplots-1 do begin
   xra = [iplot*(nsn/nplots), (iplot+1)*nsn/nplots]
   plot,  index, my_ftone[index], /xs, xra=xra, /ys
   oplot, index, my_ftone[index], col=70
   oplot, index, data[index].el
   flagged = nk_where_flag( data.k_flag[ikid], 2, nflag=nflagged)
   if nflagged ne 0 then begin
      for i=0, nflagged-1 do oplot, [1,1]*index[flagged[i]], [-1,1]*1e20, col=250, thick=2
   endif

   for i=1, 9 do begin
      w = where( data.scan_st eq i, nw)
      if nw ne 0 then begin
         for j=0, nw-1 do begin
            oplot, [1,1]*index[w[j]], [-1,1]*1e20, col=ct[i-1], line=line[i-1]
            xyouts, w[j], dy[i], messages[i-1], orient=90, chars=0.6
         endfor
      endif
   endfor
   
   if iplot eq 0 then begin
      legendastro, box=0, ['Numdet '+strtrim(kidpar[ikid].numdet,2), $
                           'box '+strtrim(kidpar[ikid].acqbox,2)]
      col = [!p.color, 70, 250]
      legendastro, box=0, line=0, col=col, $
                   ['Elevation', 'Scaled Ftone', 'k_flag = 4'], /bottom, textcol=col
   endif
endfor

;; ;; Limit the number of displayed boxes for clarity
;; my_multiplot, 1, (nbox/2)<2, pp, pp1, /rev, gap_y=0.05, gap_x=0.05
;; charsize=0.5
;; for ibox=0, (nbox-1)<2 do begin
;;    if ibox eq 0 then begin
;;       xtitle = 'Sample index'
;;       ytitle = 'F tone (AU)'
;;    endif else begin
;;       delvarx, xtitle, ytitle
;;    endelse
;;    
;;    w1 = where( kidpar.type eq 1 and kidpar.acqbox eq ibox, nw1)
;;    if nw1 ne 0 then begin
;;       ikid = w1[0]
;;       plot, data.f_tone[ikid], /xs, /ys, xtitle=xtitle, ytitle=ytitle, $
;;             position=pp1[ibox,*], /noerase, charsize=charsize
;; 
;;       flagged = nk_where_flag( data.k_flag[ikid], 2, nflag=nflagged)
;;       if nflagged ne 0 then begin
;;          for i=0, nflagged-1 do oplot, [1,1]*flagged[i], [-1,1]*1e20, col=70
;;       endif
;;       legendastro, 'box '+strtrim(ibox,2), col=ct, box=0
;;    endif
;; endfor
;; stop


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
         
         ph_min = min( data.nsotto[lambda-1,*])
         ph_max = max( data.nsotto[lambda-1,*])
         for iph=ph_min>0, ph_max do begin
            w = where( data.nsotto[lambda-1,*] eq iph, nw)
            
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
for iph = 0, max( iloc) do $
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
   info.status = 1
   return
endelse

dred = replicate( data[0], ndred)
; reduced skydip to be saved 10 is really the limit, 11 is to be understood
dred.f_tone = !values.d_nan  ; default values
dred.df_tone = !values.d_nan
dred.el = !dpi/2
;aa = 0
for idet = 0, nkid-1 do begin
   if kidpar[ idet].type eq 1 then begin
;;;;      ind = where( data.scan_valid[0] eq 0 and data.scan_valid[1] eq 0 and $
      ind = where( data.scan_valid[itotsotto] eq 0 and $
                   finite(data.f_tone[ idet]) and finite(data.df_tone[ idet]) and $
;                   data.scan_valid[4] ge 0 and abs( data.df_tone[idet]) lt 1D4, nind)
                   nsotto[itotsotto, *] ge 0 and abs( ang[idet, *]) lt param.flag_sat_val, nind)
;;;;                   nsotto[kidpar[ idet].lambda gt 1.5, *] ge 0 and abs( ang[idet, *]) lt param.flag_sat_val, nind)

      if nind ge 200 then begin
         am = 1/sin(data[ind].el)
         freso = data[ind].f_tone[ idet]+data[ind].df_tone[ idet]
         for iph = 0, ndred-1 do begin
            u = where( nsotto[ itotsotto, ind] eq unsusot[ iph], nu)
            if nu gt 2 then begin
               dred[iph].f_tone[ idet] = median( data[ind[ u]].f_tone[ idet])
               dred[iph].df_tone[ idet] = median( data[ind[ u]].df_tone[ idet])
               dred[iph].el = median( data[ind[ u]].el)
;               if aa lt 11 then stop, 'Check el'
            endif
            
         endfor
         
;         endif
         
         taufit, am, freso, frb, fr2K, tau, frfit, rms, /silent
         frbarr[idet] = frb
         fr2Karr[idet] = fr2K
         tauarr[idet] = tau
         rmsarr[idet] = rms
; Compute tau with c0 and c1 known
         if kidpar[idet].c1_skydip ne 0 then begin
            taufit2, am, freso, $
                     -kidpar[ idet].c0_skydip, $
                     kidpar[ idet].c1_skydip, $
                     taumedk, taumeank, frfit, rmsk, tau = tau, /silent
            taufarr[ idet] = taumedk
            rmsfarr[ idet] = rmsk
         endif
;         aa = aa+1

      endif
   endif
endfor

; Select good kids in each band
meantau1 = 0.
meanftau1 = 0.
medtau1 = 0.
good1=where( rmsarr gt 0 and kidpar.type eq 1 and kidpar.lambda lt 1.5, ngood1)
if ngood1 ge 2 then begin
  medtau1 = median( tauarr[ good1])
  rgood1 = where( rmsarr gt 0 and kidpar.type eq 1 and kidpar.lambda lt 1.5 and $
                  abs( tauarr-medtau1) le 0.1 and rmsarr lt 3.*median( rmsarr[ good1]), nrgood1)
  if param.silent eq 0 then message, /info, $
        'Number of good kids1 before/after selection '+strtrim(ngood1, 2)+', '+strtrim(nrgood1, 2)
  if nrgood1 ge 2 then begin
     meantau1 = mean( tauarr[ rgood1])
   endif
endif else begin
   nrgood1 = 0
endelse

fgood1=where( rmsfarr gt 0 and kidpar.type eq 1 and kidpar.lambda lt 1.5, nfgood1)
if nfgood1 ge 2 then meanftau1 = mean( taufarr[ fgood1])

meantau2 = 0.
meanftau2 = 0.
medtau2 = 0.
good2=where( rmsarr gt 0 and kidpar.type eq 1 and kidpar.lambda gt 1.5, ngood2)
if ngood2 ge 2 then begin
  medtau2 = median( tauarr[ good2])
  rgood2 = where( rmsarr gt 0 and kidpar.type eq 1 and kidpar.lambda gt 1.5 and $
                  abs( tauarr-medtau2) le 0.05 and rmsarr lt 3.*median( rmsarr[ good2]), nrgood2)
  if param.silent eq 0 then message, /info, $
        'Number of good kids2 before/after selection '+strtrim(ngood2, 2)+', '+strtrim(nrgood2, 2)
   if nrgood2 ge 2 then begin
      meantau2 = mean( tauarr[ rgood2])
   endif
endif else begin
   nrgood2 = 0
endelse

fgood2 = where( rmsfarr gt 0 and kidpar.type eq 1 and kidpar.lambda gt 1.5, nfgood2)
if nfgood2 ge 2 then meanftau2 = mean( taufarr[ fgood2])

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
      if nfgood1 ne 0 then print, 'Median rms1 = ', median( rmsarr[ good1]), median( rmsfarr[ fgood1])
      if nfgood2 ne 0 then print, 'Median rms2 = ', median( rmsarr[ good2]), median( rmsfarr[ fgood2])
   endif
endif

if param.do_plot eq 1 then begin
   if param.plot_ps eq 0 then wind, 1, 1, xs = 1000, ys = 600, title = 'Opacity measurements', iconic = param.iconic
   outplot, file=output_dir+"/plot_"+param.scan, png=param.plot_png, ps=param.plot_ps
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
      p = 0 ; plot init
      if nrgood1 ne 0 then begin
         plot, kidpar[rgood1].numdet, tauarr[rgood1], psym = 4, $
               title = info.scan, subtitle = 'Tau225 = '+string(info.tau225, format = '(1F10.3)'), xra = numrange, $
               xtitle = 'Kid NumDet', ytitle = 'Zenith opacity', ysty = 1, xsty = 0, yra=[0,1.5]
         oplot, kidpar[indkid1].numdet, meantau1*(indkid1*0+1), psym = -3, col = 100, thick = 2
         if (nfgood1 ne 0) then oplot, kidpar[fgood1].numdet, taufarr[fgood1], psym=2
         oplot, kidpar[indkid1].numdet, meanftau1*(indkid1*0+1), psym = -3, col = 100
         xyouts, kidpar[indkid1[0]].numdet+10, meantau1*0.7, col = 100, $
                 'Tau1mm = '+ string(meantau1, format = '(1F8.3)')
         xyouts, kidpar[indkid1[0]].numdet+10, meanftau1*0.6, col = 100, $
                 'Input kidpar coeff Tau1mm = '+ string(meanftau1, format = '(1F8.3)')
         p=1
      endif else begin
         message, /info, "nrgood1 = 0 !!"
      endelse

      if p eq 0 then wind, 1, 1, /free, /large, iconic=param.iconic

      if nrgood2 ne 0 then begin
         if p eq 0 then begin
            plot, kidpar[rgood2].numdet, tauarr[rgood2], psym = 4, $
                  xra = numrange,$
                  title = info.scan, subtitle = 'Tau225 = '+string(info.tau225, format = '(1F10.3)'), $
                  xtitle = 'Kid NumDet', ytitle = 'Zenith opacity', ysty = 1, xsty = 0, yra=[0,1.5]
         endif else begin
            oplot, kidpar[rgood2].numdet, tauarr[rgood2], psym = 4
         endelse
         oplot, kidpar[indkid2].numdet, meantau2*(indkid2*0+1), psym = -3, col = 200, thick = 2
         if nfgood2 ne 0 then oplot, kidpar[fgood2].numdet, taufarr[fgood2], psym=2
         
         oplot, kidpar[indkid2].numdet, meanftau2*(indkid2*0+1), psym = -3, col = 200
         xyouts, kidpar[indkid2[0]].numdet+10, meantau2*0.7, col = 200, $
                 'Tau2mm = '+ string(meantau2, format = '(1F8.3)')
         xyouts, kidpar[indkid2[0]].numdet+10, meanftau2*0.6, col = 200, $
                 'Input kidpar coeff Tau2mm = '+ string(meanftau2, format = '(1F8.3)')
      endif else begin
         message, /info, "nrgood2 = 0 !!"
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
   !p.multi = [0, 2, 2]
   if param.plot_ps eq 0 then wind, 2, 1, xs = 1000, ys = 600, title = 'c0 and c1 measurements for '+info.scan, iconic = param.iconic
endif

outplot, file=output_dir+"/plot_correl_"+param.scan, png=param.plot_png, ps=param.plot_ps
nostop = 1-param.do_plot
itot = -1
noplot = 1-param.do_plot
for idet = 0, nkid-1 do begin
   if kidpar[ idet].type eq 1 then begin
      ind = where( finite(data.f_tone[ idet]) and $
                   finite(data.df_tone[ idet]) and $
                   nsotto[itotsotto, *] ge 0, nind)
;                   nsotto[kidpar[ idet].lambda gt 1.5, *] ge 0, nind)
;      ind = where( data.scan_valid[0] eq 0 and data.scan_valid[1] eq 0 and $
;                   finite(data.f_tone[ idet]) and finite(data.df_tone[ idet]) and $
;                    nsotto[kidpar[ idet].lambda gt 1.5, *] ge 0 and abs( ang[idet, *]) lt param.flag_sat_val, nind)
      if kidpar[idet].lambda lt 1.5 then begin
         tau0 = meantau1    
         ftau0 = meanftau1
      endif else begin
         tau0 = meantau2
         ftau0 = meanftau2
      endelse

      if nind ge 200 then begin
         itot = itot+1
         am = 1/sin(data[ind].el)
         freso =  data[ind].f_tone[ idet]+data[ind].df_tone[ idet]
         plot_correl, (1-exp(-tau0*am)), freso/1D9, $
                      title = 'Numdet = '+strtrim(kidpar[idet].numdet, 2)+ $
                      ' Color line= Reference', $
                      sl, a0, sigma, rcorr, chisqr, ycorr, $
                      /nostop, noplot = noplot , xtitle = '(1-exp(-tau0*am))', $
                      ytitle = 'Resonance frequency [GHz]', psym = 4
         oplot, (1-exp(-ftau0*am)), $
                (-kidpar[ idet].c1_skydip*Tatm*(1-exp(-ftau0*am))- $
                kidpar[ idet].c0_skydip)/1D9, $
                col = 100, psym = -3, thick = 2
         frbsarr[idet]  = a0*1D9
         fr2Ksarr[idet] = sl*1D9
         rmssarr[idet]  = stddev( ycorr)
      endif
   endif
   if itot mod 4 eq 3 then noplot = 1 ;cont_plot, nostop = nostop
endfor
outplot,/close
if param.do_plot eq 1 then !p.multi = 0

; Can now update info and parameters
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
         if not keyword_set( param.silent) then $
            print, 'Median c1 (Hz/K) 1mm ', median( kidpar[ rgood1].c1_skydip)
      endif
      if nrgood2 ne 0 then begin
         kidpar[rgood2].c0_skydip = -frbsarr[  rgood2]
         kidpar[rgood2].c1_skydip = -fr2Ksarr[ rgood2]/Tatm
         if not keyword_set( param.silent) then $
            print, 'Median c1 (Hz/K) 2mm ', median( kidpar[ rgood2].c1_skydip)
      endif      
;   kidpar[ [rgood1, rgood2]].c0_skydip = -frbsarr [ [rgood1, rgood2]]
;   kidpar[ [rgood1, rgood2]].c1_skydip = -fr2Ksarr[ [rgood1, rgood2]]/Tatm
;   if not keyword_set( param.silent) then $
;      print, 'Median c1 (Hz/K) 1&2mm ', $
;             median( kidpar[ rgood1].c1_skydip), $
;             median( kidpar[ rgood2].c1_skydip) 
     endif else begin
        message, /info, 'Not enough valid kids to change c0 and c1'
     endelse
endif else begin
   message, /info, 'Not enough valid kids to change c0 and c1'
endelse

;; Get useful information for the logbook
;; nika_get_log_info, param.scan_num, param.day, data, log_info, kidpar=kidpar
nk_get_log_info, param, info, data, log_info
log_info.scan_type = info.obs_type
log_info.tau_1mm = string(info.result_tau_1mm, format='(F5.2)')
log_info.tau_2mm = string(info.result_tau_2mm, format='(F5.2)')
save, file=output_dir+"/log_info.save", log_info
nk_logbook_sub, param.scan_num, param.day

end
