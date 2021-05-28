;+
; PURPOSE: Produce a plot with all TOI and PS
;
; INPUT: data, kidpar and parameter
;
; OUTPUT: the plot produced
;
; KEYWORD:
;
; MODIFICATIONS:  - 18/02/2014 creation (adam@lpsc.in2p3.fr)
;
;-

pro nika_pipe_plotdecortoi, param, data, kidpar, no_merge_fig=no_merge_fig
  mydevice = !d.name
  set_plot, 'ps'

  w1mm = where(kidpar.type eq 1 and kidpar.array eq 1, n1mm)
  w2mm = where(kidpar.type eq 1 and kidpar.array eq 2, n2mm)
  
  time = dindgen(n_elements(data))/!nika.f_sampling
  
  ;;------- Covariance matrix
  loadct,4
  cov_mat1 = correlate(data.RF_dIdQ[w1mm])
  cov_mat2 = correlate(data.RF_dIdQ[w2mm])
  med1 = median(cov_mat1)
  med2 = median(cov_mat2)
  std1 = stddev(cov_mat1,/nan)
  std2 = stddev(cov_mat2,/nan)
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/check_corr_matrix_'+strtrim(param.scan_list[param.iscan],2)+'.ps'
  !p.multi = [0,2,1]
  rg1 = [med1-2.0*std1, med1+2.0*std1]
  rg2 = [med2-2.0*std2, med2+2.0*std2]
  dispim_bar, cov_mat1, cr=rg1, /asp, /noc, xtitle='KID number', ytitle='KID number', title='Detector correlation matrix 1mm', charsize=0.7
  dispim_bar, cov_mat2, cr=rg2, /asp, /noc, xtitle='KID number', ytitle='KID number', title='Detector correlation matrix 2mm', charsize=0.7
  !p.multi = 0
  cgText, 0.5, 0.6, ALIGNMENT=0.5, CHARSIZE=1.25, /NORMAL, strtrim(param.scan_list[param.iscan],2)
  device,/close
  ps2pdf_crop, param.output_dir+'/check_corr_matrix_'+strtrim(param.scan_list[param.iscan],2)
  loadct,39

  if not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'pdftk '+param.output_dir+'/check_corr_matrix_*.pdf cat output '+param.output_dir+'/check_corr_matrix.pdf'
  if not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'rm -rf '+param.output_dir+'/check_corr_matrix_*.pdf'

  ;;------- Plot 
  range1mm_ps = [0.001,10]
  range1mm_toi = [-3,3]
  range2mm_ps = [0.001,10]
  range2mm_toi = [-1,1]
  
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/check_TOI_PS_'+strtrim(param.scan_list[param.iscan],2)+'.ps'
  for ikid = 0, n1mm-1 do begin
     wgood = where(data.flag[w1mm[ikid]] eq 0, nwgood, comp=wbad, ncomp=nwbad)
     if nwgood ne 0 then begin
        power_spec, data.RF_dIdQ[w1mm[ikid]], !nika.f_sampling, ps, fr
        wssi = where(data.subscan mod 2 eq 1, nwssi) ;odd subscan

        !p.multi=[0,1,2]
        plot, time, data.RF_dIdQ[w1mm[ikid]], yr=range1mm_toi, xtitle='Time (s)', ytitle='Flux (Jy)',title='KID numdet '+strtrim(kidpar[w1mm[ikid]].numdet,2)+' - Scan '+strtrim(param.scan_list[param.iscan],2), /xs, ystyle=1
        if nwssi ne 0 then oplot, time[wssi], data[wssi].RF_dIdQ[w1mm[ikid]], col=150
        if nwbad ge 2 then oplot, time[wbad], data[wbad].RF_dIdQ[w1mm[ikid]], col=250, psym=3

        plot_oo, fr, ps, yr=range1mm_ps, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)',$
                 title='KID numdet '+strtrim(kidpar[w1mm[ikid]].numdet,2), /xs, ystyle=1
        oplot, fr, ps*0+0.0001, col=250, linestyle=2
        oplot, fr, ps*0+0.001, col=250, linestyle=2
        oplot, fr, ps*0+0.01, col=250, linestyle=2
        oplot, fr, ps*0+0.1, col=250, linestyle=2
        oplot, fr, ps*0+1, col=250, linestyle=2
        oplot, fr, ps*0+10, col=250, linestyle=2
        oplot, fr, ps*0+100, col=250, linestyle=2
        oplot, fr, ps*0+1000, col=250, linestyle=2
        !p.multi = 0
     endif
  endfor
  for ikid = 0, n2mm-1 do begin
     wgood = where(data.flag[w2mm[ikid]] eq 0, nwgood, comp=wbad, ncomp=nwbad)
     if nwgood ne 0 then begin
        power_spec, data.RF_dIdQ[w2mm[ikid]], !nika.f_sampling, ps, fr
        wssi = where(data.subscan mod 2 eq 1, nwssi) ;odd subscan
        
        !p.multi=[0,1,2]
        plot, time, data.RF_dIdQ[w2mm[ikid]], yr=range2mm_toi, xtitle='Time (s)', ytitle='Flux (Jy)',$
              title='KID numdet '+strtrim(kidpar[w2mm[ikid]].numdet,2)+' - Scan '+strtrim(param.scan_list[param.iscan],2), /xs, ystyle=1
        if nwssi ne 0 then oplot, time[wssi], data[wssi].RF_dIdQ[w2mm[ikid]], col=150
        if nwbad ge 2 then oplot, time[wbad], data[wbad].RF_dIdQ[w2mm[ikid]], col=250, psym=3

        plot_oo, fr, ps, yr=range2mm_ps, xtitle='Frequency (Hz)', ytitle='P(f) (Jy.Hz!U-1/2!N)',$
                 title='KID numdet '+strtrim(kidpar[w2mm[ikid]].numdet,2), /xs, ystyle=1
        oplot, fr, ps*0+0.0001, col=250, linestyle=2
        oplot, fr, ps*0+0.001, col=250, linestyle=2
        oplot, fr, ps*0+0.01, col=250, linestyle=2
        oplot, fr, ps*0+0.1, col=250, linestyle=2
        oplot, fr, ps*0+1, col=250, linestyle=2
        oplot, fr, ps*0+10, col=250, linestyle=2
        oplot, fr, ps*0+100, col=250, linestyle=2
        oplot, fr, ps*0+1000, col=250, linestyle=2
        !p.multi = 0
     endif
  endfor
  device,/close
  ps2pdf_crop, param.output_dir+'/check_TOI_PS_'+strtrim(param.scan_list[param.iscan],2)

  ;;if not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'pdftk '+param.output_dir+'/check_TOI_PS_*.pdf cat output '+param.output_dir+'/check_TOI_PS.pdf'
  ;;if not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'rm -rf '+param.output_dir+'/check_TOI_PS_*.pdf'

  SET_PLOT, mydevice

  return
end
