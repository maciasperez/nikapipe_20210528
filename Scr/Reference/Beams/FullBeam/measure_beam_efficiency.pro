;;
;;
;;
;;   Measurement of the total solid angle and main beam efficiency 
;;
;;    voir production de la carte dans comresult_beammap.pro
;;
;;    LP, 2019
;;
;;________________________________________________________________________

pro measure_beam_efficiency, png=png, ps=ps, pdf=pdf
  
  project_dir  = '/home/perotto/NIKA/Plots/Beams/FullBeams/'
  plot_dir     = project_dir
  version      = 1

  ;; plot aspect settings
  ;;----------------------------------------------------------------  
  ;; window size
  wxsize = 600.
  wysize = 440.
  ;; plot size in files
  pxsize = 12.3
  pysize = 9.
  ;; charsize
  charsize  = 1.0
  if keyword_set(png) then png = 1 else png=0 
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 2.0
  symsize   = 0.7

  decibel=1

;; scan list
;;---------------------------------------------------------------------------------------------

;; N2R8: best file
scan_list_n2r8 = ['20170125s243']

;; N2R9: best file
scan_list_n2r9 = ['20170224s177', '20170226s415']

;; from the DB
select_beammap_scans, selected_scan_list, selected_source

scan_list_all = [scan_list_n2r8, scan_list_n2r9, selected_scan_list]
source_all    = ['Uranus', '3C84', selected_source]
index = uniq(scan_list_all)

scan_list = scan_list_all[index] ;; 18 beammaps dont 6 vers Mars
sources   = source_all[index]  

;; excluding scan of Mars
;wmars=where(strupcase(sources) eq 'MARS', nmars, compl=w)
;if nmars gt 0 then begin
;   scan_list = scan_list[w] 
;   sources   = sources[w]  
;endif

;; excluding scan of 3C273 (not bright enought)
;wq=where(strupcase(sources) eq '3C273', nq, compl=w)
;if nq gt 0 then begin
;   scan_list = scan_list[w] 
;   sources   = sources[w]  
;endif


;; input_map_files and profile_fit_files
;; --> produced in launch_full_beam_analysis
;;---------------------------------------------------------------------------------------------
profile_fit_files = project_dir+'Profiles/'+'Prof_3Gauss_'+strtrim(scan_list,2)+'.save'
input_map_files   = project_dir+'v_'+strtrim(string(version), 2)+'/'+strtrim(scan_list,2)+'/results.save'

;;scan_list FR fit A 2mm OK : 20170125s243 20170226s425 20170227s84 20171022s158 20171024s105 20171024s106 20171025s41 20171025s42 20171027s49 20171029s266 20171030s268 20180122s82 20180122s309

;; scan selection: excluding fit failures
w_11 = [0, 5, 6, 8, 10, 11, 12, 13, 14, 17]
w_11 = [0, 5, 6, 10, 11, 12, 13, 14, 17]
w_22 = [0, 1, 3, 4, 7, 8, 9, 10, 11, 13, 14, 16, 17]

;;_______________________________________________________________________________________
;;_______________________________________________________________________________________
;;_______________________________________________________________________________________

nscan = n_elements(scan_list)

rmax = 90.0d0

;;________________________________________________________________________________________
;;
;;   KRAMER+2013
;;________________________________________________________________________________________
freq_ck   = [145.0d0, 210.0d0, 230.0d0, 280.0d0]
fwhm_0_ck = [16.0d0, 11.0d0, 10.4d0, 8.4d0]
fwhm_1_ck = [85.0d0, 65.0d0, 56.5d0, 50.0d0]
fwhm_2_ck = [350.0d0, 250.0d0, 217.0d0, 175.0d0]
fwhm_3_ck = [1200.0d0, 860.0d0, 761.0d0, 620.0d0]
a0_ck = [1.0d0, 1.0d0, 1.0d0, 1.0d0]
a1_ck = [8.0d-4, 1.9d-3, 2.0d-3, 2.0d-3]
a2_ck = [2.5d-4, 3.5d-4, 4.1d-4, 5.0d-4]
a3_ck = [1.6d-5, 2.2d-5, 3.5d-5, 5.5d-5]
a0_ck = a0_ck-a1_ck-a2_ck-a3_ck

beff_ck = [0.74, 0.63, 0.59, 0.49]

;; Forward and rearward spillover and scattering
fss = [2.0d0, 6.0d0, 8.0d0, 9.0d0]
rss = [7.0d0, 6.0d0, 8.0d0, 13.0d0] ;; 1-F_eff

om_tot_ck = 2.0d0*!dpi*(fwhm_0_ck*!fwhm2sigma)^2/beff_ck

;; extropol to NIKA2 freq
k     = [2400.0, 13000.0, 50000.0, 175000.0]
sig_k = [100.0, 1000.0, 2000.0, 3000.0]

freq0     = [260d0, 260d0, 260d0, 150d0]

