
;+
;
; SOFTWARE: NIKA pipeline / Real time analysis
;
; NAME: 
; nk_get_2ndbeam_kidpar
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_get_2ndbeam_kidpar, scan, kidpar, skydip_scan=skydip_scan
; 
; PURPOSE: 
;        Recomputes offsets and calibration of the (EXTRAORDINARY) SECOND BEAM of kids that have
;        already been selected when we use the prism.
;        Pointing is referenced to the ordinary beam of the reference kid.
; 
; INPUT: 
;        - scan : the scan identifier
;        - kidpar_in : a structure containing with kid types up to date (valid,
;          unvalid...
;
; OUTPUT: 
;         - kidpar_out : the kid structure with newly computed offsets and calibration
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct 5th, 2014: NP
;-
;================================================================================================


pro nk_get_2ndbeam_kidpar, scan, xpeak_ref, ypeak_ref, source, kidpar_in_file, kidpar_out_file, $
                           undersamp=undersamp


;; Subtract an esimate of the planet as seen by the ordinary beam and then fit
;; the remaining extraorindary beam in the same way to derive offsets.
kidpar_out_file = "kidpar_out_2beams_"+scan+".fits"

nk_default_param,   param
nk_init_grid, param, grid
nk_default_info,    info

param.source = source
param.silent = 0

if keyword_set(undersamp) then param.undersamp = undersamp

param.plot_dir = !nika.plot_dir+"/"+scan
spawn, "mkdir -p "+param.plot_dir

nk_update_scan_param, scan, param, info

;; Force kidpar to the current one and update param with scan infos
param.file_kidpar = kidpar_in_file

param.math = "RF" ; to be faster

;; Get the data and KID parameters
nk_getdata, param, info, data, kidpar, sn_min=sn_min, sn_max=sn_max

;; Add the necessary fields when the prism is on
kidpar_new = kidpar[0]
kidpar_new = create_struct( kidpar_new, $
                            "nas_x1", 0.d0, $
                            "nas_y1", 0.d0, $
                            "a_peak1", 0.d0, $
                            "sigma_x1", 0.d0, $
                            "sigma_y1", 0.d0, $
                            "fwhm_x1", 0.d0, $
                            "fwhm_y1", 0.d0, $
                            "fwhm1", 0.d0, $
                            "theta1", 0.d0)

kidpar_new = replicate( kidpar_new, n_elements(kidpar))
tags     = tag_names(kidpar)
tags_new = tag_names(kidpar_new)
my_match, tags_new, tags, suba, subb
for i=0, n_elements(suba)-1 do kidpar_new.(suba[i]) = kidpar.(subb[i])
kidpar = kidpar_new

;; Compute individual kid pointing once for all for the ordinary beam
nk_get_kid_pointing, param, info, data, kidpar

;; Deglitch
nk_deglitch, param, info, data, kidpar

nkids = n_elements(kidpar)

;;message, /info, "Subtract an estimate of the planet seen by the ordinary beam"
data1 = data
data1.toi *= 0.d0
info.polar = 0 ; to suppress the extraordinary beam
nks_default_simpar, simpar, n_point_sources=1, /polar
simpar.reset = 1
case strupcase(param.source) of
   "URANUS": begin
      simpar.ps_flux_1mm = !nika.flux_uranus[0]
      simpar.ps_flux_2mm = !nika.flux_uranus[1]
   end
   "NEPTUNE":begin
      simpar.ps_flux_1mm = !nika.flux_neptune[0]
      simpar.ps_flux_2mm = !nika.flux_neptune[1]
   end
   "MARS":begin
      simpar.ps_flux_1mm = !nika.flux_mars[0]
      simpar.ps_flux_2mm = !nika.flux_mars[1]
   end
end
nks_add_source, param, simpar, info, data1, kidpar

;; Devide by two because the prism splits the power into two halves compared to
;; the full power calibration
data1.toi /= 2.d0

;; Subtract the ordinary planet
data.toi -= data1.toi

;; Save for further use
data_copy = data

;; Apply the preliminary calibration derived when the kids where selected in
;; Katana.
;; It differs from the future absolute calibrtion but it's a good
;; proxy to relative calibration that can be used for the map projections.
nk_apply_calib, param, info, data, kidpar

;; Makes no assumption about the source location, make a first map to locate
;; it, then iterate to have the best calibration.
grid.mask_source = 1.d0   ; make sure
param.decor_method = "common_mode"
nk_scan_reduce, param, info, data, kidpar, grid
nk_projection_3, param, info, data, kidpar, grid

;; Quicklook and fit the planet position
map_var  = double(finite(grid.map_w8_1mm))*0.d0
w        = where( grid.map_w8_1mm gt 0, nw)
if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_1mm[w]

stop
educated=1
wind, 1, 1, /free, xs=1500, ys=900
my_multiplot, 2, 1, pp, pp1, gap_x=0.1, xmargin=0.1
nk_map_photometry, grid.map_i_1mm, map_var, grid.nhits_1mm, $
                   grid.xmap, grid.ymap, param.input_fwhm_1mm, $
                   flux_1mm, sigma_flux_1mm, $
                   sigma_bg_1mm, output_fit_par_1mm, output_fit_par_error_1mm, $
                   bg_rms_1mm, flux_center_1mm, sigma_flux_center_1mm, sigma_bg_center_1mm, $
                   educated=educated, ps_file=ps_file, position=pp1[0,*], $
                   k_noise=k_noise, noplot=noplot, param=param, $
                   title=param.scan+" 1mm (1st iteration) [Hz]"

map_var  = double(finite(grid.map_w8_2mm))*0.d0
w        = where( grid.map_w8_2mm gt 0, nw)
if nw ne 0 then map_var[w] = 1.d0/grid.map_w8_2mm[w]
nk_map_photometry, grid.map_i_2mm, map_var, grid.nhits_2mm, $
                   grid.xmap, grid.ymap, param.input_fwhm_2mm, $
                   flux_2mm, sigma_flux_2mm, $
                   sigma_bg_2mm, output_fit_par_2mm, output_fit_par_error_2mm, $
                   bg_rms_2mm, flux_center_2mm, sigma_flux_center_2mm, sigma_bg_center_2mm, $
                   educated=educated, ps_file=ps_file, position=pp1[1,*], $
                   k_noise=k_noise, noplot=noplot, param=param, $
                   title=param.scan+" 2mm (1st iteration) [Hz]"

xsource = (output_fit_par_1mm[4]+output_fit_par_2mm[4])/2.
ysource = (output_fit_par_1mm[5]+output_fit_par_2mm[5])/2.
d = sqrt( (grid.xmap-xsource)^2 + (grid.ymap-ysource)^2)

;; Restore original (uncalibrated, still in Hz) data for the next decorrelation
data = data_copy

;; Derive mask
w = where( d lt 1.5*!nika.fwhm_nom[1], nw)
if nw eq 0 then begin
   message, /info, "Wrong planet position"
   stop
endif else begin
   grid.mask_source[w] = 0.d0
endelse

;; Final decorrelation
param.decor_method = "common_mode_band_mask"
nk_scan_reduce, param, info, data, kidpar, grid, subtract_maps=subtract_maps

;; Account for elevation dependent gain of the telescope
nk_tel_gain_cor, param, info, data, kidpar

;; Valid samples
w = where( data.flag[0] eq 0 and data.scan_valid[0] eq 0, nw)
if nw eq 0 then begin
   message, /info, "no valid sample."
   stop
endif
nsn   = n_elements(data)
w8    = intarr(nsn)
w8[w] = 1.d0

;; Make individual maps in Az, El
xra = minmax(data[w].ofs_az)
yra = minmax(data[w].ofs_el)
param.map_xsize = (xra[1]-xra[0])*1.1
param.map_ysize = (yra[1]-yra[0])*1.1
nk_init_grid, param, grid_azel
get_bolo_maps_3, data.toi, data.ofs_az, data.ofs_el, data.w8, kidpar, grid_azel, map_list_azel, map_var_list_azel

;; Map in Nasmyth
azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_nasx, ofs_nasy
xra1  = minmax(ofs_nasx[w])
yra1  = minmax(ofs_nasy[w])
param.map_xsize = (xra1[1]-xra1[0])*1.1
param.map_ysize = (yra1[1]-yra1[0])*1.1
nk_init_grid, param, grid_nasmyth
get_bolo_maps_3, data.toi, ofs_nasx, ofs_nasy, data.w8, kidpar, grid_nasmyth, map_list_nasmyth, map_var_list_nasmyth

;; Derive beam parameters
beam_guess, map_list_azel, grid_azel.xmap, grid_azel.ymap, kidpar, $
            x_peaks_azel, y_peaks_azel, a_peaks_azel, sigma_x_azel, sigma_y_azel, $
            beam_list_azel, theta_azel, /noplot

beam_guess, map_list_nasmyth, grid_nasmyth.xmap, grid_nasmyth.ymap, kidpar, $
            x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, $
            beam_list, theta, /noplot

;; Re-center beams on the reference kid.
w1 = where( kidpar.type eq 1)
x_peaks[w1] -= xpeak_ref
y_peaks[w1] -= ypeak_ref

;; Stores results
kidpar[w1].nas_x1   = x_peaks[w1]
kidpar[w1].nas_y1   = y_peaks[w1]
kidpar[w1].a_peak1  = a_peaks[w1]
kidpar[w1].sigma_x1 = sigma_x[w1]
kidpar[w1].sigma_y1 = sigma_y[w1]
kidpar[w1].fwhm_x1  = sigma_x[w1]/!fwhm2sigma
kidpar[w1].fwhm_y1  = sigma_y[w1]/!fwhm2sigma
kidpar[w1].fwhm1    = sqrt( sigma_x[w1]*sigma_y[w1])/!fwhm2sigma
kidpar[w1].theta1   = theta[w1]

;; Write to disk
nika_write_kidpar, kidpar, kidpar_out_file

;; Plot
lambda_min = min(kidpar.array)
lambda_max = max(kidpar.array)
wind, 1, 1, /free, xs=1200, ys=900
outplot, file=param.plot_dir+"/FocalPlane", png=png, ps=ps
if lambda_min ne lambda_max then !p.multi=[0,2,1]

phi = dindgen(200)/199.*2.d0*!dpi
for lambda=lambda_min, lambda_max do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1

   xra = minmax( [kidpar[w1].nas_x, kidpar[w1].nas_x1])
   xra = xra + [-0.2,0.2]*(xra[1]-xra[0])
   yra = minmax( [kidpar[w1].nas_y, kidpar[w1].nas_y1])
   yra = yra + [-0.2,0.2]*(yra[1]-yra[0])
   
   plot, kidpar[w1].nas_x, kidpar[w1].nas_y, psym=1, /iso, $
         xra=xra, yra=yra, /xs, /ys, title=scan, xtitle='Arcsec', ytitle='Arcsec'
   for i=0, nw1-1 do begin
      ikid = w1[i]
      xx1  = kidpar[ikid].sigma_x*cos(phi)*0.5 ; 0.5 to have diameter=sigma, not radius
      yy1  = kidpar[ikid].sigma_y*sin(phi)*0.5 ; 0.5 to have diameter=sigma, not radius
      x1   =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
      y1   =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
      oplot, kidpar[ikid].nas_x+x1, kidpar[ikid].nas_y+y1

      oplot, kidpar[ikid].nas_x1+x1, kidpar[ikid].nas_y1+y1, col=70
   endfor

   legendastro, [strtrim(lambda,2)+" mm", $
                 '1!7r!3 radius contours'], box=0, /right
endfor
outplot, /close

end
