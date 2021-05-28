;+
;PURPOSE: Flag pulse tube lines and remove low frequencies
;
;INPUT: fc: low frequency cutoff
;       larg: width of the range over which we look for lines 
;       nsigma: number of sigma at wich we flag
;       cut_f: frequency above which we look for lines
;       data: the raw data
;       dataclean: the contaminated data
;
;KEYWORD: check: set this keyword to check the result
;
;OUTPUT: The filters data.
;
;LAST EDITION: 
;   2013: creation (adam@lpsc.in2p3.fr)
;   21/09/2013: reiteration for more efficient flag
;-

pro nika_pipe_linefilter, fc, larg, nsigma, cut_f, data, dataclean, check=check
  
  ;;------- Define the frequency vector
  data = reform(data)  
  ndata = n_elements(data)      ;Number of points in the TOI
  n2 = n_elements(data)/2
  fr  = dindgen(n2+1)/double(n2) * !nika.f_sampling/2.0 ;Frequency
  if ((ndata mod 2) eq 0) then fr=[fr, -1*reverse(fr[1:n2-1])]
  if ((ndata mod 2) eq 1) then fr=[fr, -1*reverse(fr[1:*])]
  
  ;;------- Compute the power spectrum
  power_spec, data, !nika.f_sampling, spectre, f_spec
  
  ;;------- Flag the lines
  indice = lindgen(n2)                     ;index des points
  ind_cut = long(cut_f/max(f_spec)*n2) - 1 ;index correspondant a cut_f
  
  nflag = 0                     ;nombre de points flagged
  x1 = ind_cut                  ;we start to check out at cut_f
  spectre_loop = spectre
  while x1 le (n2-1) do begin
     x2 = (x1 + larg) < (n2-1)

     x = dindgen(x2-x1+1)
     y = spectre[x1:x2]

     loc_no_line = where(x eq x, nloc_no_line) ;first consider no line
     if nloc_no_line ge 4 then begin
        nitt = 5
        for iit=1, nitt do begin
           if nloc_no_line ge 2 then begin
              ;;------- Remove baseline
              error = dblarr(n_elements(x)) + 1e6
              error[loc_no_line] = 1
              fit = poly_fit(x, y, 2, yfit=baseline, measure_errors=error)
              ps_bl = y - baseline
              
              ;;------- Iterate away from potential lines
              sig_spec = stddev(ps_bl[loc_no_line])
              selrange = where(ps_bl le nsigma * sig_spec,nselrange)
              if nselrange gt 3 then sig_spec = stddev(ps_bl[selrange])
              loc_no_line = [where(ps_bl le 2*float(nitt)/float(iit) * sig_spec), nloc_no_line]
           endif
        endfor
        
        ;;------- Flag
        spectre_loop[x1:x2] = spectre_loop[x1:x2] - baseline
        flag_loop = where(spectre_loop gt nsigma*sig_spec and indice ge x1 and indice le x2, nflag_loop)
        
        if (nflag_loop ne 0) then begin
           if nflag eq 0 then flag = flag_loop else flag = [flag, flag_loop]
        endif

        nflag = nflag + nflag_loop
     endif
     x1 = x2 +1
  endwhile

  ;;------- Define the line filter
  filter_pos = dblarr(n2) + 1
  if ((ndata mod 2) eq 0) then filter_neg = dblarr(n2-1) + 1 else filter_neg = dblarr(n2) + 1

  if nflag ne 0 then begin 
     filter_pos[flag] = 0 
     filter_neg[flag] = 0 
  endif

  filter_neg = reverse(filter_neg)  
  filter     = [1,filter_pos,filter_neg]
  
  ;;------- Low frequency filter
  if fc[0] ne 0 or fc[1] ne 0 then begin  
     z1 = where(abs(fr) lt fc[0])              ;low freq zone
     z2 = where(fr gt fc[0] and fr lt fc[1])   ;transition at positive low freq
     z3 = where(fr gt -fc[1] and fr lt -fc[0]) ;transition at negative low freq
     
     cosfilt = dblarr(ndata) + 1.0
     cosfilt[z1] = 0                                                 ;cut low freq
     cosfilt[z2] = (sin((!pi/2.0) * (fr[z2]-fc[0])/(fc[1]-fc[0])))^2 ;cos^2 transition at positive low freq
     cosfilt[z3] = (cos((!pi/2.0) * (fr[z3]+fc[1])/(fc[1]-fc[0])))^2 ;cos^2 transition at negative low freq
  endif else begin
     cosfilt = 1
  endelse

  ;;------- Apply the filter and get filtered data
  df_filt = fft(data,/double) * filter * cosfilt
  dataclean = double(fft(df_filt,/double,/inv))

  ;;------- Case we want to check
  if keyword_set(check) then begin
     power_spec,dataclean,!nika.f_sampling,spectre_clean,f_spec
     plot_oo, f_spec,spectre
     oplot, f_spec,spectre_clean,col=250
     stop
  endif

end
