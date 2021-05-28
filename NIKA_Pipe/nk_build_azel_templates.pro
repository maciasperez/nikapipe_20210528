
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_build_azel_templates
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_build_azel_templates, param, info, index, templates
; 
; PURPOSE: 
;        Generates the templates of systematics correlated to azimuth or
;        elevation in Lissajous mode that will be used for later decorrelation
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - index: the sample number to be used
;        - templates: the array of cos, sin, cos(2*..) elevation and azimuth templates
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - July 24th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_build_azel_templates, param, info, index, templates

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

templates = dblarr( 4*param.n_harmonics_azel, n_elements(index))

for i=1, param.n_harmonics_azel do begin
   templates[ (i-1)*2*param.n_harmonics_azel + 0,*] = sin( i*info.liss_freq_az*index)
   templates[ (i-1)*2*param.n_harmonics_azel + 1,*] = cos( i*info.liss_freq_az*index)
   templates[ (i-1)*2*param.n_harmonics_azel + 2,*] = sin( i*info.liss_freq_el*index)
   templates[ (i-1)*2*param.n_harmonics_azel + 3,*] = cos( i*info.liss_freq_el*index)
endfor

end
