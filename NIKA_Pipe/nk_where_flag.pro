;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_where_flag
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_where_flag, vec, flag_num_vec, nflag=nflag, complement=complemtn, ncomplement=ncomplement
; 
; PURPOSE: 
;        Return the location of a given flag in the flag toi
; 
;INPUT: The flag vector, the requested flag index (can be a vector of
;       multiple flag)
;
;OUTPUT: The flag location
;
;KEYWORDS: - nflag: The number of flag
;          - complement: The complement position with respect to the flag
;          - ncomplement: The number of complement position with respect to the flag
; 
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)


;; Confirm comparison syntax
;; poweroftwo = [2L^0, 2L^2, 2L^8, 2L^11]
;; vec = [poweroftwo, 2L^8 + 2L^2 + 2L^6]
;; for i=0, 11 do begin
;;    print,  "i: "+string(i,form='(I2.2)')+", ", (vec and 2L^i) eq 2L^i
;; endfor

function nk_where_flag, vec, flag_num_vec, nflag=nflag, complement=complement, ncomplement=ncomplement
;-

  ntype = n_elements(flag_num_vec) ;number of flagging index
  Npt   = n_elements(vec)          ;number of data point

  flag = intarr(Npt)            ;= 0 if no flag
  for nf=0, ntype-1 do begin
     powerOfTwo = 2L^flag_num_vec[nf]
     loc = where((LONG(vec) AND powerOfTwo) EQ powerOfTwo, nloc)

     if nloc ne 0 then flag[loc] += 1
  endfor
  
  flag_pos = where(flag ne 0, nflag, complement=comp_flag, ncomplement=ncomp_flag)

  complement = comp_flag
  ncomplement = ncomp_flag
  
  return, flag_pos
end
