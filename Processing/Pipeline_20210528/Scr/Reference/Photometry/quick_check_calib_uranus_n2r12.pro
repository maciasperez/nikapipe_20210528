
scan_list = ['20171026s3']


method = 'common_mode_kids_out'
source = 'Uranus'

nk_scan2run, scan_list[0]

input_kidpar_file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/kidpar_recal_NoTauCorrect0.fits'
method = 'common_mode_kids_out'
source = 'Uranus'
reset = 1
project_dir = '/home/macias/NIKA/Plots/Run25/TestCalibUranus/'
scan_list =['20171025s41','20171025s42','20171027s49','20171026s3']
nscans = n_elements(scan_list)
NoTauCorrect = 0

nproc = 4
split_for, 0, nscans-1, $
           commands=['obs_nk_ps, i, scan_list, project_dir, '+$
                     'method, source, input_kidpar_file=input_kidpar_file, '+$
                           'reset=reset, NoTauCorrect=NoTauCorrect'], $
           nsplit=nproc, $
           varnames=['scan_list', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                           'reset', 'NoTauCorrect']
;; obsnk_ps, 0, scan_list,  project_dir,method, source, input_kidpar_file = input_kidpar_file,  NoTauCorrect=0
;; obs_nk_ps, 1, scan_list,  project_dir,method, source, input_kidpar_file = input_kidpar_file,  NoTauCorrect=0
;; obs_nk_ps, 2, scan_list,  project_dir,method, source, input_kidpar_file = input_kidpar_file,  NoTauCorrect=0
;; obs_nk_ps, 3, scan_list,  project_dir,method, source, input_kidpar_file = input_kidpar_file,  NoTauCorrect=0


uranus_flux_1mm = dblarr(nscans)
uranus_flux_2mm = dblarr(nscans)

for iscan=0,nscans-1 do  begin
   restore, project_dir+'v_1/'+scan_list[iscan]+'/results.save'
   uranus_flux_1mm[iscan] = info1.result_flux_i_1mm
   uranus_flux_2mm[iscan] = info1.result_flux_i_2mm
endfor

; Mars
project_dir = '/home/macias/NIKA/Plots/Run25/TestCalibMars/'
scan_list = ['20171020s65', '20171020s72', '20171020s93', '20171021s167', '20171022s158', '20171023s101']
nscans = n_elements(scan_list)
method = 'common_mode_kids_out'
source = 'Mars'
reset =1
NoTauCorrect = 0
input_kidpar_file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/kidpar_recal_NoTauCorrect0.fits'
nproc = 6
split_for, 0, nscans-1, $
           commands=['obs_nk_ps, i, scan_list, project_dir, '+$
                     'method, source, input_kidpar_file=input_kidpar_file, '+$
                           'reset=reset, NoTauCorrect=NoTauCorrect'], $
           nsplit=nproc, $
           varnames=['scan_list', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                           'reset', 'NoTauCorrect']

mars_flux_1mm = dblarr(nscans)
mars_flux_2mm = dblarr(nscans)
tau1mm = dblarr(nscans)
tau2mm = dblarr(nscans)
tau225 = dblarr(nscans)

for iscan=0,nscans-1 do  begin
   restore, project_dir+'v_1/'+scan_list[iscan]+'/results.save'
   mars_flux_1mm[iscan] = info1.result_flux_i_1mm
   mars_flux_2mm[iscan] = info1.result_flux_i_2mm
   tau1mm[iscan] = info1.result_tau_1mm
   tau2mm[iscan] = info1.result_tau_2mm
   tau225[iscan] = info1.tau225
endfor


;; MWC349
project_dir = '/home/macias/NIKA/Plots/Run25/TestCalibMWC349/'
scan_list = ['20171024s178', '20171024s179', '20171024s182', '20171024s189', '20171024s190', '20171024s194', '20171024s202', '20171024s220', '20171027s289', '20171027s290']
nscans = n_elements(scan_list)
method = 'common_mode_kids_out'
source = 'MWC349'
reset =1
NoTauCorrect = 0
input_kidpar_file = '/home/macias/NIKA/Processing/Labtools/JM/NIKA2/RUN25/kidpar_recal_NoTauCorrect0.fits'
nproc = 6
split_for, 0, nscans-1, $
           commands=['obs_nk_ps, i, scan_list, project_dir, '+$
                     'method, source, input_kidpar_file=input_kidpar_file, '+$
                           'reset=reset, NoTauCorrect=NoTauCorrect'], $
           nsplit=nproc, $
           varnames=['scan_list', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                           'reset', 'NoTauCorrect']
mwc349_flux_1mm = dblarr(nscans)
mwc349_flux_2mm = dblarr(nscans)
tau1mm = dblarr(nscans)
tau2mm = dblarr(nscans)
tau225 = dblarr(nscans)
elev = dblarr(nscans)

for iscan=0,nscans-1 do  begin
   restore, project_dir+'v_1/'+scan_list[iscan]+'/results.save'
   mwc349_flux_1mm[iscan] = info1.result_flux_i_1mm
   mwc349_flux_2mm[iscan] = info1.result_flux_i_2mm
   tau1mm[iscan] = info1.result_tau_1mm
   tau2mm[iscan] = info1.result_tau_2mm
   tau225[iscan] = info1.tau225
   elev[iscan] = info1.elev
endfor
