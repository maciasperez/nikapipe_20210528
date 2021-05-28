pro make_plots

  scan_list_in = '20140124s200'
 

  iscan = 0

  dir = !nika.plot_dir+"/Pipeline/scan_"+strtrim( scan_list_in[iscan], 2)
  file_save = dir+"/results.save"
  restore, file_save
  png = 0
  ps  = 0
  
  xmap=info1.xmap
  ymap=info1.ymap
  
  
  nx   = n_elements(xmap[*,0])
  ny   = n_elements(xmap[0,*])
  

  charthick=2
  yra = [-120, 100]
  wind, 1, 1, /free, xs=1600, ys=1000
  outplot, file='map_1mm', png=1, ps=ps
  imview, info1.coadd_1mm, xmap=xmap, ymap=ymap, title='T 1mm',yra=yra,$
          charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  outplot, /close
  outplot, file='map_q_1mm', png=1, ps=ps
  imview, info1.coadd_q_1mm, xmap=xmap, ymap=ymap, title='Q 1mm', yra=yra,$
          charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  outplot, /close
  outplot, file='map_u_1mm', png=1, ps=ps
  imview, info1.coadd_u_1mm, xmap=xmap, ymap=ymap,  title='U 1mm', yra=yra,$
          charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  outplot, /close
 
  outplot, file='map_2mm', png=1, ps=ps
  
  imview, info1.coadd_2mm, xmap=xmap, ymap=ymap, title='T 1mm', yra=yra,$
          charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  outplot, /close
  outplot, file='map_q_2mm', png=1, ps=ps
  imview, info1.coadd_q_2mm, xmap=xmap, ymap=ymap, title='Q 1mm', yra=yra,$
          charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  outplot, /close
  outplot, file='map_u_2mm', png=1, ps=ps
  imview, info1.coadd_u_2mm, xmap=xmap, ymap=ymap,  title='U 1mm', yra=yra,$
          charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  outplot, /close
  stop
;; CasA
  
  ;; wind, 1, 1, /free, xs=1600, ys=1000
  ;; outplot, file='map_1mm', png=1, ps=ps
  ;; imview, output_maps1.map_1mm, xmap=xmap, ymap=ymap, title='T 1mm',yra=yra,imrange=[-1,1],$
  ;;         charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  ;; outplot, /close
  ;; outplot, file='map_q_1mm', png=1, ps=ps
  ;; imview, output_maps1.map_q_1mm, xmap=xmap, ymap=ymap,title='Q 1mm',yra=yra,$
  ;;         imrange=[-1,1]*0.5,$
  ;;         charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  ;; outplot, /close
  ;; outplot, file='map_u_1mm', png=1, ps=ps
  ;; imview, output_maps1.map_u_1mm, xmap=xmap, ymap=ymap,title='U 1mm',yra=yra,$
  ;;         imrange=[-1,1]*0.5,$
  ;;         charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec', units='Jy'
  ;; outplot, /close

  ;; outplot, file='map_2mm', png=1, ps=ps
  ;; imview, output_maps1.map_2mm, xmap=xmap, ymap=ymap, title='T 2mm',imrange=[-1,1],$
  ;;         charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec'
  ;; outplot, /close
  ;; outplot, file='map_q_2mm', png=1, ps=ps
  ;; imview, output_maps1.map_q_2mm, xmap=xmap, ymap=ymap,title='Q 2mm',$
  ;;         imrange=[-1,1]*0.05,$
  ;;         charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec'
  ;; outplot, /close
  ;; outplot, file='map_u_2mm', png=1, ps=ps
  ;; imview, output_maps1.map_u_2mm, xmap=xmap, ymap=ymap,title='U 2mm',$
  ;;         imrange=[-1,1]*0.05,$
  ;;         charthick=charthick, chars=1.3, xtitle='Arcsec', ytitle='Arcsec'
  ;; outplot, /close







end
