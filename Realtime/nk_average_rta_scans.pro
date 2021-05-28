;+
; stack a list of scans
;
; example (diffuse source) : nk_average_rta_scans, '20181124s'+strtrim([103, 104, 115, 107],2), imrange_i2=[-0.1,0.05], imrange_i1=[-0.2, 0.2], source_diffuse=1
;
; first creation: Nov 2018
;-

pro nk_average_rta_scans, scan_list, imrange_i1 = imrange_i1, imrange_i2 = imrange_i2, source_diffuse=source_diffuse

  restore, !nika.plot_dir+'/v_1/'+strtrim(scan_list[0],2)+'/results.save'

  print, 'map pixel resolution  = ', strtrim(param1.map_reso, 2), ' arcsec'
  nk_average_scans, param1, scan_list, grid_tot, grid_jk, average_only=1, nofits=1

  
  nk_display_grid, grid_tot, $
                   png=png, ps=ps, $
                   aperture_photometry=aperture_photometry, $
                   educated=educated, title='flux density', coltable=39, $
                   imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                   imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                   imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                   imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                   flux=flux, charsize=charsize, map=map, conv=conv


  mask1 = grid_tot.mask_source_1mm
  mask2 = grid_tot.mask_source_2mm
  w1=where(mask1 gt 0)
  w2=where(mask2 gt 0)
  sig1 = stddev((grid_tot.map_i_1mm)[w1])
  sig2 = stddev((grid_tot.map_i_2mm)[w2])

  print, ''
  print, '---------------------------------------------------'
  print, ''
  print, ' Basic estimates: '
  print, " RTA noise decorrelation using noise decorrelation outside a 60 arcsec radius mask (aka 'common mode kids out')"
  print, ''
  print, '---------------------------------------------------'
  
  print, 'rms 1mm with default mask = ', strtrim(stddev((grid_tot.map_i_1mm)[w1]),2), ' Jy/beam' 
  print, 'rms 2mm with default mask = ', strtrim(stddev((grid_tot.map_i_2mm)[w2]),2), ' Jy/beam' 

  if keyword_set(source_diffuse) then begin
     ;xmap = grid_tot.xmap
     ;ymap = grid_tot.xmap

     ;; could be useful in case of very high detection
     ;;m1 = mask1*0.0 + 1.0 
     ;;m2 = mask2*0.0 + 1.0
     m1 = mask1 
     m2 = mask2
     ws1 = where(grid_tot.map_i_1mm gt 2.0*sig1, n1)
     ws2 = where(grid_tot.map_i_2mm gt 2.0*sig2, n2)
     if n1 gt 0 then m1[ws1] = 0.0
     if n2 gt 0 then m2[ws2] = 0.0

     m1g = gauss_smooth(m1, 3)
     w1g = where(m1g gt 0.7)
     m1t = m1g*0.0
     m1t[w1g] = 1.0 
     m2g = gauss_smooth(m2, 3)
     w2g = where(m2g gt 0.7)
     m2t = m2g*0.0
     m2t[w2g] = 1.0 
     
     mask1=m1t
     mask2=m2t

     mask1 =  mask1*mask2
     mask2 =  mask1*mask2
     
     wind, 1, 1, /free
     imview, mask1, title="source-thresholding mask", coltable=1
     
     w1=where(mask1 gt 0)
     w2=where(mask2 gt 0)
     print, 'rms 1mm using source-thresholding mask = ', strtrim(stddev((grid_tot.map_i_1mm)[w1]),2), ' Jy/beam' 
     print, 'rms 2mm using source-thresholding mask = ', strtrim(stddev((grid_tot.map_i_2mm)[w2]),2), ' Jy/beam' 

  endif
 


  nk_display_grid, grid_jk, $
                   png=png, ps=ps, $
                   aperture_photometry=aperture_photometry, $
                   educated=educated, title='noise estimates', coltable=39, $
                   imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                   imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                   imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                   imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                   flux=flux, charsize=charsize, map=map, conv=conv

  w1=where(mask1 gt 0)
  w2=where(mask2 gt 0)
  
  ;print, 'median noise (basic common mode) 1mm = ', strtrim(median(abs((grid_jk.map_i_1mm)[w1])),2), ' Jy/beam' 
  ;print, 'median noise (basic common mode) 2mm = ', strtrim(median(abs((grid_jk.map_i_2mm)[w2])),2), ' Jy/beam'
  
  print, 'stddev noise 1mm = ', strtrim(stddev((grid_jk.map_i_1mm)[w1]),2), ' Jy/beam' 
  print, 'stddev noise 2mm = ', strtrim(stddev((grid_jk.map_i_2mm)[w2]),2), ' Jy/beam'
  
  
  ;stop
end
