;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_latex_scan_report
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_latex_scan_report, param
; 
; PURPOSE: 
;        Prepares a LaTeX file to gather all plots produced for this scan
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - param.output_dir+'/scan_report.tex'
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 5th, 2014, NP
;-

pro nk_latex_scan_report, param

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_latex_scan_report, param"
   return
endif

spawn, "ls "+param.output_dir+"/*png", png_list

if png_list[0] ne '' then begin
   nplots = n_elements(png_list)

   get_lun, file_unit
   openw, file_unit, param.output_dir+"/scan_report.tex"
   printf, file_unit, "\documentclass[a4paper,10pt]{article}"
   printf, file_unit, "\usepackage{epsfig}"
   printf, file_unit, "\usepackage{latexsym}"
   printf, file_unit, "\usepackage{graphicx}"
   printf, file_unit, "\usepackage{amsfonts}"
   printf, file_unit, "\usepackage{amsmath}"
   printf, file_unit, "\usepackage{xcolor}"
   printf, file_unit, "%\topmargin=-3cm"
   printf, file_unit, "\topmargin=-1cm"
   printf, file_unit, "\oddsidemargin=-1cm"
   printf, file_unit, "\evensidemargin=-1cm"
   printf, file_unit, "\textwidth=17cm"
   printf, file_unit, "%\textheight=27cm"
   printf, file_unit, "\textheight=25cm"
   printf, file_unit, "\raggedbottom"
   printf, file_unit, "\sloppy"
   printf, file_unit, "\title{"+param.scan+"}"
   printf, file_unit, "%\author{The Authors}"
   printf, file_unit, "\begin{document}"
   printf, file_unit, "\maketitle"

   for i=0, nplots-1 do begin
      plot_name = file_basename( png_list[i])
      l = strlen( plot_name)
      ;; remove .png from plot_name
      plot_name = strmid( plot_name, 0, l-4)
      caption = str_replace( plot_name, "_", "-")
      printf, file_unit, "\begin{figure}"
      printf, file_unit, "\begin{center}"
      printf, file_unit, "\includegraphics[clip, angle=0, scale = 0.4]{"+plot_name+".png}"
      printf, file_unit, "\caption{"+caption+"}"
      printf, file_unit, "\end{center}"
      printf, file_unit, "\end{figure}"
   endfor
   printf, file_unit, "\end{document}"
   close, file_unit
   free_lun, file_unit
endif


end
