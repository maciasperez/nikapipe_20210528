;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_monitoring_plots
; 
; PURPOSE: 
;        Read the raw data
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;        - data: the data structure
;        - kidpar: the KID parameter structure
; 
; KEYWORDS:
;        - LIST_DATA: the list of variables to be put in the data structure
;        - RETARD: a retard between NIKA and telescope data
;        - EXT_PARAMS: extra variables to be put in the data structure
;        - ONE_MM_ONLY: set this keyword if you only want the 1mm channel
;        - TWO_MM_ONLY: set this keyword if you only want the 2mm channel
;        - FORCE_FILE:Use this keyword to force the list of scans used
;        instead of checking if they are valid
;        - RF: set this keyword if you want to use RF_dIdQ instead of
;          the polynom
;        - NOERROR: set this keyword to bypass errors
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_getdata.pro 
;        (Nicolas Ponthieu - nicolas.ponthieu@obs.ujf-grenoble.fr)
;-
;====================================================================================================

pro nk_monitoring_plots, param, info, data, kidpar, $
                         ikid=ikid, hwp_motor_position=hwp_motor_position, $
                         pipq=pipq


narrays = max(kidpar.array)-min(kidpar.array)+1

charsize = 0.6

;;-------------------------------
;; Scan status and messages plot
w1 = where( kidpar.type eq 1, nw1)
if not keyword_set(ikid) then ikid = w1[0]

dy = max(data.toi[ikid]) - min(data.toi[ikid])
yra = minmax(data.toi[ikid]) + [-0.2, 0.2]*dy
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

if param.do_plot ne 0 and param.plot_ps eq 0 then $
   wind, 1, 1, /free, /large, $
         title = "nk_monitoring_plots "+strtrim(param.scan, 2), $
         iconic = param.iconic
outplot, file=param.plot_dir+"/scan_status_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps
charsize = 0.6
my_multiplot, 1, 3, pp, pp1, /rev
plot, data.toi[ikid], /xs, yra=yra, /ys, position=pp1[0,*], charsize=charsize
for i=1, 9 do begin
   w = where( data.scan_st eq i, nw)
   if nw ne 0 then begin
      ;; oplot, [w], [data[w].toi[ikid]], psym=8, col=ct[i-1]
      for j=0, nw-1 do begin
         oplot, [1,1]*w[j], [-1,1]*1e10, col=ct[i-1], line=line[i-1]
         xyouts, w[j], dy[i], messages[i-1], orient=90, chars=0.6
      endfor
   endif
endfor

plot, data.ofs_az, /xs, position=pp1[1,*], /noerase, $
      ytitle='OFS azimuth (arcsec)', charsize=charsize
for i=1, 9 do begin
   w = where( data.scan_st eq i, nw)
   if nw ne 0 then begin
      for j=0, nw-1 do begin
         oplot, [1,1]*w[j], [-1,1]*1e10, col=ct[i-1], line=line[i-1]
      endfor
   endif
endfor

plot, data.ofs_el, /xs, position=pp1[2,*], /noerase, $
      ytitle='OFS elevation (arcsec)', xtitle='Sample index', charsize=charsize
for i=1, 9 do begin
   w = where( data.scan_st eq i, nw)
   if nw ne 0 then begin
      for j=0, nw-1 do begin
         oplot, [1,1]*w[j], [-1,1]*1e10, col=ct[i-1], line=line[i-1]
      endfor
   endif
endfor
outplot, /close

;;--------------------------------------------
if param.do_plot ne 0 and param.plot_ps eq 0 then $
   wind, 1, 1, /free, /large, $
         title = "nk_monitoring_plots "+strtrim(param.scan, 2), $
         iconic = param.iconic
outplot, file=param.plot_dir+"/monitoring_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps

;; Polarization specific plots
;; Start with them to overplot rotation
if info.polar ne 0 then begin
   ;xmin = pp[1, 0, 2]
   xmin = 0.7
   my_multiplot, 1, 4, pp2, /rev, xmin = xmin, xmax = 0.95, xmargin=0.05, gap_x=0.05, gap_y=0.05
   
   np_histo, data.position*!radeg, position = pp2[0, 0, *], $
             /noerase, /fill, fcol = 70, xtitle = 'Degrees',  bin = 1, $
             charsize=charsize
   legendastro, 'Effective HWP angle', box = 0

