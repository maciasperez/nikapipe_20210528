;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_liss_elev_templates
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Produces templates of cos/sin azimuth and elevation for
;        decorrelation in Lissajous mode
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - templates
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 19th, 2014: N. Ponthieu, R. Adam, F.-X. Desert
;-

pro nk_liss_elev_templates, param, info, data, kidpar, templates

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_liss_elev_templates, param, info, data, kidpar, templates"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(data)
index     = dindgen( nsn)
templates = dblarr(8,nsn)
templates[0,*] = sin(      info.liss_freq_az*index)
templates[1,*] = cos(      info.liss_freq_az*index)
templates[2,*] = sin(      info.liss_freq_el*index)
templates[3,*] = cos(      info.liss_freq_el*index)
templates[4,*] = sin( 2.d0*info.liss_freq_az*index)
templates[5,*] = cos( 2.d0*info.liss_freq_az*index)
templates[6,*] = sin( 2.d0*info.liss_freq_el*index)
templates[7,*] = cos( 2.d0*info.liss_freq_el*index)

end
