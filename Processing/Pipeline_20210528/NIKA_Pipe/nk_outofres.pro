
;+
;
; SOFTWARE:
;
; NAME: 
; nk_outofres
;
; CATEGORY:
;
; CALLING SEQUENCE:
; 
; PURPOSE: 
;        Flag the KIDs that are saturated or out of resonance
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - nika_pipe_otf_pointing_restore : Created by Laurence Perotto (LPSC)
;   17/12/2013: creation (adam@lpsc.in2p3.fr)
;   06/01/2014: use nika_pipe_addflag for flagging
;   29/01/2014: FXD: add badkid and verb keywords
;   01/02/2014: FXD: Keyword to change kidpar.flag
;        - June 12th, 2014: Ported to the new pipeline format, not
;          checked yet. N. Ponthieu
;   11/11/2014: FXD translate nika_pipe_outofres into the new nk
;version
;   19/08/2016: JFMP, correct bug for mask1 and mask2 which are made
;               for the KIDs and not for the samples
; 19/09/2016: NP, modified to deal "per array" rather than "per band".
;   Nov. 9, 2016: replaced a loop on KIDs for more efficient array
;operations (HR)
;   Sept 2019: FXD implement a different method of saturation detection
;for Cf method
;-

pro nk_outofres, param, info, data, kidpar, bypass_error=bypass_error, $
                 badkid = badkid, verb = verb;, changekid = changekid
  
;; define badkid list with a structure
badkid = replicate({sat:0, pos:0, ident:0, over:0}, n_elements( kidpar))

