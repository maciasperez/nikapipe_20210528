pro nika_pipe_noiseperkid, mpk, mpspk, order, output_dir, name4file, param, kid_par=kid_par, check_sampling=check_sampling,nbin_pk=nbin_pk, nbin_a=nbin_a, nbin_b=nbin_b
  
  if not keyword_set(nbin_pk) then nbin_pk=50
  if not keyword_set(nbin_a) then nbin_a=50
  if not keyword_set(nbin_b) then nbin_b=50

  ;;----- Show the nb hit map to check that hit everywhere
  if keyword_set(check_sampling) then dispim_bar, mpspk[0,0].time*!nika.f_sampling, $
     /noc, /asp, title='Number of hit per pixel - first KID - first scan'
  
  ;;----- Define variables
  nkid = n_elements(mpspk[0,*])
  nscan = n_elements(mpspk[*,0])
  nx = (size(mpspk[0,0].jy))[1]
  ny = (size(mpspk[0,0].jy))[2]
  
  if keyword_set(kid_par) then begin     
     won_a = where(kid_par.type eq 1 and kid_par.array eq 1, nkida)
     won_b = where(kid_par.type eq 1 and kid_par.array eq 2, nkidb)
     won = where(kid_par.type eq 1)
  endif

  sig_noise = dblarr(nkid)
  
  ;;----- Loop for all KID
  for ikid=0, nkid-1 do begin
     ;;---Put the map for a given KID as it should
     test_map = dblarr(nx, ny)
     list = {A:{Jy:test_map, var:test_map, time:test_map},$
             B:{Jy:test_map, var:test_map, time:test_map}}
     list = replicate(list, nscan)
     for iscan = 0, nscan-1 do list[iscan].A = mpspk[iscan, ikid]
     list.B = list.A
     list = list[order]

     ;;--- Get the jack knife
     map_jk = nika_pipe_jackknife(param, list) ;A and B structure are equals

     ;;--- Get the noise
     if not keyword_set(kid_par) then nika_pipe_noisefromjk, map_jk.A/2.0, mpk[ikid].time, stddev_map, noise,$
         ps=output_dir+'/'+name4file+'_sensitivity_hist_kid'+string(ikid,format='(I4.4)')+'.ps',$
        title='KID ON number '+strtrim(ikid,2),nbins=nbin_pk
     if keyword_set(kid_par) then nika_pipe_noisefromjk, map_jk.A/2.0, mpk[ikid].time, stddev_map, noise,$
        ps=output_dir+'/'+name4file+'_sensitivity_hist_kid'+string(ikid,format='(I4.4)')+'.ps',$
        title='KID numdet '+strtrim(kid_par[won[ikid]].numdet,2),nbins=nbin_pk
     
     ;;--- Convert to pdf and remove ps for only one pdf file
     spawn, 'ps2pdf '+output_dir+'/'+name4file+'_sensitivity_hist_kid'+string(ikid,format='(I4.4)')+'.ps '+ $
            output_dir+'/'+name4file+'_sensitivity_hist_kid'+string(ikid,format='(I4.4)')+'.pdf'
     spawn, 'rm -rf '+output_dir+'/'+name4file+'_sensitivity_hist_kid'+string(ikid,format='(I4.4)')+'.ps'
     
     sig_noise[ikid] = noise
  endfor
  
  spawn, "pdftk "+output_dir+'/'+name4file+'_sensitivity_hist_kid*.pdf cat output '+ $
         output_dir+'/'+name4file+'sensitivity_hist_all_kid.pdf'
  spawn, "rm -rf "+output_dir+'/'+name4file+'_sensitivity_hist_kid*.pdf'
  
  ;;--- Histogram for the noise of all KIDs
  ;;....... Case of no kid_par given
  if not keyword_set(kid_par) then begin
     message, /info, 'You did not give the kid_par so the histogram is made for both arrays at once'
     
     hist = histogram(sig_noise, nbins=nbin_a+nbin_b)
     bins = FINDGEN(N_ELEMENTS(hist))/(N_ELEMENTS(hist)-1) * $
            (MAX(sig_noise)-MIN(sig_noise))+MIN(sig_noise) 
  
     set_plot, 'ps'
     DEVICE, /COLOR, filename=output_dir+'/'+name4file+'_sensitivity_distribution.ps'
     plot, bins, hist, psym=10, xtitle='Noise distribution (mJy/Beam.s!E1/2!N)', ytitle='Number of KIDs',$
           title='KIDs noise distribution - 1 and 2 mm',charthick=2,/nodata,xstyle=1,ystyle=1,$
           xr=[0,1]*max(bins),yr=[0, max(hist)*1.2]
     oplot, bins, hist, col=50, psym=10, thick=2
     device, /close
     set_plot, 'x'
  endif

  ;;....... Case kid_par given
  if keyword_set(kid_par) then begin
     message, /info, 'You gave the kid_par so the histogram is made for both arrays separately'
     
     hist_a = histogram(sig_noise[0:nkida-1], nbins=nbin_a)
     bins_a = FINDGEN(N_ELEMENTS(hist_a))/(N_ELEMENTS(hist_a)-1) * $
              (MAX(sig_noise[0:nkida-1])-MIN(sig_noise[0:nkida-1]))+MIN(sig_noise[0:nkida-1]) 
     
     hist_b = histogram(sig_noise[nkida:*], nbins=nbin_b)
     bins_b = FINDGEN(N_ELEMENTS(hist_b))/(N_ELEMENTS(hist_b)-1) * $
              (MAX(sig_noise[nkida:*])-MIN(sig_noise[nkida:*]))+MIN(sig_noise[nkida:*]) 
     
     set_plot, 'ps'
     DEVICE, /COLOR, filename=output_dir+'/'+name4file+'_sensitivity_distribution_1mm.ps'
     plot, bins_a, hist_a, psym=10, xtitle='Noise distribution (mJy/Beam.s!E1/2!N)', ytitle='Number of KIDs',$
           title='KIDs noise distribution - 1mm',charthick=2,/nodata,xstyle=1,ystyle=1,$
           xr=[0,1]*max(bins_a),yr=[0, max(hist_a)*1.2]
     oplot, bins_a, hist_a, col=50, psym=10, thick=2
     device, /close
     set_plot, 'x'

     set_plot, 'ps'
     DEVICE, /COLOR, filename=output_dir+'/'+name4file+'_sensitivity_distribution_2mm.ps'
     plot, bins_b, hist_b, psym=10, xtitle='Noise distribution (mJy/Beam.s!E1/2!N)', ytitle='Number of KIDs',$
           title='KIDs noise distribution - 2mm', charthick=2,/nodata,xstyle=1,ystyle=1,$
           xr=[0,1]*max(bins_b),yr=[0, max(hist_b)*1.2]
     oplot, bins_b, hist_b, col=50, psym=10, thick=2
     device, /close
     set_plot, 'x'
     
  endif

  return
end
