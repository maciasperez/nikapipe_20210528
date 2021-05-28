;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_make_header
;
; CATEGORY: 
;        initialization
;
; CALLING SEQUENCE:
;        nk_make_header, param, xsmin, ysmin, xsmax, ysmax, $
;        [RESO=, S_MAP=, GIVEN_HEAD=, PROJECTION=]
; 
; PURPOSE: 
;        Define the header on which to project the data
; 
; INPUT: 
;        - param: the parameter structure used in the reduction
;        - xsmin: the list of minimum pointing offset along x
;        - ysmin: the list of minimum pointing offset along y
;        - xsmax: the list of maximum pointing offset along x
;        - ysmax: the list of maximum pointing offset along y
; 
; OUTPUT: 
;        - param: the parameter structure used in the reduction with
;          filled header
; 
; KEYWORDS:
;        - RESO: the requested resolution of the map (arcsec)
;
;        - S_MAP: The size of the field of view of the map (in arcsec)
;          as a 2D vector [size_along_x, size_along_y]
;
;        - GIVEN_HEAD: a predefined header that will contain the
;          astrometry can be provided. If not, the astrometry is set
;          by default using the pointing coordinates and the scan size
;
;        - PROJECTION: use this keyword to define your projection type. Possible values are 
;                - 'RADEC' for R.A-Dec. (default)
;                - 'AZEL' for azimuth-elevation with pointing
;                  coordinates as reference center
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 15/03/2014: creation
;-

