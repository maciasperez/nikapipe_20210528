;+
;PURPOSE: Simulate a map based on given parameters and save it as a
;         fits file to be read with map to TOI routines.
;
;INPUT: The source caracteristics structure, SZ unit conversion, the
;       astrometry and the output directory
;
;OUTPUT: The fits map is created in the output directory
;
;KEYWORDS: 
;
;LAST EDITION: 
;   01/07/2014: creation
;   10/03/2016: apart from amplitude, the white noise is the same at both frequency
;-

pro nika_pipe_simu_fits_map, source_struct, astrometry, dir, name_file=name_file
  
  if not keyword_set(name_file) then nf = 'Input_Simulation' else nf = name_file


  ;;========== Create the empty map
  nx = astrometry.naxis[0]
  ny = astrometry.naxis[1]
  reso = astrometry.cdelt[1]*3600

  map1mm = dblarr(nx, ny)
  map2mm = dblarr(nx, ny)

  ;;========== Add the different contribution for all components
  types = strsplit(source_struct.type, '+', /extract)
  ntype = n_elements(types)
  for itype=0, ntype-1 do begin
     case strupcase(types[itype]) of
        ;;-1------- SZ cluster
        "SZ": begin
           ;;----- Get the y profile
           Dang = dda(source_struct.CL.z, 0.315, 0.685, 67.3)
           Dang = Dang[0, 0]
           y_R = icm_compute_sz_profile(Dang, 100.0, $         ;
                                        source_struct.CL.P0, $ ;P0
                                        source_struct.CL.rp, $ ;r_p
                                        source_struct.CL.a, $  ;a
                                        source_struct.CL.b, $  ;b
                                        source_struct.CL.c, $  ;c
                                        Tiso=0.01, $           ;
                                        Nlos=1000)             ;
           
           ;;---------- Project onto map
           theta = y_R[*,1] / (Dang*1e3) * 180.0/!pi * 3600 ;arcsec
           y_theta = y_R[*,0]                               ;y
           xmap = (dindgen(nx)-nx/2)*reso
           ymap = (dindgen(ny)-ny/2)*reso
           xmap = xmap # replicate(1, ny)
           ymap = ymap ## replicate(1, nx)
           y_xy = icm_map_projection(y_theta, theta, $
                                     source_struct.CL.pos[0], source_struct.CL.pos[1], $
                                     xmap, ymap)
           
           ;;---------- Convolve to the beam and convert to Jy/beam
           map1mm += source_struct.CL.calib[0] * filter_image(y_xy, FWHM=source_struct.beam[0]/reso, /all)
           map2mm += source_struct.CL.calib[1] * filter_image(y_xy, FWHM=source_struct.beam[1]/reso, /all)
        end
        
        ;;-2------- Point source
        "PS":begin
           if n_elements(reform(source_struct.ps.flux[0,*])) ne n_elements(reform(source_struct.ps.pos[0,*])) $
           then message, 'The number of point sources simulated is different for flux and position'
           
           xmap = (dindgen(nx)-nx/2)*reso
           ymap = (dindgen(ny)-ny/2)*reso
           xmap = xmap # replicate(1, ny)
           ymap = ymap ## replicate(1, nx)
           
           nbps = n_elements(reform(source_struct.ps.flux[0,*]))
           for ips=0, nbps-1 do begin
              radius_source = sqrt((xmap - (reform(source_struct.ps.pos[0,ips]))[0])^2 + $
                                   (ymap - (reform(source_struct.ps.pos[1,ips]))[0])^2)
              map1mm += (reform(source_struct.ps.flux[0,ips]))[0] * $
                        exp(-radius_source^2/2.0/(source_struct.beam[0]*!fwhm2sigma)^2)
              map2mm += (reform(source_struct.ps.flux[1,ips]))[0] * $
                        exp(-radius_source^2/2.0/(source_struct.beam[1]*!fwhm2sigma)^2)
           endfor
        end

        ;;-3------- White Noise
        "WN":begin
           WNmap = randomn(seed, nx, ny)
           map1mm += WNmap*source_struct.WN.rms[0]
           map2mm += WNmap*source_struct.WN.rms[1]
        end

        ;;-4------- Point source
        "DISK":begin
           xmap = (dindgen(nx)-nx/2)*reso
           ymap = (dindgen(ny)-ny/2)*reso
           xmap = xmap # replicate(1, ny)
           ymap = ymap ## replicate(1, nx)
           radius_source = sqrt((xmap - source_struct.disk.pos[0])^2 + $
                                (ymap - source_struct.disk.pos[1])^2)
           
           disk1mm = dblarr(nx, ny)
           disk2mm = dblarr(nx, ny)
           wdisk = where(radius_source le source_struct.disk.radius, nwdisk)

           if nwdisk ne 0 then disk1mm[wdisk] = source_struct.disk.flux[0]
           if nwdisk ne 0 then disk2mm[wdisk] = source_struct.disk.flux[1]

           map1mm += disk1mm
           map2mm += disk2mm
        end

        ;;-5------- Given map
        "GIVEN_MAP":begin
           gm1mm = mrdfits(source_struct.GM.mapfile[0], 0, head1mm, /silent)
           gm2mm = mrdfits(source_struct.GM.mapfile[1], 0, head2mm, /silent)
           EXTAST, head1mm, astr1mm
           EXTAST, head2mm, astr2mm

           reso1mm = astr1mm.cdelt[1]*3600
           nx1mm = astr1mm.naxis[0]
           ny1mm = astr1mm.naxis[1]

           reso2mm = astr2mm.cdelt[1]*3600
           nx2mm = astr2mm.naxis[0]
           ny2mm = astr2mm.naxis[1]

           if reso1mm/reso2mm gt 1.01 or reso1mm/reso2mm lt 0.99 or $
              reso1mm/reso gt 1.01 or reso1mm/reso lt 0.99 or $
              reso2mm/reso gt 1.01 or reso2mm/reso lt 0.99 or $
              nx1mm ne nx2mm or nx1mm ne nx or nx2mm ne nx or $
              ny1mm ne ny2mm or ny1mm ne ny or ny2mm ne ny then $
                 message, 'The given map must correpond to the produced map in term of pixel number and resolution'

           gm1mm = filter_image(gm1mm, FWHM=source_struct.GM.relobe[0]/reso, /all)
           gm2mm = filter_image(gm2mm, FWHM=source_struct.GM.relobe[1]/reso, /all)
           
           map1mm += gm1mm
           map2mm += gm2mm
        end
     endcase
  endfor
  
  ;;========== Save the map as a fits file
  mkhdr, header, map1mm
  putast, header, astrometry, equinox=2000, cd_type=0

  ;;------- 1mm Map in first file
  file1mm = dir+'/'+nf+'_1mm.fits'
  mwrfits, map1mm, file1mm, header, /create, /silent

  ;;------- 2mm Map in first file
  file2mm = dir+'/'+nf+'_2mm.fits'
  mwrfits, map2mm, file2mm, header, /create, /silent
  
  return
end
