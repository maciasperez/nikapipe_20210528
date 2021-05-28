;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_6
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_decor_6, param, info, data, kidpar, grid,
;         out_temp_data, out_coeffs=out_coeffs, snr_toi=snr_toi, Q=Q, U=U
; 
; PURPOSE: 
;        Decorrelates kids, filters...
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 09th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Oct. 15th, 2015: NP, adapted nk_decor_4 to the 3 arrays of NIKA2.
;        - April 8th, 2016: NP, adapted to nk_decor_sub_6


pro nk_decor_6, param, info, data, kidpar, grid, out_temp_data, out_coeffs=out_coeffs, $
                snr_toi=snr_toi, Q=Q, U=U, hfnoise_w8=hfnoise_w8
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_decor_6'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

istokes = 1                     ; default, work on non polarized observations
if keyword_set(q) then istokes=2
if keyword_set(u) then istokes=3

nsn   = n_elements(data)
nkids = n_elements(kidpar)
if param.subscan_edge_w8 gt 0 then hfnoise_w8 = dblarr(nkids,nsn)

;; Keep compatibility with old acquistions
nk_patch_kidpar, param, info, data, kidpar
;message, /info, "fix me:"
;wj = where( kidpar.array eq 1) & print, minmax(kidpar[wj].type)

;; Init the common mode output structure
out_temp_data = create_struct( "toi", data[0].toi*0.d0)
out_temp_data = replicate( out_temp_data, n_elements(data))

;; @ Discard kids that are too uncorrelated to the other ones
if param.flag_uncorr_kid ne 0 then begin
   for i = 1, param.iterate_uncorr_kid do nk_flag_uncorr_kids, param, info, data, kidpar
endif

;; ;; @ Allow smoother weighting for the common mode as a function of an
;; ;; input weight map
;; if param.w8_source ge 1 then begin
;;    w8_source_all = data.off_source*0.d0 + 1.d0
;;    for lambda=1, 2 do begin
;;       w1 = where( kidpar.type eq 1 and round(kidpar.lambda) eq lambda, nw1)
;;       if nw1 ne 0 then begin
;;          if lambda eq 1 then w8_map = grid.w8_source_1mm else w8_map = grid.w8_source_2mm
;;          nk_map2toi_3, param, info, w8_map, data.ipix[w1], w8_toi, toi_init_val=1.d0
;;          w8_source_all[w1,*] = w8_toi
;;       endif
;;    endfor
;; endif

;; ;;================================================================================
;; message, /info, "fix me: remove unnecessary estimation of nas_x, nas_y"
;; ofs_az = data.ofs_az            ; leave data.ofs_oz untouched for safety
;; ofs_el = data.ofs_el            ; leave data.ofs_el untouched for safety
;; if strupcase(info.systemof) eq "PROJECTION" then begin
;;    if strtrim(strupcase(info.ctype1),2) eq "GLON" and $
;;       strtrim(strupcase(info.ctype2),2) eq "GLAT" then begin
;;       euler, info.longobj + ofs_az/3600.d0, info.latobj + ofs_el/3600.d0, ra, dec, 2
;;       euler, info.longobj, info.latobj, ra_center, dec_center, 2
;;       ofs_az = (ra - ra_center)*3600.d0*cos(dec*!dtor)
;;       ofs_el = (dec-dec_center)*3600.d0
;;    endif
;; endif
;; alpha = data.paral
;; ofs_az1  = -cos(alpha)*ofs_az + sin(alpha)*ofs_el
;; ofs_el   =  sin(alpha)*ofs_az + cos(alpha)*ofs_el
;; ofs_az =  ofs_az1
;; azel2nasm, data.el, ofs_az, ofs_el, ofs_x, ofs_y
;; ;;================================================================================


if strupcase(param.decor_method) eq "ATM_DERIV_ONE_BOX" then begin
   ;; Compute the derivative of the atmospheric common mode on the
   ;; entire scan, otherwise there are problems with the derivatives
   ;; on the edges of the (short) subscans
   w1 = where( kidpar.type eq 1, nw1)
   nk_get_cm_sub_2, param, info, data.toi[w1], data.flag[w1], $
                    data.off_source[w1], kidpar[w1], atm_cm
   atm_deriv = deriv( smooth(atm_cm,round(!nika.f_sampling)))
endif

;; Derive the toi associated to the zero level mask
nk_map2toi_3, param, info, grid.zero_level_mask, data.ipix, zm_toi

