;;Simulation of the lobed CMB in the small angular size approximation
;;for a given map size

pro genere_cmb,param, cmb

;;;;;;;;;;;;;;RECUPERATION DES C_l AVEC CAMB;;;;;;;;;;;;;;;;;;;;;;;;;
  outputdir = !nika.simu_dir+'/Fiducial_Cl'
  file = outputdir+'/camb_18982736_scalcls.dat'
  spawn,'wc -l '+file,nl
  spawn,'wc -w '+file,nw
  nc = double(nw)/double(nl)
  nl = double(nl)
  data = dblarr(nc,nl)

  openr,1,file
  readf,1,data
  close,1

  l = data[0,*]
  cl = data[1,*]*2.0*!dpi/l/(l+1.0)*1d-12
  l = [0,1,reform(l)]             ;We add l=0 and l=1 not present at first
  cl = [0,0,reform(cl)]

;;;;;;;;;;;;;;;;CALCUL LA CARTE DU CMB;;;;;;;;;;;;;;;;;;;;;;;
  map = randomn(seed,param.N_sky,param.N_sky) ;Gaussian noise
  fmap = fft(map)

  karr = dist(param.N_sky)      ;k map

  ind = karr*180.0/param.Taille_carte
  clarr = cl[ind]
  larr = l[ind]
  cmb = double(fft(param.N_sky*sqrt(clarr)*fmap,/inverse))

  ft = fft(cmb)
  k = 2*!pi*dist(param.N_sky)/param.Taille_carte
  ft = ft*exp(-k*k*param.Taille_lobe*param.Taille_lobe)
  cmb = double(fft(ft,/inverse))

 return
end
