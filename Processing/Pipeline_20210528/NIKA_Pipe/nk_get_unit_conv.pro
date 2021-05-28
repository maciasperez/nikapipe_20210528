;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_get_unit_conv
;
; CATEGORY: 
;        initialization
;
; CALLING SEQUENCE:
;         nk_get_unit_conv, param
; 
; PURPOSE: 
;        Get the unit conversion coefficients from the bandpasses and
;        the beam
; 
; INPUT: 
;        - param: the parameter structure used in the reduction
; 
; OUTPUT: 
;        - param: the parameter structure used in the reduction filled
;          with the coefficients
; 
; KEYWORDS:
;        - MAKE_UNIT_CONV: set this keyword to save the coefficients
;          in a fit file
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 15/03/2014: creation
;-

pro nk_get_unit_conv, param, MAKE_UNIT_CONV=MAKE_UNIT_CONV

nscan = n_elements(param)

;;========== Define the files to be used
;; Init to last run values by default to provide place holders for lab tests
bandpass_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits'
beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best1mm.fits'
beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best2mm.fits'

if strmid(param.scan, 0, 6) eq '201211' then begin
   bandpass_file = !nika.soft_dir+'/Run5_pipeline/Calibration/BP/NIKA_bandpass_Run5.fits'
   beam_file1mm = !nika.soft_dir+'/Run5_pipeline/Calibration/Beam/NIKA_beam_Run5_best1mm.fits'
   beam_file2mm = !nika.soft_dir+'/Run5_pipeline/Calibration/Beam/NIKA_beam_Run5_best2mm.fits'
endif
if strmid(param.scan, 0, 6) eq '201306' then begin
   bandpass_file = !nika.soft_dir+'/Run6_pipeline/Calibration/BP/NIKA_bandpass_Run6.fits'
   beam_file1mm = !nika.soft_dir+'/Run6_pipeline/Calibration/Beam/NIKA_beam_Run6_best1mm.fits'
   beam_file2mm = !nika.soft_dir+'/Run6_pipeline/Calibration/Beam/NIKA_beam_Run6_best2mm.fits'
endif
if strmid(param.scan, 0, 6) eq '201311' then begin
   bandpass_file = !nika.soft_dir+'/RunCryo_pipeline/Calibration/BP/NIKA_bandpass_RunCryo.fits'
   beam_file1mm = !nika.soft_dir+'/RunCryo_pipeline/Calibration/Beam/NIKA_beam_RunCryo_best1mm.fits'
   beam_file2mm = !nika.soft_dir+'/RunCryo_pipeline/Calibration/Beam/NIKA_beam_RunCryo_best2mm.fits'
endif
if strmid(param.scan, 0, 6) eq '201401' then begin
   bandpass_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run7.fits'
   beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best1mm.fits'
   beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best2mm.fits'
endif
if strmid(param.scan, 0, 6) eq '201402' then begin
   bandpass_file = !nika.soft_dir+'/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits'
   beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best1mm.fits'
   beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best2mm.fits'
endif
;; begin LP
if strmid(param.scan, 0, 6) ge '201510' then begin
   bandpass_file = !nika.soft_dir+'/Pipeline/Calibration/BP/Transmission_2017_Jan_NIKA2_v1.fits'
   beam_file1mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best1mm.fits'
   beam_file2mm = !nika.soft_dir+'/Pipeline/Calibration/Beam/NIKA_beam_Run5_best2mm.fits'
endif
;; end LP

;;========== Get the coef from BP
nk_do_unit_conv, !nika.lambda[0], bandpass_file, $
                     Kcmb2Krj1mm, Ytsz2Kcmb1mm, Yksz2Kcmb1mm, $
                     colcor_dust1mm, colcor_radio1mm

nk_do_unit_conv, !nika.lambda[1], bandpass_file, $
                     Kcmb2Krj2mm, Ytsz2Kcmb2mm, Yksz2Kcmb2mm, $
                     colcor_dust2mm, colcor_radio2mm

;;========== Get the beam volume
beam_vol1mm = nika_pipe_measure_beam_volume(!nika.lambda[0], beam_file1mm)
beam_vol2mm = nika_pipe_measure_beam_volume(!nika.lambda[1], beam_file2mm)

;;========== Fill the parameters
param.KRJ2KCMB_1mm = 1.0/Kcmb2Krj1mm
param.KRJ2KCMB_2mm = 1.0/Kcmb2Krj2mm
param.KCMB2Y_1mm = 1.0/Ytsz2Kcmb1mm
param.KCMB2Y_2mm = 1.0/Ytsz2Kcmb2mm
param.JY2KRJ_1mm = 1.0/(beam_vol1mm*(!pi/3600/180)^2 * 2/(!nika.lambda[0]*1d-3)^2*!const.k * 1d26)
param.JY2KRJ_2mm = 1.0/(beam_vol2mm*(!pi/3600/180)^2 * 2/(!nika.lambda[1]*1d-3)^2*!const.k * 1d26)
param.y2Kcmb_1mm = Ytsz2Kcmb1mm
param.y2Kcmb_2mm = Ytsz2Kcmb2mm
param.Beam2Sr_1mm = beam_vol1mm*(!pi/180/3600)^2
param.Beam2Sr_2mm = beam_vol2mm*(!pi/180/3600)^2

end
