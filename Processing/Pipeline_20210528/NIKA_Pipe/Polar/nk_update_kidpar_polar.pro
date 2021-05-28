
pro nk_update_kidpar_polar, param, info, kidpar, param_c

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif


;; Now that the pointing is computed for each kid in nk_getdata, make sure that
;; by default, I don't get NaNs
kidpar.nas_x        = 0.d0
kidpar.nas_y        = 0.d0
kidpar.nas_center_x = 0.d0
kidpar.nas_center_y = 0.d0
;; Adding two parameters to account two polarization states
;; kidpar.pol_offset_x = 0.d0
;; kidpar.pol_offset_y = 24 ; arcsec, 0.4 arcmin shifted image by prism

if strlen( param.file_kidpar) ne 0 then begin
   if not param.silent then message, /info, "Input kidpar = "+strtrim( param.file_kidpar,2)

   ;; Useful quantities
   tags  = tag_names(kidpar)
   ntags = n_elements(tags)
   filex = file_test( param.file_kidpar)

   ;; Read input kidpar
   if filex ne 1 then begin
      nk_error, 'This requested param.file_kidpar does not exist: '+ strtrim(param.file_kidpar,2)
      return
   endif
   kidpar_a = mrdfits( param.file_kidpar, 1, /silent)
   tags_a   = tag_names(kidpar_a)
   ntags_a  = n_elements( tags_a)

   ;; Check that all read kids have a counterpart in the input kidpar
   for i=0, n_elements(kidpar)-1 do begin
      w = where( kidpar_a.numdet eq kidpar[i].numdet, nw)
      if nw eq 0 then begin
         nk_error, info, "Numdet "+strtrim(kidpar[i].numdet,2)+" has been read in nk_getdata but is not present in "+strtrim(param.file_kidpar,2)
         message, /info, info.error_message
         return
      endif
   endfor

   ;; Overwrite the raw kidpar parameters by those from the input one
   for i=0, n_elements(kidpar_a)-1 do begin
      wdet = where( kidpar.numdet eq kidpar_a[i].numdet, nwdet)
      if nwdet gt 1 then begin
         nk_error, strtrim(nwdet,2)+" kids have the same numdet = "+strtrim(kidpar_a[i].numdet,2)+" ?!"
         return
      endif
      if nwdet eq 1 then begin
         for j=0, ntags_a-1 do begin
            wtag = where( strupcase( tags) eq strupcase(tags_a[j]), nwtag)
            if nwtag ne 0 then kidpar[wdet].(wtag) = kidpar_a[i].(j)
         endfor
      endif
   endfor

endif else begin
   ;; Initialize kidpar

   ;; default init with lab values
   wa = where( strupcase(kidpar.acqbox) eq 0, nwa)
   wb = where( strupcase(kidpar.acqbox) eq 1, nwb)
   if nwa ne 0 then begin
      kidpar[wa].array = 1                ; make sure
      kidpar[wa].lambda = !nika.lambda[0] ; make sure
   endif
   if nwb ne 0 then begin
      kidpar[wb].array = 2                ; make sure
      kidpar[wb].lambda = !nika.lambda[1] ; make sure
   endif

   ;; update with fligh configuration
   if strmid( string(param.day,format="(I8.8)"), 0, 6) eq '201211' then begin
      wa = where( strupcase(kidpar.acqbox) eq 1, nwa)
      wb = where( strupcase(kidpar.acqbox) eq 2, nwb)
      if nwa ne 0 then begin
         kidpar[wa].lambda = !nika.lambda[0]
         kidpar[wa].array  = 1
      endif
      if nwb ne 0 then begin
         kidpar[wb].lambda = !nika.lambda[1]
         kidpar[wb].array  = 2
      endif
   endif

   if tag_exist( param_c, "AF_MOD")  then afmod = double( param_c.AF_MOD)*1000.d0 else afmod = 0.d0
   if tag_exist( param_c, "A_F_MOD") then afmod = double( param_c.A_F_MOD)        else afmod = 0.d0
   if tag_exist( param_c, "BF_MOD")  then bfmod = double( param_c.BF_MOD)*1000.d0 else bfmod = 0.d0
   if tag_exist( param_c, "B_F_MOD") then bfmod = double( param_c.B_F_MOD)        else bfmod = 0.d0
   
   if nwa ne 0 then kidpar[wa].df = afmod
   if nwb ne 0 then kidpar[wb].df = bfmod
endelse

end
