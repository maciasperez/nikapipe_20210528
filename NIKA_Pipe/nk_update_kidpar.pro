
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_update_kidpar
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_update_kidpar, param, info, kidpar, param_c
; 
; PURPOSE: 
;        Overwrites default values of the kidpar returned by read_nika_brute
;        with values determined on the reference scan (kid type) and completes it with
;        information relevant to pointing and calibration.
; 
; INPUT: 
;        - param, info, kidpar:
; 
; OUTPUT: 
;        - kidpar is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_update_kidpar, param, info, kidpar, param_c

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; Now that the pointing is computed for each kid in nk_getdata, make sure that
;; by default, I don't get NaNs
kidpar.nas_x        = 0.d0
kidpar.nas_y        = 0.d0
kidpar.nas_center_x = 0.d0
kidpar.nas_center_y = 0.d0

if strlen( param.file_kidpar) ne 0 then begin
   if not param.silent then message, /info, "Input kidpar = "+strtrim( param.file_kidpar,2)

   ;; Useful quantities
   tags  = tag_names(kidpar)
   ntags = n_elements(tags)
   filex = file_test( param.file_kidpar)

   ;; Read input kidpar
   if filex ne 1 then begin
      nk_error, info, 'This requested param.file_kidpar does not exist: '+ $
                strtrim(param.file_kidpar,2)
      return
   endif
   kidpar_a = mrdfits( param.file_kidpar, 1, /silent)

   tags_a   = tag_names(kidpar_a)
   ntags_a  = n_elements( tags_a)

   ;; Check that all read kids have a counterpart in the input kidpar
   nchange = 0
   for i=0, n_elements(kidpar)-1 do begin
      w = where( kidpar_a.numdet eq kidpar[i].numdet, nw)
      if nw eq 0 then begin
         nchange++
         kidpar[i].type = 5 ; 3
      endif
   endfor
   if nchange ne 0 then $
      if not param.silent then $
         message, /info, strtrim(nchange,2)+ $
                  " kids were read but were not present in "+ $
                  strtrim(param.file_kidpar, 2)+" => set their type to 5" ; 3"

   ;; Overwrite the raw kidpar parameters by those from the input one
   for i=0, n_elements(kidpar_a)-1 do begin
      wdet = where( kidpar.numdet eq kidpar_a[i].numdet, nwdet)
      if nwdet gt 1 then begin
         nk_error, info, strtrim(nwdet,2)+" kids have the same numdet = "+strtrim(kidpar_a[i].numdet,2)+" ?!"
         stop
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

   if long(!nika.run) le 12 then begin
      ;; default init with lab values
      wa = where( strupcase(kidpar.acqbox) eq 0, nwa)
      wb = where( strupcase(kidpar.acqbox) eq 1, nwb)
      if nwa ne 0 then begin
         kidpar[wa].array = 1             ; make sure
         kidpar[wa].lambda = !nika.lambda[0] ; make sure
      endif
      if nwb ne 0 then begin
         kidpar[wb].array = 2             ; make sure
         kidpar[wb].lambda = !nika.lambda[1] ; make sure
      endif
      
      ;; update with flight configuration
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

   endif else begin
      if param.lab eq 0 then begin
         ;; NIKA2
         w = where( kidpar.array eq 2, nw)
         if nw ne 0 then begin
            kidpar[w].lambda = !nika.lambda[1]
            if strupcase(!nika.acq_version) eq "V1" then begin
               kidpar[w].df = param_c.A_F_MOD
            endif else begin
               kidpar[w].df = param_c.ARRAY2_MODULFREQ
            endelse
         endif
         
         w = where( kidpar.array eq 1, nw)
         if nw ne 0 then begin
            kidpar[w].lambda = !nika.lambda[0]
            if strupcase(!nika.acq_version) eq "V1" then begin
               kidpar[w].df = param_c.E_F_MOD
            endif else begin
               kidpar[w].df = param_c.ARRAY1_MODULFREQ
            endelse
         endif

         w = where( kidpar.array eq 3, nw)
         if nw ne 0 then begin
            kidpar[w].lambda = !nika.lambda[0]
            if strupcase(!nika.acq_version) eq "V1" then begin
               kidpar[w].df = param_c.M_F_MOD
            endif else begin
               kidpar[w].df = param_c.ARRAY3_MODULFREQ
            endelse
         endif
      endif

