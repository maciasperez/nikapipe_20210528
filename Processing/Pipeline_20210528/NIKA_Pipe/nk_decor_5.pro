;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_5
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_handle, param, info, data, kidpar
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
;-

pro nk_decor_5, param, info, data, kidpar, out_temp_data=out_temp_data, keep_all=keep_all


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_5, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

loadct, 39, /silent

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

do_patch = 0
if strupcase( strtrim(!nika.run,2)) eq "CRYO" then begin
   do_patch = 1
endif else begin
   if long(!nika.run) le 5 then do_patch = 1
endelse
if do_patch then begin
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      power_spec, data.toi[ikid] - my_baseline( data.toi[ikid]), !nika.f_sampling, pw, freq
      wf = where( freq gt 4.d0)
      kidpar[ikid].noise = avg(pw[wf]) ; Jy/Beam/sqrt(Hz) since data is in Jy/Beam
   endfor
endif

if info.polar ne 0 then begin
   out_temp_data = create_struct( "toi", data[0].toi, "toi_q", data[0].toi_q, "toi_u", data[0].toi_u)
endif else begin
   out_temp_data = create_struct( "toi", data[0].toi)
endelse
out_temp_data = replicate( out_temp_data, n_elements(data))

;;@ Determine the blocks of maximally correlated kids on the entire scan once for all
if strupcase(param.decor_method) eq "COMMON_MODE_ONE_BLOCK" and $
   param.corr_block_per_subscan eq 0 then begin
   nk_get_corr_block_2, param, info, data, kidpar, kid_corr_block
   save, kid_corr_block, file=param.output_dir+"/kid_corr_block.save"
endif

if strupcase(param.decor_method) eq "COMMON_MODE_BOX" or $
   strupcase(param.decor_method) eq "ATM_AND_COMMON_MODE_BOX" then begin
   nkids = n_elements(kidpar)
   kid_corr_block = intarr(nkids,nkids) - 1
   for i=0, nkids-1 do begin
      w = where( kidpar.acqbox eq kidpar[i].acqbox and kidpar.type eq 1, nw)
      if nw ne 0 then kid_corr_block[i,0:nw-1] = w
   endfor
endif

;;@ Discard kids that are too uncorrelated to the other ones
if param.flag_uncorr_kid ne 0 then begin
   for i = 1, param.iterate_uncorr_kid do nk_flag_uncorr_kids, param, info, data, kidpar
endif

;;@ Discard the noisiest kids from the common mode estimation,
;; update w1 definition
if param.lab eq 0 and (not keyword_set(keep_all)) then begin
   for iarray=1, 3 do begin
      w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
      if nw1 ne 0 then begin
         noise_avg = avg( kidpar[w1].noise)
         sigma = stddev(  kidpar[w1].noise)
         w = where( kidpar.type eq 1 and kidpar.array eq iarray and $
                    kidpar.noise le (noise_avg + 3*sigma), nw)
         if nw eq 0 then begin
            nk_error, info, "No kid in array "+strtrim(iarray,2)+" has a noise closer to the average than 3 sigma."
            return
         endif
         wout = where( finite(kidpar.noise) eq 1 and kidpar.array eq iarray and $
                       kidpar.noise gt (noise_avg + 3*sigma), nwout)
         if nwout ne 0 then begin
            kidpar[wout].type = 3
            if param.silent eq 0 then print, "noisy kids: ", nwout
         endif
      endif
   endfor
endif

nkids = n_elements(kidpar)


;; Decorrelates either per subscan or on the entire scan
if strupcase(param.decor_per_subscan) eq 1 then begin

   nsubscans = max(data.subscan) - min(data.subscan) + 1
   
   for i=min(data.subscan), max(data.subscan) do begin
      wsample = where( data.subscan eq i, nwsample)
;; Keep the slew for now, it should be masked by the source mask
;; discard slew too if it's not cut out by nk_cut_scans
;;       ;; nk_where_flag for the syntax
;;       powerOfTwo = 2L^8
;;       wsample = where( data.subscan eq i and (long(data.flag[0]) and powerOfTwo) ne powerOfTwo, nwsample)

      if nwsample lt param.nsample_min_per_subscan then begin
         if param.silent eq 0 then $
            message, /info, "Less than "+strtrim(param.nsample_min_per_subscan,2)+$
                  " samples in subscan "+strtrim( long(i),2)+" => do not project."
         if nwsample ne 0 then nk_add_flag, data, 8, wsample=wsample
      endif else begin

         data1 = data[wsample]

         case strupcase(param.decor_method) of
            
            "COMMON_MODE_ONE_BLOCK": begin
               nk_decor_sub_corr_block_2, param, info, data1, kidpar, $
                                          kid_corr_block=kid_corr_block, $
                                          out_temp_data=out_temp_data1
               out_temp_data[wsample].toi = out_temp_data1.toi
            end

            "COMMON_MODE_BOX": begin
               nk_decor_sub_corr_block_2, param, info, data1, kidpar, $
                                          kid_corr_block=kid_corr_block, $
                                          out_temp_data=out_temp_data1
               out_temp_data[wsample].toi = out_temp_data1.toi
            end

            "ATM_AND_COMMON_MODE_BOX": begin
               ;; global atmospheric common mode
               w1 = where( kidpar.type eq 1, nw1)
               nk_get_cm_sub_3, param, info, data1.toi[w1], data1.off_source[w1], $
                                kidpar[w1], atm_common
               nk_decor_sub_corr_block_2, param, info, data1, kidpar, $
                                          kid_corr_block=kid_corr_block, $
                                          out_temp_data=out_temp_data1, atm_common = atm_common
               out_temp_data[wsample].toi = out_temp_data1.toi
            end
            else: begin
               nk_decor_sub_5, param, info, data1, kidpar, $
                               sample_index=wsample, out_temp_data=out_temp_data1
               out_temp_data[wsample].toi = out_temp_data1.toi
            end
         endcase
         ;; Update data:
         data[wsample].toi = data1.toi
      endelse
   endfor
   
endif else begin
   ;; decorrelate on the entire scan

   case strupcase(param.decor_method) of
      
      "COMMON_MODE_ONE_BLOCK": begin
         nk_decor_sub_corr_block_2, param, info, data, kidpar, $
                                    kid_corr_block=kid_corr_block, $
                                    out_temp_data=out_temp_data
      end
      
      "COMMON_MODE_BOX": begin
         nk_decor_sub_corr_block_2, param, info, data, kidpar, $
                                    kid_corr_block=kid_corr_block, $
                                    out_temp_data=out_temp_data
      end
      
      "ATM_AND_COMMON_MODE_BOX": begin
         ;; global atmospheric common mode
         w1 = where( kidpar.type eq 1, nw1)
         nk_get_cm_sub_3, param, info, data.toi[w1], data.off_source[w1], $
                          kidpar[w1], atm_common
         nk_decor_sub_corr_block_2, param, info, data, kidpar, $
                                    kid_corr_block=kid_corr_block, $
                                    out_temp_data=out_temp_data, atm_common = atm_common
      end
      else: begin
         nk_decor_sub_5, param, info, data, kidpar, $
                         sample_index=wsample, out_temp_data=out_temp_data
      end
   endcase
endelse

if param.cpu_time then nk_show_cpu_time, param

end