efwhm = dblarr(4,4)
eamp  = dblarr(4,4)
sig_efwhm = dblarr(4, 4)
sig_eamp  = dblarr(4, 4)
;; In Greve+1998, 5% rel. errors on the relative amplitude P
;; In the Calib&Perf paper, rms <5% at 1mm and <2% at 2mm on the beam profiles
relerror = [0.05, 0.05, 0.05, 0.02]
efwhm[0, *] = k[0]/freq0
efwhm[1, *] = k[1]/freq0
efwhm[2, *] = k[2]/freq0
efwhm[3, *] = k[3]/freq0
sig_efwhm[0, *] = sig_k[0]/freq0
sig_efwhm[1, *] = sig_k[1]/freq0
sig_efwhm[2, *] = sig_k[2]/freq0
sig_efwhm[3, *] = sig_k[3]/freq0
eamp[ 0, *] = [1.0d0,  1.0d0, 1.0d0,  1.0d0]
eamp[ 1, *] = [2.0d-3, 2.0d-3, 2.0d-3, 8.0d-4]
eamp[ 2, *] = [4.5d-4, 4.5d-4, 4.5d-4, 2.5d-4]
eamp[ 3, *] = [4.5d-5, 4.5d-5, 4.5d-5, 1.6d-5]
eamp[ 0, 0] = eamp[ 0, 0] - total(eamp[1:3, 0])
eamp[ 0, 1] = eamp[ 0, 1] - total(eamp[1:3, 1])
eamp[ 0, 2] = eamp[ 0, 2] - total(eamp[1:3, 2])
eamp[ 0, 3] = eamp[ 0, 3] - total(eamp[1:3, 3])
for itag=0, 3 do sig_eamp[*, itag]  = eamp[*, itag]*relerror[itag] 
eta_fss = [8.0d0, 8.0d0, 8.0d0, 2.0d0] 
eta_rss = [10.0d0, 10.0d0, 10.0d0, 8.5d0]
;;
;; Greve+1998 and http://iram.fr/IRAMFR/ARN/aug05/node6.html
sig_feff = [2.0d0, 2.0d0, 2.0d0, 2.0d0] ;; percent
;; Greve+1998 : +/-3 at 150 and 230GHz before improvement
;; 2005 measurements : +/- 4 at 260 and +/- 2 at 150GHz
sig_beff = [3.0d0, 3.0d0, 3.0d0, 2.0d0] ;; percent
sig_eta_fss = sqrt(sig_feff^2+sig_beff^2)
sig_eta_rss = sig_feff

om_tot_emir = dblarr(4)
om_frss     = dblarr(4)
sig_om_fsl  = dblarr(4)
sig_om_eb   = dblarr(4) ;; uncertainties on the third and fourth EB
om_eb       = dblarr(4)

sidesize = 3600.0d0
r0 = dindgen(7200)/7200.d0*sidesize
dr0 = 0.5d0

for itag = 0, 3 do begin
   emir_prof = eamp[0,itag]*exp(-(r0)^2/2.0/(efwhm[0, itag]*!fwhm2sigma)^2) + $
               eamp[1,itag]*exp(-(r0)^2/2.0/(efwhm[1, itag]*!fwhm2sigma)^2) + $
               eamp[2,itag]*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2) + $
               eamp[3,itag]*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)
   ;; 2nd and 3rd error beam only
   eb_prof   = eamp[2,itag]*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2) + $
               eamp[3,itag]*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)
   om_tot_emir[itag] = total(emir_prof*2.0d0*!dpi*r0*dr0)*(1d0+(eta_fss[itag]+eta_rss[itag])/100.0d0)
   om_frss[itag] = total(emir_prof*2.0d0*!dpi*r0*dr0)*(eta_fss[itag]+eta_rss[itag])/100.0d0
   ;; derivee totale
   sig_om_fsl[itag] = relerror[itag]*om_frss[itag] + $
                      total(emir_prof*2.0d0*!dpi*r0*dr0)*(sig_eta_fss[itag]+sig_eta_rss[itag])/100.0d0
   ;; moyenne quadratique
   sig_om_fsl[itag] = om_frss[itag]*sqrt(relerror[itag]^2 + $
                                         (sig_eta_fss[itag]^2+sig_eta_rss[itag]^2)/(eta_fss[itag]+eta_rss[itag])^2)
   om_eb[itag] = total(eb_prof*2.0d0*!dpi*r0*dr0)
   ;; incertitudes sur l'amplitude
   ;; et erreur sur l'extrapolation dasn les bandes NIKA2 (derivee totale)
   sig_om_eb[itag] = relerror[itag]*om_eb[itag] + $
                     total((eamp[2,itag]*(r0^2*sig_efwhm[2,itag]*!fwhm2sigma/(efwhm[2, itag]*!fwhm2sigma)^3*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2)) + $
                            eamp[3,itag]*(r0^2*sig_efwhm[3,itag]*!fwhm2sigma/(efwhm[3, itag]*!fwhm2sigma)^3*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)))*2.0d0*!dpi*r0*dr0)
   ;; moyenne quadratique
   i3 = total(exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2)*2.0d0*!dpi*r0*dr0)
   i4 = total(exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)*2.0d0*!dpi*r0*dr0)
   var_i3 = total((r0^2*sig_efwhm[2,itag]*!fwhm2sigma/(efwhm[2, itag]*!fwhm2sigma)^3*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2)*2.0d0*!dpi*r0*dr0)^2)
   var_i4 =  total((r0^2*sig_efwhm[3,itag]*!fwhm2sigma/(efwhm[3, itag]*!fwhm2sigma)^3*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)*2.0d0*!dpi*r0*dr0)^2)
   sig_om_eb[itag] = sqrt(eamp[2,itag]^2*i3^2*(relerror[itag]^2 + var_i3/i3^2) + $
                          eamp[3,itag]^2*i4^2*(relerror[itag]^2 + var_i4/i4^2)  )
endfor

;; JFL results

;;R09 (27sc)   | 245±20 | 233±18 | 239±15  | 452±16 |
;;R012 (20sc)  | 209±9   | 203±8  | 206±7  | 422±9  |
;;R014 (28sc)  | 232±14 | 228±18 | 230±14  | 441±14 |
;;comb (75sc)  | 229±9  | 221±8   | 225±6  | 438±8  | 

om_tot_jfl = dblarr(4, 3, 4)
sig_om_tot_jfl = dblarr(4, 3, 4)

om_tot_jfl_180 = dblarr(4, 3, 4)
sig_om_tot_jfl_180 = dblarr(4, 3, 4)

om_tot_jfl(*,0,0) = [245.0, 233.0, 239.0, 452.0]
om_tot_jfl(*,0,1) = [209.0, 203.0, 206.0, 422.0]
om_tot_jfl(*,0,2) = [232.0, 228.0, 230.0, 441.0]

sig_om_tot_jfl(*,0,0) = [20.0, 18.0, 15.0, 16.0]
sig_om_tot_jfl(*,0,1) = [9.0, 8.0, 7.0, 9.0]
sig_om_tot_jfl(*,0,2) = [14.0, 18.0, 14.0, 14.0]

