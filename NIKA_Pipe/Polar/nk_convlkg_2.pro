
pro nk_convlkg_2, map_i, map_q, map_u, kernel_i, kernel_q, kernel_u, $
                  L_IQ, L_IU    ; map_corr_q, map_corr_u

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_convlkg, map_i, map_q, map_u, kernel_i, kernel_q, kernel_u, $"
   print, "            L_IQ, L_IU"; ; map_corr_q, map_corr_u"
   return
endif

L_IQ = convolve( map_i, kernel_q);/total(kernel_i)
L_IU = convolve( map_i, kernel_u);/total(kernel_i)

end
