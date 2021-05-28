;+
;PURPOSE: Flag the KIDs that are saturated or out of resonance
;
;INPUT: The parameter, combined map, map per scan and astrometry
;
;LAST EDITION: 
;   17/12/2013: creation (adam@lpsc.in2p3.fr)
;   06/01/2014: use nika_pipe_addflag for flagging
;   29/01/2014: FXD: add badkid and verb keywords
;   01/02/2014: FXD: Keyword to change kidpar.flag
;-

pro nika_pipe_outofres, param, data, kidpar, bypass_error=bypass_error, $
                        badkid=badkid, verb=verb, changekid=changekid
  
  w1mm = where(kidpar.type eq 1 and kidpar.array eq 1, nw1mm)
  w2mm = where(kidpar.type eq 1 and kidpar.array eq 2, nw2mm)

  ;; define badkid list with a structure
  badkid = replicate({sat:0, pos:0, over:0}, n_elements( kidpar))
  
  ;;------- Flag saturated detectors
  if param.flag.sat eq 'yes' then begin
     npix_sat1mm = 0
     npix_sat2mm = 0
     mask3 = mask_saturated_data(data, satur_level=param.flag.sat_val)
     for ikid=0, n_elements(kidpar)-1 do begin
        loc_mask3 = where(reform(mask3[ikid,*]) ne 0, nloc_mask3)

        ;;Flag all TOI if more than 30 percent saturated
        if nloc_mask3 gt 0.3*n_elements(data) then nika_pipe_addflag, data, 2, wkid=[ikid] $
        else if nloc_mask3 ne 0 then nika_pipe_addflag, data, 2, wkid=[ikid], wsample=loc_mask3
        
        if nloc_mask3 gt 0.3*n_elements(data) and kidpar[ikid].array eq 1 and kidpar[ikid].type eq 1 then begin
           npix_sat1mm += 1
           badkid[ ikid].sat = 1
        endif
        if nloc_mask3 gt 0.3*n_elements(data) and kidpar[ikid].array eq 2 and kidpar[ikid].type eq 1 then begin
           npix_sat2mm += 1
           badkid[ ikid].sat = 1
        endif
     endfor

     if not keyword_set(bypass_error) then if npix_sat1mm eq nw1mm then message, 'All the 1mm KIDs are saturated for more than 30% of the data, remove this scan or set param.flag.sat = "no" to remove the flag'
     if not keyword_set(bypass_error) then if npix_sat2mm eq nw2mm then message, 'All the 2mm KIDs are saturated for more than 30% of the data, remove this scan or set param.flag.sat = "no" to remove the flag'
     if keyword_set( verb) then message, /info, 'Number of KIDs saturated for more than 30% of the data at 1mm: '+strtrim(npix_sat1mm, 2)+'/'+strtrim(nw1mm, 2)
     if keyword_set( verb) then message, /info, 'Number of KIDs saturated for more than 30% of the data at 2mm: '+strtrim(npix_sat2mm, 2)+'/'+strtrim(nw2mm, 2)
  endif  
  
  ;;------- Flag tones not well set 
  if param.flag.oor eq 'yes' then begin
     mask1 = mask_resopos(data, kidpar, tol=param.flag.oor_val)
     loc_mask1 = where(mask1 ne 0, nloc_mask1)
     if nloc_mask1 ne 0 then begin
        nika_pipe_addflag, data, 3, wsample=loc_mask1
        ipix1mm = where(kidpar[loc_mask1].type eq 1 and kidpar[loc_mask1].array eq 1, npix_oor1mm)
        if npix_oor1mm ne 0 then badkid[ loc_mask1[ ipix1mm]].pos = 1
        ipix2mm = where(kidpar[loc_mask1].type eq 1 and kidpar[loc_mask1].array eq 2, npix_oor2mm)
        if npix_oor2mm ne 0 then badkid[ loc_mask1[ ipix2mm]].pos = 1
        if not keyword_set(bypass_error) then if npix_oor1mm eq nw1mm then message, 'All the 1mm KIDs are out of resonance, remove this scan or set param.flag.oor = "no" to remove the flag'
        if not keyword_set(bypass_error) then if npix_oor2mm eq nw2mm then message, 'All the 2mm KIDs are out of resonance, remove this scan or set param.flag.oor = "no" to remove the flag'
        if keyword_set( verb) then message, /info, 'Number of KIDs out of resonance for the data at 1mm: '+strtrim(npix_oor1mm, 2)+'/'+strtrim(nw1mm, 2)
        if keyword_set( verb) then message, /info, 'Number of KIDs out of resonance for the data at 2mm: '+strtrim(npix_oor2mm, 2)+'/'+strtrim(nw2mm, 2)
     endif
  endif
  
  ;;------- Flag overlap between resonances
  if param.flag.ovlap eq 'yes' then begin
     mask2 = mask_resooverlap(data, kidpar, tol=param.flag.ovlap_val)
     loc_mask2 = where(mask2 ne 0, nloc_mask2)
     if nloc_mask2 ne 0 then begin
        nika_pipe_addflag, data, 4, wsample=loc_mask2
        ipixo1mm = where(kidpar[loc_mask2].type eq 1 and kidpar[loc_mask2].array eq 1, npix_ovlap1mm)
        if npix_ovlap1mm ne 0 then badkid[ loc_mask2[ ipixo1mm]].over = 1
        ipixo2mm = where(kidpar[loc_mask2].type eq 1 and kidpar[loc_mask2].array eq 2, npix_ovlap2mm)
        if npix_ovlap2mm ne 0 then badkid[ loc_mask2[ ipixo2mm]].over = 1
        if not keyword_set(bypass_error) then if npix_ovlap1mm eq nw1mm then message, 'All the 1mm KIDs are overlaping, remove this scan or set param.flag.ovlap = "no" to remove the flag'
        if not keyword_set(bypass_error) then if npix_ovlap2mm eq nw2mm then message, 'All the 2mm KIDs are overlaping, remove this scan or set param.flag.ovlap = "no" to remove the flag'
        if keyword_set( verb) then message, /info, 'Number of KIDs overlaping for the data at 1mm: '+strtrim(npix_ovlap1mm, 2)+'/'+strtrim(nw1mm, 2)
        if keyword_set( verb) then message, /info, 'Number of KIDs overlaping for the data at 2mm: '+strtrim(npix_ovlap2mm, 2)+'/'+strtrim(nw2mm, 2)
     endif
  endif  

  if keyword_set( changekid) then begin
     kidpar.flag = kidpar.flag+ (badkid.(0)*2L+badkid.(1)*4L+badkid.(2)*8L)
  endif


  return
end
