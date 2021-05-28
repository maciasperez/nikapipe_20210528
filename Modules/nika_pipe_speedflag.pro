;+
;PURPOSE: Flag the data when the telescope is moving with anomalous speed
;
;INPUT: The param and data structure.
;OUTPUT: The valid location.
;KEYWORDS: -brutal: Cut even the first and the last subscan.
;          -safe: Cut the 51 first and last points because RFdIdQ
;                 might be undefined there. (Recomanded)
;LAST EDITION: 23/01/2012
;              16/06/2013: change everything (now it uses the scan speed)
;              05/01/2014: add the loc_bad keyword (complement of loc_ok)
;              27/04/2014: add the keyword acc_flag_lissajous=[max_acc_x, max_acc_y]
;              03/07/2015: use the uncut part of the flag for the
;                          median calculation
;-

pro nika_pipe_speedflag, param, data, $
                         check=check, $
                         ps=ps, $
                         no_merge_fig=no_merge_fig, $
                         acc_flag_lissajous=acc_flag_lissajous, $
                         w_nocut=w_nocut

  if param.scan_type[param.iscan] eq 'otf_azimuth' or param.scan_type[param.iscan] eq 'otf_elevation' or param.scan_type[param.iscan] eq 'otf_diagonal' then begin

     if param.scan_type[param.iscan] eq 'otf_azimuth' then v = deriv(data.ofs_az)*!nika.f_sampling
     if param.scan_type[param.iscan] eq 'otf_elevation' then v = deriv(data.ofs_el)*!nika.f_sampling
     if param.scan_type[param.iscan] eq 'otf_diagonal' then $
        v = sqrt((deriv(data.ofs_el))^2 + (deriv(data.ofs_el))^2)*!nika.f_sampling
     if param.scan_type[param.iscan] eq 'otf_azimuth' then vcomp = deriv(data.ofs_el)*!nika.f_sampling
     if param.scan_type[param.iscan] eq 'otf_elevation' then vcomp = deriv(data.ofs_az)*!nika.f_sampling
     if param.scan_type[param.iscan] eq 'otf_diagonal' then vcomp = deriv(data.ofs_az)*0
     
     ;;------- First guess
     if keyword_set(w_nocut) then begin
        if param.scan_type[param.iscan] eq 'otf_azimuth' then med = median(abs(v[w_nocut]))
        if param.scan_type[param.iscan] eq 'otf_elevation' then med = median(abs(v[w_nocut]))
        if param.scan_type[param.iscan] eq 'otf_diagonal' then med = median(abs(v[w_nocut]))
     endif else begin
        if param.scan_type[param.iscan] eq 'otf_azimuth' then med = median(abs(v))
        if param.scan_type[param.iscan] eq 'otf_elevation' then med = median(abs(v))
        if param.scan_type[param.iscan] eq 'otf_diagonal' then med = median(abs(v))
     endelse
     ind_cut = indgen(n_elements(v))
     flag_cut = intarr(n_elements(v))+1
     if keyword_set(w_nocut) then flag_cut[w_nocut] = 0 else flag_cut = 0
     
     flag = where(abs(v) gt 1.5*med or abs(v) lt 0.5*med or abs(vcomp) gt 5 or flag_cut eq 1, nflag, $
                  comp=cflag)
     
     ;;------- Iteration, just in case
     for iit=0, 5 do begin
        if param.scan_type[param.iscan] eq 'otf_azimuth' then med = median(abs(v[cflag]))
        if param.scan_type[param.iscan] eq 'otf_elevation' then med = median(abs(v[cflag]))
        if param.scan_type[param.iscan] eq 'otf_diagonal' then med = median(abs(v[cflag]))
        flag = where(abs(v) gt 1.5*med or abs(v) lt 0.5*med or abs(vcomp) gt 5 or flag_cut eq 1, nflag, $
                     comp=cflag)
     endfor
     
     ;;------ Print the flagged percentage
     inside_ss = where(data.subscan ge 1 and data.subscan le max(data.subscan), ninside_ss)
     flag_ss = where(data.subscan ge 1 and data.subscan le max(data.subscan) and $
                     (abs(v) gt 1.5*med or abs(v) lt 0.5*med or abs(vcomp) gt 5), nflag_ss)
     message, /info, 'Flagged part of the scan with speed: '+strtrim(nflag_ss/!nika.f_sampling,2)+' sec'
     message, /info, 'Flagged part of the scan with speed: '+strtrim(100*double(nflag_ss)/double(ninside_ss),2)+' %'
     
     ;;------- Flag data.flag
     if nflag ne 0 then nika_pipe_addflag, data, 11, wsample=flag

  endif else if keyword_set(acc_flag_lissajous) then begin
     accx = deriv(deriv(data.ofs_az)*!nika.f_sampling)*!nika.f_sampling
     accy = deriv(deriv(data.ofs_el)*!nika.f_sampling)*!nika.f_sampling
     flag = where(abs(sqrt(accx^2 + accy^2)) gt acc_flag_lissajous, nflag, comp=cflag)
     if nflag ne 0 then nika_pipe_addflag, data, 11, wsample=flag     
  endif else nflag = 0

  ;;------- Checking plot if requested
  title_az_1 = 'Azimuthal speed ("/s)'
  title_el_1 = 'Elevation speed ("/s)'
  title_az_2 = 'Azimuthal offset (")'
  title_el_2 = 'Elevation offset (")'
  daz = data.ofs_az
  del = data.ofs_el

  if strupcase(param.projection.type) eq "PROJECTION" then begin
     alpha = data.paral
     daz =  -cos(alpha)*data.ofs_az - sin(alpha)*data.ofs_el
     del =  -sin(alpha)*data.ofs_az + cos(alpha)*data.ofs_el
  endif
  
  if keyword_set(check) then begin
     time = dindgen(n_elements(data))/!nika.f_sampling
     
     wcut = nika_pipe_wflag(data.flag[0], [7,8,9], comp=w_nocut, ncomp=nw_nocut)

     if not keyword_set(ps) then window, 14, xsize=1000, ysize=700
     if keyword_set(ps) then begin
        SET_PLOT, 'PS'
        device,/color, bits_per_pixel=256, filename=param.output_dir+'/check_flag_speed_'+strtrim(param.scan_list[param.iscan],2)+'.ps'
     endif
     !p.multi = [0,2,2]
     plot, time, deriv(daz)*!nika.f_sampling, ytitle=title_az_1, xtitle='Time (s)', psym=3, yr=[-100,100], /xs, title=param.scan_list[param.iscan], charsize=1,symsize=3
     if nflag ne 0 then oplot, time[flag], (deriv(daz)*!nika.f_sampling)[flag], col=250, psym=3, symsize=3
     legendastro, ['All data', 'Flagged data'], col=[0,250], psym=8, box=0, /right, /top, charsize=0.7,spacing=0.3

     plot, time, deriv(del)*!nika.f_sampling, ytitle=title_el_1, xtitle='Time (s)', psym=3, yr=[-100,100], /xs, title=param.scan_list[param.iscan], charsize=1,symsize=3
     if nflag ne 0 then oplot, time[flag], (deriv(del)*!nika.f_sampling)[flag],col=250,psym=3,symsize=3
     legendastro, ['All data', 'Flagged data'], col=[0,250], psym=8, box=0, /right, /top, charsize=0.7,spacing=0.3

     if nw_nocut ne 0 then plot, daz, del, xtitle=title_az_2, ytitle=title_el_2, title=param.scan_list[param.iscan], charsize=1, yr=[-1.25*max(abs(del[w_nocut])), 2*max(abs(del[w_nocut]))], xr=[-1.25*max(abs(daz[w_nocut])), 1.25*max(abs(daz[w_nocut]))], ystyle=1, xstyle=1 else plot, daz, del, xtitle=title_az_2, ytitle=title_el_2, title=param.scan_list[param.iscan], charsize=1, yr=[-1.25*max(abs(del)), 2*max(abs(del))], xr=[-1.25*max(abs(daz)), 1.25*max(abs(daz))], ystyle=1, xstyle=1
     if nw_nocut ne 0 then oplot, daz[w_nocut], del[w_nocut], col=150
     if nflag ne 0 then oplot, daz[flag], del[flag], col=250, psym=3, symsize=3
     legendastro, ['All data', 'Cut scan', 'Flagged data'], col=[0,150,250], psym=8, box=0, /right, /top, charsize=0.7,spacing=0.3
     !p.multi = 0

     if keyword_set(ps) then begin
        device,/close
        SET_PLOT, 'X'
        ps2pdf_crop, param.output_dir+'/check_flag_speed_'+strtrim(param.scan_list[param.iscan],2)
     endif

     if keyword_set(ps) and not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'pdftk '+param.output_dir+'/check_flag_speed_*.pdf cat output '+param.output_dir+'/check_flag_speed.pdf'
     if keyword_set(ps) and not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then spawn, 'rm -rf '+param.output_dir+'/check_flag_speed_*.pdf'
  endif

  return
end
