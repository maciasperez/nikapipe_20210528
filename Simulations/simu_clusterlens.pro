;+
; PURPOSE:
;   generate a CMB cluster lensed map in an ideal case
; ASSUMPTION:
;   - spherical isolated cluster with a NFW density profile  
;   - unlensed cmb is a pure gradient (at this stage)
;   - no LSS lensing
; VERSION:
;  first created by LP in 2013, May 17th 
;-


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; MAIN
;___________________________________________________________

function simu_clusterlens, clusterpar, mappar


; Fiducial Cosmology
;_________________________________________________________________________
; - H0 = Hubble par.
; - Omega_b*h^2 = baryon physical density
; - Omega_{cdm}*h^2  = CDM physical density 
; - As = scalar ampli
; - ns = scalar index
; - tau = optical depth 
; - mnu = neutrino mass
;
; rem: on n'a pas besoin de As, ns et tau ici
;
; les valeurs par defaut sont issues du best-fit LambdaCDM6 de Planck
;--------------------------------------------
cosmo={H0:67.77,omb:0.022161,omc:0.11889,As:2.21381e-9,ns:0.9611,tau:0.0952,mnu:0.06}

; Parameters
;_________________________________________________________________________
; cluster
m200 = clusterpar.m_200
rs_kpc = clusterpar.rs ; rs = r200/c
z_cl = clusterpar.z
unlensclt_file = clusterpar.unlensclt_file
dopuregrad = not(clusterpar.cmbstockastic)
dodiff = clusterpar.cmbsubtraction

; map characteristic
sra=mappar.size_ra ; arcsec
sdec=mappar.size_dec ; arcsec
reso=mappar.reso ; arcsec

;; derived param.
rs = rs_kpc*1d-3
r200 = clusterlens_m2r(m200,200d0,z_cl,cosmo)
c200 = r200/rs 
if (sra ne sdec) then begin
   print,"on ne gere que les cartes carrées pour l'instant"
   stop
endif
angsize = sra/60d0  ; arcmin
pixsize = reso/60d0 ; arcmin

; deflection field
;__________________________________________________________________________________
; carte de x et de y en radians
;------------------------------
nx=angsize/pixsize
vecy=(dindgen(nx+1)*pixsize - 0.5*angsize)*!dpi/180d0/60d0
y=(dblarr(nx+1)+1d0)#vecy
x=transpose(y)

; calcul de la deflexion par l'amas
;-----------------------------------
nfw_deflexion, x, y, m200, c200, z_cl, cosmo, dx, dy

; unlensed CMB
;__________________________________________________________________________________

if dopuregrad then begin
   lmax=10000
   Ty = clusterlens_cl2rmsgrad(unlensclt_file, lmax, 1d6)
   tildeTmap = clusterlens_gradtmap(Ty, angsize, pixsize)
endif else begin
   print,"---> cmb generation not yet implemented..."
   print,"---> clusterpar.cmbstockastic should be set to false."
   stop
endelse

; lensed CMB
;__________________________________________________________________________________

; routine tres basique a modifier
clusterlensing, Ty, angsize, pixsize, dy, tmap


if dodiff then map = tmap - tildetmap else map=tmap 

return, map

end
