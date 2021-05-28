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

pro nk_monitoring_plots_2, param, info, data, kidpar, $
                           ikid=ikid, hwp_motor_position=hwp_motor_position, $
                           pipq=pipq


narrays = max(kidpar.array)-min(kidpar.array)+1

charsize = 0.6

w1 = where( kidpar.type eq 1, nw1)
if not keyword_set(ikid) then ikid = w1[0]

nsn = n_elements(data)

dy = max(data.toi[ikid]) - min(data.toi[ikid])
yra = minmax(data.toi[ikid]) + [-0.2, 0.2]*dy
y1 = min(yra)
y2 = min(yra) + 0.5*(max(yra)-min(yra))

if param.do_plot ne 0 and param.plot_ps eq 0 and param.plot_z eq 0 and !nika.plot_window[0] lt 0 then begin
   wind, 1, 1, /free, /large, $
         title = "nk_monitoring_plots "+strtrim(param.scan, 2), $
         iconic = param.iconic
endif
outplot, file=param.plot_dir+"/monitoring_"+strtrim(param.scan), png=param.plot_png, ps=param.plot_ps


;; Polarization specific plots
if info.polar ne 0 then begin
   xmin = 0.8
   my_multiplot, 1, 4, pp2, /rev, $
                 xmin = xmin, xmax = 0.95, xmargin=0.05, gap_x=0.05, gap_y=0.05
   
   np_histo, data.position*!radeg, position = pp2[0, 0, *], $
             /noerase, /fill, fcol = 70, xtitle = 'Degrees',  bin = 1, $
             charsize=charsize, title='Effective HWP angle'

   ;; Checking synchronization and HWP position angle:
   ;; If not problem, we should see only one triangle
   plot, hwp_motor_position*!radeg, data.synchro, xtitle='HWP MOTOR position (deg)', ytitle='Synchro', $
         position=pp2[0,1,*], /noerase, charsize=charsize
   legendastro, ['Check for drift', 'of the triangle'], textcol=250
   legendastro, [strtrim(min(data.synchro)/max(data.synchro)*100,2)+"%"], /bottom
   
   junk = data.position - shift(data.position, 1)
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

   np_histo, 1./hwp_per, position = pp2[0,3, *], /noerase, /fill, fcol = 150, $
             xtitle = 'Hz', bin = 0.1, min=0.5/hwp_per, max=1.5/hwp_per
   legendastro, 'HWP rotation frequency', box = 0, chars = 1
endif

;;--------------------------------------------
;; TOI plots
xmax_loc = 0.3
ymax_loc = 0.47
my_multiplot, 1, 3, pp, /rev, xmin=0.02, xmax=xmax_loc, /full, /dry, $
              ymin=0.03, ymax=ymax_loc, xmargin=0.01, ymargin=0.001
letter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', $
          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't']
nlett = n_elements(letter)

;; fraction of valid KIDs per box
plot, [0, 1], [-1, 21], /xs, /ys, /nodata, $
      position=[xmax_loc+0.02, 0.03, 0.4, ymax_loc], /noerase, $
      charsize=0.7, title='Fraction of valid KIDs per box'
oplot, [0.5, 0.5], [-1, 21], line=2
frac = dblarr(nlett)
for ilett=0, nlett-1 do begin
   w = where( strupcase(tag_names(info)) eq 'FRAC_VALID_KIDS_BOX_'+strupcase(letter[ilett]), nw)
   if nw ne 0 then begin
      frac[ilett] = info.(w)
      if info.(w) lt 0.5 then $
         xyouts, xmax_loc+0.02, ymax_loc-ilett*0.02, 'Valid Frac. '+$
                 strupcase(letter[ilett])+": "+string(info.(w),form='(F4.2)'), /norm, $
                 col=250, charsize=0.8
   endif
endfor
oplot, frac, indgen(nlett)
w = where( frac lt 0.5, nw, compl=wc, ncompl=nwc)
if nw ne 0 then oplot, frac[w], w, psym=8, col=250, syms=0.5
if nwc ne 0 then oplot, frac[wc], wc, psym=8, col=150, syms=0.5