;   power_spec, data.position, !nika.f_sampling, pw, freq
;   plot_oo, freq, pw, position = pp2[0, 1, *], /noerase, xtitle = 'Hz', /xs, charsize=charsize
;   legendastro, 'HWP angle', box = 0

   ;; Checking synchronization and HWP position angle:
   ;; If not problem, we should see only one triangle
   plot, hwp_motor_position*!radeg, data.synchro, xtitle='HWP MOTOR position (deg)', ytitle='Synchro', $
         position=pp2[0,1,*], /noerase, charsize=charsize
   ;; oplot, [1,1]*180., [-1,1]*1e10, col=70
   ;; legendastro, ['Reference'], textcol=70, /bottom, /right
   legendastro, ['Check for drift', 'of the triangle'], textcol=250
   
   junk = data.position - shift(data.position, 1)
   ;; w =  where( abs(junk) gt 3*!dpi/2.,  nw)
   w = where( abs(data.synchro-median(data.synchro)) gt 3*stddev(data.synchro), nw)
   if nw eq 0 then begin
      txt = "Problem with HWP data.synchro"
      nk_error, info, txt
      return
   endif

   hwp_per = (w-shift(w,1))[1:*]/!nika.f_sampling
   hwp_per_avg = avg(hwp_per)
   s = stddev(hwp_per-hwp_per_avg)
   yra = hwp_per_avg + [-1, 1]*0.1
   plot, data[w[1:*]].a_t_utc-data[0].a_t_utc, hwp_per, /xs, $
         xtitle = 'time (sec)', position = pp2[0, 2, *], $
         /noerase, yra = yra, /ys, charsize=charsize
   legendastro, 'HWP rotation period', box = 0, chars = 1

   np_histo, 1./hwp_per, position = pp2[0,3, *], /noerase, /fill, fcol = 150, xtitle = 'Hz', bin = 0.1
   legendastro, 'HWP rotation frequency', box = 0, chars = 1
   
endif

;;--------------------------------------------
;; TOI plots
if info.polar eq 0 then begin
   xmax = 0.99
endif else begin
   xmax = 0.7
endelse

;my_multiplot, 3, 2, pp, /rev, xmargin=0.07, $
;              gap_x=0.05, ymargin=0.05, gap_y=0.05
;; my_multiplot, 2, 3, pp, /rev, xmargin=0.07, $
;;               gap_x=0.05, ymargin=0.05, gap_y=0.05
my_multiplot, 1, 3, pp, /rev, xmargin=0.07, $
              gap_x=0.05, ymargin=0.05, gap_y=0.05, xmax=xmax

letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't']

for iarray=1,3 do begin

   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)

   if nw1 ne 0 then begin
      make_ct, nw1, ct

      yra = minmax(data.toi[w1])

      ;; Timelines
      ikid = w1[0]

      boxes = kidpar[w1].acqbox
      boxes = boxes[UNIQ(boxes, SORT(boxes))]
      make_ct, n_elements(boxes), ct
      plot, data.toi[ikid], yra = yra, /ys, /nodata, position = pp[0, iarray-1, *], $
            /noerase, xtitle = 'sample', ytitle = 'Hz', /xs, charsize=charsize
      nika_title, info, /az, /ut, /el, /scan, title='Raw data'
      for ibox=0, n_elements(boxes)-1 do begin
         ww = where( kidpar.type eq 1 and kidpar.array eq iarray and $
                     kidpar.acqbox eq boxes[ibox], nww)
         for j=0, nww-1 do begin
            ikid = ww[j]
            oplot, data.toi[ikid], col = ct[ibox]
         endfor
      endfor
      legendastro, 'Acq. Box '+strtrim(boxes,2)+"/"+strupcase(letter[boxes]), line=0, col=ct, box=0

