pro geom_sort_kids_per_numdet, kidpar_in, kidpar_out

  ;; LP, 21/10/16
  ;; ex: geom_sort_kids_per_numdet, 'kidpar_20161010s19_v0_LP.fits', 'kidpar_20161010s19_v0_LP_sort.fits'
  
  kpi = mrdfits(kidpar_in, 1)

  tri = sort(kpi.numdet)
  kpo = kpi[tri]
  
  nk_write_kidpar, kpo, kidpar_out
 
  
end
