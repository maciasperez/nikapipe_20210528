
;+
;
; SOFTWARE:
;; NIKA pipeline / Polarization
;
; NAME: 
; nk_hwp_rm
;
; CATEGORY:
;
; CALLING SEQUENCE:
;     nk_hwp_rm, param, kidpar, data, amplitudes
; 
; PURPOSE: 
;        Estimate the HWP parasitic signal as a sum of harmonics of the
;rotation frequency and subtract it from data.toi
; 
; INPUT: 
;    - param, kidpar, data
; 
; OUTPUT: 
;    - amplitudes
;    - data.toi is modified
; 
; KEYWORDS:
;    - fit : the last fit
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - NP
;-

pro nk_hwp_rm, param, kidpar, data, amplitudes, fit=fit, df_tone=df_tone


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_hwp_rm, param, kidpar, data, amplitudes, fit=fit, df_tone=df_tone"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements( kidpar)
nsn   = n_elements( data)

ncoeff = 2 + 4*param.polar_n_template_harmonics

t = dindgen(nsn)/!nika.f_sampling

w1 = where(kidpar.type eq 1, nw1)
wall  = where( avg( data.flag[w1], 0) eq 0, nwall)
if nwall eq 0 then begin
   message, /info, "No sample with all kid flags = 0 to determine the hwp template"
;   stop
   amplitudes = dblarr( nkids, ncoeff)
   return
endif

if param.hwp_harmonics_only eq 0 then begin
   amplitudes = dblarr( nkids, ncoeff)

   ;; Fitting template, only on good positions
   temp = dblarr( ncoeff, nwall)
   temp[0,*] = 1.0d0
   temp[1,*] = t[wall]
   for i=0, param.polar_n_template_harmonics-1 do begin
      temp[ 2 + i*4,     *] =         cos( (i+1)*data[wall].c_position)
      temp[ 2 + i*4 + 1, *] = t[wall]*cos( (i+1)*data[wall].c_position)
      temp[ 2 + i*4 + 2, *] =         sin( (i+1)*data[wall].c_position)
      temp[ 2 + i*4 + 3, *] = t[wall]*sin( (i+1)*data[wall].c_position)
   endfor

   ;; Global template for the reconstruction
   outtemp = dblarr( ncoeff, nsn)
   outtemp[0,*] = 1.0d0
   outtemp[1,*] = t
   for i=0, param.polar_n_template_harmonics-1 do begin
      outtemp[ 2 + i*4,     *] =   cos( (i+1)*data.c_position)
      outtemp[ 2 + i*4 + 1, *] = t*cos( (i+1)*data.c_position)
      outtemp[ 2 + i*4 + 2, *] =   sin( (i+1)*data.c_position)
      outtemp[ 2 + i*4 + 3, *] = t*sin( (i+1)*data.c_position)
   endfor
endif else begin

   amplitudes = dblarr( nkids, ncoeff-2)

   ;; Fitting template, only on good positions
   temp = dblarr( ncoeff-2, nwall)
   for i=0, param.polar_n_template_harmonics-1 do begin
      temp[ i*4,     *] =         cos( (i+1)*data[wall].c_position)
      temp[ i*4 + 1, *] = t[wall]*cos( (i+1)*data[wall].c_position)
      temp[ i*4 + 2, *] =         sin( (i+1)*data[wall].c_position)
      temp[ i*4 + 3, *] = t[wall]*sin( (i+1)*data[wall].c_position)
   endfor

   ;; Global template for the reconstruction
   outtemp = dblarr( ncoeff-2, nsn)
   for i=0, param.polar_n_template_harmonics-1 do begin
      outtemp[ i*4,     *] =   cos( (i+1)*data.c_position)
      outtemp[ i*4 + 1, *] = t*cos( (i+1)*data.c_position)
      outtemp[ i*4 + 2, *] =   sin( (i+1)*data.c_position)
      outtemp[ i*4 + 3, *] = t*sin( (i+1)*data.c_position)
   endfor
endelse

ata   = matrix_multiply( temp, temp, /btranspose)
atam1 = invert(ata)

womega = where( data.c_position eq min(data.c_position), nwomega)

p = 0
for ikid=0, nkids-1 do begin

   ;r = nk_where_flag( data.flag[ikid], 9, nflag = nflag, compl = wgood)
   w = where( data.flag[ikid] eq 0, nw)

   ;; Loop only on valid kids to save time
   if kidpar[ikid].type eq 1 then begin

;print, 'df', keyword_set(df_tone)
      if keyword_set(df_tone) then begin
        if param.hwp_harmonics_only eq 1 then begin
            base = interpol( data[womega].df_tone[ikid], womega, dindgen(nsn))
            data.df_tone[ikid] -= base
            a = avg( data.df_tone[ikid])
            data.df_tone[ikid] -= a
         endif
         atd = matrix_multiply( data[wall].df_tone[ikid], temp, /btranspose)
         ampl = atam1##atd
         amplitudes[ikid,*] = ampl
         fit  = reform( outtemp##ampl)
         ;; if p eq 0 and param.do_plot ne 0 then begin
         ;;    wind, 1, 1, /free
         ;;    !p.multi=[0,1,2]
         ;;    plot, data.sample, data.df_tone[ikid], title='df_tone, data '+strtrim(ikid,2), xra = min(data.sample)+[0, 200], /xs
         ;;    plot, data.sample, data.df_tone[ikid]-fit, title='data-fit', xra = min(data.sample)+[0, 200], /xs
         ;;    !p.multi=0
         ;;    p++
         ;; endif
         data.df_tone[ikid] -= fit
         if param.hwp_harmonics_only eq 1 then data.df_tone[ikid] += a + base

      endif else begin

         if param.hwp_harmonics_only eq 1 then begin
            base = interpol( data[womega].toi[ikid], womega, dindgen(nsn))
            data.toi[ikid] -= base
            a = avg( data.toi[ikid])
            data.toi[ikid] -= a
         endif
         atd = matrix_multiply( data[wall].toi[ikid], temp, /btranspose)
         ampl = atam1##atd
         amplitudes[ikid,*] = ampl
         fit  = reform( outtemp##ampl)
         ;; if p eq 0 and param.do_plot ne 0 then begin
         ;;    wind, 1, 1, /free
         ;;    !p.multi=[0,1,2]
         ;;    plot, data.sample, data.toi[ikid], title='TOI, data '+strtrim(ikid,2), xra = min(data.sample)+[0, 200], /xs
         ;;    plot, data.sample, data.toi[ikid]-fit, title='data-fit', xra = min(data.sample)+[0, 200], /xs
         ;;    !p.multi=0
         ;;    p++
         ;; endif
         data.toi[ikid] -= fit
         if param.hwp_harmonics_only eq 1 then data.toi[ikid] += a + base
      endelse

   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_hwp_rm"

end
