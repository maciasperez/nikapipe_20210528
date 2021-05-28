;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_display_grid
;
; CATEGORY:
;
; CALLING SEQUENCE:
; nk_display_grid, grid, $
;                  png=png, ps=ps, $
;                  aperture_photometry=aperture_photometry, $
;                  educated=educated, title=title, coltable=coltable, $
;                  imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
;                  imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
;                  imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
;                  imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
;                  image_only = image_only, charsize=charsize
;
; PURPOSE: 
;        display maps present in the "maps" structure
;        hacked from nk_average_scans
; 
; INPUT: 
;        - param, info, maps
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 24th, 2014: NP
;-

pro nk_display_grid, grid, $
                     png=png, ps=ps, $
                     aperture_photometry=aperture_photometry, $
                     educated=educated, title=title, coltable=coltable, $
                     imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                     imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                     imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                     imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                     flux=flux, charsize=charsize, map=map, conv=conv

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_display_grid, grid, $"
   print, "                 png=png, ps=ps, $"
   print, "                 aperture_photometry=aperture_photometry, $"
   print, "                 educated=educated, title=title, coltable=coltable, $"
   print, "                 imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $"
   print, "                 imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $"
   print, "                 imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $"
   print, "                 imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $"
   print, "                 image_only = image_only, charsize=charsize, map=map, conv=conv"
   return
endif

title_ext=''
if keyword_set(title) then title_ext=title

if not keyword_set(info) then nk_default_info, info

if not keyword_set(flux) then begin
   if not keyword_set(title) then title=''
   stokes = ["I", "Q", "U"]
   grid_tags = tag_names( grid)


   suffix   = ['1', '2', '3', "_1MM"];, "_2MM"]
   suffix_1 = ['1', '2', '3', '1MM'];, '2MM']
   hits_field   = ["NHITS_1", "NHITS_2", "NHITS_3", "NHITS_1MM"];, "NHITS_2MM"]
   iarray_list  = [1, 2, 3, 1];, 2]
   nfields      = n_elements(suffix)
   
   ;; re-order plots: do it here and not in an additional field to "param"
   ;; otherwise param cannot be passed easily to the output fits header
   array_plot_position = [0, 2, 1, 3, 4]

   if not keyword_set(plot_dir) then plot_dir = "."
   if not keyword_set(ps) then begin
      ;; Quick scan on grid tags to initialize display parameters
      grid_tags = tag_names(grid)
      
      ;; Find if stokes maps are present and not empty to
      ;; determine if it's a polarized scan or not.
      nstokes = 1               ; I at least
      for iarray=1, 3 do begin
         wtag = where( strupcase(grid_tags) eq "MAP_VAR_Q"+strtrim(iarray,2), nwtag)
         if nwtag ne 0 then begin
            if total( grid.(wtag)) ne 0.d0 then nstokes=3
         endif
      endfor
      ;; my_multiplot, narrays, nstokes, pp, pp1, /rev
      my_multiplot, 1, 1, ntot=nfields*nstokes, pp, pp1, /rev
      wind, 1, 1, /free, /large, iconic = iconic
      if keyword_set(map) then my_multiplot, /reset
      
   endif
   if keyword_set(png) eq 1 then outplot, file=plot_dir+"/maps_"+info_out.scan, /png

   noplot=0
   ;; Main loop
      ;; Loop on I, Q and U
   for istokes=0, 2 do begin
      delvarx, imrange
      
      for ifield=0, nfields-1 do begin
         iarray = iarray_list[ifield]
   
