
;; This is an example script to illustrate the use of the most common parameters
;; Take DR21OH as an example
;;----------------------------------------------------------------------------

source = 'DR21OH'

;; Restore the data base file
db_file = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_Run13_v0.save"
restore, db_file

;; Find the relevant data files
w = where( strupcase( strtrim(scan.object,2))  eq strupcase(source) and $
           strupcase( strtrim(scan.obstype,2)) ne 'ONTHEFLY' and $
           long(scan.day) ge 20150929, nw)
scan_list =  scan[w].day+'s'+strtrim(scan[w].scannum, 2)
nscans = n_elements(scan_list)
;print, "nscans (raw): ", nscans
;stop

;; keep = intarr(nscans) + 1
;; readcol, "dr21_oh_black_list.dat", black_list, format = 'A'
;; my_match, scan_list, black_list, suba, subb
;; 
;; if n_elements(suba) ne 0 then keep[suba] = 0
;; w = where(keep eq 1)
;; scan_list = scan_list[w]

;; 
;; 
;; 
;; 
;; 
;; 
;; 59], 2)]

scan_list = ['20151030s206', $
             '20151031s'+strtrim([259, 261], 2)]
nscans = n_elements(scan_list)
;; for i=0, nscans-1 do begin
;;    nk_find_raw_data_file, a, scan=scan_list[i]
;; endfor
;; stop
;; % NK_FIND_RAW_DATA_FILE: found data file /home/nika2/NIKA/Data/run13_X//X24_2015_10_30/X_2015_10_30_22h57m20_A0_0206_O_DR21OH
;; % NK_FIND_RAW_DATA_FILE: found imbfits   /home/observer/NIKA/AntennaImbfits/iram30m-antenna-20151030s206-imb.fits
;; 
;; % NK_FIND_RAW_DATA_FILE: found data file /home/nika2/NIKA/Data/run13_X//X24_2015_10_31/X_2015_10_31_22h49m22_A0_0259_O_DR21OH
;; % NK_FIND_RAW_DATA_FILE: found imbfits   /home/observer/NIKA/AntennaImbfits/iram30m-antenna-20151031s259-imb.fits
;; 
;; % NK_FIND_RAW_DATA_FILE: found data file /home/nika2/NIKA/Data/run13_X//X24_2015_10_31/X_2015_10_31_22h59m29_A0_0261_O_DR21OH
;; % NK_FIND_RAW_DATA_FILE: found imbfits   /home/observer/NIKA/AntennaImbfits/iram30m-antenna-20151031s261-imb.fits
   

;; 1st iteration to guess the source and the mask for the second
;; iteration and flag out bad scans.
nk_default_param, param
param.project_dir = !nika.plot_dir+"/"+strupcase(source)
param.map_xsize = 800 ;arcsec
param.map_ysize = 800
param.decor_method = 'common_mode' ; 1 common mode per array
param.set_zero_level_per_subscan = 1
param.fine_pointing = 0
param.do_aperture_photometry = 0
param.flag_uncorr_kid = 0 ; 
param.flag_sat        = 1
param.flag_oor        = 1
param.flag_ovlap      = 1
param.interpol_common_mode = 1
param.do_plot = 1

;; message, /info, "plot_ps and automatic report... plot_png"
;; stop
param.plot_ps = 1
param.silent  = 0 ; 1

;; Reset preprocessed data
filing = 1
nk_reset_filing,  param,  scan_list

;; Process each scan
;; nk, scan_list[0], param=param, grid=grid
;; stop

;nk, scan_list, param=param, filing=filing
;stop

;; Combine scan maps
nk_average_scans, param, scan_list, grid, info = info
nk_fits2grid, param.project_dir+"/MAPS_out_v1.fits", grid
;; nk_display_grid, grid
my_multiplot, 2, 1, pp, pp1
wind, 1, 1, /free, /xlarge
imview, grid.map_i1, imrange=[-1,1], position=pp1[0,*]
imview, grid.map_i2, imrange=[-1,1]*0.5, position=pp1[1,*], /noerase
my_multiplot, /res
stop

;; nk_display_grid, grid, /flux
;; stop

;; Determine a mask to improve the decorrelation
sn_thres = 2
w = where( grid.map_var_i1 ne 0, nw)
map_sn = grid.map_i1*0.d0
mask   = grid.map_i1*0.d0 + 1.d0
map_sn[w] = grid.map_i1[w]/sqrt(grid.map_var_i1[w])
wmask = where( map_sn gt sn_thres, nwmask)
if nwmask ne 0 then mask[wmask] = 0
wind, 1, 1, /f
imview, mask

;; enlarge a bit
mask1 = filter_image( mask, fwhm = 8)
wind, 2, 2, /f
imview,  mask1, xmap = grid.xmap, ymap = grid.ymap

w = where( mask1 lt 0.99 and $
           abs( grid.xmap) le 200 and $
           abs( grid.ymap) le 300, nw)
mask = mask*0 + 1.d0
mask[w] = 0
imview,  mask

grid.mask_source = mask
;; grid_file = 'dr21oh_grid.save'
;; save, grid, file = grid_file

;; 2nd iteration
param.decor_method = 'common_mode_kids_out'
param.version = '2'
nk, scan_list, param=param, grid=grid
nk_average_scans,  param,  scan_list,  grid,  info =  info

phi = dindgen(100)/99.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
xc = min(grid.xmap) + (max(grid.xmap)-min(grid.xmap))*0.05
yc = min(grid.ymap) + (max(grid.ymap)-min(grid.ymap))*0.05
fwhm1 = 12.
fwhm2 = 18.

png = 0

wind, 1, 1, /free, /xlarge
my_multiplot, 2, 1, pp, pp1, /rev
colt = 5
imrange = [-0.05, 2]
outplot, file = 'press_release_DR21OH_1_2mm', png = png
imview, filter_image(grid.map_i1, fwhm = 2), xmap = grid.xmap, ymap = grid.ymap, $
        imrange = imrange, colt = colt, /nobar, $
        position = pp1[0, *], chars = 1e-10
legendastro, ['DR21OH', '1mm'], box = 0, textcol = 255
legendastro, ['NIKA2 First light, Oct. 2015'], textcol = 255, box = 0, /bottom, /right
polyfill, xc+fwhm1/2.*cosphi, yc+fwhm1/2.*sinphi, col = 255

imview, filter_image(grid.map_i2, fwhm = 2), xmap = grid.xmap, ymap = grid.ymap, $
        imrange = imrange, colt = colt, position = pp1[1, *], /noerase, chars = 1e-10, /nobar
legendastro, ['DR21OH', '2mm'], box = 0, textcol = 255
legendastro, ['NIKA2 First light, Oct. 2015'], textcol = 255, box = 0, /bottom, /right
polyfill, xc+fwhm2/2.*cosphi, yc+fwhm2/2.*sinphi, col = 255
outplot, /close



end

