;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
;  nk_get_cm_block
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; PURPOSE: 
;        Computes a common mode from the kids that are most correlated to the
;current kid.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 21st, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_get_cm_block, param, info, toi, flag, off_source, kidpar, common_mode, isubscan=isubscan, elev=elev, ofs_el=ofs_el

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_cm_block, param, info, toi, flag, off_source, kidpar, common_mode"
   return
endif

;;--------------------------------------
;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif
nkids = n_elements( toi[*,0])
if nkids ne n_elements(kidpar) then begin
   nk_error, info, "incompatible kidpar ("+strtrim(n_elements(kidpar),2)+" kids) and toi ("+strtrim(nkids,2)+" kids)."
   return
endif
w = where( kidpar.type ne 1, nw)
if nw ne 0 then begin
   nk_error, info, "Found "+strtrim(nw,2)+" unvalid kids, whereas they should all be valid to derive the C. M."
   return
endif
;;--------------------------------------

nsn         = n_elements( toi[0,*])
common_mode = dblarr(nkids, nsn)
w8          = dblarr(nsn)


if param.debug eq 1 then begin

; TOI_SS  = TOI[*, wsubscan]
;        w8source = 1 - wsource[*,wsubscan]
;        elevation_ss = elevation[wsubscan]
;        ofs_el_ss = ofs_el[wsubscan]
  
  nkid = n_elements(kidpar)
  w1   = where( kidpar.type eq 1, nw1)
  nsn  = n_elements( toi[0,*])

  base    = toi*0.d0
  TOI_out = toi*0.d0

  ;;------- Cross Calibration
  atm_x_calib = dblarr(nkid,2)
  atm_x_calib[*,1] = 1.d0

  atmxcalib = nika_pipe_atmxcalib(toi[w1,*], 1-off_source[w1, *])
  atm_x_calib[w1, *] = atmxcalib
  
  ;;------- Compute the correlation between all KIDs and to 0
  mcorr = correlate(toi)
  wnan = where(finite(mcorr) ne 1, nwnan)
  if nwnan ne 0 then mcorr[wnan] = -1

  ;;======= Look at all KIDs
  for i=0, nw1-1 do begin
     ikid = w1[i]
     wfit = where( off_source[ikid,*] ne 0, nwfit)
     if nwfit eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
                                 'It is so large that the decorrelated KID is always on-source'

     ;;------- Search for best set of KIDs to be used for deccorelation
     corr = reform(mcorr[ikid,*])
     wbad = where(kidpar.type ne 1, nwbad) ;Force rejected KIDs not to be correlated
     if nwbad ne 0 then corr[wbad] = -1
     s_corr = corr[reverse(sort(corr))] ;Sorted by best correlation
     
     ;;First bloc with the min number of KIDs allowed
     bloc = where(corr gt s_corr[param.n_corr_bloc_min+1] and corr ne 1, nbloc)
     ;;Then add KIDs and test if correlated enough  
     sd_bloc = stddev(corr[bloc])
     mean_bloc = mean(corr[bloc])
     iter = param.n_corr_bloc_min+1
     test = 'ok'
     while test eq 'ok' and iter lt nw1-2 do begin
        if s_corr[iter] lt mean_bloc-param.nsigma_corr_bloc*sd_bloc $
        then test = 'pas_ok' $
        else bloc = where(corr gt s_corr[param.n_corr_bloc_min+iter] and corr ne 1, nbloc)
        iter += 1
     endwhile
     
     ;;------- Build the appropriate noise template
     hit_b = lonarr(nsn)        ;Number of hit in the block common mode timeline 
     cm_b = dblarr(nsn)         ;Block common mode ignoring the source
     for j=0, nbloc-1 do begin
        cm_b += (atm_x_calib[bloc[j],0] + atm_x_calib[bloc[j],1]*toi[bloc[j],*]) * off_source[bloc[j],*]
        hit_b += off_source[bloc[j],*]
     endfor
     
     loc_hit_b = where(hit_b ge 1, nloc_hit_b, COMPLEMENT=loc_no_hit_b, ncompl=nloc_no_hit_b)
     if nloc_hit_b ne 0 then cm_b[loc_hit_b] = cm_b[loc_hit_b]/hit_b[loc_hit_b]
     if nloc_no_hit_b ne 0 then cm_b[loc_no_hit_b] = !values.f_nan

     ;;------- If holes, interpolates
     if nloc_no_hit_b ne 0 then begin
        if nloc_hit_b eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
                                         'It is so large that not even a single KID used in the ' + $
                                         'common-mode can be assumed be off-source'
        warning = 'yes'
        indice = dindgen(nsn)
        cm_b = interpol(cm_b[loc_hit_b], indice[loc_hit_b], indice, /quadratic)
     endif
     
     ;;---------- Case of elevation
