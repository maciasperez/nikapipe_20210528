pro nika_pipe_plotmapperkid, output_dir, maps, reso, kidpar, range=range

  nkid = n_elements(kidpar)
  
  count = 0
  for ikid=0, nkid-1 do begin
     if kidpar[ikid].type eq 1 then begin
        
        name_title = 'KID numdet '+strtrim(kidpar[ikid].numdet, 2)
        name_plot = output_dir+'/map_kid'+string(ikid, format='(I4.4)')+'.ps'

        map = maps[count].jy
        nx = (size(map))[1]
        ny = (size(map))[2]

        set_plot, 'PS'
        device, /color, bits_per_pixel=256, filename=name_plot
        dispim_bar, filter_image(map, fwhm=18.5/reso, /all), $
                    /aspect, /nocont, $
                    xmap=dindgen(nx)*reso - nx/2*reso, $
                    ymap=dindgen(ny)*reso - nx/2*reso, $
                    title=name_title, $
                    xtitle='R.A. offset (arcsec)', $
                    ytitle='DEC. offset (arcsec)', $
                    crange=range
        device,/close
        set_plot, 'X'

        spawn, 'ps2pdf '+output_dir+'/map_kid'+string(ikid, format='(I4.4)')+'.ps '+output_dir+'/map_kid'+string(ikid, format='(I4.4)')+'.pdf'
        spawn, 'rm -rf '+output_dir+'/map_kid'+string(ikid, format='(I4.4)')+'.ps'
        
        count += 1
     endif
  endfor

  spawn, "pdftk "+output_dir+"/map_kid*.pdf cat output "+output_dir+"/map_all_kid.pdf"
  spawn, "rm -rf "+output_dir+"/map_kid*.pdf"

  return
end