;;265±23 252±23 259±18 466±17
;;229±11 221±10 225±9  437±9
;;251±16 245±18 248±15 457±15
;;
;;240±10 230±10  235±9 446±9

om_tot_jfl_180(*,0,0) = [265.0, 252.0, 259.0, 466.0]
om_tot_jfl_180(*,0,1) = [229.0, 221.0, 225.0, 437.0]
om_tot_jfl_180(*,0,2) = [251.0, 245.0, 248.0, 457.0]

sig_om_tot_jfl_180(*,0,0) = [23.0, 23.0, 18.0, 17.0]
sig_om_tot_jfl_180(*,0,1) = [11.0, 10.0, 9.0, 9.0]
sig_om_tot_jfl_180(*,0,2) = [16.0, 18.0, 15.0, 15.0]

;; combined results using UN75 : Om_{90}
s1 = dblarr(4)
s2 = dblarr(4)
s3 = dblarr(4)
for itag = 0, 3 do begin
   ;; inverse-variance weighted average
   om_tot_jfl(itag, 0, 3) = total(om_tot_jfl(itag, 0, 0:2)/sig_om_tot_jfl(itag,0,0:2)^2)/total(1.0d0/sig_om_tot_jfl(itag,0,0:2)^2)
   om_tot_jfl_180(itag, 0, 3) = total(om_tot_jfl_180(itag, 0, 0:2)/sig_om_tot_jfl_180(itag,0,0:2)^2)/total(1.0d0/sig_om_tot_jfl_180(itag,0,0:2)^2)
   max = max(om_tot_jfl(itag, 0, 0:2), imax)
   min = min(om_tot_jfl(itag, 0, 0:2), imin)
   s1[itag] = 0.1*(max+5.*sig_om_tot_jfl(itag, 0, imax) - (min-5.*sig_om_tot_jfl(itag, 0, imin)))
   s2[itag] = (max - min)/2.0d0
   s3[itag] = stddev(om_tot_jfl(itag, 0, 0:2))
   max = max(om_tot_jfl_180(itag, 0, 0:2), imax)
   min = min(om_tot_jfl_180(itag, 0, 0:2), imin)
   sig_om_tot_jfl_180(itag,0,3) = 0.1*(max+5.*sig_om_tot_jfl_180(itag, 0, imax) - (min-5.*sig_om_tot_jfl_180(itag, 0, imin)))
endfor
sig_om_tot_jfl(*,0,3) = s2
;; debug
sig_om_tot_jfl_180 = sig_om_tot_jfl


be_jfl     = dblarr(4, 3, 4)
sig_be_jfl = dblarr(4, 3, 4)

;; N2R12
be_jfl(*, 0, 1) = [1./1.56, 1./1.54, 1./1.55, 1./1.25]
sig_be_jfl(*, 0, 1) = [0.04/1.56^2, 0.03/1.54^2, 0.035/1.55^2, 0.02/1.25^2]
;; N2R9
be_jfl(*, 0, 0) = [1./1.66, 1./1.61, 1./1.635, 1./1.31]
sig_be_jfl(*, 0, 0) = [0.09/1.66^2, 0.09/1.61^2, 0.09/1.635^2, 0.04/1.31^2]
;; N2R14
be_jfl(*, 0, 2) = [1./1.62, 1./1.60, 1./1.61, 1./1.28]
sig_be_jfl(*, 0, 2) = [0.06/1.62^2, 0.08/1.60^2, 0.07/1.61^2, 0.03/1.28^2]

;; Combined BE_{90}
for itag = 0, 3 do begin
   be_jfl(itag, 0, 3) = total(be_jfl(itag, 0, 0:2)/sig_be_jfl(itag,0,0:2)^2)/total(1.0d0/sig_be_jfl(itag,0,0:2)^2)
   max = max(be_jfl(itag, 0, 0:2), imax)
   min = min(be_jfl(itag, 0, 0:2), imin)
   ;; methode 1
   sig_be_jfl(itag, 0, 3) = 0.1*(max+5.*sig_be_jfl(itag, 0, imax) - (min-5.*sig_be_jfl(itag, 0, imin)))
   ;; methode 2
   sig_be_jfl(itag, 0, 3) = (max-min)/2.0d0
endfor


fwhm_jfl = [11.3, 11.2, 11.2, 17.4]
sig_fwhm_jfl = [0.4, 0.4, 0.3, 0.2]
om_mb_jfl = 2.0d0*!dpi*(fwhm_jfl*!fwhm2sigma)^2
sig_om_mb_jfl = 4.0d0*!dpi*(fwhm_jfl*!fwhm2sigma^2)*sig_fwhm_jfl

;; TEST
be_jfl(*, 1, 3) = om_mb_jfl/om_tot_jfl(*, 0, 3)
;;sig_be_jfl(*, 1, 3) = abs(om_tot_jfl(*, 0, 3)*sig_om_mb_jfl - sig_om_tot_jfl(*, 0, 3)*om_mb_jfl)/om_tot_jfl(*, 0, 3)^2
for itag=0, 3 do sig_be_jfl(itag, 1, 3) = 0.1*( (2.0d0*!dpi*((fwhm_jfl[itag]-3.0*sig_fwhm_jfl[itag])*!fwhm2sigma)^2)/(om_tot_jfl(itag, 0, 3)-5.0*sig_om_tot_jfl(itag, 0, 3)) - (2.0d0*!dpi*((fwhm_jfl[itag]+3.0*sig_fwhm_jfl[itag])*!fwhm2sigma)^2)/(om_tot_jfl(itag, 0, 3)+5.0*sig_om_tot_jfl(itag, 0, 3)))



;;________________________________________________________________________________________


