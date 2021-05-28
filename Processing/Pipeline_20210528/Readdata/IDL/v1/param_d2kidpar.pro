
;; ajoute les bonnes colonnes apres read_nika.pro

;pro param_d2kidpar, param_d, kidpar, first_det, n_read_det
pro param_d2kidpar, param_d, kidpar,  nb_detecteur_lu , list_detecteur

nkids = n_elements( param_d.(0))

;if( param_d[0].type eq 101752 ) then begin 
;		print, "correction des types car on trouve  101752 "
;		 param_d.type = param_d.type-101752 + (65536*256)
;	endif

;; Create kidpar

;; v833
;; strexc = "kidpar = create_struct('name', 'a', 'raw_num', -1L, 'numdet', -1L, "+$
;;          "'nas_x', 0.d0, 'nas_y', 0.d0, 'nas_center_x', 0.d0, 'nas_center_y', 0.d0, 'magnif', 0.d0, "+$
;;          "'calib', 0.d0, 'atm_x_calib', 0.d0, 'fwhm', 0.d0, 'fwhm_x', 0.d0, 'fwhm_y', 0.d0, "+$
;;          "'lambda', 0.d0, 'num_array', 0L, 'units', 'Jy/Beam', 's1', 0.d0, 's2', 0.d0, 'a_peak', 0.d0, 'tau', 0.d0, 'el_source', 0.d0 "

;;v834 tau --> tau0
strexc = "kidpar = create_struct('name', 'a', 'raw_num', -1L, 'numdet', -1L, "+$
         "'nas_x', 0.d0, 'nas_y', 0.d0, 'nas_center_x', 0.d0, 'nas_center_y', 0.d0, 'magnif', 0.d0, "+$
         "'calib', 0.d0, 'calib_fix_fwhm', 0.d0, 'atm_x_calib', 0.d0, 'fwhm', 0.d0, 'fwhm_x', 0.d0, 'fwhm_y', 0.d0, 'theta', 0.d0, "+$
         "'lambda', 0.d0, 'num_array', 0L, 'units', 'Jy/Beam', 's1', 0.d0, 's2', 0.d0, 'a_peak', 0.d0, 'tau0', 0.d0, 'el_source', 0.d0 "
         

;; Copy or create param_d tags
d_tags = tag_names( param_d)
nd_tags = n_elements( d_tags)
for i=0, nd_tags-1 do begin
   p=0
   if strupcase( d_tags[i] eq "NAME") then p=1
   if strupcase( d_tags[i] eq "RES_FRQ") then begin
      strexc = strexc+", 'res_frq', 0.d0"
      p=1
   endif
   if (p eq 0) and (strupcase( d_tags[i]) eq "RES_LG") then begin
      strexc = strexc+", 'res_lg', 0.d0, 'k_flag', 0L"
      p=1
   endif
   
;   if (p eq 0) and (strupcase( d_tags[i]) eq "TYPE") then begin
;      strexc = strexc+", 'type', 0L, 'acqbox', 0L, 'array', 0L"
;      p=1
;   endif
   
   ; if tag not found, then create it
   if (p eq 0) then begin
      strexc = strexc+", '"+d_tags[i]+"', 0L"
   endif
endfor
strexc = strexc+")"
dummy = execute( strexc)

;; Replicate
kidpar = replicate( kidpar, nkids)

for i=0, nd_tags-1 do begin
   p=0
   if strupcase( d_tags[i] eq "RES_FRQ") then begin
      kidpar.res_frq = param_d.res_frq * 10.d0
      p=1
   endif
   if (p eq 0) and (strupcase( d_tags[i]) eq "RES_LG") then begin
      kidpar.k_flag = param_d.res_lg/2L^24
      kidpar.res_lg = param_d.res_lg mod 2L^24
      p=1
   endif

;   if (p eq 0) and (strupcase( d_tags[i]) eq "TYPE") then begin
;      kidpar.acqbox = (param_d.type/65536) mod 256
;      kidpar.array = param_d.type/(65536*256)
;      kidpar.type = param_d.type mod 65536
;      p=1
;   endif

   if (p eq 0 ) then begin
      w = where( tag_names( kidpar) eq d_tags[i], nw)
      if nw eq 0 then begin
         print, "probleme"
         stop
      endif else begin
         kidpar.(w) = param_d.(i)
      endelse
   endif
endfor


;; Determination de numdet
kidpar.raw_num = lindgen( nkids)
for ikid=0, nkids-1 do begin
   if (kidpar[ikid].type eq 1) then begin
      name = kidpar[ikid].name
      l = strlen( name)
      str_numdet = strmid(name,l-1) ; init
      for i=l-2, 0, -1 do begin
         char = strmid(name,i,1)
         if  (byte(char) ge 48) and (byte(char) le 57) then begin
            str_numdet = char+str_numdet
         endif
      endfor
      kidpar[ikid].numdet = long( str_numdet)
   endif
endfor

;;w = where(kidpar.type eq 1, nw)
;;;print, "on trouve" , nw , " detecteurs valides"
;; Keep only detectors in the list
;;kidpar = kidpar[first_det:first_det+n_read_det-1]

;;  -------------------------    je  garde la liste  des  detecteurs demandes   --------------------------
kidpar = kidpar[list_detecteur]

end