;; TOI plot
charsize = 0.6
avg_toi = avg( data.toi, 1)
for iarray=1,3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   if iarray eq 3 then xcharsize=charsize else xcharsize=1d-10
   if nw1 ne 0 then begin
      make_ct, nw1, ct
      yra = minmax(data.toi[w1])
      ikid = w1[0]
      boxes = kidpar[w1].acqbox
      boxes = boxes[UNIQ(boxes, SORT(boxes))]
      make_ct, n_elements(boxes), ct

      toi_med = median( data.toi[w1], dim=1)

      ;; quick determination of a plausible yra
      ymin = 1d6
      ymax = -1d6
      for i=0, nw1-1, 30 do begin
         ikid = w1[i]
         fit = linfit( toi_med, data.toi[ikid])
         d = data.toi[ikid] - (fit[0] + fit[1]*toi_med)
         if max(d) gt ymax then ymax = max(d)
         if min(d) lt ymin then ymin = min(d)
      endfor
      yra = [ymin, ymax]*2.
      ;; Plot all tois
      plot, data.toi[ikid]-(fit[0]+fit[1]*toi_med), yra = yra, /ys, /nodata, position = pp[0, iarray-1, *], $
            /noerase, xtitle = 'sample', ytitle = 'Recal. on median mode (Hz)', /xs, charsize=charsize, $
            xcharsize=xcharsize, nsum=10
      ;nika_title, info, /az, /ut, /el, /scan, title='Raw data'
      for ibox=0, n_elements(boxes)-1 do begin
         ww = where( kidpar.type eq 1 and kidpar.array eq iarray and $
                     kidpar.acqbox eq boxes[ibox], nww)
         for j=0, nww-1 do begin
            ikid = ww[j]
            fit = linfit( toi_med, data.toi[ikid])
            oplot, data.toi[ikid]-(fit[0]+fit[1]*toi_med), col = ct[ibox]
         endfor
      endfor
      wtag = where( strupcase(tag_names(info)) eq "FRAC_VALID_KIDS_ARRAY_"+strtrim(iarray,2), nwtag)
      if nwtag ne 0 then begin
         if info.(wtag) ge 100 then fmt='(I3.3)' else fmt='(I2.2)'
         legendastro, 'A'+strtrim(iarray,2)+$
                      ' '+string( info.(wtag),form=fmt)+'% valid'
      endif else begin
         legendastro, 'A'+strtrim(iarray,2)
      endelse
                   
;      legendastro, 'Acq. Box '+strtrim(boxes,2)+"/"+strupcase(letter[boxes]), line=0, col=ct, box=0
   endif
endfor

;; Check tuning except with doing a skydip because plots are
;; misleading then.
if strupcase( strtrim( info.obs_type, 2)) eq "DIY" then return
ang = nk_angleiq_didq( data)

;; ;;---------------------
;; w1 = where( kidpar.type eq 1)
;; wind, 1, 1, /f
;; plot, ang[w1[0],*], /xs, /ys
;; stop
;; ;;---------------------
charsize = 0.6
if param.plot_ps eq 0 and param.plot_z eq 0 and !nika.plot_window[0] lt 0 then begin
   wind, 1, 1, /free, /large
   xmin = 0.1
   xmax = 0.9
   ymin = 0.1
   ymax = 0.9
endif else begin
   if param.plot_ps eq 0 then wset, !nika.plot_window[0]
   xmin=0.45
   xmax=0.75
   ymin=0.03
   ymax=0.45
endelse
my_multiplot, 1, 3, pp, /rev,  $
              xmin=xmin, xmax=xmax, xmargin=0.001, $
              ymin=ymin, ymax=ymax, ymargin=0.001, gap_y=0.02

array_color = [70, 200, 100]
charsize = 0.6
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw)
   if iarray eq 3 then xtitle='Angle (degrees)' else xtitle=''
   if nw1 ne 0 then begin
      myang = ang[w1,0]
      a = median( myang)
      sigma = stddev( myang)
      ;; w = where( abs(myang-a) le 2*sigma, nw)
      ;; w = where( abs(myang-a) le max( abs(myang-a))/5.)
      w = where( abs(myang-a) le !dpi/10, nw)
      if nw eq 0 then begin
         plot, [0,1],[0,1], position=pp[0,iarray-1,*], /noerase
         legendastro, 'All KIDs in A'+strtrim(iarray,2)+" are not well tuned"
      endif else begin
         if iarray eq 1 then title='Angle IQ-dIdQ' else title=''
         hmax = max( [!dpi/10, 3*stddev(myang[w])])
         hmin = -hmax
;         wind, 1, 1, /f
;         plot, myang[w], /xs, /ys
;         stop
         np_histo, myang[w]*!radeg, xh, yh, gpar, position=pp[0,iarray-1,*], /fit, /noerase, $
                   xrange=[-1,1]*!dpi/4*!radeg, /noprint, /nolegend, $
                   charsize=charsize, title=title, xtitle=xtitle, colorplot=array_color[iarray-1];, $
                   ;/fill, fcolor=array_color[iarray-1], colorfit=array_color[iarray-1], /contour
         legendastro, 'A'+strtrim(iarray,2), textcol=array_color[iarray-1]
         oplot, [0,0], [-1,1]*1d20, col=250, thick=2
         if (gpar[1]-2*gpar[2]) lt -(!dpi/4*!radeg) or (gpar[1]+2*gpar[2]) gt (!dpi/4*!radeg) then begin
            legendastro, "Histo. far from 0 => BAD TUNING ?", $
                         textcol=250, charthick=2
         endif
      endelse
   endif
