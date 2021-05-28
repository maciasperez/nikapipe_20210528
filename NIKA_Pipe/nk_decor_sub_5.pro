;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_sub_5
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_decor_sub, param, info, data, kidpar
; 
; PURPOSE: 
;        Decorrelates kids, filters...
;        This is the core of nk_decor.pro that only dispatches per_subscan or not
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
;        - sample_index: the sample nums absolute values
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 09th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - Oct. 15th, 2015: NP, adapted nk_decor_sub.pro to NIKA2 arrays
;-

pro nk_decor_sub_5, param, info, data, kidpar, $
                    sample_index=sample_index, $
                    out_temp_data=out_temp_data

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_sub_5, param, info, data, kidpar, $"
   print, "               sample_index=sample_index, $"
   print, "               out_temp_data=out_temp_data"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(data)
if not keyword_set(sample_index) then sample_index = lindgen( nsn)
nwsample = n_elements( sample_index)
if nwsample ne nsn then begin
   nk_error, info, "sample_index and data have incompatible sizes"
   return
endif

if param.decor_elevation and strupcase(info.obs_type) eq "LISSAJOUS" then begin
   nk_build_azel_templates, param, info, sample_index, azel_templates
endif

if info.polar ne 0 then begin
   out_temp_data = {toi:data[0].toi*0.d0, toi_q:data[0].toi_q*0.d0, toi_u:data[0].toi_u*0.d0}
endif else begin
   out_temp_data = {toi:data[0].toi*0.d0}
endelse
out_temp_data = replicate( out_temp_data, nsn)

;;====================================================================================================
;; Select which decorrelation method must be applied
do_1_common_mode      = 0
do_multi_common_modes = 0
case strupcase(param.decor_method) of

   ;; 1. No decorrelation
   "NONE": begin
   end

   ;; 2. Simple commmon mode, one per lambda
   "COMMON_MODE":begin
      ;; keep all valid samples, even on source => modify data.off_source
      data.off_source  = 1.d0
      do_1_common_mode = 1
   end
   
   ;; 3. Common mode with KIDs OFF source, one per lambda
   "COMMON_MODE_KIDS_OUT":begin
      ;; leave data.off_source untouched, precisely to know whether kids are on
      ;; or off source.
      do_1_common_mode = 1
   end
   
   ;; 4. One common mode per electronic band, no source mask
   "COMMON_MODE_BAND_NO_MASK":begin
      ;; keep all valid samples, even on source => modify data.off_source
      data.off_source       = 1.d0
      do_multi_common_modes = 1
   end
   
   ;; 5. One common mode per electronic band computed far from the source
   "COMMON_MODE_BAND_MASK":begin
      ;; leave data.off_source untourched
      do_multi_common_modes = 1
   end

   ;; 6. One common mode with all kids far from the ref det (for
   ;; crosses)
   ;; test NP, Oct. 8th, 2016
   "COMMON_MODE_FAR_FROM_REF_DET":begin
      ;; leave data.off_source untourched
      do_1_common_mode = 1
      data.off_source = 1
   end

   ;;----------------------------------------------------------------------------------
   ;; 6. Subtract the 1mm common mode to the 2mm timelines.
   ;; WARNING: the 1mm common mode is computed on the whole map, but regressed
   ;; only outside the mask when subtracted from the 2mm.
   "DUAL_BAND_DEC":begin
      ;; leave data.off_source untourched
      do_1_common_mode = 1
      w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
      if nw1 eq 0 then begin
         txt = "No valid pixels on Array 1 to compute the common mode for dual_band_dec"
         nk_error, info, txt
         return
      endif
      data.off_source[w1] = 1.d0
   end

   ELSE: begin
      nk_error, info, "Unrecognized decorelation method: "+param.decor_method
      return
   end
endcase

;; if requested, discard kids (locally) that spend too much time on source and
;; will therefore give poor contribution to the common mode and will be badly decorrelated.
if param.max_on_source_frac ne 0 then begin
;   kidpar_copy = kidpar
   w = where( kidpar.type eq 1, nw)
   for i=0, nw-1 do begin
      ikid = w[i]
      ;; if total( data.off_source[ikid])/nsn lt (1-param.max_on_source_frac) then kidpar.type = 3
      if total( data.off_source[ikid])/nsn lt (1-param.max_on_source_frac) then begin
         data.flag[ikid] = 1
         print, "ikid "+strtrim(ikid,2)+" spends more than "+strtrim(param.max_on_source_frac,2)+" of its time on the mask."
      endif
   endfor
