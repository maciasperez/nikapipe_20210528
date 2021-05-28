;+
;PURPOSE: Plot the maps per scan
;
;INPUT: The parameter, data and kidpar structures.
;
;OUTPUT: none
;
;LAST EDITION: 
;   2013: creation (adam@lpsc.in2p3.fr)
;   21/09/2013: add astrometry (adam@lpsc.in2p3.fr)
;   15/02/2014: define the "best" range by default
;   16/02/2014: uses radec_bar_map instead of dispim_bar if ps set
;-

pro nika_pipe_plotmaps, param, kidpar, astr, maps, $
                        ps=ps, $
                        png=png, $
                        range_plot_scan_a=range_plot_scan_a, $
                        range_plot_scan_b=range_plot_scan_b,$
                        no_merge_fig=no_merge_fig
  loadct, 4

  iscan = param.iscan
  nscans = n_elements(param.scan_list)
  
  ;;------- Define the range if not set
  if not keyword_set(range_plot_scan_a) then begin
     loc = where(filter_image(maps.A.time, FWHM=20.0/param.map.reso, /all) gt 1.5*min(filter_image(maps.A.time, FWHM=20.0/param.map.reso, /all)), nloc)
     if nloc ne 0 then range_plot_scan_a=minmax((filter_image(maps.A.Jy, FWHM=20.0/param.map.reso, /all))[loc])/2
  endif
  if not keyword_set(range_plot_scan_b) then begin
     loc = where(filter_image(maps.B.time, FWHM=20.0/param.map.reso, /all) gt 1.5*min(filter_image(maps.B.time, FWHM=20.0/param.map.reso, /all)), nloc)
     if nloc ne 0 then range_plot_scan_b=minmax((filter_image(maps.B.Jy, FWHM=20.0/param.map.reso, /all))[loc])/2
  endif

  ;;------- Defines the windows
  wind_ind = {scans_a:1, scans_b:2} ;Indices of the windows for each plot
  Device, Window_State=theseWindows

  if (iscan eq 0 or theseWindows[wind_ind.scans_a] eq 0) and not keyword_set(ps) and not keyword_set(png) then $
     window, wind_ind.scans_a, xsize=1500,ysize=900,title='Map per scan - 1.25 mm'
  if (iscan eq 0 or theseWindows[wind_ind.scans_b] eq 0) and not keyword_set(ps) and not keyword_set(png) then $
     window, wind_ind.scans_b, xsize=1500,ysize=900,title='Map per scan - 2.05 mm'
  
  ;;------- Get the optimal number of lines and columns
  Nb_scan_line = long(sqrt(nscans))
  Nb_scan_col = long(sqrt(nscans))
  while Nb_scan_line*Nb_scan_col lt nscans do Nb_scan_col = Nb_scan_col+1
  
  ;;------- Get the scale on the axis
  n_map_x = astr.naxis[0]
  n_map_y = astr.naxis[1]
  x_carte = dindgen(n_map_x)*(-astr.cdelt[0])*3600 - (n_map_x/2-0.5)*(-astr.cdelt[0])*3600
  y_carte = dindgen(n_map_y)*(astr.cdelt[1])*3600 - (n_map_y/2-0.5)*(astr.cdelt[1])*3600
  
  ;;------- Plot the map
  reso = ((-astr.cdelt[0])*3600 + (astr.cdelt[1])*3600)/2.0

  if not keyword_set(ps) and not keyword_set(png) then begin
     wset, wind_ind.scans_a
     !p.multi = [Nb_scan_line*Nb_scan_col-iscan,Nb_scan_col,Nb_scan_line]
     dispim_bar, filter_image(maps.A.Jy, fwhm=sqrt(22.0^2-12.0^2)/reso,/all), xmap=x_carte, ymap=y_carte, /aspect, /nocont, title=param.scan_list[iscan], xtitle='arcsec', ytitle='arcsec', charsize=1, crange=range_plot_scan_a, /silent
     !p.multi=0
     
     wset, wind_ind.scans_b
     !p.multi = [Nb_scan_line*Nb_scan_col-iscan,Nb_scan_col,Nb_scan_line]
     dispim_bar, filter_image(maps.B.Jy, fwhm=sqrt(22.0^2-18.0^2)/reso,/all),xmap=x_carte,ymap=y_carte,/aspect,/nocont,title=param.scan_list[iscan],xtitle='arcsec',ytitle='arcsec',charsize=1, crange=range_plot_scan_b, /silent
     !p.multi=0
  endif
  
  ;;------- Png plots
  if keyword_set(png) then begin
     imview, filter_image(maps.A.Jy, fwhm=sqrt(22.0^2-12.0^2)/reso,/all), xmap=x_carte#replicate(1,n_map_y), ymap=y_carte##replicate(1,n_map_x), title=param.scan_list[iscan], xtitle='arcsec', ytitle='arcsec', charsize=1,png=param.output_dir+'/map_1mm_scan_'+strtrim(param.scan_list[param.iscan],2)+'.png',imrange=range_plot_scan_a
     imview, filter_image(maps.B.Jy, fwhm=sqrt(22.0^2-18.0^2)/reso,/all),xmap=x_carte#replicate(1,n_map_y),ymap=y_carte##replicate(1,n_map_x), title=param.scan_list[iscan],xtitle='arcsec',ytitle='arcsec',charsize=1,png=param.output_dir+'/map_2mm_scan_'+strtrim(param.scan_list[param.iscan],2)+'.png', imrange=range_plot_scan_b
  endif
  
  ;;------- ps plots
  if keyword_set(ps) then begin
     mymap1mm = filter_image(maps.A.Jy, fwhm=sqrt(22.0^2-12.0^2)/reso,/all)
     mymap2mm = filter_image(maps.B.Jy, fwhm=sqrt(22.0^2-18.0^2)/reso,/all)
     ;;-----------
     ;; quick fix, Nico
     if not keyword_set(range_plot_scan_a) then range_plot_scan_a = minmax( mymap1mm)
     if not keyword_set(range_plot_scan_b) then range_plot_scan_b = minmax( mymap2mm)
     ;;-----------
     sat_up1mm = where(mymap1mm gt range_plot_scan_a[1], nsat_up1mm, comp=ok_up_1mm)
     if nsat_up1mm ne 0 then mymap1mm[sat_up1mm] = max(mymap1mm[ok_up_1mm])
     sat_dw1mm = where(mymap1mm lt range_plot_scan_a[0], nsat_dw1mm, comp=ok_dw_1mm)
     if nsat_dw1mm ne 0 then mymap1mm[sat_dw1mm] = min(mymap1mm[ok_dw_1mm])

     sat_up2mm = where(mymap2mm gt range_plot_scan_b[1], nsat_up2mm, comp=ok_up_2mm)
     if nsat_up2mm ne 0 then mymap2mm[sat_up2mm] = max(mymap2mm[ok_up_2mm])
     sat_dw2mm = where(mymap2mm lt range_plot_scan_b[0], nsat_dw2mm, comp=ok_dw_2mm)
     if nsat_dw2mm ne 0 then mymap2mm[sat_dw2mm] = min(mymap2mm[ok_dw_2mm])

     mkhdr, head, mymap1mm      ;get header typique
     putast, head, astr, equinox=2000, cd_type=0 ;astrometry in header
     
     if param.map.size_ra ge 4*60.0 or param.map.size_dec ge 4*60.0 then cp = 'arcmin' else cp = 'arcsec'

     radec_bar_map, 1e3*mymap1mm, head, $
                    title=param.scan_list[iscan], $
                    xtitle=cp, ytitle=cp, bartitle='mJy/beam',$
                    range=range_plot_scan_a*1e3,$
                    conts=range_plot_scan_a*1e3,$
                    pdf=param.output_dir+'/map_1mm_scan_'+strtrim(param.scan_list[param.iscan],2)
     radec_bar_map, 1e3*mymap2mm, head, $
                    title=param.scan_list[iscan], $
                    xtitle=cp, ytitle=cp, bartitle='mJy/beam',$
                    range=range_plot_scan_b*1e3,$
                    conts=range_plot_scan_a*1e3,$
                    pdf=param.output_dir+'/map_2mm_scan_'+strtrim(param.scan_list[param.iscan],2)

     if not keyword_set(no_merge_fig) and param.iscan eq n_elements(param.scan_list)-1 then begin
        spawn, 'pdftk '+param.output_dir+'/map_1mm_scan_*.pdf cat output '+param.output_dir+'/map_1mm_scan.pdf'
        spawn, 'rm -rf '+param.output_dir+'/map_1mm_scan_*.pdf'
        spawn, 'pdftk '+param.output_dir+'/map_2mm_scan_*.pdf cat output '+param.output_dir+'/map_2mm_scan.pdf'
        spawn, 'rm -rf '+param.output_dir+'/map_2mm_scan_*.pdf'
     endif

  endif

  loadct,39

  return
end