;; begin LP copy from nk_decor_5
;;@ Determine the blocks of maximally correlated kids on the entire scan once for all
if strupcase(param.decor_method) eq "COMMON_MODE_ONE_BLOCK" and $
   param.corr_block_per_subscan eq 0 then begin
   nk_get_corr_block_2, param, info, data, kidpar, kid_corr_block
;;   save, kid_corr_block, file=param.output_dir+"/kid_corr_block.save"
endif
;; end LP

if strupcase(param.new_method) eq "NEW_DECOR_ATMB_PER_ARRAY" then begin
;; if requested, do not project the 1st or last n seconds of subscans
   if param.flag_n_seconds_subscan_start ne 0 then begin
      npts_flag = round( param.flag_n_seconds_subscan_start*!nika.f_sampling)
      for i=min(data.subscan), max(data.subscan) do begin
         w = where( data.subscan eq i, nw)
         if nw ne 0 then begin
            wsample = (indgen(npts_flag) + min(w)) < max(w)
            nk_add_flag, data, 8, wsample=wsample
         endif
      endfor
   endif
endif

;; @ Decorrelates either per subscan or on the entire scan
if strupcase(param.decor_per_subscan) eq 1 then begin

   nsubscans = max(data.subscan) - min(data.subscan) + 1
   for isubscan=min(data.subscan), max(data.subscan) do begin

;;      message, /info, "subscan "+strtrim( long(i),2)+"/"+strtrim( long(max(data.subscan)),2)

      if param.log then nk_log, info, "subscan "+strtrim(isubscan,2)
      wsample = where( data.subscan eq isubscan, nwsample)
      if nwsample lt param.nsample_min_per_subscan then begin
         if param.silent eq 0 then $
            message, /info, "Less than "+strtrim(param.nsample_min_per_subscan,2)+$
                     " samples in subscan "+strtrim( long(isubscan),2)+" => do not project."
         if nwsample ne 0 then nk_add_flag, data, 8, wsample=wsample
      endif else begin
         case istokes of
            1: toi = data[wsample].toi
            2: toi = data[wsample].toi_q
            3: toi = data[wsample].toi_u
         endcase
         flag       = data[wsample].flag
         off_source = data[wsample].off_source
         elevation  = data[wsample].el

;;         elevation = data[wsample].elev_offset*!arcsec2rad

;;          ;; Need a local copy of w8_source otherwise it remains stuck
;;          ;; to the default value of the 1st subscan when it's
;;          ;; created by default
;;          if param.w8_source ge 1 then w8_source1 = w8_source_all[*,wsample]

         if defined(atm_deriv) then my_atm_deriv = atm_deriv[wsample]

;; ;         message,/info, "subscan "+strtrim( long(isubscan),2)+"/"+strtrim( long(max(Data.subscan)),2)
;;          message, /info, "fix me:"
;;          print, "isubscan = "+strtrim(isubscan,2)
;;         !mydebug.title='subscan '+strtrim(isubscan,2)
;;          !mydebug.subscan = long(isubscan)
;;          if !mydebug.window eq -1 then begin
;;             wind, 1, 1, /free, /large
;;             !mydebug.window = !d.window
;;          endif
;; ;;         if isubscan ge 7 and isubscan le 9 then begin
;; ;;            stop
;; ;;            param.interactive = 1
;; ;;         endif else begin
;; ;;            param.interactive=0
;; ;;         endelse
;; stop

;;          if param.interactive eq 1 then begin
;;             save, file='all_data_subscan_'+strtrim( long(isubscan),2)+'.save'
;;             message, /info, 'saved all_data_subscan_'+strtrim( long(isubscan),2)+'.save'
;;          endif

         if keyword_set(snr_toi) then my_snr_toi = snr_toi[*,wsample] else delvarx, my_snr_toi
         nk_decor_sub_6, param, info, toi, flag, off_source, kidpar, $
                         out_temp, elevation, $ ; nas_x=ofs_x[wsample], nas_y=ofs_y[wsample], $
                         kid_corr_block=kid_corr_block, atm_d=my_atm_deriv, $
                         out_coeffs=out_coeffs, subscan=data[wsample].subscan, $
                         dra=data[wsample].dra, ddec=data[wsample].ddec, zm_toi=zm_toi[*,wsample], $
                         w8_hfnoise=w8_hfnoise, snr_toi=my_snr_toi
 
         case istokes of
            1: data[wsample].toi   = toi
            2: data[wsample].toi_q = toi
            3: data[wsample].toi_u = toi
         endcase
         data[wsample].flag     = flag
         out_temp_data[wsample].toi = out_temp.toi
         if param.subscan_edge_w8 gt 0 then hfnoise_w8[*,wsample] = w8_hfnoise
      endelse
   endfor