;; 4 channels (A1, A3, 1mm, 2mm), 3 esti (r<90, EMIR-EB, 4pi)
;; 3 méthodes (3G-prof-LP; 3G-prof-FR; map)
om_mb_prof1  = dblarr(4, nscan) 
om_tot_prof1 = dblarr(4, 3, nscan) 
be_prof1     = dblarr(4, 3, nscan)
om_mb_prof2  = dblarr(4, nscan) 
om_tot_prof2 = dblarr(4, 3, nscan) 
be_prof2     = dblarr(4, 3, nscan) 
om_tot_prof3 = dblarr(4, 3, nscan) 
be_prof3     = dblarr(4, 3, nscan) 

om_tot_prof = dblarr(4, 3, nscan) 
be_prof     = dblarr(4, 3, nscan)
om_tot_map = dblarr(4, 3, nscan) 
be_map     = dblarr(4, 3, nscan)

om_mb_prof = dblarr(4, nscan)
om_mb_map  = dblarr(4, nscan)

fwhmtab = dblarr(4, 3, nscan)

sidesize = 3600.0d0
r0 = dindgen(7200)/7200.d0*sidesize/2.
dr0 = 0.25d0

vect = dindgen(sidesize)-sidesize/2.
un = dblarr(sidesize)+1.0d0
xmap = un#vect
ymap = transpose(xmap)
rmap = sqrt(xmap^2 + ymap^2)
dx = 1.0d0
dy = 1.0d0

tags = ['A1', 'A3', '1mm', '2mm']


;; JFL
;;-----------------------

for itag = 0, 3 do begin

   prof_feb = eamp[2,itag]*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2) + $
              eamp[3,itag]*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)
    
   om_hyb = total(prof_feb*2.0d0*!dpi*r0*dr0)
   w=where(r0 gt 90.0)
   om_hyb2 = total(prof_feb(w)*2.0d0*!dpi*r0(w)*dr0)
   om_tot_jfl(itag, 1, *) = (1.0d0-eamp[2, itag]-eamp[3, itag])*om_tot_jfl_180(itag, 0, *)+om_hyb
   ;;om_tot_jfl(itag, 1, *) = om_tot_jfl(itag, 0, *)+om_hyb2
   sig_om_tot_jfl(itag, 1, *) = (1.0d0-eamp[2, itag]-eamp[3, itag])*sig_om_tot_jfl_180(itag, 0, *)
   ;;
   om_tot_jfl(itag, 2, *) = om_tot_jfl(itag, 1, *) + om_frss(itag)
   sig_om_tot_jfl(itag, 2, *) = sig_om_tot_jfl(itag, 1, *)

   ;; ecriture en fonction de BE_{90}
   be_jfl(itag, 1, *) = be_jfl(itag, 0, *)/((1.0d0-eamp[2, itag]-eamp[3, itag])*om_tot_jfl_180(itag, 0, *)/om_tot_jfl(itag, 0, *)+om_hyb/om_tot_jfl(itag, 0, *))
   ;;
   sig_be_jfl(itag, 1, *) = sig_be_jfl(itag, 0, *)/((1.0d0-eamp[2, itag]-eamp[3, itag])*om_tot_jfl_180(itag, 0, *)/om_tot_jfl(itag, 0, *)+om_hyb/om_tot_jfl(itag, 0, *)) + be_jfl(itag, 0, *)/((1.0d0-eamp[2, itag]-eamp[3, itag])*om_tot_jfl_180(itag, 0, *)+om_hyb)*sig_om_tot_jfl(itag, 0, *)
   ;;
   be_jfl(itag, 2, *) = be_jfl(itag, 0, *)/((1.0d0-eamp[2, itag]-eamp[3, itag])*om_tot_jfl_180(itag, 0, *)/om_tot_jfl(itag, 0, *)+om_hyb/om_tot_jfl(itag, 0, *)+om_frss(itag)/om_tot_jfl(itag, 0, *))
   ;;
   sig_be_jfl(itag, 2, *) = sig_be_jfl(itag, 1, *)

   ;; alternative method using the average FWHM 
   ;;be_jfl(itag, 1, *) = om_mb_jfl[itag]/om_tot_jfl(itag, 1, *)
   ;;be_jfl(itag, 2, *) = om_mb_jfl[itag]/om_tot_jfl(itag, 2, *)

   ;; NB: om_MB and om_tot are not fully independent
   ;;sig_be_jfl(itag, 1, *) = 0.1*( (2.0d0*!dpi*((fwhm_jfl[itag]-3.0*sig_fwhm_jfl[itag])*!fwhm2sigma)^2)/(om_tot_jfl(itag, 0, 3)-5.0*sig_om_tot_jfl(itag, 0, 3)) - (2.0d0*!dpi*((fwhm_jfl[itag]+3.0*sig_fwhm_jfl[itag])*!fwhm2sigma)^2)/(om_tot_jfl(itag, 0, 3)+5.0*sig_om_tot_jfl(itag, 0, 3)))
   ;;sig_be_jfl(itag, 2, *) = sig_be_jfl(itag, 1, *) 
   
   print, be_jfl(itag, 0, 3), '+/-', sig_be_jfl(itag, 0, 3)
   
endfor

details = 0

for iscan = 0, nscan-1 do begin

restore, profile_fit_files[iscan]

;; absolute value of FWHM
for i=3, 5 do threeg_param[3:5, *] = abs(threeg_param[3:5, *])
for i=3, 5 do threeg_param_2[3:5, *] = abs(threeg_param_2[3:5, *])

