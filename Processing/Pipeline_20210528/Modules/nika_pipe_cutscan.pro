;+
;PURPOSE: This procedure gets the location of the valid part of a
;         given scan. It is chosen as the part of the scan where the
;         telescope moves.
;INPUT: The data structure.
;OUTPUT: The valid location.
;KEYWORDS: -brutal: Cut even the first and the last subscan.
;          -safe: Cut the 51 first and last points because RFdIdQ
;                 might be undefined there. (Recomanded)
;LAST EDITION: 23/01/2012
;              16/06/2013: change everything (now it uses the scan speed)
;              05/01/2014: add the loc_bad keyword (complement of loc_ok)
;              06/01/2014: split the scan type finder elsewhere
;              20/06/2014: add status for a graceful exit (status=-1
;                          means bad)
;              24/07/2015: add keyword rm_part_ss
;-

pro nika_pipe_cutscan, param, data, loc_ok, brutal=brutal, rm_part_ss=rm_part_ss, safe=safe, loc_bad=loc_bad, status=status

  status = 0                    ; 0=OK
  N_pt = n_elements(data)

  ;; Methode qui coupe le premier et dernier subscan pour etre certain
  ;; de bien couper, mais attention, uniquement pour les OTF
  if keyword_set(brutal) then begin
     loc_ok = where(data.subscan gt 1 and data.subscan lt max(data.subscan) and data.scan eq median(data.scan))
  endif
  
  ;;############################## FIND THE TYPE OF SCAN BASED ON SPEED ##################################
  if not keyword_set(brutal) then begin
     vx = deriv(data.ofs_az)*!nika.f_sampling ;scan speed (arcsec/sec)
     vy = deriv(data.ofs_el)*!nika.f_sampling ;

     scan_valid = data.scan*0
     scan_valid = scan_valid or data.scan_valid[0]
     scan_valid = scan_valid or data.scan_valid[1]

     loc_val = where(scan_valid eq 0, nloc_val)
     if nloc_val eq 0 then scan_valid *= 0

     ;; search the first real scan
     sc = long( data.scan)
     sc = sc[ sort(sc)]
     isc = uniq(sc)
     iscgood = where( sc[isc] ne 0, niscgood)
     loc_ok = -1
     if niscgood eq 0 then begin
        message, /info, 'No scan data in this file '+ param.scan_list[ param.iscan]
     endif
     if niscgood ge 2 then begin 
        ;;message, /info, '2 scans in the same file '+param.scan_list[ param.iscan]
        ;;print,  sc[isc[ iscgood]]
     endif
     if niscgood ge 1 then begin
        sc = sc[ isc[ iscgood]]
        imatch = where( sc eq param.scan_num[ param.iscan], nimatch)
        if nimatch eq 0 then begin
           message, /info, 'Requested scan not the in the file '+ param.scan_list[ param.iscan]
        endif else begin
           effscan = sc[ imatch[0]] ; is the requested scan
           
           ;;------- Cut based on subscan and scan status
           beginscan = min(where(data.subscan ge 1 and data.subscan le max(data.subscan) and $
                                 data.scan eq effscan and scan_valid eq 0))
           endscan = max(where(data.subscan ge 1 and data.subscan le max(data.subscan) and $
                               data.scan eq effscan and scan_valid eq 0))
           if endscan eq N_pt then endscan = endscan - 1
           
           ;;------- Additional cut based on speed (if static then cut)
           ivgood = where( sqrt(vx[beginscan:endscan]^2 + vy[beginscan:endscan]^2) ne 0, nvgood)
           if nvgood ge 110 then begin
              beginscan_temp = beginscan
              beginscan = beginscan+ ivgood[0]
              endscan = beginscan_temp+ ivgood[nvgood -1]
              ;;while sqrt(vx[beginscan]^2 + vy[beginscan]^2) eq 0  do beginscan += 1
              ;;while sqrt(vx[endscan]^2 + vy[endscan]^2) eq 0      do endscan -= 1
              
              ;;Get the localisation of the real scan
              indice = lindgen(N_pt)
              if keyword_set(safe) then $
                 loc_ok = indice[beginscan+param.pointing.cut[0]+51:endscan-param.pointing.cut[1]-51] else $
                    loc_ok = indice[beginscan+param.pointing.cut[0]:endscan-param.pointing.cut[1]] 
           endif else begin
              message, /info, 'Not enough valid samples in that scan '+ param.scan_list[ param.iscan]
              status = -1
           endelse
        endelse
     endif
  endif
  junk = intarr(n_elements(data))
  if loc_ok[0] ne (-1) then junk[loc_ok] = 1

  ;;========== Remove % of subscan
  junk2 = intarr(n_elements(data))
  if keyword_set(rm_part_ss) then begin
     for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
        wsubscan = where(data.subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           wrm = where(dindgen(nwsubscan) lt rm_part_ss[0]*nwsubscan or $
                       dindgen(nwsubscan) gt (1-rm_part_ss[1])*nwsubscan, nwrm)
           if nwrm ne 0 then junk2[wsubscan[wrm]] = 1
        endif
     endfor
  endif
  
  loc_bad = where(junk eq 0 or junk2 eq 1, nloc_bad)
  
  return
end