;; Martino's email, Oct. 5th, 2015 and Feb. 16, 2016
;; Boites A, B, C, D = matrice 2mm
;; Boites E -> L = premiere matrice 1mm
;; Boites M -> T = premiere matrice 1mm
;; and array=2 for the 2mm, array=1 and 3 for the two 1mm matrices
;; Freqnorm_vec must be in this order because in nika_conviq2pf, this array is
;; refered to by kidpar.array-1.

;;      message, /info, "Check the afmod, bfmod,..., gfmod definitions."
;;      message, /info, "check the corresponding array definitions."
;;      message, /info, "Leave the temporary version to pass and debug"
;;      wa = where( strupcase(kidpar.acqbox) eq 0, nwa)
;;      wb = where( strupcase(kidpar.acqbox) eq 1, nwb)
;;      if nwa ne 0 then begin
;;         kidpar[wa].array = 1                ; make sure
;;         kidpar[wa].lambda = !nika.lambda[0] ; make sure
;;      endif
;;      if nwb ne 0 then begin
;;         kidpar[wb].array = 2                ; make sure
;;         kidpar[wb].lambda = !nika.lambda[1] ; make sure
;;      endif
;;      
;;      if tag_exist( param_c, "AF_MOD")  then afmod = double( param_c.AF_MOD)*1000.d0 else afmod = 0.d0
;;      if tag_exist( param_c, "A_F_MOD") then afmod = double( param_c.A_F_MOD)        else afmod = 0.d0
;;      if tag_exist( param_c, "BF_MOD")  then bfmod = double( param_c.BF_MOD)*1000.d0 else bfmod = 0.d0
;;      if tag_exist( param_c, "B_F_MOD") then bfmod = double( param_c.B_F_MOD)        else bfmod = 0.d0
;;      
;;      if nwa ne 0 then kidpar[wa].df = afmod
;;      if nwb ne 0 then kidpar[wb].df = bfmod
   endelse

endelse

; Do some photometric correction if required
; FXD and NP added that in March 2018
if param.do_fpc_correction eq 2 then begin
   if file_test( param.file_ptg_photo_corr) then begin
      nk_read_csv_3, param.file_ptg_photo_corr, corr
      isc = where(strmatch( strtrim(corr.day, 2)+'s'+strtrim( corr.scannum,2), $
                       param.scan),nist)

      ;; Update photometric correction
      w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
      if nw1 ge 1 then begin
         ;; Hz to Jy
         kidpar[w1].calib_fix_fwhm *= corr[ isc].fcorr1
      endif
;      print, corr[isc].fcorr1, corr[isc].fcorr2, kidpar[w1[0]].calib_fix_fwhm
      w1 = where( kidpar.type eq 1 and kidpar.array eq 3, nw1)
      if nw1 ge 1 then kidpar[w1].calib_fix_fwhm *= corr[ isc].fcorr1
      w1 = where( kidpar.type eq 1 and kidpar.array eq 2, nw1)
      if nw1 ge 1 then kidpar[w1].calib_fix_fwhm *= corr[ isc].fcorr2
   endif else message, /info, 'No pointing/photometric correction file available= -'+ $
                       param.file_ptg_photo_corr+'-'
endif


new_fields = {C0_4OMEGA:0.d0, C1_4OMEGA:0.d0}
upgrade_struct, kidpar, new_fields, kidpar_out
kidpar = kidpar_out

if param.cpu_time then nk_show_cpu_time, param, "nk_update_kidpar"

end