;; reordering G1, G2 and G3
for itag=0, 3 do begin
   ggg = threeg_param[3:5, itag]
   ggg0 = [threeg_param[3, itag], max([threeg_param[4, itag], 12.]), max([threeg_param[5, itag], 15.])]
   threeg_param[3:5, itag] = ggg(sort(ggg0))
   threeg_param[0:2, itag] = threeg_param[sort(ggg0), itag]
   ;;
   ggg = threeg_param_2[3:5, itag]
   ggg0 = [threeg_param_2[3, itag], max([threeg_param_2[4, itag], 12.]), max([threeg_param_2[5, itag], 15.])]
   threeg_param_2[3:5, itag] = ggg(sort(ggg0))
   threeg_param_2[0:2, itag] = threeg_param_2[sort(ggg0), itag]
   ;;
   ;; Profiles
   ;;----------------------------------------

   wr = where(r0 le rmax, n)

   ;; PROFILE 1
   p1 = threeG_param[*, itag]
   prof1 = p1[0]*exp(-(r0-p1[6])^2/2.0/(p1[3]*!fwhm2sigma)^2) + $
           p1[1]*exp(-(r0-p1[6])^2/2.0/(p1[4]*!fwhm2sigma)^2) + $
           p1[2]*exp(-(r0-p1[6])^2/2.0/(p1[5]*!fwhm2sigma)^2)
   prof1 = prof1/prof1[0] ;; p1[6]=0

   hyb_prof1 = (1.0d0-eamp[2, itag]-eamp[3, itag])*prof1 + $
               eamp[2,itag]*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2) + $
               eamp[3,itag]*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)
   
   om_mb = 2.0d0*!dpi*(p1[3]*!fwhm2sigma)^2
   om_mb_prof1[itag, iscan] = om_mb
   om_tot = total(prof1[wr]*2.0d0*!dpi*r0[wr]*dr0)
   om_tot_hyb = total(hyb_prof1*2.0d0*!dpi*r0*dr0)
   om_tot_4pi = om_tot_hyb + om_frss[itag]
   om_tot_prof1[itag,0,iscan] = om_tot
   om_tot_prof1[itag,1,iscan] = om_tot_hyb
   om_tot_prof1[itag,2,iscan] = om_tot_4pi
   be_prof1[itag,0,iscan] = om_mb/om_tot
   be_prof1[itag,1,iscan] = om_mb/om_tot_hyb
   be_prof1[itag,2,iscan] = om_mb/om_tot_4pi
   ;;
   ;; PROFILE 2 
   p2 = threeG_param_2[*, itag]
   p2[6] = 0.0d0
   p2[3] = p2[3]+1.0d0 ;; correcting impact of decentering
   prof2 = p2[0]*exp(-(r0-p2[6])^2/2.0/((p2[3])*!fwhm2sigma)^2) + $
           p2[1]*exp(-(r0-p2[6])^2/2.0/(p2[4]*!fwhm2sigma)^2) + $
           p2[2]*exp(-(r0-p2[6])^2/2.0/(p2[5]*!fwhm2sigma)^2)
   prof2 = prof2/prof2[0]
   hyb_prof2 = (1.0d0-eamp[2, itag]-eamp[3, itag])*prof2 + $
               eamp[2,itag]*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2) + $
               eamp[3,itag]*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)
   
   om_mb = 2.0d0*!dpi*(p2[3]*!fwhm2sigma)^2
   om_mb_prof2[itag, iscan] = om_mb
   om_tot = total(prof2[wr]*2.0d0*!dpi*r0[wr]*dr0)
   om_tot_hyb = total(hyb_prof2*2.0d0*!dpi*r0*dr0)
   om_tot_4pi = om_tot_hyb + om_frss[itag]
   om_tot_prof2[itag,0,iscan] = om_tot
   om_tot_prof2[itag,1,iscan] = om_tot_hyb
   om_tot_prof2[itag,2,iscan] = om_tot_4pi
   be_prof2[itag,0,iscan] = om_mb/om_tot
   be_prof2[itag,1,iscan] = om_mb/om_tot_hyb
   be_prof2[itag,2,iscan] = om_mb/om_tot_4pi

   ;;if itag gt 2 then print, scan_list[iscan], ', ', sources[iscan], p1, p2
   
   
   
   ;;
   ;; Map
   ;;---------------------------------------
   p3 = mainbeam_param[*, itag]
   ;;p3[6] = 0.0d0 ;; tilt
   ;;p3[0] = 0.0d0 ;; piediestal
   ;;map = nika_gauss2(xmap, ymap, p3)
   ;;xx =  cos(p3[6])*(xmap-p3[4]) + sin(p3[6])*(ymap-p3[5])
   ;;yy = -sin(p3[6])*(xmap-p3[4]) + cos(p3[6])*(ymap-p3[5])
   ;;u = (xx/p3[2])^2 + (yy/p3[3])^2
   ;;mask = u LT 100
   ;;f = p3[0] + p3[1] * exp(-0.5D * u)
   ;;mask = 0
   ;;flux3 = total(map*dx*dy)
   ;;flux3 = 2.0d0*!dpi*(p3[2]*p3[3])*p3[1]
   print, ''
   print, scan_list[iscan], ', ',sqrt(p3[2]*p3[3])/!fwhm2sigma, fwhm[itag], p1[3]
   fwhmtab[itag, 0, iscan] = sqrt(p3[2]*p3[3])/!fwhm2sigma
   fwhmtab[itag, 1, iscan] = fwhm[itag]
   fwhmtab[itag, 2, iscan] = p1[3]
   
   
   om_mb = 2.0d0*!dpi*(p3[2]*p3[3])
   if itag eq 3 then om_mb = 2.0d0*!dpi*((fwhm[itag]-0.2)*!fwhm2sigma)^2
   pm = measured_profile[*, itag]
   pm = [p3[1], pm] ;; add the central point
   rm = measured_profile_radius[*, itag]
   rm = [0.0d0, rm] ;; add the central point
   prof3 = interpol(pm, rm, r0, /quadratic)
   prof3 = prof3/p3[1]
   wn = where(prof3 lt 0.0d0)
   meas_rmax = max(rm)
   ws = where(r0 gt meas_rmax)
   rprof3 = prof3
   rprof3[wn] = 0.0d0 ;; avoid strong filtering effect
   rprof3[ws] = 0.0d0 ;; avoid interpolation artefacts
   hyb_prof3 = (1.0d0-eamp[2, itag]-eamp[3, itag])*rprof3 + $
               eamp[2,itag]*exp(-(r0)^2/2.0/(efwhm[2, itag]*!fwhm2sigma)^2) + $
               eamp[3,itag]*exp(-(r0)^2/2.0/(efwhm[3, itag]*!fwhm2sigma)^2)
   
   om_tot = total(prof3[wr]*2.0d0*!dpi*r0[wr]*dr0)
   om_tot_hyb = total(hyb_prof3*2.0d0*!dpi*r0*dr0)
   om_tot_4pi = om_tot_hyb + om_frss[itag]
   om_tot_prof3[itag,0,iscan] = om_tot
   om_tot_prof3[itag,1,iscan] = om_tot_hyb
   om_tot_prof3[itag,2,iscan] = om_tot_4pi
   be_prof3[itag,0,iscan] = om_mb/om_tot
   be_prof3[itag,1,iscan] = om_mb/om_tot_hyb
   be_prof3[itag,2,iscan] = om_mb/om_tot_4pi

   om_tot_map[itag,*,iscan] = om_tot_prof3[itag,*,iscan]
   be_map[itag,*,iscan]     = be_prof3[itag,*,iscan]
   om_mb_map[itag, iscan]   = om_mb
   
   if itag lt 3 then begin
      om_tot_prof[itag,*,iscan]  = om_tot_prof1[itag,*,iscan]
      be_prof[itag,*,iscan]      = be_prof1[itag,*,iscan]
      om_mb_prof[itag,iscan]     = om_mb_prof1[itag,iscan]
   endif else begin
      om_tot_prof[itag,*,iscan] = om_tot_prof2[itag,*,iscan]
      be_prof[itag,*,iscan]     = be_prof2[itag,*,iscan]
      om_mb_prof[itag,iscan]    = om_mb_prof2[itag,iscan]
   endelse


   if details gt 0 then begin
      ;; search for fit failures
      ;;if ((p1[0] lt 0.0) or (p1[1] lt 0.0) or (p1[2] lt -1d-2) or
      ;;(p1[5] lt p1[4]) or (p1[5] gt 1000.0)) then begin
      ;;if ((p1[0] lt 0.0) or (p1[1] lt 0.0) or (p1[2] lt -1d-2) or (p1[5] lt p1[4])) then begin
      ;;   print,'3G LP fit failure for ', scan_list[iscan]
      ;;   ;;stop
      ;;   om_tot_prof[itag,*,iscan] = om_tot_prof2[itag,*,iscan]
      ;;   be_prof[itag,*,iscan] = be_prof2[itag,*,iscan]
      
      
      wind, 1, 1, xsize = 700, ysize = 500, /free
      plot, r0, hyb_prof1, /xlog , xr=[r0[1], max(r0)], /xs, /nodata, /ylog, yr=[1.0d-6, 1.1]
      oplot, r0, hyb_prof1, col=90
      oplot, r0, hyb_prof2, col=250
      oplot, r0, hyb_prof3, col=50
      legendastro, ['P1', 'P2', 'P3'], textcolor=[90, 250, 50], box=0, /right
      xyouts, 1, 10, string(scan_list[iscan])
      
      print,''
      print,tags[itag]
      print, 'Om_tot M1: ',reform(om_tot_prof1(itag, *, iscan))
      print, 'Om_tot M2: ',reform(om_tot_prof2(itag, *, iscan))
      print, 'Om_tot M3: ',reform(om_tot_prof3(itag, *, iscan))
      print, '------'
      print, 'B.E. M1: ',reform(be_prof1(itag, *, iscan))
      print, 'B.E. M2: ',reform(be_prof2(itag, *, iscan))
      print, 'B.E. M3: ',reform(be_prof3(itag, *, iscan))
      
      print, "p1 = ", p1
      print, "p2 = ", p2
      ;;ans = 1
                                ;print, 'prof 1 OK ?'
                                ;read, ans
                                ;if long(ans) le 1 then begin
                                ;   om_tot_prof[itag,*,iscan] = om_tot_prof1[itag,*,iscan]
                                ;   be_prof[itag,*,iscan] = be_prof1[itag,*,iscan]
                                ;endif else begin
                                ;   om_tot_prof[itag,*,iscan] = om_tot_prof2[itag,*,iscan]
                                ;   be_prof[itag,*,iscan] = be_prof2[itag,*,iscan]
                                ;endelse
      
                                ;stop
   endif
      
   