;;      make_ct, nw1, ct
;;      plot, data.toi[ikid], yra = yra, /ys, /nodata, position = pp[0, iarray-1, *], $
;;            /noerase, title = 'Raw data', xtitle = 'sample', ytitle = 'Hz', /xs, charsize=charsize
;;      for i = 0, nw1-1 do begin
;;         ikid = w1[i]
;;         oplot, data.toi[ikid], col = ct[i]
;;      endfor
;;      legendastro, ['Raw data', $
;;                    "Array "+strtrim(iarray,2)], box = 0, /right, chars = 1
;;      legendastro, param.scan, chars = 1, box = 0


;;      ;; Power spectra
;;      ikid = w1[0]
;;      nsn = n_elements(data)
;;      i=0
;;      w7 = nk_where_flag( data.flag[ikid], 7, compl=w)
;;      yfit = my_baseline(data[w].toi[ikid])
;;      power_spec, data[w].toi[ikid]-yfit, !nika.f_sampling, pw, freq
;;      plot_oo, freq, pw, /nodata, position = pp[1, iarray-1, *], $
;;               /noerase, title = 'Raw data', xtitle = 'Hz', ytitle = 'Hz/sqrt(Hz)', /xs, charsize=charsize
;;      if info.polar ne 0 and i eq 0 then begin
;;         for ii = 1, 10 do oplot, [ii, ii]*1./hwp_per_avg, [1e-10, 1e10], line = 2, col = 70
;;         legendastro, ['HWP rot freq: '+num2string(1./hwp_per_avg)+" Hz"], line = 2, col = 70, box = 0, textcol = 70
;;      endif
;;      
;;      for i = 0, nw1-1 do begin
;;         ikid = w1[i]
;;         w7 = nk_where_flag( data.flag[ikid], 7, compl=w)
;;         if n_elements( w) gt 10 then begin
;;            yfit = my_baseline(data[w].toi[ikid])
;;            power_spec,  data[w].toi[ikid]-yfit,  !nika.f_sampling,  pw,  freq
;;            oplot, freq, pw, col = ct[i]
;;         endif
;;
;;      endfor
;;      legendastro, "Array "+strtrim(iarray,2), box = 0, /right, chars = 1
;;      legendastro, ['Raw data - baseline', $
;;                    'Acq. Freq: '+num2string(!nika.f_sampling)], box = 0, chars = 1, /bottom


   endif
endfor
outplot,  /close

if param.do_plot ne 0 then begin
   if keyword_set(pipq) then begin
      if param.plot_ps eq 0 then wind, 1, 1, /free, /large
      outplot, file=param.plot_dir+"/monitoring_pipq_"+strtrim(param.scan), $
               png=param.plot_png, ps=param.plot_ps
      my_multiplot, 1, 3, pp, pp1, /rev
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            make_ct, nw1, ct
            plot, pipq[w1[0],*], /xs, yra=minmax(pipq[w1,*]), /ys, $
                  /noerase, position=pp1[iarray-1,*]
            nika_title, info, /ut, /az, /el, /scan, /object
            legendastro, 'pIpQ A'+strtrim(iarray,2)
            for i=0, nw1-1 do oplot, pipq[w1[i],*], col=ct[i]
         endif
      endfor
      outplot, /close
   endif
endif

;; Check tuning
nsn = n_elements(data)
ang = nk_angleiq_didq( data)
;; wind, 1, 1, /free, /large
;; my_multiplot, 1, 3, pp, pp1, /rev
;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;    if nw1 ne 0 then begin
;;       myang = ang[w1,nsn/2]
;;       a = median( myang)
;;       sigma = stddev( myang)
;;       yra = a + [-1,1]*2*sigma
;;       plot, myang, /xs, yra=yra, /ys, position=pp1[iarray-1,*], /noerase, $
;;             title='AngIQdIdQ'
;;       oplot, [0, nsn], [1,1]*a, col=250
;;       oplot, [0, nsn], [0,0], col=70
;;       oplot, [0, nsn], [1,1]*!pi/3,  col=70, line=2
;;       oplot, [0, nsn], -[1,1]*!pi/3, col=70, line=2
;; 
;;       legendastro, ['A'+strtrim(iarray,1), $
;;                     'Nvalid '+strtrim(nw1,2), $
;;                     'Median ang: '+string(a,form='(F5.3)'), $
;;                     'Median ang/ stddev: '+string(a/sigma,form='(F6.3)')], $
;;                    textcol=[!p.color, !p.color, 250, 250], /bottom
;; 
;;    endif
;; endfor