endif

;; stokes[0] = '' because data.toi_Q, data.toi_U, BUT data.toi (no _I)
if info.polar eq 0 then begin
   stokes = ['']
endif else begin
   stokes = ['', '_Q', '_U']
endelse
nstokes = n_elements(stokes)

tags = tag_names(data)

;;for istokes=0, nstokes-1 do begin
for istokes=0, 0 do begin
   wtag = where( strupcase(tags) eq "TOI"+stokes[istokes], nwtag)
   if nwtag ne 0 then begin

      for iarray=1, 3 do begin
         w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
         if nw1 ne 0 then begin
            toi = (data.(wtag))[w1,*]

            ;; Compute common mode off source (depending on the mask)
            if do_1_common_mode then begin
               flag = data.flag[w1]
               nk_get_cm_sub_2, param, info, toi, flag, data.off_source[w1], kidpar[w1], common_mode
               data.flag[w1] = flag
               common_mode = reform( common_mode, 1, nsn)
               n_cm = 1
            endif

            if strupcase(param.decor_method) eq "DUAL_BAND_DEC" then begin
               ;; Store Array 1's common mode
               if iarray eq 1 then common_mode_1mm = common_mode
               ;; Pass it to the decorrelation of the 2mm channel
               if iarray eq 2 then common_mode = common_mode_1mm
               ;; Array 3 will be dealt with later.
            endif

            ;; Common modes per instrumental electronic band
            if do_multi_common_modes then begin
               if strupcase(param.decor_method) eq "COMMON_MODE_BAND_NO_MASK" or $
                  strupcase(param.decor_method) eq "COMMON_MODE_BAND_MASK" then begin
                  nk_get_common_mode_band, param, info, kidpar[w1], toi, $
                                           data.flag[w1], data.off_source[w1], common_mode
                  n_cm = n_elements( common_mode[*,0])
               endif
            endif

            ;; Add azimuth and elevation templates to the decorrelation if requested
            if (param.decor_elevation eq 1) and (param.lab eq 0) then begin
               if strupcase(info.obs_type) eq "LISSAJOUS" then begin
                  templates = dblarr( n_cm+ 4*param.n_harmonics_azel, nsn)
                  for i=0, n_cm-1 do templates[i,*] = common_mode[i,*]
                  templates[n_cm:*,*] = azel_templates
               endif else begin ; OTF, etc...
                  templates = dblarr( n_cm + 1, nsn)
                  for i=0, n_cm-1 do templates[i,*] = common_mode[i,*]
                  templates[n_cm,*] = data.el
               endelse
            endif else begin
               templates = common_mode
            endelse
            
            ;; Decorrelate from the pointing acceleration
            if param.decor_accel eq 1 then begin
               speed        = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)
               acceleration = deriv(speed)
               tt = templates
               nt = n_elements(templates[*,0])
               templates = dblarr( nt+1, nsn)
               for i=0, nt-1 do templates[i,*] = tt[i,*]
               templates[nt,*] = acceleration
            endif

            ;; To mimic the dual_band decorrelation in the case of
            ;; Crab on simulations for transfer functions
            if !db.lvl eq 1 then begin
               w1 = where( kidpar.type eq 1 and kidpar.array eq 2, nw1)
               for i=0, nw1-1 do begin
                  ikid = w1[i]
                  data.toi[ikid] -= common_mode * (150./260.)^2
               endfor

            endif else begin
               ;; Perform decorrelation
               kidpar1 = kidpar[w1] ; slight modif to make sure corr2cm is affected correctly (NP, Sep. 23, 2016 for a test)
               nk_subtract_templates_3, param, info, toi, data.flag[w1], data.off_source[w1], kidpar1, templates, out_temp
               kidpar[w1] = kidpar1 ; slight modif to make sure corr2cm is affected correctly (NP, Sep. 23, 2016 for a test)
            
               ;; IDL does not allow to copy the full array at once (?) :
               ;; (data.(wtag))[w1,*] = toi
               case istokes of
                  0: begin
                     out_temp_data.toi[  w1] = out_temp
                     data.toi[w1] = toi
                  end
                  1: begin
                     out_temp_data.toi_q[w1] = out_temp
                     data.toi_q[w1] = toi
                  end
                  2: begin
                     out_temp_data.toi_u[w1] = out_temp
                     data.toi_u[w1] = toi
                  end
               endcase
            endelse ; !db.lvl for Crab transfer function
         endif                  ; wtag
      endfor                    ; stokes
   endif                        ; nw1
endfor                          ; iarray


end