endfor ;; itag

endfor ;; iscan


;;  GATHERING EVERYTHING
;;______________________________________________________

;; FISRT INDEX  = [A1, A3, 1mm, 2mm]
;; SECOND INDEX = [90, hyb, tot]
;; THIRD INDEX  = methods

methods = ['Prof-3G', 'Prof-1G', 'Map-based', 'Combined']

avg_om_tot     = dblarr(4, 3, 4)
avg_sig_om_tot = dblarr(4, 3, 4)
avg_be         = dblarr(4, 3, 4)
avg_sig_be     = dblarr(4, 3, 4)

coeff_EB_error  = [0.0d0, 1.0d0, 1.0d0]
coeff_FSL_error = [0.0d0, 0.0d0, 1.0d0]

for itag = 0, 3 do begin
   
   ;; removing prof3G fit failures
   if itag le 2 then w=w_11 else w=w_22

   for mm = 0, 2 do begin
      ;; prof 3G
      ;;-------------------------------------------------------------------
      avg_om_tot(itag, mm, 0)     = mean(om_tot_prof(itag, mm, w))
      ;; propagation des erreurs sur chaque contribution en quadrature
      sig_om_90 = stddev(om_tot_prof(itag, 0, w))
      avg_sig_om_tot(itag, mm, 0) = sqrt( sig_om_90^2 + $
                                    (coeff_EB_error[mm]*sig_om_eb[itag])^2 + $
                                    (coeff_FSL_error[mm]*sig_om_fsl[itag])^2)
      ;;
      avg_be(itag, mm, 0)         = mean(be_prof(itag, mm, w))
      ;; method 1 (rewriting BE as a function of BE_90)
      avg_sig_be(itag, mm, 0)     = stddev(be_prof(itag, mm, w)) + $
                                    coeff_EB_error[mm]*sig_om_eb[itag]/avg_om_tot(itag, mm, 0)*avg_be(itag, mm, 0) +$
                                    coeff_FSL_error[mm]*sig_om_fsl[itag]/avg_om_tot(itag, mm, 0)*avg_be(itag, mm, 0)
      ;; methode 2
       avg_om_mb     = mean(om_mb_prof(itag, w))
       avg_sig_om_mb = stddev(om_mb_prof(itag, w))
       avg_sig_be(itag, mm, 0)     = avg_be(itag, mm, 0)*sqrt((avg_sig_om_mb/avg_om_mb)^2 + $
                                                              (avg_sig_om_tot(itag, mm, 0)/avg_om_tot(itag, mm, 0))^2) 
       ;; method 3
      ;avg_sig_be(itag, mm, 0)     = stddev(be_prof(itag, mm, w)) + $
      ;                              avg_be(itag, mm, 0)/avg_om_tot(itag, mm, 0)*$
      ;                              sqrt((coeff_EB_error[mm]*sig_om_eb[itag])^2 +$
      ;                                   (coeff_FSL_error[mm]*sig_om_fsl[itag])^2)
      ;; map
      ;;-------------------------------------------------------------------
      avg_om_tot(itag, mm, 2)     = mean(om_tot_map(itag, mm, *))
      sig_om_90                   = stddev(om_tot_map(itag, 0, w))
      avg_sig_om_tot(itag, mm, 2) = sqrt(sig_om_90^2 + $
                                         (coeff_EB_error[mm]*sig_om_eb[itag])^2 + $
                                         (coeff_FSL_error[mm]*sig_om_fsl[itag])^2)
      ;;
      avg_be(itag, mm, 2)         = mean(be_map(itag, mm, *))
      ;; methode 1
      avg_sig_be(itag, mm, 2)     = stddev(be_map(itag, mm, *))+ $
                                    coeff_EB_error[mm]*sig_om_eb[itag]/avg_om_tot(itag, mm, 2)*avg_be(itag, mm, 2) +$
                                    coeff_FSL_error[mm]*sig_om_fsl[itag]/avg_om_tot(itag, mm, 2)*avg_be(itag, mm, 2)
      ;; methode 2
       avg_om_mb     = mean(om_mb_map(itag, *))
       avg_sig_om_mb = stddev(om_mb_map(itag, *))
       avg_sig_be(itag, mm, 2)  = avg_be(itag, mm, 2)*sqrt((avg_sig_om_mb/avg_om_mb)^2 + $
                                                       (avg_sig_om_tot(itag, mm, 2)/avg_om_tot(itag, mm, 2))^2) 
       ;; methode 3
       ;avg_sig_be(itag, mm, 2)     = stddev(be_map(itag, mm, *))+ $
       ;                              avg_be(itag, mm, 2)/avg_om_tot(itag, mm, 2)*$
       ;                              sqrt((coeff_EB_error[mm]*sig_om_eb[itag])^2 +$
       ;                                   (coeff_FSL_error[mm]*sig_om_fsl[itag])^2)
      ;; prof 1G
      ;;-------------------------------------------------------------------
      avg_sig_om_tot(itag, mm, 1) = sqrt(sig_om_tot_jfl(itag, 0, 3)^2 + $
                                         (coeff_EB_error[mm]*sig_om_eb[itag])^2 + $
                                         (coeff_FSL_error[mm]*sig_om_fsl[itag])^2)
      ;;
      ;; methode 1
      avg_sig_be(itag, mm, 1)     = sig_be_jfl(itag, mm, 3)+ $
                                    coeff_EB_error[mm]*sig_om_eb[itag]/om_tot_jfl(itag, mm, 3)*be_jfl(itag, mm, 3) + $
                                    coeff_FSL_error[mm]*sig_om_fsl[itag]/om_tot_jfl(itag, mm, 3)*be_jfl(itag, mm, 3)
      ;; methode 2
      avg_sig_be(itag, mm, 1)     = be_jfl(itag, mm, 3)*sqrt((sig_om_mb_jfl[itag]/om_mb_jfl[itag])^2 + $
                                                         (avg_sig_om_tot(itag, mm, 1)/om_tot_jfl(itag, mm, 3))^2)
       ;; methode 3
      ;avg_sig_be(itag, mm, 1)     = sig_be_jfl(itag, mm, 3)+ $
      ;                              be_jfl(itag, mm, 3)/om_tot_jfl(itag, mm, 3)*$
      ;                              sqrt((coeff_EB_error[mm]*sig_om_eb[itag])^2 + $
      ;                                   (coeff_FSL_error[mm]*sig_om_fsl[itag])^2)

      
   endfor
   avg_om_tot(itag, *, 1)     = om_tot_jfl(itag, *, 3)
   avg_be(itag, *, 1)         = be_jfl(itag, *, 3)
      
   ;; combined
   for mm = 0, 2 do begin
      avg_om_tot(itag, mm, 3) = total(avg_om_tot(itag, mm, 0:2)/avg_sig_om_tot(itag,mm,0:2)^2)/total(1.0d0/avg_sig_om_tot(itag,mm,0:2)^2)
      avg_be(itag, mm, 3)     = total(avg_be(itag, mm, 0:2)/avg_sig_be(itag,mm,0:2)^2)/total(1.0d0/avg_sig_be(itag,mm,0:2)^2)
      ;;
      ;; Uncertainties on Om_tot
      max = max(avg_om_tot(itag, mm, 0:2), imax)
      min = min(avg_om_tot(itag, mm, 0:2), imin)
      ;; methode 1
      avg_sig_om_tot(itag, mm, 3) = 0.1*(max+5.*avg_sig_om_tot(itag, mm, imax) - (min-5.*avg_sig_om_tot(itag, mm, imin)))
      ;; methode 2
      avg_sig_om_tot(itag, mm, 3) = sqrt(1.0d0/total(1.0d0/avg_sig_om_tot(itag,mm,0:2)^2))
      ;; methode 3
      avg_sig_om_tot(itag, mm, 3) = sqrt(1./3.0d0*total(avg_sig_om_tot(itag,mm,0:2)^2))
      ;;
      ;; Uncertainties on BE
      max = max(avg_be(itag, mm, 0:2), imax)
      min = min(avg_be(itag, mm, 0:2), imin)
      ;; methode 1 
      avg_sig_be(itag, mm, 3) = 0.1*(max+5.*avg_sig_be(itag, mm,imax) - (min-5.*avg_sig_be(itag, mm, imin)))
      ;; methode 2
      avg_sig_be(itag, mm, 3) = sqrt(1.d0/total(1.0d0/avg_sig_be(itag,mm,0:2)^2))
      ;; methode 3
      avg_sig_be(itag, mm, 3) = sqrt(1./3.0d0*total(avg_sig_be(itag,mm,0:2)^2))
   endfor
