;+
;PURPOSE: Add (or subtract) a source by hand in the timelines.
;
;INPUT: param file, data file, kidpar file and source characteristics
;
;OUTPUT: The data with the added source
;
;LAST EDITION: 
;   11/05/2013: Addapted to the Run6 (adam@lpsc.in2p3.fr)
;   01/07/2013: Now the map is created before once for all scans and here we do map2toi only
;-

pro nika_pipe_addsource, param, data, kidpar

  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)
  
  ;;========== position of the source vs pointing (arcsec_x, arcsec_y)
  pos = [-ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0 + $    
         ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $ 
         ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2]) - $
         ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
  
  ;;========== Compute correction if projection already in R.A.-Dec.
  if strupcase(param.projection.type) eq "PROJECTION" then begin        
     alpha = data.paral
     daz =  -cos(alpha)*data.ofs_az - sin(alpha)*data.ofs_el
     del =  -sin(alpha)*data.ofs_az + cos(alpha)*data.ofs_el
     mean_dec_pointing=ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])
     correction = cos(mean_dec_pointing*!pi/180.0)
  endif else begin
     daz = data.ofs_az
     del = data.ofs_el
     correction = 1.0
  endelse

  ;;======= Loop for all the KIDs valid 
  for ikid=0, N_kid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        nika_nasmyth2draddec, daz, del, data.el, data.paral, $
                              kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                              0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                              nas_y_ref=kidpar[ikid].nas_center_Y
      
        ;;------- Shift TOI according to projection
        dra  = dra - pos[0]*correction
        ddec = ddec - pos[1]
        
        case kidpar[ikid].array of
           1: map = mrdfits(param.output_dir+'/Input_Simulation_1mm.fits', 0, head,/silent)
           2: map = mrdfits(param.output_dir+'/Input_Simulation_2mm.fits', 0, head,/silent)
        endcase
        EXTAST, head, astr
        reso = astr.cdelt[1]*3600
        source = simu_map2toi(map, reso, dra, ddec)
        data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] + source
     endif
  endfor
  
  return
end
