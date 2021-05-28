;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_fits2grid
;
; CATEGORY: 
;        products
;
; CALLING SEQUENCE:
;        nk_fits2grid, fitsfile, grid
; 
; PURPOSE: 
;        Reads in a NIKA map from a fitsfile and creates the corresponding grid structure
; 
; INPUT: 
;        - param: the reduction parameter structure
;        - info: the information parameter structure
;        - maps: the map structure (optional as input)
; 
; OUTPUT: 
;        - The maps are saved as fits
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Dec. 29th, 2015: NP
;        - March 10th, 2016: NP, adapated to nk_map2fits_3.pro called by nk_average_scans
;
pro nk_fits2grid, fitsfile, grid, header, info_out, scan_list=scan_list
;-
  
if n_params() lt 1 then begin
   dl_unix, 'nk_fits2grid'
   return
endif

;; Get info_out
if not defined( fitsfile) then begin
   message, /info, 'fits file name not defined'
   return
endif
if file_test( fitsfile) eq 0 then begin
   message, /info, 'That file does not exist: '+ fitsfile
   return
endif

junk = mrdfits( fitsfile, 0, info_out, /silent)

;; Read other fields
map = mrdfits( fitsfile, 1, header, /silent)
reso = abs(sxpar( header, "cdelt1"))*3600.d0
nx = n_elements( map[*,0])
ny = n_elements( map[0,*])
nk_default_param, param
param.map_xsize = nx*reso
param.map_ysize = ny*reso
param.map_reso  = reso

nk_default_info, info
info.polar = sxpar( info_out, "POLAR")

;; nk_init_grid, param, info, grid, header=header
extast, header, astr
nk_init_grid_2, param, info, grid, astr=astr

;; Check if it's a polarized map (if not used inside a single
;; scan, info might have been wronly initialized)
iext   = 1
status = 0
WHILE status EQ 0 AND iext LT 100 DO BEGIN
   m = mrdfits( fitsfile, iext, h, status = status, /silent)
   extname = sxpar( h, 'EXTNAME')
   if strtrim(extname,2) eq 'Brightness_Q_1mm' then info.polar = 1
   if strtrim(extname,2) eq 'Brightness_Q_2mm' then info.polar = 1
   iext++
endwhile

if info.polar ge 1 then nk_add_qu_to_grid, param, grid

;; Read the input file
iext   = 1
status = 0
WHILE status EQ 0 AND iext LT 100 DO BEGIN
   m = mrdfits( fitsfile, iext, h, status = status, /silent)
   extname = sxpar( h, 'EXTNAME')
;   print, "extname: "+extname
   if strtrim(extname,2) eq 'Brightness_1mm'         then grid.map_i_1mm       = m
   if strtrim(extname,2) eq 'Brightness_2mm'         then grid.map_i2          = m
   if strtrim(extname,2) eq 'Nhits_1mm'              then grid.nhits_1mm       = m
   if strtrim(extname,2) eq 'Nhits_2mm'              then grid.nhits_2         = m
   if strtrim(extname,2) eq 'Brightness_Q_1mm'       then grid.map_q_1mm       = m
   if strtrim(extname,2) eq 'Brightness_U_1mm'       then grid.map_u_1mm       = m
   if strtrim(extname,2) eq 'Brightness_Q_2mm'       then grid.map_q2          = m
   if strtrim(extname,2) eq 'Brightness_U_2mm'       then grid.map_u2          = m
   if strtrim(extname,2) eq 'Stddev_1mm'             then grid.map_var_i_1mm   = m^2
   if strtrim(extname,2) eq 'Stddev_2mm'             then grid.map_var_i2      = m^2
   if strtrim(extname,2) eq 'Stddev_Q_1mm'           then grid.map_var_q_1mm   = m^2
   if strtrim(extname,2) eq 'Stddev_U_1mm'           then grid.map_var_u_1mm   = m^2
   if strtrim(extname,2) eq 'Stddev_Q_2mm'           then grid.map_var_q2      = m^2
   if strtrim(extname,2) eq 'Stddev_U_2mm'           then grid.map_var_u2      = m^2
   if strtrim(extname,2) eq 'Brightness_1'           then grid.map_i1          = m
   if strtrim(extname,2) eq 'Brightness_2'           then grid.map_i2          = m
   if strtrim(extname,2) eq 'Brightness_3'           then grid.map_i3          = m
   if strtrim(extname,2) eq 'Nhits_1'                then grid.nhits_1         = m
   if strtrim(extname,2) eq 'Nhits_2'                then grid.nhits_2         = m
   if strtrim(extname,2) eq 'Nhits_3'                then grid.nhits_3         = m
   if strtrim(extname,2) eq 'Brightness_Q1'          then grid.map_q1          = m
   if strtrim(extname,2) eq 'Brightness_U1'          then grid.map_u1          = m
   if strtrim(extname,2) eq 'Brightness_Q2'          then grid.map_q2          = m
   if strtrim(extname,2) eq 'Brightness_U2'          then grid.map_u2          = m
   if strtrim(extname,2) eq 'Brightness_Q3'          then grid.map_q3          = m
   if strtrim(extname,2) eq 'Brightness_U3'          then grid.map_u3          = m
   if strtrim(extname,2) eq 'Stddev_1'               then grid.map_var_i1      = m^2
   if strtrim(extname,2) eq 'Stddev_2'               then grid.map_var_i2      = m^2
   if strtrim(extname,2) eq 'Stddev_3'               then grid.map_var_i3      = m^2
   if strtrim(extname,2) eq 'Stddev_Q1'              then grid.map_var_q1      = m^2
   if strtrim(extname,2) eq 'Stddev_U1'              then grid.map_var_u1      = m^2
   if strtrim(extname,2) eq 'Stddev_Q2'              then grid.map_var_q2      = m^2
   if strtrim(extname,2) eq 'Stddev_U2'              then grid.map_var_u2      = m^2
   if strtrim(extname,2) eq 'Stddev_Q3'              then grid.map_var_q3      = m^2
   if strtrim(extname,2) eq 'Stddev_U3'              then grid.map_var_u3      = m^2
   if strtrim(extname,2) eq 'Decorrelation_mask_1mm' then grid.mask_source_1mm = m
   if strtrim(extname,2) eq 'Decorrelation_mask_2mm' then grid.mask_source_2mm = m
   ; FXD Feb 2021, added these 2 lines:
   if strtrim(extname,2) eq 'Zero_level_mask_1mm'    then grid.zero_level_mask_1mm = m
   if strtrim(extname,2) eq 'Zero_level_mask_2mm'    then grid.zero_level_mask_2mm = m
   if strtrim(extname,2) eq 'scan_list'              then begin
      scan_list            = m
;      print, scan_list
   endif
   iext++
endwhile


end