endfor


   
for itag = 0, 3 do begin
   if itag le 2 then w=w_11 else w=w_22
   print,''
   print, '     |   Om (r<90)  |  Om (hyb)  |  Om  (4pi)   |  BE (r<90)    |  BE (hyb)   |  BE (4pi)  |' 
   print,tags[itag]
   print, '------'
   print, 'Prof | ',median(om_tot_prof(itag, 0, w)), '+/-',strtrim(stddev(om_tot_prof(itag, 0, w)),2), '|', $
          median(om_tot_prof(itag, 1, w)), ' +/- ',strtrim(stddev(om_tot_prof(itag, 1, w)),2), '|', $
          median(om_tot_prof(itag, 2, w)), ' +/- ',strtrim(stddev(om_tot_prof(itag, 2, w)),2), '|', $
          median(be_prof(itag, 0, w)), ' +/- ',strtrim(stddev(be_prof(itag, 0, w)),2), '|', $
          median(be_prof(itag, 1, w)), ' +/- ',strtrim(stddev(be_prof(itag, 1, w)),2), '|', $
          median(be_prof(itag, 2, w)), ' +/- ',strtrim(stddev(be_prof(itag, 2, w)),2), '|'
   print, '------'
   print, 'Map: ',median(om_tot_map(itag, 0, *)), '+/- ',strtrim(stddev(om_tot_map(itag, 0, *)),2), '|', $
          median(om_tot_map(itag, 1, *)), ' +/- ',strtrim(stddev(om_tot_map(itag, 1, *)),2), '|', $
          median(om_tot_map(itag, 2, *)), ' +/- ',strtrim(stddev(om_tot_map(itag, 2, *)),2), '|', $
          median(be_map(itag, 0, *)), ' +/- ',strtrim(stddev(be_map(itag, 0, *)),2), '|', $
          median(be_map(itag, 1, *)), ' +/- ',strtrim(stddev(be_map(itag, 1, *)),2), '|', $
          median(be_map(itag, 2, *)), ' +/- ',strtrim(stddev(be_map(itag, 2, *)),2), '|'
