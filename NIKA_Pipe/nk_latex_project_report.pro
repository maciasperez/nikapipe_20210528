;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_latex_project_report
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_latex_project_report, param
; 
; PURPOSE: 
;        Prepares a LaTeX file to gather all plots for this project, one page
;        per scan.
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - param.project_dir+'/project_report.tex'
;        - tex_unit : file unit to be used in the calling code (printf, tex_unit, blabla)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 5th, 2014, NP
;        - Sept. 14th, NP: added pdf compilation and compliance with both
;          .ps/.eps and .png plots.
;        - Sept. 25th, 2015: NP, back to .ps only for convenience and quality.
;-

pro nk_latex_project_report, param, scan_list, project_dir=project_dir, plot_dir=plot_dir

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_latex_project_report, param, scan_list, project_dir=project_dir"
   return
endif

nk_latex_maps_report, param, scan_list, project_dir=project_dir, plot_dir=plot_dir
nk_latex_toi_report,  param, scan_list, project_dir=project_dir, plot_dir=plot_dir

end
