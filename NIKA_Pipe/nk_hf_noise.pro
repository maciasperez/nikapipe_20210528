;
; computes the HF noise of a series of timelines
; used in NIKA2 method 120 IMCM  nk_decor_atmb_per_array
; FXD Dec 2020

FUNCTION nk_hf_noise, toi, nsm = nsm
  toih = toi
  if keyword_set( nsm) then knsm = nsm else knsm = 11
  nkid = n_elements( toih[*, 0])
  nsn = n_elements( toih[0, *])
  for ik = 0, nkid-1 do toih[ ik, *] = $
     toi[ ik, *]- median( reform(toi[ ik,*]), knsm) 
  hfnoise = smooth( stddev( toih, dim=1), knsm, /edge_truncate)
  hfnoise = hfnoise/median(hfnoise)
  hfnoise[0:knsm-1]=1
  hfnoise[nsn-knsm:nsn-1]=1
  return, hfnoise
           
end
