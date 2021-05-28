pro fit_main_beam_fwhm, map, var, xmap, ymap, center_x, center_y, $
                        output_fit_par, output_covar, output_fit_par_error, $
                        internal_radius=internal_radius, external_radius=external_radius, $
                        flux_thresh=flux_thresh, chi2=chi2, $
                        optimise_radius=optimise_radius, max_flux=max_flux, $
                        min_frac_flux_cut=min_frac_flux_cut,  max_frac_flux_cut=max_frac_flux_cut, $
                        min_internal_radius=min_internal_radius, max_internal_radius=max_internal_radius, $
                        k_noise = k_noise, alpha_flux=alpha_flux

  ;; Fit only near the very center and far from it to
  ;; avoid side lobes
  
  d    = sqrt( (xmap-center_x)^2 + (ymap-center_y)^2)
  
  if keyword_set(external_radius) then rbg = external_radius else rbg = 100.

  if keyword_set(flux_thresh) then begin
     wdist    = where( (map gt flux_thresh and d lt rbg))
     rsource  = max(d[wdist])
     print, "cut radius = ", rsource
  endif else if keyword_set(internal_radius) then rsource=internal_radius else begin
     rsource = 10.
     if not(keyword_set(optimise_radius)) then print, "fixed arbitrary cut radius = ", rsource
  endelse

  if keyword_set(min_frac_flux_cut) then alp_min = min_frac_flux_cut else alp_min=0.02
  if keyword_set(max_frac_flux_cut) then alp_max = max_frac_flux_cut else alp_max=0.60

  internal_radius_binning = 0
  if keyword_set(min_internal_radius) then rin_min = min_internal_radius else rin_min=8.
  if keyword_set(max_internal_radius) then rin_max = max_internal_radius else rin_max=11.
  if keyword_set(min_internal_radius) or  keyword_set(min_internal_radius) then internal_radius_binning = 1
  
  if keyword_set(k_noise) then k_noise=k_noise else k_noise=0

  
  flux_thresh = 0
  internal_radius = 0
  ;; optimise the cut radius
  ;;------------------------------------------------------
  if keyword_set(optimise_radius) then begin

     internal_radius_binning = 1
     
     if keyword_set(max_flux) then flux=max_flux else flux = max(map(where(d le 40.)))

     ;; flux binning
     ;;---------------------------------------
     if internal_radius_binning lt 1 then begin

        print, " flux binning........."
        alpha_flux_cuts = indgen(51)/50.
        alpha_flux_cuts = indgen(27)/30.+0.05
        alpha_flux_cuts = indgen(35)/60.+0.02
        alpha_nbin = (alp_max-alp_min)/0.01 + 1
        alpha_flux_cuts = indgen(alpha_nbin)*0.01+alp_min
        ;;alpha_flux_cuts = [0.5, 0.35, 0.3]
        ntest = n_elements(alpha_flux_cuts)
        output_fit_par_test = dblarr(7, ntest)
        apeak_test = dblarr(ntest)
        fwhm_test  = dblarr(ntest)
        chi2_test  = dblarr(ntest)
        radius_test = dblarr(ntest)
        alpha_flux_test  = dblarr(ntest)
        
        for ia= 0, ntest-1 do begin
           alpha_flux_cut = alpha_flux_cuts[ia]
           wfit = where( (map gt alpha_flux_cut*flux and d le rbg) or (d ge rbg and var lt mean(var)), nwfit, compl=wout)
           wsource = where( (map gt alpha_flux_cut*flux and d le rbg), nsource )
           
           if nsource gt 0 then begin 
              map_var0 = var
              map_var0[wout] = 0.d0
              nk_fitmap, map, map_var0, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
                         educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
                         xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
              output_fit_par_test[*,ia] = output_fit_par[*]
              ww = where(map_var0 gt 0., ndata)
              chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
              print,"max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
              apeak_test[ia] = output_fit_par[1]
              fwhm_test[ia]  = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
              chi2_test[ia]  = chi2
              radius_test[ia] = max(d[wsource])
              alpha_flux_test[ia] = alpha_flux_cut
           endif
        endfor

     endif else begin
        ;; internal radius binning
        ;;------------------------------------

        print, "binning of the internal radius.................."
        
        alpha_nbin = (rin_max-rin_min)/0.5 + 1
        alpha_cuts = indgen(alpha_nbin)*0.5+rin_min
        ntest = n_elements(alpha_cuts)
        output_fit_par_test = dblarr(7, ntest)
        apeak_test = dblarr(ntest)
        fwhm_test  = dblarr(ntest)
        chi2_test  = dblarr(ntest)
        alpha_flux_test  = dblarr(ntest)
        radius_test = dblarr(ntest)
        for ia= 0, ntest-1 do begin
           alpha_cut = alpha_cuts[ia]
           wfit = where( (d lt alpha_cut) or (d ge rbg and var lt mean(var)), nwfit, compl=wout)
           wsource = where( (d lt alpha_cut), nsource )
           
           if nsource gt 0 then begin 
              map_var0 = var
              map_var0[wout] = 0.d0
              nk_fitmap, map, map_var0, xmap, ymap, output_fit_par, covar, output_fit_par_error, $
                         educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
                         xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
              output_fit_par_test[*,ia] = output_fit_par[*]
              ww = where(map_var0 gt 0., ndata)
              chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
              print,"in radius = ", alpha_cut," max = ", output_fit_par[1], ", fwhm = ", sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ", chi2
              apeak_test[ia] = output_fit_par[1]
              fwhm_test[ia]  = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
              chi2_test[ia]  = chi2
              alpha_flux_test[ia]  = total(map[wsource])/total(map[where( (d le rbg))] )
              radius_test[ia] = alpha_cut
           endif
        endfor
        
     endelse
     
        wdefined = where(fwhm_test gt 1.0 and finite(fwhm_test) gt 0)
        bestchi2 = min(abs(chi2_test(wdefined) - 1.d0))
        wbest = where(abs(chi2_test - 1.d0) eq bestchi2 and fwhm_test gt 1.0 and finite(fwhm_test) gt 0, nbest)
        rsource = radius_test[wbest[0]] 
        alpha_flux_thresh = alpha_flux_test[wbest[0]]
        print, "internal_radius = ", rsource, "flux ratio thresh = ", alpha_flux_thresh, ", FWHM = ", fwhm_test[wbest[0]]
     endif
  
  
  
  wfit = where( d lt rsource or (d ge rbg and var lt mean(var)), nwfit, compl=wout)
  internal_radius = rsource

  wsource     = where( (d lt rsource), nsource )
  alpha_flux  = total(map[wsource])/total(map[where( (d le rbg))] )
  
  map_var0 = var
  map_var0[wout] = 0.d0
  nk_fitmap, map, map_var0, xmap, ymap, output_fit_par, output_covar, output_fit_par_error, $
             educated=educated, k_noise=k_noise, info=info_out, status=status, dmax=dmax, $
             xguess=xguess, yguess=yguess, guess_fit_par=guess_fit_par, sigma_guess=input_sigma_beam, map_fit=best_model
  ww = where(map_var0 gt 0., ndata)
  chi2 = total((map[ww]-best_model[ww])^2/map_var0[ww])/(ndata-7.)
  
  ;;print,"max = ", output_fit_par[1], ", fwhm = ", sqrt(
  ;;output_fit_par[2]*output_fit_par[3])/!fwhm2sigma, ", chi2 = ",
  ;;chi2
  
  ;;wind, 1, 1, xsize = 800, ysize = 650, /free
  ;;my_multiplot, 2, 2,  pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08    
  ;;diff = map-best_model
  ;;imview, diff[250:350, 250:350], position= pp1[0, *]
  ;;dd=diff
  ;;dd[wout]=0.0
  ;;imview, dd[250:350, 250:350], position= pp1[1, *], /noerase  
  ;;mm=map                      
  ;;mm[wout]=0.0                
  ;;imview, mm[250:350, 250:350], position= pp1[2, *], /noerase  
  ;;ff=best_model               
  ;;ff[wout]=0.0                
  ;;imview, ff[250:350, 250:350], position= pp1[3, *], /noerase  
  ;;stop
  
end
