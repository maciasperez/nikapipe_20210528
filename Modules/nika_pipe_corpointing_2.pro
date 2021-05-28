;+
;PURPOSE: Correct the pointing from antenna data
;
;INPUT: uncorrected data
;
;OUTPUT: corrected data
;
;LAST EDITION: 
;   16/06/2013: procedure created
;   30/04/2014: updated by Nico (merged previous version and imbfits
;pointing interpolation).
;   11/12/2014: Add keyword coord_only to use only the coordinate part
;of the code
;-

pro nika_pipe_corpointing_2, param, data, kidpar, $
                             plot=plot, flag_holes=flag_holes, $
                             silent=silent, status=status, coord_only=coord_only
  
  status = 0
  ;;------- Get the pointing coordinate center from the IMBFITS unless
  ;;        provided by the user
  if not keyword_set(simu) and not keyword_set(azel) and param.imb_fits_file ne '' then begin
     antenna1 = mrdfits(param.imb_fits_file, 1, head1, status=status1, /silent)
     antenna2 = mrdfits(param.imb_fits_file, 2, head2, status=status2, /silent)
     if status1 lt 0 or status2 lt 0 then begin
        message, /info, 'antenna fits incomplete, Do not produce clean fits file for this scan '+ param.imb_fits_file
        status = -1
        return
     endif
     
     ;;------- Case of no IMBFITS and no pointing given
     if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
        and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 $
        and status1 eq -1 then if not keyword_set( silent) then message, 'You did not give the pointing coordinates and you do not have IMB_FITS, so I cannot read it from the file ...'
     
     
     ;;------- Get the pointing coordinates
     if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
        and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 then begin
        longobj = sxpar(head1,'longobj') 
        latobj = sxpar(head1,'latobj') 
        ra = SIXTY(longobj/15.0)
        dec = SIXTY(latobj)
        dec[2] = Float(Round(dec[2]*1000)/1000.)
        message, /info, 'IMBFITS pointing is :'
        message, /info, 'R.A.: '+strtrim(ra[0],2)+' h '+strtrim(ra[1],2)+' min '+strtrim(ra[2],2)+' s'
        message, /info, 'Dec.: '+strtrim(dec[0],2)+' deg '+strtrim(dec[1],2)+" arcmin "+strtrim(dec[2],2)+' arcsec'
        param.coord_pointing.ra = ra
        param.coord_pointing.dec = dec
        if not keyword_set( silent) then $
           message, /info, $
                    'You did not give the pointing coordinates, so I got it from the IMB_FITS file'
     endif
     
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

     if not keyword_set(coord_only) then begin
        ;;------- Get the projection type
        param.projection.type = sxpar(head2, "systemof")
        if strupcase(param.projection.type) eq "PROJECTION" then data.ofs_az /= cos(data.el)
        
        ;; Retrieve pointing from antenna imbfits: either complete for less holes
        ;; than in NIKA dta
        ;;if long(!nika.run) eq 8 then $
        nika_pipe_antenna2pointing_2, param, data, kidpar, $
                                      plot=plot, flag_holes=flag_holes, $
                                      status=status
        if status lt 0 then begin
           message, /info, 'Do not produce clean fits file for this scan'
        endif
        
        ;; Shift subscans to solve IRAM synchronization problems but do not
        ;; wrap around the final subscan to the first one.
        nshift = long( !nika.subscan_delay_sec*!nika.f_sampling)
        if nshift ne 0 then begin
           nsn    = n_elements(data)
           data[nshift:*].subscan = (shift( data.subscan, nshift))[nshift:*]
        endif
     endif
  endif
  
  return
end
