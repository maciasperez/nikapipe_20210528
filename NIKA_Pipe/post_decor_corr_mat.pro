


;; Need to compute raw correlation matrices here with the updated list
;; of valid kids

for iarray=1, 3 do begin &$
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1) &$
   corr_mat = abs( correlate( data.toi[w1])) &$
   raw_mat  = abs( correlate( toi_copy[w1,*])) &$
   case iarray of &$
      1: begin &$
         raw_corr_mat1        = raw_mat &$
         post_decor_corr_mat1 = corr_mat &$
      end &$
      2: begin &$
         raw_corr_mat2        = raw_mat &$
         post_decor_corr_mat2 = corr_mat &$
      end &$
      3: begin &$
         raw_corr_mat3        = raw_mat &$
         post_decor_corr_mat3 = corr_mat &$
      end &$
   endcase &$
endfor
save, kidpar, param, info, raw_corr_mat1, raw_corr_mat2, raw_corr_mat3, $
      post_decor_corr_mat1, post_decor_corr_mat2, post_decor_corr_mat3, $
      file='post_decor_corr_matrices_'+param.scan+'.save'


