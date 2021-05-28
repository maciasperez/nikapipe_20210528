;+
;PURPOSE: To use statistical tests to reject KIDs that are unusable
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The data structure with the kidpar.type changed to -1 if the
;        KID is rejected
;
;LAST EDITION: 
;   17/01/2013: creation (adam@lpsc.in2p3.fr)
;   05/01/2014: remove all the useless things at the end and flag KIDs
;               not enough correlated with the other
;   11/02/2014: Request median correlation to be greater then 0.5
;   27/04/2014: Add the keyword median_cut=[min_median_1mm,
;               min_median_2mm]
;   07/07/2015: restaure off tones in kidpar
;-

pro nika_pipe_flagkid, param, data, kidpar, $
                       bad_kids=bad_kids, $
                       show=show, $
                       ps=ps, $
                       no_merge_fig=no_merge_fig, $
                       silent=silent, $
                       median_cut=median_cut, $
                       found_bad_kids=found_bad_kids, $
                       nbad=nbad

  ;;------- Flag the samples that should not be used
  wcut1mm = nika_pipe_wflag(data.flag[0], [7,8,9], comp=wnocut1mm)
  wcut2mm = nika_pipe_wflag(data.flag[0], [7,8,9], comp=wnocut2mm)

  ;;------- Flag additional KIDs using uncorrelated KIDs
  w1mm = where(kidpar.type eq 1 and kidpar.array eq 1, n1mm)
  w2mm = where(kidpar.type eq 1 and kidpar.array eq 2, n2mm)
  toi1mm = data[wnocut1mm].RF_dIdQ[w1mm]
  toi2mm = data[wnocut2mm].RF_dIdQ[w2mm]

  if wnocut1mm[0] eq (-1) or wnocut2mm[0] eq (-1) then begin
     print, 'Not enough good data for nika_pipe_flagkid to work '+ $
            strtrim( long(median(data.scan)), 2)
     currentscan = param.iscan
     param.scan_flag[currentscan] = 1
     goto, the_end
  endif 
  cor1mm = correlate(toi1mm)    ;correlation matrices
  cor2mm = correlate(toi2mm)
  
  med1mm = dblarr(n1mm)
  for ikid=0, n1mm-1 do med1mm[ikid] = median(cor1mm[ikid,*])
  med2mm = dblarr(n2mm)
  for ikid=0, n2mm-1 do med2mm[ikid] = median(cor2mm[ikid,*])

  if min(finite(med1mm)) eq 0 or min(finite(med1mm) eq 0) then param.flag.uncorr='no'

  if param.flag.uncorr eq 'yes' then begin
     if not keyword_set(median_cut) then begin
        good1mm = where(med1mm gt median(med1mm)-3*stddev(med1mm) and med1mm gt 0.0, ngood1mm, comp=nogood1mm, ncomp=nnogood1mm)
        for ii=0, 5 do if ngood1mm gt 0 then good1mm = where(med1mm gt median(med1mm[good1mm])-3*stddev(med1mm[good1mm]), ngood1mm, comp=nogood1mm, ncomp=nnogood1mm)
        
        good2mm = where(med2mm gt median(med2mm)-3*stddev(med2mm) and med2mm gt 0.0, ngood2mm, comp=nogood2mm, ncomp=nnogood2mm)
        for ii=0, 5 do if ngood2mm gt 0 then good2mm = where(med2mm gt median(med2mm[good2mm])-3*stddev(med2mm[good2mm]), ngood2mm, comp=nogood2mm, ncomp=nnogood2mm)
     endif else begin
        good1mm = where(med1mm gt median_cut[0], ngood1mm, comp=nogood1mm, ncomp=nnogood1mm)
        good2mm = where(med2mm gt median_cut[1], ngood2mm, comp=nogood2mm, ncomp=nnogood2mm)
     endelse
  endif else begin
     good1mm = where(med1mm gt -1, ngood1mm, comp=nogood1mm, ncomp=nnogood1mm)     
     good2mm = where(med2mm gt -1, ngood2mm, comp=nogood2mm, ncomp=nnogood2mm)
  endelse

  if not keyword_set(silent) then message,/info, strtrim(nnogood1mm,2)+'/'+strtrim(n1mm,2)+' KIDs flagged at 1mm'
  if not keyword_set(silent) then message,/info, strtrim(nnogood2mm,2)+'/'+strtrim(n2mm,2)+' KIDs flagged at 2mm'

  wflag = [-1]
  if nnogood1mm ne 0 then wflag = [wflag, w1mm[nogood1mm]]
  if nnogood2mm ne 0 then wflag = [wflag, w2mm[nogood2mm]]
  nflag = n_elements(wflag) - 1
  if nflag ne 0 then numdet_flag = kidpar[wflag[1:*]].numdet

  if keyword_set(show) then begin
     if not keyword_set(ps) then window, 25, xsize=1000, ysize=800, title='Flag based on lack of correlation'
     if keyword_set(ps) then begin
        SET_PLOT, 'PS'
        device,/color, bits_per_pixel=256, filename=param.output_dir+'/check_flag_corr_'+strtrim(param.scan_list[param.iscan],2)+'.ps'
     endif
     !p.multi = [0,2,2]
     dispim_bar, cor1mm, /asp,/noc, title='1mm KIDs correlation matrix', charsize=0.7, /silent
     dispim_bar, cor2mm, /asp,/noc, title='2mm KIDs correlation matrix', charsize=0.7, /silent
     ind1mm = dindgen(n1mm)
     ind2mm = dindgen(n2mm)
     plot, ind1mm, med1mm, xtitle='KID number', ytitle='Median correlation with other KIDs',$
           /ys, /xs, charsize=0.7
     if ngood1mm ne 0 then oplot, ind1mm[good1mm], med1mm[good1mm], col=250
     legendastro, ['Valid KIDs', 'Flagged KIDs'], col=[250,0], psym=[0,0], thick=[3,3],$
                  box=0,/right,/bottom, charsize=0.7
     plot, ind2mm, med2mm, xtitle='KID number', ytitle='Median correlation with other KIDs',$
           /ys, /xs, charsize=0.7
     if ngood2mm gt 1 then oplot, ind2mm[good2mm], med2mm[good2mm], col=250
     legendastro, ['Valid KIDs', 'Flagged KIDs'], col=[250,0], psym=[0,0], thick=[3,3],$
                  box=0,/right,/bottom, charsize=0.7
     cgText, 0.5, 1.0, ALIGNMENT=0.5, CHARSIZE=1.25, /NORMAL, strtrim(param.scan_list[param.iscan],2)
     !p.multi = 0
     if keyword_set(ps) then begin
        device,/close
        SET_PLOT, 'X'
        ps2pdf_crop, param.output_dir+'/check_flag_corr_'+strtrim(param.scan_list[param.iscan],2)
     endif

     if keyword_set(ps) and not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'pdftk '+param.output_dir+'/check_flag_corr_*.pdf cat output '+param.output_dir+'/check_flag_corr.pdf'
     if keyword_set(ps) and not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'rm -rf '+param.output_dir+'/check_flag_corr_*.pdf'

     ;;print, 'Numdet flagged from lack of correlation:'
     ;;if nflag ne 0 then print, numdet_flag else print, '0'
  endif

  ;;------- Remove the bad KIDs
  if keyword_set(bad_kids) then begin
     if nflag ge 1 then my_bad_kids = [bad_kids, numdet_flag] else my_bad_kids = bad_kids
  endif else begin
     if nflag ge 1 then my_bad_kids = numdet_flag else goto, the_end
  endelse
  
  my_bad_kids = my_bad_kids(rem_dup(my_bad_kids)) ;remove duplicates
  nbad = n_elements(my_bad_kids)
  for ibad = 0, nbad-1 do begin
     bad_list = where(kidpar.numdet eq my_bad_kids[ibad])
     nika_pipe_addflag, data, 6, wkid=bad_list
  endfor
  found_bad_kids = my_bad_kids
  
  the_end:
  
  ;;========== checking kids flags before doing anything else
  myw1mm = where(kidpar.type eq 1 and kidpar.array eq 1, nw1mm)
  myw2mm = where(kidpar.type eq 1 and kidpar.array eq 2, nw2mm)

  kidparn = kidpar
  w_valid_kid = nika_pipe_kid4cm(param, data, kidparn, Nvalid=nv, complement=w_bad_kid, ncomplement=nw_bad_kid)  
  nrej1mm = 0                   ; default init ?
  nrej2mm = 0                   ; default init ?
  if nw_bad_kid ne 0 then begin
     kidpar[w_bad_kid].type = -1 ;We use only Valid On KIDs and eventually Offs tones
     rej1mm = where(kidpar[w_bad_kid].type eq 1 and kidpar[w_bad_kid].array eq 1, nrej1mm)
     rej2mm = where(kidpar[w_bad_kid].type eq 1 and kidpar[w_bad_kid].array eq 2, nrej2mm)
  endif

  ;;---------- restaure off tones
  w_off_tones = where(kidparn.type eq 2, nw_off_tones)
  if nw_off_tones ne 0 then kidpar[w_off_tones].type = 2

  if (nrej1mm eq nw1mm) or (nrej2mm eq nw2mm) then param.flag.scan[param.iscan] = 1 
  if param.flag.scan[param.iscan] ne 0 then print, '==================== WARNING: scan flagged'

  return
end






