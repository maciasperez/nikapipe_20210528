;+
;PURPOSE: Define astrometry of the requested map or set it to the
;         given astrometry header
;
;INPUT: The parameter structure.
;
;OUTPUT: The astrometric parameter.
;
;KEYWORD: -given_head_map: a header that contains a predefined
;          astrometry that will be used if this keyword is set
;         -simu: set this keyword in case of simulation
;
;LAST EDITION: -20/11/2013: comments
;
;-

pro nika_pipe_def_header, param, astrometry, $
                          given_head_map=given_head_map, simu=simu, azel=azel, $
                          status = status
  
  status = 0  ; 0: OK
  ;;======= If the header is given, we extract the astrometry from it
  if keyword_set(given_head_map) then begin
     message,/info, 'You are using a predefined header, so the map parameters are changed'
     extast, given_head_map, astrometry
     param.map.reso = abs(astrometry.cdelt[0])*3600 ;assumes reso_x = reso_y
     param.map.size_ra = param.map.reso * astrometry.naxis[0]
     param.map.size_dec = param.map.reso * astrometry.naxis[1]

     ra_map = astrometry.crval[0] + param.map.reso*(astrometry.crpix[0] - ((astrometry.naxis[0]-1)/2.0+1))/3600.0
     dec_map = astrometry.crval[1] - param.map.reso*(astrometry.crpix[1] - ((astrometry.naxis[1]-1)/2.0+1))/3600.0
     param.coord_map.ra = SIXTY(ra_map/15.0)
     param.coord_map.dec = SIXTY(dec_map)

     astrometry.ctype = ['RA---TAN','DEC--TAN']
  endif

  ;;======= Otherwise, we build it from the map parameters and the pointing
  if not keyword_set(given_head_map) then begin ;the header is defined according to the map parameters
     
     ;;------- Get the number of pixels along x (= R.A.) and y (= Dec.)
     nx = param.map.size_ra/param.map.reso
     ny = param.map.size_dec/param.map.reso
     
     ;;------- Force the number of pixel to be an odd number in order to have a
     ;;        reference pixel at the center
     nx = 2*long(nx/2.0) + 1
     ny = 2*long(ny/2.0) + 1
     
     ;;------- If the user did not give the map coordinates, they are
     ;;        forced to the pointing coordinates, and if the user did
     ;;        not give the pointing coordinates we use the IMB_FITS
     ;;        of the first scan (if provided)
     if not keyword_set(simu) and not keyword_set(azel) then begin
        if ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0 eq 0 $
           and ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2]) eq 0 then begin
           
           if ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 eq 0 $
              and ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2]) eq 0 $
           then begin
              nika_find_raw_data_file, param.scan_num[0], param.day[0], file_scan, imb_fits_file, /silent, status = stf
              if stf lt 0 then begin
                 status = -1
                 return
              endif
              
              if file_test( imb_fits_file) ne 1 then begin
                 message, /info, 'Antenna imbfits file does not exist '+ imb_fits_file
                 status = -1
                 return
              endif
             antenna = mrdfits(imb_fits_file,1,head, status=status, /silent)
              if status eq -1 then message, 'You did not give the map coordinantes, the pointing coordinates and you do not have IMB_FITS...'

              longobj = sxpar(head,'longobj') 
              latobj = sxpar(head,'latobj') 
              
              ra = SIXTY(longobj/15.0)
              dec = SIXTY(latobj)
              dec[2] = Float(Round(dec[2]*1000)/1000.) ;Avoid some bug...
              
              param.coord_map.ra = ra
              param.coord_map.dec = dec
              
           endif else begin
              param.coord_map = param.coord_pointing
           endelse
        endif
     endif

     ;;------- Build the astrometric parameters
     naxis = [nx, ny]                            ;Nb pixel along x and y
     cd = [[1.0,-0.0],[0.0,1.0]]                 ;Rotation matrix but no rotation here
     cdelt = [-1.0, 1.0] * param.map.reso/3600.0 ;Pixel size (ra along -1)
     crpix = ([nx, ny] - 1)/2.0 + 1              ;Ref pixel (central pixel (always odd nb))
     ra = ten(param.coord_map.ra[0],$            ;
              param.coord_map.ra[1],$            ;
              param.coord_map.ra[2])*15.0        ;RA in degrees
     dec = ten(param.coord_map.dec[0],$          ;
               param.coord_map.dec[1],$          ;
               param.coord_map.dec[2])           ;DEC in degrees
     crval = [ra, dec]                        ;ra dec of the ref pix
     ctype = ['RA---TAN','DEC--TAN']          ;Projection type
     
     ;;------- Build the usual astrometry structure
     astrometry = {naxis:naxis, $
                   cd:cd, $
                   cdelt:cdelt, $
                   crpix:crpix, $
                   crval:crval, $
                   ctype:ctype,$
                   longpole:180.0, $
                   latpole:90.0, $
                   pv2:[0.0,0.0]}

  endif
  
  return
end