endfor

;; arrondi
for itag = 0, 3 do begin
   print,''
   print, '     |    Om (r<90)  |   Om (hyb)   |   Om  (4pi)    |   BE (r<90)     |   BE (hyb)    |   BE (4pi)  |' 
   print,tags[itag]
   for mm = 0, 3 do begin
      print, '------'
      print, methods[mm], ' | ',string(avg_om_tot(itag, 0, mm),'(f5.1)'), $
             ' +/- ',strtrim(string(avg_sig_om_tot(itag, 0, mm),'(f5.1)'),2), ' | ', $
             string(avg_om_tot(itag, 1, mm),'(f5.1)'), $
             ' +/- ',strtrim(string(avg_sig_om_tot(itag, 1, mm),'(f5.1)'),2), ' | ', $
             string(avg_om_tot(itag, 2, mm),'(f5.1)'), $
             ' +/- ',strtrim(string(avg_sig_om_tot(itag, 2, mm),'(f5.1)'),2), ' | ', $
             string(avg_be(itag, 0, mm),'(f4.2)'), $
             ' +/- ',strtrim(string(avg_sig_be(itag, 0, mm),'(f5.3)'),2), ' | ', $
             string(avg_be(itag, 1, mm),'(f4.2)'), $
             ' +/- ',strtrim(string(avg_sig_be(itag, 1, mm),'(f5.3)'),2), ' | ', $
             string(avg_be(itag, 2, mm),'(f4.2)'), $
             ' +/- ',strtrim(string(avg_sig_be(itag, 2, mm),'(f5.3)'),2), ' | '
   endfor
   
endfor

;; Reference beam efficiencies
fwhm0 = [12.5d0, 12.5d0, 12.5d0, 18.5d0]
om0 = 2.0d0*!dpi*(fwhm0*!fwhm2sigma)^2
for itag = 0, 3 do begin
   print,''
   print, '     |  BE_0 (r<90)     |   BE_0 (hyb)    |   BE_0 (4pi)  |' 
   print,tags[itag]
   for mm = 0, 3 do begin
      print, '------'
      print, methods[mm], ' | ',string(om0[itag]/avg_om_tot(itag, 0, mm),'(f5.3)'), $
             ' +/- ',strtrim(string(avg_sig_om_tot(itag, 0, mm)*om0[itag]/avg_om_tot(itag, 0, mm)^2,'(f5.3)'),2), ' | ', $
             string(om0[itag]/avg_om_tot(itag, 1, mm),'(f5.3)'), $
             ' +/- ',strtrim(string(avg_sig_om_tot(itag, 1, mm)*om0[itag]/avg_om_tot(itag, 1, mm)^2,'(f5.3)'),2), ' | ', $
             string(om0[itag]/avg_om_tot(itag, 2, mm),'(f5.3)'), $
             ' +/- ',strtrim(string(avg_sig_om_tot(itag, 2, mm)*om0[itag]/avg_om_tot(itag, 2, mm)^2,'(f5.3)'),2), ' | '
             
   endfor
   
endfor
stop

;;________________________________________________________________________________________



end
