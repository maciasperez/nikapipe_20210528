;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_lf_sin_fit
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_lf_sin_fit, param, info, data, kidpar
; 
; PURPOSE: 
;        Fits a sum of cos and sin outside the source to filter out low
;        frequency noise and atmosphere residuals. The number of harmonics is passed
;        in param.lf_sin_fit_n_harmonics.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 2015: NP
;-

pro nk_lf_sin_fit, param, info, data, kidpar, output_fit

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_lf_sin_fit, param, info, data, kidpar, output_fit"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements(data)
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "no valid kid"
   return
endif

x = dindgen(nsn)
n_harmo = param.lf_sin_fit_n_harmonics

output_fit = data.toi*0.d0

for ii=0, nw1-1 do begin
   ikid = w1[ii]

   wsample = where( data.off_source[ikid,*] ne 0 and $
                    (data.flag[ikid] eq 0 or data.flag[ikid] eq 2L^11), nwsample)
   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this kid
      data.flag[ikid] = 2L^7
   endif else begin

      y = data.toi[ikid]
      junk = my_baseline(y[wsample], x=x[wsample], base=0.1, const=const, slope=slope)
      baseline = const + slope*x

      y -= baseline
      avg_y = avg(y[wsample])
      y -= avg_y

      ata = dblarr( 2*n_harmo, 2*n_harmo)
      atd = dblarr( 2*n_harmo)
      
      for p=0, n_harmo-1 do begin
         ;; x goes from 0 to (nsn-1), so yes, divide 2*pi by (nsn-1) to
         ;; explore the full period
         ap = cos(2.d0*!dpi/(nsn-1)*x[wsample]*(p+1))
         bp = sin(2.d0*!dpi/(nsn-1)*x[wsample]*(p+1))
         
         atd[2*p]   = total( ap*y[wsample])
         atd[2*p+1] = total( bp*y[wsample])
         
         for k=0, n_harmo-1 do begin
            ak = cos(2.d0*!dpi/(nsn-1)*x[wsample]*(k+1))
            bk = sin(2.d0*!dpi/(nsn-1)*x[wsample]*(k+1))
            
            ata[2*p,2*k]     = total( ap*ak)
            ata[2*p,2*k+1]   = total( ap*bk)
            ata[2*p+1,2*k]   = total( bp*ak)
            ata[2*p+1,2*k+1] = total( bp*bk)
         endfor
      endfor
      
      coeffs = invert(ata)##atd
      yfit = y*0.d0
      for p=0, n_harmo-1 do begin
         yfit += coeffs[2*p]   * cos(2.d0*!dpi/(nsn-1)*x*(p+1))
         yfit += coeffs[2*p+1] * sin(2.d0*!dpi/(nsn-1)*x*(p+1))
      endfor

      yfit += avg_y + baseline
      output_fit[ikid,*] = yfit
      data.toi[ikid] -= yfit
   endelse
endfor
      
if param.cpu_time then nk_show_cpu_time, param, "nk_lf_sin_fit"

end
