;+
;PURPOSE: New flag for all KIDs that tell if they are on source or not
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: Set the flag
;
;LAST EDITION: 15/02/2014: creation(adam@lpsc.in2p3.fr)
;              20/11/2014: show the flagged region maps
;-

pro nika_pipe_onsource, param, data, kidpar, astr, AzEl=AzEl

  N_kid = n_elements(kidpar)
  w1 = where( kidpar.type eq 1, nw1)

  ;;========== position of the source vs pointing (arcsec_x, arcsec_y)
  if keyword_set(AzEl) then begin
     pos_p = [0.0,0.0]
     pos_s = [0.0,0.0]
  endif else begin
     pos_p = [-ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0 + $    
              ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $ 
              ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2]) - $
              ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
     
     pos_s = [-ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 + $    
              ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $ 
              ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) - $
              ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
  endelse

  ;;========== Extract the flagging maps
  max_noise1 = param.decor.common_mode.flag_max_noise[0]
  max_noise2 = param.decor.common_mode.flag_max_noise[1]
  if param.w8.map_guess1mm ne '' then $
     nika_pipe_extract_map_flag, param.w8.map_guess1mm, param.w8.flag_type, param.w8.relob.a, map_w8_1mm, reso_w8_1mm, max_noise=max_noise1
  if param.w8.map_guess2mm ne '' then $
     nika_pipe_extract_map_flag, param.w8.map_guess2mm, param.w8.flag_type, param.w8.relob.b, map_w8_2mm, reso_w8_2mm, max_noise=max_noise2
  
  if param.zero_level.map_guess1mm ne '' then $
     nika_pipe_extract_map_flag, param.zero_level.map_guess1mm, param.zero_level.flag_type, param.zero_level.relob.a, map_zl_1mm, reso_zl_1mm, max_noise=max_noise1
  if param.zero_level.map_guess2mm ne '' then $
     nika_pipe_extract_map_flag, param.zero_level.map_guess2mm, param.zero_level.flag_type, param.zero_level.relob.b, map_zl_2mm, reso_zl_2mm, max_noise=max_noise2

  if param.decor.common_mode.map_guess1mm ne '' then $
     nika_pipe_extract_map_flag, param.decor.common_mode.map_guess1mm, param.decor.common_mode.flag_type, param.decor.common_mode.relob.a, map_cm_1mm, reso_cm_1mm, max_noise=max_noise1
  if param.decor.common_mode.map_guess2mm ne '' then $
     nika_pipe_extract_map_flag, param.decor.common_mode.map_guess2mm, param.decor.common_mode.flag_type, param.decor.common_mode.relob.b, map_cm_2mm, reso_cm_2mm, max_noise=max_noise2

  ;;========= Plot the flag maps
  if param.iscan eq 0 then begin
     if param.w8.map_guess1mm ne '' then mapf = map_w8_1mm
     if param.w8.map_guess2mm ne '' then mapf = map_w8_2mm
     if param.zero_level.map_guess1mm ne '' then mapf = map_zl_1mm
     if param.zero_level.map_guess2mm ne '' then mapf = map_zl_2mm
     if param.decor.common_mode.map_guess1mm ne '' then mapf = map_cm_1mm
     if param.decor.common_mode.map_guess1mm ne '' then mapf = map_cm_2mm
    
     if param.w8.map_guess1mm ne '' or param.w8.map_guess2mm ne '' or $
        param.zero_level.map_guess1mm ne '' or param.zero_level.map_guess2mm ne '' or $
        param.decor.common_mode.map_guess1mm ne '' or param.decor.common_mode.map_guess2mm ne '' $
     then doplot = 1 else doplot =0

     if param.map.size_ra ge 4*60.0 or param.map.size_dec ge 4*60.0 then cp = 'arcmin' else cp = 'arcsec'
     if doplot eq 1 then mkhdr, head, mapf                           ;get header typique
     if doplot eq 1 then putast, head, astr, equinox=2000, cd_type=0 ;astrometry in header
     ;;W8
     if param.w8.map_guess1mm ne '' then begin
        map_flag_plot = map_w8_1mm*0
        if  param.w8.flag_lim[0] ge 0 then loc_flag = where(map_w8_1mm gt param.w8.flag_lim[0], nloc_flag)
        if  param.w8.flag_lim[0] lt 0 then loc_flag = where(map_w8_1mm lt param.w8.flag_lim[0], nloc_flag)
        if nloc_flag ne 0 then map_flag_plot[loc_flag] = 1
        radec_bar_map, map_flag_plot, head, $
                       title='Weight 1mm', $
                       xtitle=cp, ytitle=cp, bartitle='Flag',$
                       barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                       range=[-1,1],$
                       conts=[-1,1],$
                       pdf=param.output_dir+'/flag_w8_1mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     endif
     if param.w8.map_guess2mm ne '' then begin
        map_flag_plot = map_w8_2mm*0
        if  param.w8.flag_lim[1] ge 0 then loc_flag = where(map_w8_2mm gt param.w8.flag_lim[1], nloc_flag)
        if  param.w8.flag_lim[1] lt 0 then loc_flag = where(map_w8_2mm lt param.w8.flag_lim[1], nloc_flag)
        if nloc_flag ne 0 then map_flag_plot[loc_flag] = 1
        radec_bar_map, map_flag_plot, head, $
                       title='Weight 1mm', $
                       xtitle=cp, ytitle=cp, bartitle='Flag',$
                       barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                       range=[-1,1],$
                       conts=[-1,1],$
                       pdf=param.output_dir+'/flag_w8_2mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     endif
     ;;ZL
     if param.zero_level.map_guess1mm ne '' then begin
        map_flag_plot = map_zl_1mm*0
        if  param.zero_level.flag_lim[0] ge 0 then loc_flag = where(map_zl_1mm gt param.zero_level.flag_lim[0], nloc_flag)
        if  param.zero_level.flag_lim[0] lt 0 then loc_flag = where(map_zl_1mm lt param.zero_level.flag_lim[0], nloc_flag)
        if nloc_flag ne 0 then map_flag_plot[loc_flag] = 1
        radec_bar_map, map_flag_plot, head, $
                       title='Zero level 1mm', $
                       xtitle=cp, ytitle=cp, bartitle='Flag',$
                       barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                       range=[-1,1],$
                       conts=[-1,1],$
                       pdf=param.output_dir+'/flag_zl_1mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     endif
     if param.zero_level.map_guess2mm ne '' then begin
        map_flag_plot = map_zl_2mm*0
        if param.zero_level.flag_lim[1] ge 0 then loc_flag = where(map_zl_2mm gt  param.zero_level.flag_lim[1], nloc_flag)
        if param.zero_level.flag_lim[1] lt 0 then loc_flag = where(map_zl_2mm lt  param.zero_level.flag_lim[1], nloc_flag)
        if nloc_flag ne 0 then map_flag_plot[loc_flag] = 1
        radec_bar_map, map_flag_plot, head, $
                       title='Zero level 2mm', $
                       xtitle=cp, ytitle=cp, bartitle='Flag',$
                       barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                       range=[-1,1],$
                       conts=[-1,1],$
                       pdf=param.output_dir+'/flag_zl_2mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     endif
     ;;CM
     if param.decor.common_mode.map_guess1mm ne '' then begin
        map_flag_plot = map_cm_1mm*0
        if   param.decor.common_mode.flag_lim[0] ge 0 then loc_flag = where(map_cm_1mm gt  param.decor.common_mode.flag_lim[0], nloc_flag)
        if   param.decor.common_mode.flag_lim[0] lt 0 then loc_flag = where(map_cm_1mm lt  param.decor.common_mode.flag_lim[0], nloc_flag)
        if nloc_flag ne 0 then map_flag_plot[loc_flag] = 1
        radec_bar_map, map_flag_plot, head, $
                       title='Decorrelation 1mm', $
                       xtitle=cp, ytitle=cp, bartitle='Flag',$
                       barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                       range=[-1,1],$
                       conts=[-1,1],$
                       pdf=param.output_dir+'/flag_cm_1mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     endif
     if param.decor.common_mode.map_guess2mm ne '' then begin
        map_flag_plot = map_cm_2mm*0
        if   param.decor.common_mode.flag_lim[1] ge 0 then loc_flag = where(map_cm_2mm gt  param.decor.common_mode.flag_lim[1], nloc_flag)
        if   param.decor.common_mode.flag_lim[1] lt 0 then loc_flag = where(map_cm_2mm lt  param.decor.common_mode.flag_lim[1], nloc_flag)
        if nloc_flag ne 0 then map_flag_plot[loc_flag] = 1
        radec_bar_map, map_flag_plot, head, $
                       title='Decorrelation 2mm', $
                       xtitle=cp, ytitle=cp, bartitle='Flag',$
                       barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                       range=[-1,1],$
                       conts=[-1,1],$
                       pdf=param.output_dir+'/flag_cm_2mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     endif

     if doplot eq 1 then spawn, 'pdftk '+param.output_dir+'/flag_*.pdf cat output '+param.output_dir+'/flags_maps.pdf'
     if doplot eq 1 then spawn, 'rm -rf '+param.output_dir+'/flag_*.pdf'
  endif

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
  
  ;;========== Determine if kids are "on" or "off source"
  for i=0, nw1-1 do begin
     ikid = w1[i]
     nika_nasmyth2draddec, daz, del, data.el, data.paral, $
                           kidpar[ikid].nas_x,kidpar[ikid].nas_y, 0., 0., $
                           dra,ddec,nas_x_ref=kidpar[ikid].nas_center_X,nas_y_ref=kidpar[ikid].nas_center_Y
     dra = dra - pos_p[0]*correction
     ddec = ddec - pos_p[1]

     dist_source = sqrt((ddec - pos_s[1])^2 + (dra - pos_s[0])^2) ;distance from source     

     case kidpar[ikid].array of
        ;;---------- Case of 1mm KIDs
        1: begin 
           ;;---------- Get the flag maps if availlable
           if param.w8.map_guess1mm ne '' then map_w8 = map_w8_1mm
           if param.zero_level.map_guess1mm ne '' then map_zl = map_zl_1mm
           if param.decor.common_mode.map_guess1mm ne '' then map_cm = map_cm_1mm

           if param.w8.map_guess1mm ne '' then reso_w8 = reso_w8_1mm
           if param.zero_level.map_guess1mm ne '' then reso_zl = reso_zl_1mm
           if param.decor.common_mode.map_guess1mm ne '' then reso_cm = reso_cm_1mm

           if param.w8.map_guess1mm ne '' then source_w8 = simu_map2toi(map_w8, reso_w8, dra, ddec)
           if param.zero_level.map_guess1mm ne '' then source_zl = simu_map2toi(map_zl, reso_zl, dra, ddec)
           if param.decor.common_mode.map_guess1mm ne '' then source_cm = simu_map2toi(map_cm, reso_cm, dra, ddec)

           ;;---------- Get the flag levels 
           lim_w8 = param.w8.flag_lim[0]
           lim_zl = param.zero_level.flag_lim[0]
           lim_cm = param.decor.common_mode.flag_lim[0]
           
           ;;---------- Flag the source with map
           if param.w8.map_guess1mm ne '' then begin
              if lim_w8 ge 0 then loc_on = where(source_w8 gt lim_w8, nloc_on)
              if lim_w8 lt 0 then loc_on = where(source_w8 lt lim_w8, nloc_on)
              if nloc_on ne 0 then data[loc_on].on_source_w8[ikid] = 1
           endif

           if param.zero_level.map_guess1mm ne '' then begin
              if lim_zl ge 0 then loc_on = where(source_zl gt lim_zl, nloc_on)
              if lim_zl lt 0 then loc_on = where(source_zl lt lim_zl, nloc_on)
              if nloc_on ne 0 then data[loc_on].on_source_zl[ikid] = 1
           endif

           if param.decor.common_mode.map_guess1mm ne '' then begin
              if lim_cm ge 0 then loc_on = where(source_cm gt lim_cm, nloc_on)
              if lim_cm lt 0 then loc_on = where(source_cm lt lim_cm, nloc_on)
              if nloc_on ne 0 then data[loc_on].on_source_dec[ikid] = 1
           endif
        end

        ;;---------- Case of 2mm KIDs
        2: begin 
           ;;---------- Get the flag maps if availlable
           if param.w8.map_guess2mm ne '' then map_w8 = map_w8_2mm
           if param.zero_level.map_guess2mm ne '' then map_zl = map_zl_2mm
           if param.decor.common_mode.map_guess2mm ne '' then map_cm = map_cm_2mm

           if param.w8.map_guess2mm ne '' then reso_w8 = reso_w8_2mm
           if param.zero_level.map_guess2mm ne '' then reso_zl = reso_zl_2mm
           if param.decor.common_mode.map_guess2mm ne '' then reso_cm = reso_cm_2mm

           if param.w8.map_guess2mm ne '' then source_w8 = simu_map2toi(map_w8, reso_w8, dra, ddec)
           if param.zero_level.map_guess2mm ne '' then source_zl = simu_map2toi(map_zl, reso_zl, dra, ddec)
           if param.decor.common_mode.map_guess2mm ne '' then source_cm = simu_map2toi(map_cm, reso_cm, dra, ddec)

           ;;---------- Get the flag levels 
           lim_w8 = param.w8.flag_lim[1]
           lim_zl = param.zero_level.flag_lim[1]
           lim_cm = param.decor.common_mode.flag_lim[1]
           
           ;;---------- Flag the source with map
           if param.w8.map_guess2mm ne '' then begin
              if lim_w8 ge 0 then loc_on = where(source_w8 gt lim_w8, nloc_on)
              if lim_w8 lt 0 then loc_on = where(source_w8 lt lim_w8, nloc_on)
              if nloc_on ne 0 then data[loc_on].on_source_w8[ikid] = 1
           endif

           if param.zero_level.map_guess2mm ne '' then begin
              if lim_zl ge 0 then loc_on = where(source_zl gt lim_zl, nloc_on)
              if lim_zl lt 0 then loc_on = where(source_zl lt lim_zl, nloc_on)
              if nloc_on ne 0 then data[loc_on].on_source_zl[ikid] = 1
           endif

           if param.decor.common_mode.map_guess2mm ne '' then begin
              if lim_cm ge 0 then loc_on = where(source_cm gt lim_cm, nloc_on)
              if lim_cm lt 0 then loc_on = where(source_cm lt lim_cm, nloc_on)
              if nloc_on ne 0 then data[loc_on].on_source_dec[ikid] = 1
           endif
        end
     endcase

     ;;---------- Flag the source with distance
     loc_on = where(dist_source lt param.w8.dist_off_source, nloc_on)
     if nloc_on ne 0 then data[loc_on].on_source_w8[ikid] = 1

     loc_on = where(dist_source lt param.zero_level.dist_off_source, nloc_on)
     if nloc_on ne 0 then data[loc_on].on_source_zl[ikid] = 1

     loc_on = where(dist_source lt param.decor.common_mode.d_min, nloc_on)
     if nloc_on ne 0 then data[loc_on].on_source_dec[ikid] = 1
  endfor

  return
end