wind, 1, 1, /free, /large
ysep = 0.65
ymax = 0.90
my_multiplot, 1, 1, pp, pp1, /rev, ymin=ysep, ymax=ymax
array_color = [70, 200, 100]
;; Plot all arrays on the same plot
w1 = where( kidpar.type eq 1, nw1)
myang = ang[w1,nsn/2]
a = median( myang)
sigma = stddev( myang)
yra = a + [-1,1]*2*sigma
index = indgen(nw1)
plot, index, myang, /xs, yra=yra, /ys, position=pp1[0,*], /noerase
nika_title, info, /all, title='AngIQdIdQ (all a priori valid kids)'
legendastro, ['A1', 'A2', 'A3'], textcol=array_color
for iarray=1, 3 do begin
   w = where( kidpar[w1].array eq iarray, nw)
   if nw ne 0 then oplot, index[w], myang[w,*], psym=1, col=array_color[iarray-1]
endfor
oplot, [0, nw1], [1,1]*a, col=250
oplot, [0, nw1], [0,0], col=!p.color, thick=2
oplot, [0, nw1],  [1,1]*param.flag_sat_val,  col=70, line=2
oplot, [0, nw1], -[1,1]*param.flag_sat_val, col=70, line=2

my_multiplot, 2, 3, pp, pp1, /rev, ymax=ysep-0.05, gap_y=0.05, gap_x=0.05
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw)
   if nw1 ne 0 then begin
      myang = ang[w1,nsn/2]
      a = median( myang)
      sigma = stddev( myang)
      ;; w = where( abs(myang-a) le 2*sigma, nw)
      ;; w = where( abs(myang-a) le max( abs(myang-a))/5.)
      w = where( abs(myang-a) le !dpi/10, nw)
      if nw eq 0 then begin
         plot, [0,1],[0,1], position=pp[0,iarray-1,*], /noerase
         legendastro, 'All KIDs in A'+strtrim(iarray,2)+" are not well tuned"
      endif else begin
         plot, myang[w], /xs, position=pp[0,iarray-1,*], /noerase
         oplot, myang[w], col=array_color[iarray-1]
         oplot, [0, nw1], [1,1]*a, col=250
         oplot, [0, nw1], [0,0], col=70
         oplot, [0, nw1],  [1,1]*param.flag_sat_val,  col=70, line=2
         oplot, [0, nw1], -[1,1]*param.flag_sat_val, col=70, line=2
         legendastro, 'A'+strtrim(iarray,2), textcol=array_color[iarray-1]
         np_histo, myang[w], position=pp[1,iarray-1,*], /fill, /fit, /noerase, $
                   fcolor=array_color[iarray-1], colorfit=array_color[iarray-1], $
                   min=min(myang[w]), max=max(myang[w]), /noprint
         legendastro, 'A'+strtrim(iarray,2), textcol=array_color[iarray-1]
         oplot, [0,0], [-1,1]*1d20, col=250, thick=2
      endelse
   endif
endfor

;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;    if nw1 ne 0 then begin
;;       myang = ang[w1,nsn/2]
;;       a = median( myang)
;;       sigma = stddev( myang)
;;       yra = a + [-1,1]*2*sigma
;;       plot, myang, /xs, yra=yra, /ys, position=pp1[iarray-1,*], /noerase, $
;;             title='AngIQdIdQ'
;;       oplot, [0, nsn], [1,1]*a, col=250
;;       oplot, [0, nsn], [0,0], col=70
;;       oplot, [0, nsn], [1,1]*!pi/3,  col=70, line=2
;;       oplot, [0, nsn], -[1,1]*!pi/3, col=70, line=2
;; 
;;       legendastro, ['A'+strtrim(iarray,1), $
;;                     'Nvalid '+strtrim(nw1,2), $
;;                     'Median ang: '+string(a,form='(F5.3)'), $
;;                     'Median ang/ stddev: '+string(a/sigma,form='(F6.3)')], $
;;                    textcol=[!p.color, !p.color, 250, 250], /bottom
;; 
;;    endif
;; endfor

stop

end
