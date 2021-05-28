;+
;                               HEADER TO WRITTEN
; SOFTWARE: imcm
;
; NAME:
;   imcm_find_source
;
; CATEGORY: general
;
; CALLING SEQUENCE:
; imcmcall, source, $
                     ;; root_dir, method_num, iterin, $
                     ;; out_dir, help = k_help, silent= silent, $
                     ;; cat_snr_min = cat_snr_min, $
                     ;; input_cat = input_cat, $
                     ;; png = k_png, pdf = k_pdf, $
                     ;; image_max = image_max
; PURPOSE: 
;   wrapper for imcm plotting and catalog making
; 
; INPUT: 
;       - source  ; String Name of the source
;       - method_num  ; String ; which method e.g. '15'
;       
;    
; OUTPUT: 
; 
; KEYWORDS:
;       - /silent  ; i.e. less verbose
;       - cat_snr_min= ; float. Which minimum SNR do we keep for the
;         point-source catalog (default 3) (if no input catalog given)
;       - input_cat= ; string, a catalog of input positions instead of
;         the pgrm finding the positions on its own
;       - /png  ; makes png files (overriden by /pdf)
;       - /pdf  ; makes pdf files as plot outputs
;       - image_max = [mm1max,mm2max] ; 2 floats to give the range of
;         output images (default is [5, 2] mJy/beam)
; SIDE EFFECT: execution time is less than a minute, output QLA plots
; are filtered maps to enhance point-source
; features. source_detect.pdf shows the map smoothed by a Gaussian
; with the beam fwhm along with the detected sources.
;       
; EXAMPLE:
;; source = 'PSZ2G144'
;; root_dir = '/data2e/perotto/SZ_analysis/LPSZ_25339/'
;; method_num = '15'
;; iter = 0
;; out_dir = !nika.save_dir+'/Plots/Temp/'
;; cat_snr_min = 5.
;; k_pdf = 1
;; k_png = 0
;; image_max = [0.01, 0.003]  ; 1 & 2mm
; imcmcall, source, $
;                 root_dir, method_num, iter, $
;                  out_dir, cat_snr_min = cat_snr_min, $
;                  png = k_png, pdf = k_pdf, $
;                  image_max = image_max
; An output catalog is given in out_dir:
; PSZ2G144_15_iter0_radec_catfinal.txt
; Here are the first 3 lines
   ;; #,   ra(deg),  dec(deg),         ra,         dec,     fl1,    efl1,   snr1,      fl2,     efl2,   snr2
   ;; 0, 101.76600,  70.23910, 06:47:03.8, +70:14:20.8,    7.02,    1.23,    5.7,    0.486,    0.212,    2.3
   ;; 1, 101.81889,  70.24439, 06:47:16.5, +70:14:39.8,    5.82,    1.06,    5.5,    0.106,    0.179,    0.6

; With an external catalog
; for example
; catinput = out_dir+ 'radec_catinput_try.txt'
; with this format (the id # is not important)
;;    #,   ra(deg),  dec(deg)
;; 1000, 101.76600,  70.23910
;; 1001, 101.81889,  70.24439
;; 2000, 101.83128,  70.26189
;; imcm_find_source, source, $
;;                   root_dir, method_num, iter, $
;;                   out_dir, cat_snr_min = cat_snr_min, $
;;                   png = k_png, pdf = k_pdf, $
;;                   image_max = image_max, input_cat = catinput
;   
; MODIFICATION HISTORY: 
;        - ; FXD Jan 2021 : introduced to help spread imcm usage.
;================================================================================================
pro imcm_find_source, source, $
                     root_dir, method_num, iterin, $
                     out_dir, help = k_help, silent= silent, $
                     cat_snr_min = cat_snr_min, $
                     input_cat = input_cat, output_cat = output_cat, $
                     png = k_png, pdf = k_pdf, $
                     image_max = image_max
  


if n_params() lt 1 then begin
   dl_unix, 'imcm_find_source'
   return
endif

;;;;root_dir = !nika.save_dir+'/'+ext
source_dir = root_dir +'/'+strupcase(source)
project_dir = source_dir+'/'+strtrim( method_num, 2)
;;;imcmout_dir = source_dir+'/imcmout' ; output ascii files (catalogs)
imcmout_dir = out_dir
plot_dir = out_dir
spawn, 'mkdir -p '+imcmout_dir
; NB: !nika.project_dir is source_dir+'/'+method_num



; Start the analysis
; Plot, analyse, make catalog

if keyword_set( k_png) then begin
   png = 1                      ; default 1,  1 for all png
   ps = 0
   pdf = 0
endif else if keyword_set( k_pdf) then begin
; OR
   png = 0
   ps = 1
   pdf = 1
endif else begin
   ; or nothing
   png = 0
   ps = 0
   pdf = 0
endelse


itest = iterin
version = ''


if keyword_set( image_max) then fmax = image_max else delvarx, fmax
;fmax = [0.5, 0.5] ; range away from default eg for MWC

if keyword_set( cat_snr_min) then snr_thresh = cat_snr_min else snr_thresh = 3

iplot_min = iterin
iplot_max = iterin

if keyword_set( input_cat) then begin
   k_catmerge = input_cat
   if file_test( k_catmerge) ne 1 then begin 
      message, /info, ' must stop. That catalog does not exist '+k_catmerge
      return
   endif
   
endif else k_catmerge = ''

nk_default_param, param
param.map_truncate_percent = 40.
diff_stat = replicate({mean:0., median:0., min:0., max:0., stddev:0.}, $
                      4, iterin+1)
diff_stat_jk = replicate({mean:0., median:0., min:0., max:0., stddev:0.}, $
                         4, iterin+1)
@imcm_find_source_analysis1.scr

; Make the catmerge catalog or use an input catalog of positions
@imcm_find_source_analysis2.scr

if keyword_set(k_pdf) then wd, /all
return
end