;;------- Flag saturated detectors (only for methods other than Cf;
;;        for Cf method, see nk_data_conventions (special processing)
if param.flag_sat eq 1 and strupcase(param.math) ne 'CF' then begin
   npix_sat = lonarr(3)
   mask3 = mask_saturated_data(data, satur_level=param.flag_sat_val)


;;; suppress the loop on KIDs to speed up the flagging:
;;; replacement:
   wkid_heavysat = where(total(mask3 ne 0, 2) gt 0.3 * n_elements(data) $
                         and kidpar.type eq 1, c_hs)
   if c_hs ge 1 then begin
      nk_add_flag, data, 2, wkid=wkid_heavysat
      badkid[wkid_heavysat].sat = 1
      for arr = 0, 2 do begin
         w = where(kidpar[wkid_heavysat].array eq arr + 1, cw)
         npix_sat(arr) += cw
      endfor
   endif
   w_sat = where(mask3 ne 0, c_sat)
   if c_sat ge 1 then nk_add_flag, data, 2, w2d_k_s=w_sat


   if not keyword_set(bypass_error) then begin
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            if npix_sat[iarray-1] eq nw1 then begin
               nk_error, info, 'All Kids of array '+strtrim(iarray,2)+$
                         ' are saturated for more than 30% of the data', silent=param.silent
               return
            endif
         endif
      endfor
   endif

   if keyword_set( verb) then begin
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then begin
            message, /info, 'Number of Kids saturated ' + $
                     '(>30% samples) in array '+strtrim(iarray,2)+': '+ $
                     strtrim(npix_sat[iarray-1], 2)+'/'+strtrim(nw1, 2)
            ww = where( tag_names(info) eq "SATURATED_KIDS_A"+strtrim(iarray,2), nww)
            if nww ne 0 then info.(ww) = npix_sat[iarray-1]
         endif
      endfor
   endif
endif

;;------- Flag tones not well set 
if param.flag_oor eq 1 then begin
   mask1 = mask_resopos(data, kidpar, tol=param.flag_oor_val)
   loc_mask1 = where(mask1 ne 0, nloc_mask1)
   npix_oor = lonarr(3)
   if nloc_mask1 ne 0 then begin
;;        nk_add_flag, data, 3, wsample=loc_mask1
      nk_add_flag, data, 3, wkid=loc_mask1

      for iarray=1, 3 do begin
         w = where( kidpar[loc_mask1].type eq 1 and $
                    kidpar[loc_mask1].array eq iarray, nw)
         if nw ne 0 then begin
            badkid[ loc_mask1[ w]].pos = 1
            npix_oor[iarray-1] = nw
         endif
      endfor
      
      if not keyword_set(bypass_error) then begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            if nw1 ne 0 then begin
               if npix_oor[iarray-1] eq nw1 then begin
                  message, /info, 'All the Kids of array '+strtrim(iarray,2)+' are out of resonance, ' + $
                           'remove this scan or set param.flag_oor = 0 ' + $
                           'to remove the flag'
               endif
            endif
         endfor
      endif
      
      if keyword_set( verb) then begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            if nw1 ne 0 then begin
               message, /info, 'Number of Kids out of resonance ' + $
                        'in array '+strtrim(iarray,2)+': '+strtrim(npix_oor[iarray-1], 2)+ $
                        '/'+strtrim(nw1, 2)
            endif
         endfor
      endif
   endif
endif

;;------- Flag identical tones in a box
if param.flag_ident eq 1 then begin
   mask3 = mask_resoident(data, kidpar, tol=param.flag_ident_val)
   loc_mask3 = where(mask3 ne 0, nloc_mask3)
   if nloc_mask3 ne 0 then begin
      nk_add_flag, data, 4, wkid=loc_mask3
      npix_ident = lonarr(3)
      for iarray=1, 3 do begin
         w = where( kidpar[loc_mask3].type eq 1 and $
                    kidpar[loc_mask3].array eq iarray, nw)
         if nw ne 0 then begin
            badkid[ loc_mask3[ w]].ident = 1
            npix_ident[iarray-1] = nw
            wtag = where( strupcase(tag_names(info)) eq "IDENTICAL_FTONE_A"+strtrim(iarray,2), nwtag)
            if nwtag ne 0 then info.(wtag) = nloc_mask3
         endif
      endfor

      if not keyword_set(bypass_error) then begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            if npix_ident[iarray-1] eq nw1 then begin
               message, /info, "All the Kids of array "+strtrim(iarray,2)+" have identical frequency, "+$
                        "remove this scan or set param.flag_ident = 0 to remove the flag."
            endif
         endfor
      endif
      
      if keyword_set( verb) then begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            message, /info, 'Number of Kids with identical tone for array '+strtrim(iarray,2)+": "+$
                     strtrim(npix_ident[iarray-1],2)+"/"+strtrim(nw1,2)
         endfor
      endif
   endif
endif


;;------- Flag overlap between resonances
if param.flag_ovlap eq 1 then begin
   mask2 = mask_resooverlap(data, kidpar, tol=param.flag_ovlap_val)
   loc_mask2 = where(mask2 ne 0, nloc_mask2)
   if nloc_mask2 ne 0 then begin
;;        nk_add_flag, data, 4, wsample=loc_mask2
      nk_add_flag, data, 4, wkid=loc_mask2
      npix_ovlap = lonarr(3)
      for iarray=1, 3 do begin
         w = where( kidpar[loc_mask2].type eq 1 and $
                    kidpar[loc_mask2].array eq iarray, nw)
         if nw ne 0 then begin
            badkid[ loc_mask2[ w]].over = 1
            npix_ovlap[iarray-1] = nw
            wtag = where( strupcase(tag_names(info)) eq "NKIDS_OVERLAP_A"+strtrim(iarray,2), nwtag)
            if nwtag ne 0 then info.(wtag) = nloc_mask2
         endif
      endfor

      if not keyword_set(bypass_error) then begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            if npix_ovlap[iarray-1] eq nw1 then begin
               message, /info, "All the Kids of array "+strtrim(iarray,2)+" are overlapping, "+$
                        "remove this scan or set param.flag_ovlap = 0 to remove the flag."
            endif
         endfor
      endif
      
      if keyword_set( verb) then begin
         for iarray=1, 3 do begin
            w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
            message, /info, 'Number of Kids overlapping (incl. id.) for array '+strtrim(iarray,2)+": "+$
                     strtrim(npix_ovlap[iarray-1],2)+"/"+strtrim(nw1,2)
         endfor
      endif
   endif
endif
   

return
end