pro nk_make_header, param, xsmin, xsmax, ysmin, ysmax, $
                    RESO=RESO, $
                    S_MAP=S_MAP, $
                    GIVEN_HEAD=GIVEN_HEAD, $
                    PROJECTION=PROJECTION

  ;;========== If the header is given, we extract the astrometry from it
  if keyword_set(GIVEN_HEAD) then begin
     message,/info, 'You are using a predefined header, so the map parameters are overwriten'
     extast, given_head, astrometry
  endif

  ;;========== Otherwise, we build it from the map parameters and the pointing
  if not keyword_set(GIVEN_HEAD) then begin 
     if keyword_set(PROJECTION) then param.map_proj = strupcase(PROJECTION)
     if keyword_set(RESO) then param.map_reso = RESO
     
     ;;---------- Get the size of the mapped area
     if param[0].map_proj eq 'RADEC' then begin ;Projection is the same for all scans
        xsize = max(param.map_coord_pointing_ra + xsmax/3600.0) - $
                min(param.map_coord_pointing_ra + xsmin/3600.0)
        ysize = max(param.map_coord_pointing_dec + ysmax/3600.0) - $
                min(param.map_coord_pointing_dec + ysmin/3600.0)

        param.map_xsize = round(1.2*xsize*3600.0)
        param.map_ysize = round(1.2*ysize*3600.0)

        param.map_coord_map_ra = (max(param.map_coord_pointing_ra) + min(param.map_coord_pointing_ra))/2.0
        param.map_coord_map_dec = (max(param.map_coord_pointing_dec) + min(param.map_coord_pointing_dec))/2.0

        ;;---------- Check that we are not combining scans with too
        ;;           large pointing difference
        if param[0].map_xsize gt 3600 or param[0].map_ysize gt 3600 then begin
           ;;---------- Angular distance with respect to first pointing
           ang_dist = 60*sphdist(param[0].map_coord_pointing_ra, param[0].map_coord_pointing_dec, $
                                 param.map_coord_pointing_ra, param.map_coord_pointing_dec, /degree) 
           
           if param[0].map_xsize lt 3600*3 and param[0].map_ysize lt 3600*3 then begin
              message, /info, "WARNING - The map that you are trying to do is very large: "
              message, /info, "WARNING - Xsize = "+strtrim(param[0].map_xsize/60.0,2)+" arcmin " + $
                       "and Ysize = "+strtrim(param[0].map_ysize/60.0,2)+" arcmin"
              message, /info, "WARNING - The angular distance between different pointing is as large as " + $
                       strtrim(max(ang_dist), 2)+" arcmin"
           endif else begin
              message, /info, "ERROR - The map that you are trying to do is too large: "
              message, /info, "ERROR - Xsize = "+strtrim(param[0].map_xsize/60.0,2)+" arcmin " + $
                       "and Ysize = "+strtrim(param[0].map_ysize/60.0,2)+" arcmin"
              message, /info, "ERROR - The angular distance between different pointing is as large as " + $
                       strtrim(max(ang_dist), 2)+" arcmin"
              message, /info, "Stopped in nk_make_header.pro, line 86"
              stop
           endelse
        endif
     endif
     if param[0].map_proj eq 'AZEL' then begin ;Projection is the same for all scans
        xsize = max(xsmax) - min(xsmin)
        ysize = max(ysmax) - min(ysmin)
        
        param.map_xsize = round(1.2*xsize)
        param.map_ysize = round(1.2*ysize)

        param.map_coord_map_ra = 0.0
        param.map_coord_map_dec = 0.0
     endif

     if keyword_set(S_MAP) then begin
        param.map_xsize = S_MAP[0]
        param.map_ysize = S_MAP[1]
     endif

     ;;---------- Number of pixel is an odd number so we have center reference pixel
     nx = param[0].map_xsize/param[0].map_reso
     ny = param[0].map_ysize/param[0].map_reso
     nx = 2*long(nx/2.0) + 1
     ny = 2*long(ny/2.0) + 1
     
     ;;------- Build the astrometry parameters
     if param[0].map_proj eq 'RADEC' then begin
        ctype = ['RA---GLS','DEC--GLS']
        latpole = 0.0
        longpole = 90.0
     endif
     if param[0].map_proj eq 'AZEL' then begin
        ctype = ['AZ---GLS','EL---GLS']
        latpole = !VALUES.F_NAN
        longpole = !VALUES.F_NAN
     endif
     
     astrometry = {naxis:[nx, ny], $
                   cd:[[1.0,-0.0],[0.0,1.0]], $
                   cdelt:[-1.0, 1.0] * param[0].map_reso/3600.0, $
                   crpix:([nx, ny] - 1)/2.0 + 1, $ ;First pixel is [1,1]
                   crval:[param[0].map_coord_map_ra, param[0].map_coord_map_dec], $
                   ctype:ctype,$
                   latpole:latpole, $
                   longpole:longpole, $
                   pv2:[0.0,0.0]}
  endif

  ;;========== Create the header and put it in the param file
  map_bidon = dblarr(astrometry.naxis[0], astrometry.naxis[1])
  mkhdr, header, map_bidon                    ;get minimal header
  putast, header, astrometry, equinox=2000    ;astrometry in header

  ;;---------- In case of AzEl map, need to change the comment
  if param[0].map_proj eq 'AZEL' then begin
     SXADDPAR, header, 'CRVAL1', 0.0, 'Az. (degrees) pointing offset of reference pixel'
     SXADDPAR, header, 'CRVAL2', 0.0, 'El. pointing offset of reference pixel'
  endif

  ;;---------- Add the name of the object in the header
  list_name_ini = param.source
  source_names = list_name_ini(rem_dup(list_name_ini)) ;remove duplicates names
  nname = n_elements(source_names)

  if nname eq 1 then SXADDPAR, header, 'Object', source_names, 'Name of the source', before='CTYPE1'
  if nname gt 1 then begin
     for iname=0, nname-1 do $
        SXADDPAR, header, 'OBJECT'+strtrim(iname+1,2), source_names[iname], 'Name of the source', before='CTYPE1'
  endif

  ;;---------- Add usefull information
  SXADDPAR, header, 'CAMERA', 'NIKA', 'Name of the instrument', before='CTYPE1'
  SXADDPAR, header, 'TELES', 'IRAM30m', 'Name of the telscope', before='CTYPE1'
  SXADDPAR, header, 'SCANS', strtrim(n_elements(param), 2), 'Number of scans', before='CTYPE1'
  
  header_1mm = header
  header_2mm = header

  SXADDPAR, header_1mm, 'OBS_FREQ', '260 GHz', 'Frequency band', before='CTYPE1'
  SXADDPAR, header_2mm, 'OBS_FREQ', '150 GHz', 'Frequency band', before='CTYPE1'

  ;;---------- Put the header as one of the param structure
  param.map_head_1mm = header_1mm
  param.map_head_2mm = header_2mm
  
end