endif else begin

   nsn = n_elements(data)
   if param.tiling_decorrelation then begin

      isubmin = long(min(data.subscan))
      isubmax = long(max(data.subscan))
      for isubscan = isubmin, isubmax do begin
         wsubscan = where( data.subscan eq isubscan)
         case isubscan of
            isubmin: begin
               i1 = 0
               i2 = avg( where( data.subscan eq (isubscan+1)))
            end
            isubmax: begin
               i1 = avg( where( data.subscan eq (isubscan-1)))
               i2 = nsn-1
            end
            else: begin
               i1 = avg( where( data.subscan eq (isubscan-1)))
               i2 = avg( where( data.subscan eq (isubscan+1)))
            end
         endcase
         i1 = round(i1) > 0
         i2 = round(i2) < (nsn-1)
         mysubscan = data[i1:i2].subscan
         
         openw, 1, "new_junk.dat", /append
         printf, 1, "isubscan, i1, minmax(wsubscan), i2: ", $
                strtrim(isubscan,2)+", "+strtrim(i1,2)+", "+strtrim(min(wsubscan),2)+", "+strtrim(max(wsubscan),2)+", "+strtrim(i2,2)
         close, 1

         case istokes of
            1: toi = data[i1:i2].toi
            2: toi = data[i1:i2].toi_q
            3: toi = data[i1:i2].toi_u
         endcase
         flag       = data[i1:i2].flag
         off_source = data[i1:i2].off_source

         if defined(atm_deriv) then my_atm_deriv = atm_deriv[i1:i2]
         if keyword_set(snr_toi) then my_snr_toi = snr_toi[i1:i2,wsample] else delvarx, my_snr_toi
         nk_decor_sub_6, param, info, toi, flag, off_source, kidpar, $
                         out_temp, data[i1:i2].el, $
                         kid_corr_block=kid_corr_block, atm_d=my_atm_deriv, $
                         out_coeffs=out_coeffs, subscan=data[i1:i2].subscan, $
                         dra=data[i1:i2].dra, ddec=data[i1:i2].ddec, zm_toi=zm_toi[*,i1:i2], $
                         w8_hfnoise=w8_hfnoise, snr_toi=my_snr_toi
         
         ww = where( mysubscan eq isubscan)
         case istokes of
            1: data[wsubscan].toi   = toi[*,ww] 
            2: data[wsubscan].toi_q = toi[*,ww]
            3: data[wsubscan].toi_u = toi[*,ww]
         endcase
         data[wsubscan].flag         = flag[*,ww]
         out_temp_data[wsubscan].toi = out_temp[ww].toi
         if param.subscan_edge_w8 gt 0 then hfnoise_w8[*,wsubscan] = w8_hfnoise[*,ww]
      endfor

   endif else begin
      ;; Then work on the entire scan
      case istokes of
         1: toi = data.toi
         2: toi = data.toi_q
         3: toi = data.toi_u
      endcase
      flag = data.flag
      elevation = data.el
      ;;elevation = data.elev_offset*!arcsec2rad
      if param.log eq 1 then nk_log, info, "decorr on the full scan"
      nk_decor_sub_6, param, info, toi, flag, data.off_source, kidpar, $
                      out_temp_data, elevation, $ ; nas_x=ofs_x, nas_y=ofs_y, $
                      kid_corr_block=kid_corr_block, atm_deriv=atm_deriv, $
                      out_coeffs=out_coeffs, snr_toi=snr_toi, subscan=data.subscan, $
                      dra=data.dra, ddec=data.ddec, zm_toi=zm_toi, w8_hfnoise=w8_hfnoise
      case istokes of
         1: data.toi   = toi
         2: data.toi_q = toi
         3: data.toi_u = toi
      endcase
      data.flag  = flag
      if param.subscan_edge_w8 gt 0 then hfnoise_w8 = w8_hfnoise
   endelse
endelse

if param.cpu_time then nk_show_cpu_time, param

end