;     if keyword_set(elev) and keyword_set(ofs_el) and param.fit_elevation eq 'yes' then begin
;        if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
;        if strupcase(info.obs_type) ne strupcase('lissajous') then no_el = 1 ;Useless for OTF and avoid problems
no_el=1
        if no_el eq 0 then templates = transpose([[cm_b[wfit]], [elev[wfit]], [ofs_el[wfit]]])
        if no_el eq 1 then templates = transpose([[cm_b[wfit]], [elev[wfit]]])
        
        y = reform(toi[ikid,wfit])
        coeff = regress(templates, y, CONST=const, YFIT=yfit)

        if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit] + coeff[1]*elev[wfit] + coeff[2]*ofs_el[wfit]) else coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit] + coeff[1]*elev[wfit])

        TOI_out[ikid,*] = toi[ikid,*] - coeff[0]*cm_b - coeff[1]*elev  + coeff_0[0]
        if no_el eq 0 then TOI_out[ikid,*] = TOI_out[ikid,*] - coeff[2]*ofs_el

        base[ikid,*] = coeff[0]*cm_b + coeff[1]*elev - coeff_0[0]
        if no_el eq 0 then base[ikid,*] += coeff[2]*ofs_el
        
        ;;---------- Case of no elevation
;     endif else begin
;        templates = cm_b[wfit]
;        y = reform(toi[ikid,wfit])
;        coeff = regress(templates, y, CONST=const, YFIT=yfit)
;        coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit])
;        TOI_out[ikid,*] = toi[ikid,*] - coeff[0]*cm_b + coeff_0[0]
;        base[ikid,*] = coeff[0]*cm_b - coeff_0[0]
;     endelse

        w = where( finite(toi[ikid,*]) ne 1, nw)
        if nw ne 0 then stop
     endfor

  toi = toi_out
  
endif else begin

;; Correlation matrix for all valid kids far from the source and unflagged
;; samples
   mcorr = dblarr(nkids,nkids)
   for i=0, nkids-2 do begin
      for j=i+1, nkids-1 do begin
         w = where( off_source[i,*] eq 1 and $
                    off_source[j,*] eq 1 and $
                    flag[      i,*] eq 0 and $
                    flag[      j,*] eq 0, nw)
         if nw lt 10 then begin
            nk_error, info, "Less than 10 good samples to correlate numdet "+$
                      strtrim(kidpar[i].numdet,2)+" and "+strtrim(kidpar[j].numdet,2)
         endif else begin
            mcorr[i,j] = correlate( toi[i,w], toi[j,w])
            mcorr[j,i] = mcorr[i,j] ; for convenience
         endelse
      endfor
   endfor

;; For each kid, find the n kids that are most correlated to it
   for i=0, nkids-1 do begin
      order = reverse( sort( mcorr[i,*]))
      s_corr = reform( mcorr[i,order])

      ;; The current kid is self excluded since its autorcorr was not calculated
      ;; and is 0 in mcorr
      bloc = where( mcorr[i,*] ge s_corr[ param.n_corr_bloc_min+1] and $
                    mcorr ne 0, nbloc, compl=wcompl, ncompl=nwcompl)
      if nbloc eq 0 then begin
         nk_error, info, "No kid correlates to the current kid."
         return
      endif
      
      ;; Add extra kids if they are correlated enough
      sd_bloc   = stddev( mcorr[i,bloc])
      mean_bloc = mean(   mcorr[i,bloc])
      ;;iter = param.n_corr_bloc_min + 1
      iter = 2
      test = 1
      while test eq 1 and (param.n_corr_bloc_min+iter) lt nkids-2 do begin
         if s_corr[param.n_corr_bloc_min+iter] lt mean_bloc-param.nsigma_corr_bloc*sd_bloc then begin
            test=0
         endif else begin
            bloc = where( mcorr[i,*] ge s_corr[ param.n_corr_bloc_min+iter] and $
                          mcorr ne 0, nbloc, compl=wcompl, ncompl=nwcompl)
            iter++
         endelse
      endwhile

;   if nbloc ne param.n_corr_bloc_min then message, /info, "nbloc for "+strtrim(i,2)+" nbloc: "+strtrim(nbloc,2)

      ;; Compute the median common mode for this bloc
      nk_get_cm_sub_2, param, info, toi[bloc,*], flag[bloc,*], off_source[bloc,*], kidpar[bloc], cm

;;   ;; Add extra kids if they correlate as well as the previous ones
;;   if nwcompl ne 0 then begin

      ;; Determine valid samples for the regress
      wsample = where( off_source[i,*] eq 1 and flag[i,*] eq 0, nwsample)
      if nwsample lt param.nsample_min_per_subscan then begin
         ;; do not project this subscan for this kid
         flag[i,*] = 2L^7
      endif else begin

         ;; Regress the templates and the data off source
         coeff = regress( cm[wsample], reform( toi[i,wsample]), $
                          CHISQ= chi, CONST= const, /DOUBLE, STATUS=status)

         ;; Subtract the templates everywhere
                                ;yfit = dblarr(nsn) + const
                                ;for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
         yfit = const + coeff[0]*cm
         common_mode[i,*] = yfit

      endelse
   endfor
endelse

end