endfor
outplot, /close, /verb

if keyword_set(pipq) then begin
   if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
   outplot, file=param.plot_dir+"/monitoring_pipq_"+strtrim(param.scan), $
            png=param.plot_png, ps=param.plot_ps
   my_multiplot, 1, 3, pp, pp1, /rev
   for iarray=1, 3 do begin
      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      if nw1 ne 0 then begin
         make_ct, nw1, ct
         plot, pipq[w1[0],*], /xs, yra=minmax(pipq[w1,*]), /ys, $
               /noerase, position=pp1[iarray-1,*]
                                ;nika_title, info, /ut, /az, /el, /scan, /object
         legendastro, 'pIpQ A'+strtrim(iarray,2)
         for i=0, nw1-1 do oplot, pipq[w1[i],*], col=ct[i]
      endif
   endfor
   outplot, /close
endif

if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large
my_multiplot, 2, 2, pp, pp1, /rev
for iarray=1, 3 do begin
   case iarray of
      1: ebox_num = indgen(12-5+1)+5
      2: ebox_num = [1, 2, 3, 4]
      3: ebox_num = indgen(20-13+1) + 13
   endcase
   ebox = strupcase(letter[ebox_num-1])
   nbox = n_elements(ebox)
   make_ct, nbox, ct

   w = where( kidpar.type ne 2 and kidpar.array eq iarray, nw)
   ;;w = where( kidpar.type eq 1 and kidpar.array eq iarray, nw)
   if nw ne 0 then begin
      plot, kidpar[w].nas_x, kidpar[w].nas_y, /iso, $
            xra = [-1,1]*250, yra=[-1,1]*250, /nodata, $
            position=pp1[iarray-1,*], /noerase
      nika_title, info, /ut, /scan, title='Array '+strtrim(iarray,2)
      legendastro, 'El. Box '+strupcase(ebox), textcol=ct, /right
      for ibox=0, n_elements(ebox_num)-1 do begin
         ww = where( kidpar.acqbox eq ebox_num[ibox] and kidpar.type eq 1, nww)
         if nww ne 0 then begin
            oplot, kidpar[ww].nas_x, kidpar[ww].nas_y, psym=8, syms=0.5, col=ct[ibox]
         endif else begin
            message, /info, "No valid kid for box "+strupcase(letter[ebox_num[ibox]-1])
         endelse
      endfor
      w3 = where( kidpar.array eq iarray and kidpar.type eq 3, nw3)
;      if nw3 ne 0 then oplot, kidpar[w3].nas_x, kidpar[w3].nas_y, psym=1, thick=2, col=250

      w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
      legendastro, ['Nkids (init): '+strtrim(nw,2), $
                    'Nkids flagged: '+strtrim(nw3,2), $
                    'Frac valid: '+strtrim( string( 100*float(nw-nw3)/nw, form='(I2.2)'),2)+"%", $
                    'check that '+strtrim(nw-nw3,2)+" = "+strtrim(nw1,2)]
   endif
endfor

array_color = [70, 200, 100]
charsize = 0.6
xra = [-1,1]*!dpi/4.
yra = [0,1000]
bin = !dpi/20.
leg_txt = ['']
leg_col = [!p.color]

plot, xra, yra, /nodata, /xs, /ys, $
      xtitle='Angle (degrees)', title='Angle IQ-dIdQ', $
      position=pp1[3,*], /noerase
for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw)
   if nw1 ne 0 then begin
      myang = ang[w1,0]
      a = median( myang)
      sigma = stddev( myang)
      w = where( abs(myang-a) le !dpi/10, nw)
      if nw eq 0 then begin
         leg_txt = [leg_txt, 'All KIDs in A'+strtrim(iarray,2)+" are not well tuned"]
         leg_col = [leg_col, 250]
      endif else begin
         np_histo, myang[w]*!radeg, xh, yh, gpar, position=pp1[3,*], /fit, /noerase, $
                   xra = xra, yra=yra, /noprint, /nolegend, colorplot=array_color[iarray-1]
         oplot, [0,0], [-1,1]*1d20, col=250, thick=2
         if (gpar[1]-2*gpar[2]) lt -(!dpi/4*!radeg) or (gpar[1]+2*gpar[2]) gt (!dpi/4*!radeg) then begin
            leg_txt = [leg_txt, "Histo. far from 0 => BAD TUNING ?"]
            leg_col = [leg_col, 250]
         endif else begin
            leg_txt = [leg_txt, 'A'+strtrim(iarray,2)]
            leg_col = [leg_col, array_color[iarray-1]]
         endelse
      endelse
   endif
endfor
legendastro, leg_txt, col=leg_col

message, /info, "Place this plot on the main monitoring window"
message, /info, "get rid of useless polarization diagnosis plots as well"
;stop

end