;;      ;; Do not plot the combined 1mm map nor the 2mm map to preserve
;;      ;; current automatic displays
;;      if ifield ge 3 then noplot=1
   
         if iarray eq 1 or iarray eq 3 then begin
            if istokes eq 0 and keyword_set(imrange_i1) then imrange = imrange_i1
            if istokes eq 1 and keyword_set(imrange_q1) then imrange = imrange_q1
            if istokes eq 2 and keyword_set(imrange_u1) then imrange = imrange_u1
         endif else begin
            if istokes eq 0 and keyword_set(imrange_i2) then imrange = imrange_i2
            if istokes eq 1 and keyword_set(imrange_q2) then imrange = imrange_q2
            if istokes eq 2 and keyword_set(imrange_u2) then imrange = imrange_u2
         endelse            

         ;; Check if the map exists (in particular, are we in polarized mode ?)
         wmap = where( strupcase(grid_tags) eq "MAP_"+stokes[istokes]+suffix[ifield], nwmap)
         if keyword_set(map) then begin
            if "MAP_"+stokes[istokes]+suffix[ifield] eq strupcase(map) then begin
               noplot=0
               my_multiplot, /reset
               delvarx, pp, pp1
            endif else begin
               noplot=1
            endelse
         endif
         
         if nwmap eq 0 then begin
            ;; message, /info, "No MAP_"+stokes[istokes]+suffix[ifield]+" in grid"
         endif else begin
            ;; check if the map is not empty => look at its associated
            ;; variance
            wvar = where( strupcase(grid_tags) eq "MAP_VAR_"+stokes[istokes]+suffix[ifield], nwvar)
            if nwvar eq 0 then begin
               message, /info, "no MAP_VAR_"+stokes[istokes]+suffix[ifield]+" tag in grid ?"
               stop
            endif
            if total( grid.(wvar), /nan) ne 0 then begin
               whits = where( strupcase(grid_tags) eq hits_field[ifield], nwhits)
               ;;if defined(pp) then position = pp[array_plot_position[ifield],istokes,*]
               if defined(pp) then position = pp1[istokes*nfields+ifield,*]
               if keyword_set(ps) then begin
                  noplot=0
                  if keyword_set(nickname) then begin
                     ps_file = plot_dir+"/maps_"+strtrim(nickname, 2)+"_"+ $
                               stokes[istokes]+suffix[ifield]+'.ps'  
                  endif else begin
                     ps_file = plot_dir+"/map_"+stokes[istokes]+suffix[ifield]+".ps"
                  endelse
               endif

               charsize = 0.8
               if noplot eq 0 then begin
                  if keyword_set(conv) then begin
                     fwhm = !nika.fwhm_nom[(iarray-1) mod 2]
                     input_sigma_beam = fwhm*!fwhm2sigma
                     nx_beam_w8       = 2*long(4*input_sigma_beam/grid.map_reso/2)+1
                     ny_beam_w8       = 2*long(4*input_sigma_beam/grid.map_reso/2)+1
                     xx               = dblarr(nx_beam_w8, ny_beam_w8)
                     yy               = dblarr(nx_beam_w8, ny_beam_w8)
                     for ii=0, nx_beam_w8-1 do xx[ii,*] = (ii-nx_beam_w8/2)*grid.map_reso
                     for ii=0, ny_beam_w8-1 do yy[*,ii] = (ii-ny_beam_w8/2)*grid.map_reso
                     beam_w8 = exp(-(xx^2+yy^2)/(2.*input_sigma_beam^2))
                     image = convol( grid.(wmap), beam_w8)/total(beam_w8^2)
                     legend_text = ['Conv. FWHM '+string(fwhm,format='(F4.1)')]

                  endif else begin
                     image = grid.(wmap)
                  endelse
                  imview, image, xmap=grid.xmap, ymap=grid.ymap, position=position, legend_text=legend_text, $
                          postscript=ps_file, imrange=imrange, chars=charsize, charbar=charbar, $
                          title=title+" "+stokes[istokes]+suffix[ifield], coltable=coltable, /noerase
               endif
            endif               ;else message, /info, 'Empty map'             ; map is not empty
         endelse                ; map exists
      endfor                    ; stokes parameters
   endfor                       ; loop on fields

endif else begin
   nk_grid2info, grid, info_out, info_in=info_in, noplot=noplot, $
                 educated=educated, title=title, coltable=coltable, $
                 imrange_i1 = imrange_i1, imrange_q1 = imrange_q1, imrange_u1 = imrange_u1, $
                 imrange_i2 = imrange_i2, imrange_q2 = imrange_q2, imrange_u2 = imrange_u2,  $
                 imrange_ipol1=imrange_ipol1, imrange_ipol2=imrange_ipol2, $
                 imrange_pol_deg1=imrange_pol_deg1, imrange_pol_deg2=imrange_pol_deg2, $
                 charsize=charsize, png=png, ps=ps
endelse
end
