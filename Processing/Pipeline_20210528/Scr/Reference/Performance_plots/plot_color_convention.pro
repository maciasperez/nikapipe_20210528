pro plot_color_convention, col_a1, col_a2, col_a3, $
                           col_mwc349, col_crl2688, col_ngc7027, $
                           col_n2r9, col_n2r12, col_n2r14, col_1mm, $
                           show_color=show_color, $
                           array_color=array_color, $
                           secondary_color=secondary_color, $
                           run_color=run_color, $
                           old_version=old_version


  load_tiger_color

  ;; ARRAYS
  col_a1 = 50  ;; light blue 
  col_a3 = 20  ;; dark blue
  col_a2 = 160 ;; red
  col_1mm = 40 ; another blue

  ;; SECONDARIES
  col_mwc349  = 125 ;; dark orange
  col_crl2688 = 190 ;; violet
  col_ngc7027 = 80  ;; green
  
  ;;col_mwc349  = 35  ;; sky blue
  ;;col_ngc7027 = 95  ;; chartreuse
  ;;col_crl2688 = 120 ;; orange
  
  ;; RUNS
  col_n2r9  = 35  ;; sky blue
  col_n2r12 = 120 ;; chartreuse
  col_n2r14 = 95  ;; orange

  ;;col_n2r12  = 125 ;; dark orange
  ;;col_n2r9   = 190 ;; violet
  ;;col_n2r14  = 80  ;; green

  ;; Plots
  ;;_______________________________________________________________

  if keyword_set(show_color) then begin
     ;; pre-defined colors
     ;;--------------------------------------------------
     ind = indgen(1000)
     x = [0, 5, 10, 20, 35, 45, 50, 60, 65, 75, 80, 90, 95, 115, 120, 140, 160, 180, 190, 200, 230, 240, 255]
     ;; 0 noir
     ;; 5 kaki
     ;; 10 indigo
     ;; 20 bleu fonce
     ;; 35 bleu moyen
     ;; 45 bleu clair 1
     ;; 50 bleu clair 2
     ;; 60 turquoise
     ;; 65 ardoise
     ;; 75 vert frais
     ;; 80 vert foret
     ;; 90 vert
     ;; 95 vert jaune
     ;; 115 jaune dore
     ;; 120 orange
     ;; 140 corail
     ;; 160 rouge ecarlate
     ;; 180 marron
     ;; 190 violet 1
     ;; 200 violet pourpre
     ;; 230 violet clair
     ;; 240 rose chaud
     ;; 255 blanc
     nx = n_elements(x)
     incx = indgen(nx)*50. - nx*25.
     plot, ind, ind, /nodata, col=0
     for i=0, nx-1 do oplot, ind, ind + incx[i], col=x[i], thick=3
  endif


  if keyword_set(array_color) then begin
     ;; color convention for arrays 
     ;;--------------------------------------------------
     v0 = [60, 40, 210]
     v1 = [20, 50, 160]
     outfile = 'color_convention_arrays_tiger'
     outplot, file=outfile, png=png
     ns = 30
     window, 2                               
     index = indgen(ns)                        
     data = randomn(seed, ns)
     plot, index, data, col=0, /nodata, yr=[-1, 3], ytitle="Quantity per array", xtitle= 'index'
     oplot, index, data/10.+1., psym=8, col=v1[0] 
     oplot, index, data/10.+0.7, psym=8, col=v1[1]
     oplot, index, data/10.-0.5, psym=8, col=v1[2]
     legendastro, ['A1, "light blue", ct=Tiger, col=50', 'A3, "deep blue", ct=Tiger, col=20', 'A2, "red", ct=Tiger, col=160'], col=[50, 20, 160], textcol=[0, 0, 0], psym=[8, 8, 8], box=0
     outplot, /close
  endif

  
  if keyword_set(secondary_color) then begin
     ;; color convention for secondary calibrators 
     ;;--------------------------------------------------
     v0 = [240, 110, 150]
     v1 = [230, 90, 120]
     v1 = [35, 90, 120]
     v1 = [190, 80, 125] ;; couleurs secondaires
     outfile = 'color_convention_sources_tiger'
     outplot, file=outfile, png=png
     ns = 30
     window, 3                               
     index = indgen(ns)                        
     data = randomn(seed, ns)
     plot, index, data, col=0, /nodata, yr=[-1, 3], ytitle='secondary calibrators', xtitle='index' 
     oplot, index, data/10.+1., psym=8, col=v1[0]
     oplot, index, data/10.+0.6, psym=8, col=v1[1]
     oplot, index, data/10.+0.2, psym=8, col=v1[2]
     legendastro, ['MWC349, "orange", ct=Tiger, col=125', 'CRL2688, "violet", ct=Tiger, col=190', 'NGC7027, "green", ct=Tiger, col=80'], col=[125, 190, 80], textcol=[0, 0, 0], psym=[8, 8, 8], box=0
     outplot, /close
  endif

  
  if keyword_set(run_color) then begin
     ;; color convention for runs 
     ;;--------------------------------------------------
     v1 = [250, 35, 95]
     ;;v1 = [140, 35, 75]
     v1 = [120, 35, 95]
     
     outfile = 'color_convention_runs_tiger'
     outplot, file=outfile, png=png
     ns = 30
     window, 2                             
     index = indgen(ns)                        
     data = randomn(seed, ns)
     plot, index, data, col=0, /nodata, yr=[-1, 3], ytitle='Quantity per runs', xtitle='index'
     oplot, index, data/10.+1., psym=8, col=v1[0]
     oplot, index, data/10.+0.6, psym=8, col=v1[1]
     oplot, index, data/10.+0.2, psym=8, col=v1[2]
     legendastro, ['N2R9, "sky blue", ct=Tiger, col=35', 'N2R12, "chartreuse", ct=Tiger, col=95', 'N2R14, "orange", ct=Tiger, col=120'], col=[35, 95, 120], textcol=[0,0,0],  psym=[8, 8, 8], box=0
     outplot, /close
  endif


  ;; old version using color table 39
  
  if keyword_set(old_version) then begin
     loadct, 39
     png=0
     outfile = 'color_convention_temperature'
     outplot, file=outfile, png=png
     window, 1
     ns = 30                                   
     index = indgen(ns)                        
     data = randomn(seed, ns)
     plot, index, data, col=0, /nodata, yr=[-1, 3]
     oplot, index, data/10.+1., psym=8, col=125  
     oplot, index, data/10.+0.7, psym=8, col=250
     oplot, index, data/10.-0.5, psym=8, col=75
     legendastro, ['A1, ct=39, col=125', 'A3, ct=39, col=250', 'A2, ct=39, col=75'], col=[125, 250, 75], textcol=[125, 250, 75], box=0
     outplot, /close
     
     outfile = 'color_convention_frequency'
     outplot, file=outfile, png=png
     ns = 30
     window, 1                                
     index = indgen(ns)                        
     data = randomn(seed, ns)
     plot, index, data, col=0, /nodata, yr=[-1, 3]
     oplot, index, data/10.+1., psym=8, col=50   
     oplot, index, data/10.+0.7, psym=8, col=90
     oplot, index, data/10.-0.5, psym=8, col=230
     legendastro, ['A1, ct=39, col=50', 'A3, ct=39, col=90', 'A2, ct=39, col=230'], col=[50, 90, 230], textcol=[50, 90, 230], box=0
     outplot, /close
  endif
     
     
  
end
