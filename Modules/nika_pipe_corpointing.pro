;+
;PURPOSE: Correct the pointing from antenna data
;
;INPUT: uncorrected data
;
;OUTPUT: corrected data
;
;LAST EDITION: 
;   16/06/2013: procedure created (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_corpointing, param, data, kidpar, $
                           simu=simu, azel=azel, w_ok=w_ok, silent = silent
  
  ;;------- Get the pointing coordinate center from the IMBFITS unless
  ;;        provided by the user
  if not keyword_set(simu) and not keyword_set(azel) and param.imb_fits_file ne '' then begin
     antenna1 = mrdfits(param.imb_fits_file, 1, head1, status=status1, /silent)
     antenna2 = mrdfits(param.imb_fits_file, 2, head2, status=status2, /silent)
     
     ;;------- Case of no IMBFITS and no pointing given
     if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
        and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 $
        and status1 eq -1 then message, 'You did not give the pointing coordinates and you do not have IMB_FITS, so I cannot read it from the file ...'
     
     ;;------- Get the pointing coordinates
     longobj = sxpar(head1,'longobj') 
     latobj = sxpar(head1,'latobj') 
     ra = SIXTY(longobj/15.0)
     dec = SIXTY(latobj)
     dec[2] = Float(Round(dec[2]*1000)/1000.)
     
     param.coord_pointing.ra = ra
     param.coord_pointing.dec = dec
     if not keyword_set( silent) then $
        message, /info, $
 'You did not give the pointing coordinates, so I got it from the IMB_FITS file'
     
     ;;------- Source assumed at coord pointing
     if ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 eq 0 $
        and ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) eq 0 then begin
        param.coord_source.ra =  param.coord_pointing.ra
        param.coord_source.dec = param.coord_pointing.dec
        if not keyword_set( silent) then $
           message, /info, $
                    'You did not give the source coordinates, ' + $
                    'so I assume it is the pointing coordinates'
     endif
     
     ;;------- Get the projection type
     param.projection.type = sxpar(head2, "systemof")
     if strupcase(param.projection.type) eq "PROJECTION" then data.ofs_az /= cos(data.el)
    
     ;;------ Check if holes are present in the data
     if keyword_set(w_ok) then begin
        
        ;; VERSION COURANTE
        ;;----------------
        ;;nika_pipe_antenna2pointing, data, param.imb_fits_file
        ;;for lambda=1, 2 do begin
        ;;   arr = where( kidpar.array eq lambda, narr)
        ;;   if narr ne 0 then begin
        ;;      for isubscan=1, max(data.subscan) do begin
        ;;         wsubscan   = where( data.subscan eq isubscan, nwsubscan)
        ;;         if nwsubscan lt 50 and nwsubscan gt 0 then begin
        ;;            data[wsubscan].subscan = 0
        ;;            data[wsubscan].scan = 0
        ;;         endif
        ;;      endfor
        ;;   endif
        ;;endfor
        ;; test again for residual hole (in case of imbfits not ok)
        ;;whole = where(data.scan eq 0, nhole, comp=wnohole)
        ;;if nhole ne 0 then begin
        ;;   nika_pipe_addflag, data, 9, wsample=whole       
        ;;   
        ;;   index = indgen(n_elements(data))
        ;;   data[whole].el = interpol(data[wnohole].el, index[wnohole], index[whole])
        ;;   data[whole].paral = interpol(data[wnohole].paral, index[wnohole], index[whole])
        ;;endif
        ;; NOUVELLE VERSION
        ;;----------------------
        ;; testing against missing data
        whole = where(data.scan eq 0, nhole, comp=wnohole)
        if strmid(param.day[param.iscan], 0, 6) eq '201211' then nhole = 0
        ;; if missing data, recover the pointing from the imbfits
        if nhole ne 0 then begin
         nika_pipe_antenna2pointing, data, param.imb_fits_file
        endif
        ;; test valid sample (after pointing recovery)
        for lambda=1, 2 do begin
           arr = where( kidpar.array eq lambda, narr)
           if narr ne 0 then begin
              for isubscan=1, max(data.subscan) do begin
                 wsubscan   = where( data.subscan eq isubscan, nwsubscan)
                 if nwsubscan lt long(2.5*!nika.f_sampling) and nwsubscan gt 0 then begin
                    data[wsubscan].subscan = 0
                    data[wsubscan].scan = 0
                 endif
              endfor
           endif
        endfor
        ;; test again for residual hole (in case of imbfits not ok)
        whole = where(data.scan eq 0, nhole, comp=wnohole)
        if nhole ne 0 then begin
           nika_pipe_addflag, data, 9, wsample=whole       
           index = indgen(n_elements(data))
           data[whole].el = interpol(data[wnohole].el, index[wnohole], index[whole])
           data[whole].paral = interpol(data[wnohole].paral, index[wnohole], index[whole])
        endif
        ;; FIN NOUVELLE VERSION
        
     endif
     
     
  endif
  
  return
end
