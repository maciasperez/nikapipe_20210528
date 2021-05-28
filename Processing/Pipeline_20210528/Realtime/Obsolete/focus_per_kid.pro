
pro focus_per_kid, day, scan_num,  size = size

  if not keyword_set(size) then size = 200.0

     png        = 1
     noskydip   = 1


     nika_pipe_default_param, scan_num, day, param
     param.map.size_ra    = size;200.d0
     param.map.size_dec   = size;200.d0
     param.map.reso       = 5.d0
     ;param.decor.method   = 'median_simple'
     param.decor.method   = 'COMMON_MODE_KIDS_OUT'
     param.decor.common_mode.d_min = 40.
     param.decor.iq_plane.apply = 'no'
     ;param.kid_file.a = !nika.off_proc_dir+"/kidpar_ref_1mm_20130611_0146.fits"
     ;param.kid_file.b = !nika.off_proc_dir+"/kidpar_ref_2mm_20130611_0146.fits"
     param.kid_file.a = !nika.off_proc_dir+"/kidpar_ref_1mm_20130612_0143_v3.fits"
     param.kid_file.b = !nika.off_proc_dir+"/kidpar_ref_2mm_20130612_0143_v3.fits"

     map_per_kid = 1

     otf_map, scan_num, day, /logbook,png=png,ps=ps,param=param,noskydip=noskydip,box_maps=maps, $
              xmap=xmap,ymap=ymap,/azel, /noplot, map_per_kid = map_per_kid

     kidpar1 = mrdfits(param.kid_file.a, 1, head1)
     kidpar2 = mrdfits(param.kid_file.b, 1, head2)
     map1 =  dblarr(1, (size(maps.a.jy))[1], (size(maps.a.jy))[2])
     map2 =  dblarr(1, (size(maps.b.jy))[1], (size(maps.b.jy))[2])
     map1[0, *, *] = maps.a.jy
     map2[0, *, *] = maps.b.jy
     beam_guess, map1, xmap, ymap, kidpar1, x_peaks1, y_peaks1, a_peaks1, sigma_x1, sigma_y1, beam_list1, theta1, /noplot
     beam_guess, map2, xmap, ymap, kidpar2, x_peaks2, y_peaks2, a_peaks2, sigma_x2, sigma_y2, beam_list2, theta2, /noplot

     ;;---------- Check on maps
     xmap = dindgen((size(xmap))[1])/((size(xmap))[1]-1)*max(xmap) - max(xmap)/2.0
     ymap = dindgen((size(ymap))[2])/((size(ymap))[2]-1)*max(ymap) - max(ymap)/2.0

     window, /free,  title = 'Averaged map'
     !p.multi =  [0, 2, 2]
     dispim_bar, maps.a.jy - beam_list1[0, *, *], xmap = xmap, ymap = ymap,/aspect,/nocont,title = 'residual 1mm'
     dispim_bar, maps.b.jy - beam_list2[0, *, *],   xmap = xmap, ymap = ymap,/aspect,/nocont,title='residual 2mm'
     dispim_bar, maps.a.jy,  xmap = xmap, ymap = ymap,  /aspect,  /nocont,title='Map 1mm'
     dispim_bar, maps.b.jy,  xmap = xmap, ymap = ymap,  /aspect,  /nocont,title='Map 2mm'
     !p.multi = 0

     n1mm = n_elements(where(kidpar1.type eq 1))
     n2mm = n_elements(where(kidpar2.type eq 1))


     print, 'First looking at the 1mm pixels'
     window, /free,  title = 'Individual map'
     for ikid = 0, n1mm do begin
        dispim_bar, map_per_kid[ikid].jy,xmap=xmap,ymap=ymap,/asp,/noc,title='Map for the KID '+strtrim(ikid,2)
        bidon = ''
        read, bidon, prompt = 'Press enter to continue, press q to go to 2mm'
        if bidon eq 'q' then goto, suite1
     endfor

     suite1: print, 'Now looking at 2mm pixels'
     
     for ikid = n1mm, n1mm+n2mm-1  do begin
        dispim_bar, map_per_kid[ikid].jy,xmap=xmap,ymap=ymap,/asp,/noc,title='Map for the KID '+strtrim(ikid,2)
        bidon = ''
        read, bidon, prompt = 'Press enter to continue, press q to quit'
        if bidon eq 'q' then goto, suite2
     endfor

     suite2: print, 'The end !!!'

stop

end
