;+
;PURPOSE: Check the TOI.
;
;INPUT: param file, data file, kidpar file
;
;OUTPUT: plot the TOI
;
;LAST EDITION: 
;   21/09/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_checktoi, param, data, kidpar, raw=raw
  
  won_1mm = where(kidpar.type eq 1 and kidpar.array eq 1, n1mm)
  won_2mm = where(kidpar.type eq 1 and kidpar.array eq 2, n2mm)

  time = dindgen(n_elements(data))/!nika.f_sampling
  
  ;;------- Covariance matrix
  window, ysize=900, xsize=1200, /free, title = 'Covariance matrix'
  cov_mat = correlate(data.RF_dIdQ)
  med = median(cov_mat)
  std = stddev(cov_mat,/nan)
  dispim_bar, cov_mat, cr=[med-3*std, 1], /asp, /noc, xtitle='KID', ytitle='KID'

  ;;------- 1mm detectors 
  print, 'First looking at 1mm detectors'
  range_1mm = ''
  if not keyword_set(raw) then read, range_1mm, prompt = 'Give the range at 1mm, e.g. 1.5 [Jy]:   '
  if not keyword_set(raw) then range_1mm = [-double(range_1mm),double(range_1mm)] else $
     range_1mm = minmax(data.RF_dIdQ[won_1mm])
  
  if not keyword_set(raw) then range_1mm_ps = [0.001,10] else range_1mm_ps = [0.001,100]

  window, ysize=900, xsize=1200, /free, title = 'Individual KID TOI and PS'
  for ikid = 0, n1mm-1 do begin
     power_spec, data.RF_dIdQ[won_1mm[ikid]], !nika.f_sampling, ps, fr
     
     !p.multi=[0,1,2]
     plot, time, data.RF_dIdQ[won_1mm[ikid]], yr=range_1mm, xtitle='Time (s)', ytitle='Flux (Jy)',$
           title='KID numdet '+strtrim(kidpar[won_1mm[ikid]].numdet,2),/xs,ystyle=1
     plot_oo, fr, ps, yr=range_1mm_ps, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)',$
              title='KID numdet '+strtrim(kidpar[won_1mm[ikid]].numdet,2),/xs,ystyle=1
     oplot, fr, ps*0+0.001, col=250, linestyle=2
     oplot, fr, ps*0+0.01, col=250, linestyle=2
     oplot, fr, ps*0+0.1, col=250, linestyle=2
     oplot, fr, ps*0+1, col=250, linestyle=2
     oplot, fr, ps*0+10, col=250, linestyle=2
     oplot, fr, ps*0+100, col=250, linestyle=2
     !p.multi = 0
     
     bidon = ''
     read, bidon, prompt = 'Press enter to continue, press q to go to 2mm:   '
     if bidon eq 'q' then goto, suite1
  endfor

  ;;------- 2mm detectors
  suite1: print, ''
  print, 'Now looking at 2mm detectors'
  range_2mm = ''
  if not keyword_set(raw) then read, range_2mm, prompt = 'Give the range at 2mm, e.g. 0.5 [Jy]:   '
  if not keyword_set(raw) then range_2mm = [-double(range_2mm),double(range_2mm)] else $
     range_2mm = minmax(data.RF_dIdQ[won_2mm])

  if not keyword_set(raw) then range_2mm_ps = [0.001,1] else range_1mm_ps = [0.001,100]

  for ikid = 0, n2mm-1  do begin
     power_spec, data.RF_dIdQ[won_2mm[ikid]], !nika.f_sampling, ps, fr
     
     !p.multi=[0,1,2]
     plot, time, data.RF_dIdQ[won_2mm[ikid]], yr=range_2mm, xtitle='Time (s)', ytitle='Flux (Jy)',$
           title='KID numdet '+strtrim(kidpar[won_2mm[ikid]].numdet,2),/xs,ystyle=1
     plot_oo, fr, ps, yr=range_2mm_ps, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)',$
              title='KID numdet '+strtrim(kidpar[won_2mm[ikid]].numdet,2),/xs,ystyle=1
     oplot, fr, ps*0+0.001, col=250, linestyle=2
     oplot, fr, ps*0+0.01, col=250, linestyle=2
     oplot, fr, ps*0+0.1, col=250, linestyle=2
     oplot, fr, ps*0+1, col=250, linestyle=2
     oplot, fr, ps*0+10, col=250, linestyle=2
     oplot, fr, ps*0+100, col=250, linestyle=2
     !p.multi = 0

     bidon = ''
     read, bidon, prompt = 'Press enter to continue, press q to quit:   '
     if bidon eq 'q' then goto, suite2
  endfor

  suite2: print, 'The end, the pipeline continues !!!'

  return
end
