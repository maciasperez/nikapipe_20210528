
pro compare_calib, png=png

  kp1_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  kp2_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
    
  name1 = 'N2R12_Uranus'
  name2 = 'N2R14_Mars_skd14'

  kp1_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  kp2_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd16_calUranus16.fits"
  
  name1 = 'N2R12_Uranus'
  name2 = 'N2R14_Mars_skd16'

  
  ;;kp1_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
  ;;kp2_file = !nika.off_proc_dir+"/kidpar_20180115s122_v2_LP_skd14.fits"

  ;;name1 = 'N2R14 Mars skd14 '
  ;;name2 = 'N2R14 Uranus skd14'

  ;;kp1_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd16_calUranus16.fits"
  ;;kp2_file = !nika.off_proc_dir+"/kidpar_20180122s309_v2_HA_skd13_calUranus12.fits"

  ;;name1 = 'N2R14 Mars skd16 '
  ;;name2 = 'N2R14 3C84 skd13'


  kp1_file = !nika.off_proc_dir+"/kidpar_N2R9_baseline.fits"
  kp2_file = '/home/perotto/NIKA/Plots/N2R9/Photometry/kidpar_calib_N2R9_ref_baseline_photocorr_var1_hybrid_v0.fits'
  kp1_file = '/home/perotto/NIKA/Plots/N2R9/Photometry/Uranus_photometry_N2R9_ref_baseline/kidpar_calib_N2R9_ref_baseline_photocorr_var1_hybrid_v0.fits'
 
  name1 = 'N2R9 Juan '
  name2 = 'N2R9 Laurence'
  
  
  plot_dir = '/home/perotto/NIKA/Plots/N2R9/Photometry'

  
  kp1 = mrdfits(kp1_file, 1)
  kp2 = mrdfits(kp2_file, 1)

  w1 = where( kp1.type eq 1, nw1)
  w2 = where( kp2.type eq 1, nw2)
  kp1 = kp1[w1]
  kp2 = kp2[w2]
  my_match, kp1.numdet, kp2.numdet, sub1, sub2
  
  kp1 = kp1[sub1]
  kp2 = kp2[sub2]
  
  
  wind, 1, 1, /free, xsize=1000, ysize=550
  outplot, file=plot_dir+'/compare_calib_'+strtrim(name1,2)+'_vs_'+strtrim(name2,2), $
           png=png, ps=ps
  my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.09, xmargin=0.1, ymargin=0.1 ; 1e-6
    
  coltab = [200, 80, 250]

  wa1 = where(kp1.array eq 1) 
  plot, kp1[wa1].calib_fix_fwhm, kp2[wa1].calib_fix_fwhm, /xs, $
        psym=-4, $
        xtitle=name1+' calib_fix_fwhm', ytitle=name2+' calib_fix_fwhm', /ys, /nodata, $
        pos=pp1[0, *], title='1 mm'
  
  oplot, kp1[wa1].calib_fix_fwhm, kp2[wa1].calib_fix_fwhm, psym=8, col=coltab[0]
  wa3 = where(kp1.array eq 3) 
  oplot, kp1[wa3].calib_fix_fwhm, kp2[wa3].calib_fix_fwhm, psym=8, col=coltab[2]
  index = (max(kp1[wa1].calib_fix_fwhm)-min(kp1[wa1].calib_fix_fwhm))/100.*indgen(100)+min(kp1[wa1].calib_fix_fwhm)
  oplot, index, index, col=0

  
  wa2 = where(kp1.array eq 2) 
  plot, kp1[wa2].calib_fix_fwhm, kp2[wa2].calib_fix_fwhm, /xs, $
        psym=-4, $
        xtitle=name1+' calib_fix_fwhm', ytitle=name2+' calib_fix_fwhm', /ys, /nodata, $
        pos=pp1[1, *], /noerase, title='2 mm'
  
  oplot, kp1[wa2].calib_fix_fwhm, kp2[wa2].calib_fix_fwhm, psym=8, col=coltab[1]
  index = (max(kp1[wa2].calib_fix_fwhm)-min(kp1[wa2].calib_fix_fwhm))/100.*indgen(100)+min(kp1[wa2].calib_fix_fwhm)
  oplot, index, index, col=0
  !p.multi=0
  outplot, /close
  
  stop

  
end
