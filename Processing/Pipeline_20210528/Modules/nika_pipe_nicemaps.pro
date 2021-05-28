pro nika_pipe_nicemaps, fov_plot, reso_plot, relob, nsig_max, coord, header, param, map_combi, $
                        output_dir, name4file, source, sz=sz,$
                        range_plot_a=range_plot_a, range_plot_b=range_plot_b,$
                        cont_a=cont_a, cont_b=cont_b, var_lobe=var_lobe, cut_var=cut_var,$
                        title_a=title_a, title_b=title_b, $
                        bartitle_a=bartitle_a, bartitle_b=bartitle_b

  if not keyword_set(title_a) then title_a = source+' at 1.25 mm'
  if not keyword_set(title_b) then title_b = source+' at 2.05 mm'
  if not keyword_set(bartitle_a) then bartitle_a = 'Jy/Beam'
  if not keyword_set(bartitle_b) then bartitle_b = 'Jy/Beam'


  if not keyword_set(var_lobe) then var_lobe = 10.0
  
  coord_plot = [ten(coord.ra[0],coord.ra[1],coord.ra[2])*15.0,$
                ten(coord.dec[0],coord.dec[1],coord.dec[2])] ;Center of the plot 
  
  map_plot_a = filter_image(map_combi.A.Jy, fwhm=relob[0]/param.map.reso, /all) ;Smooth the map to be plotted
  map_plot_b = filter_image(map_combi.B.Jy, fwhm=relob[1]/param.map.reso, /all)             
  
  var_plot_a = map_combi.A.var                                                            
  var_plot_b = map_combi.B.var

  if keyword_set(cut_var) then begin
     lcva = where(var_plot_a gt cut_var[0], nlcva)
     if nlcva ne 0 then var_plot_a[lcva] = -1
     if nlcva ne 0 then map_plot_a[lcva] = 0
     lcvb = where(var_plot_b gt cut_var[0], nlcvb)
     if nlcvb ne 0 then var_plot_b[lcvb] = -1     
     if nlcvb ne 0 then map_plot_b[lcvb] = 0   
  endif
  
  loc_out_var_a = where(var_plot_a le 0, nloc_out_var_a)
  loc_out_var_b = where(var_plot_b le 0, nloc_out_var_b)
  
  if nloc_out_var_a ne 0 then var_plot_a[loc_out_var_a] = max(var_plot_a)*1e4 ;set undef var to max(var)
  if nloc_out_var_b ne 0 then var_plot_b[loc_out_var_b] = max(var_plot_b)*1e4

  loc_out_a = where(filter_image(var_plot_a, fwhm=var_lobe/param.map.reso,/all) gt $ 
                    nsig_max^2*min(filter_image(var_plot_a, fwhm=10.0/param.map.reso,/all)), nloc_out_a, $
                    comp=loc_in_a) ;get the location not shown
  if nloc_out_a ne 0 then map_plot_a[loc_out_a] = 10*max(map_plot_a)
  
  loc_out_b = where(filter_image(var_plot_b, fwhm=var_lobe/param.map.reso,/all) gt $
                    nsig_max^2*min(filter_image(var_plot_b, fwhm=10.0/param.map.reso,/all)), nloc_out_b, $
                    comp=loc_in_b)
  if nloc_out_b ne 0 then map_plot_b[loc_out_b] = 10*max(map_plot_b)
  
  if not keyword_set(range_plot_a) then range_plot_a = minmax(map_plot_a[loc_in_a]) ;get the range for the plot
  if not keyword_set(range_plot_b) then range_plot_b = minmax(map_plot_b[loc_in_b]) ;
  

  if not keyword_set(sz) then conts1a = [-1e5,-0.9,-0.6,-0.3,0.3,0.6,0.9,1e5]*max(range_plot_a)
  if not keyword_set(sz) then conts1b = [-1e5,-0.9,-0.6,-0.3,0.3,0.6,0.9,1e5]*max(range_plot_b)
  if keyword_set(sz) then conts1a = [-1e5,-0.9,-0.6,-0.3,0.3,0.6,0.9,1e5]*max(range_plot_a)
  if keyword_set(sz) then conts1b = [-1e5,-0.9,-0.6,-0.3,0.3,0.6,0.9,1e5]*abs(min(range_plot_b))
  if keyword_set(cont_a) then conts1a = cont_a
  if keyword_set(cont_b) then conts1b = cont_b

  overplot_radec_bar_map, map_plot_a, header, map_plot_a, header, fov_plot, reso_plot, coord_plot,$
                          postscript=output_dir+'/'+name4file+'_1mm.ps', title=title_a,$
                          bartitle=bartitle_a, xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)',$
                          barcharthick=2, mapcharthick=2, barcharsize=1, mapcharsize=1,$
                          range=range_plot_a, conts1=conts1a,$
                          colconts1=0, thickcont1=1.5,conts2=[-1e10,1e10],$         
                          ;anotconts1=strmid(strtrim([-1e5,0.05,0.1,0.2,0.4,0.6,0.8,1e5]*100.0,2),0,4)+'%',$
                          ;anothick1=3,$         
                          beam=sqrt(12.5^2+relob[0]^2),/type, bg1=100*max(range_plot_a)

  overplot_radec_bar_map, map_plot_b, header, map_plot_b, header, fov_plot, reso_plot, coord_plot,$
                          postscript=output_dir+'/'+name4file+'_2mm.ps', title=title_b,$
                          bartitle=bartitle_b, xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)',$
                          barcharthick=2, mapcharthick=2, barcharsize=1, mapcharsize=1,$
                          range=range_plot_b, conts1=conts1b,$
                          colconts1=0, thickcont1=1.5,conts2=[-1e10,1e10],$         
                          ;anotconts1=strmid(strtrim([-1e5,0.05,0.1,0.2,0.4,0.6,0.8,1e5]*100.0,2),0,4)+'%',$
                          ;anothick1=3,$          
                          beam=sqrt(18.5^2+relob[1]^2),/type, bg1=100*max(range_plot_b)
  
  return
end
