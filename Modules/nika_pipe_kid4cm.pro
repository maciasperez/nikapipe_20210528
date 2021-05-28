;+
;PURPOSE: Similarly to the where function, nika_pipe_kid4cm.pro tells
;         us where the tones must be used for the common-mode
;         construction, based on data.flag instead of using
;         kidpar.type. The tones considered fine are off and unflagged KIDs.
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The position of valid KIDs.
;
;LAST EDITION: 05/01/2014: creation (adam@lpsc.in2p3.fr)
;-

function nika_pipe_kid4cm, param, data, kidpar, $
                           only1mm=only1mm, only2mm=only2mm, $
                           Nvalid=Nvalid, complement=complement, ncomplement=ncomplement
  
  Npt = n_elements(data)
  Nkid = n_elements(kidpar)
  flag = intarr(Nkid)

  for ikid=0, Nkid-1 do begin

     junk = nika_pipe_wflag(data.flag[ikid], [2,3,4,5,6], nflag=Npt_flag)
     if Npt_flag eq Npt then flag[ikid] += 1

     if keyword_set(only1mm) then begin
        if kidpar[ikid].array eq 2 then flag[ikid] += 1
     endif

     if keyword_set(only2mm) then begin
        if kidpar[ikid].array eq 1 then flag[ikid] += 1
     endif

  endfor

  valid = where(flag eq 0, nok, complement=comp, ncomplement=ncomp)
  
  Nvalid = nok
  complement = comp
  ncomplement = ncomp

  return, valid
end
