
;; Subtract a signal described by a sum of harmonics of the HWP rotation
;; frequency. The amplitudes of these harmonics may vary linearly with time.
;;
;; NP.

;; fit one by one for now...
;; output the last fit for the record (optional)
;;
;; Oct. 12th, 2014: Account for flags
;;-----------------------------------------------------------------------------------

pro nk_hwp_rm_tiling, param, kidpar, data, amplitudes, tiling_period, fit=fit, df_tone=df_tone


nsn = n_elements(data)

;; number of points on which we fit for the template
n_tiling = round( !nika.f_sampling*tiling_period)
if n_tiling lt 100 then begin
   message, /info, "Are you sure you want to fit the template on less than 100 points ?"
   message, /info, "if yes, press .c"
   stop
endif

;; toi_out is needed to prevent mixing from clean/unclean timelines when in
;; the last section.
toi_out = data.toi
i1 = 0
while i1 le (nsn-1) do begin

   i2 = (i1 + n_tiling - 1) < (nsn-1)
   if i2 eq (nsn-1) then i1 = (i2 - n_tiling + 1) > 0

   data1 = data[i1:i2]
   ;; nk_hwp_rm_2, param, info, data1, kidpar, df_tone=df_tone
   nk_hwp_rm_3, param, info, data1, kidpar, df_tone=df_tone
   toi_out[*,i1:i2] = data1.toi
   
   i1 = i2+1
endwhile

;; output
data.toi = toi_out

end
