;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_latex_toi_report
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

pro nk_latex_toi_report, param, scan_list, project_dir=project_dir, plot_dir=plot_dir

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_latex_toi_report, param, scan_list"
   return
endif

if not keyword_set(project_dir) then project_dir = param.project_dir
if not keyword_set(plot_dir) then plot_dir = param.plot_dir

nscans = n_elements( scan_list)

get_lun, tex_unit
if nscans eq 1 then suffix = '' else suffix = '_nsc'+strtrim(nscans, 2)
filin = project_dir+'/toi_report_'+strtrim(str_replace(param.source," ", "_"),2) +$
        '_'+strtrim( scan_list[0], 2)+ suffix+ '.tex'
;;;filin = project_dir+"/project_report_"+strtrim(param.source,2)+".tex"
if not keyword_set(param.silent) then print, 'write '+ filin
openw,  tex_unit, filin
;; printf, tex_unit, "\documentclass[a4paper,10pt]{report}"
printf, tex_unit, "\documentclass[a4paper,10pt]{article}"
printf, tex_unit, "\usepackage{epsfig}"
printf, tex_unit, "\usepackage{latexsym}"
printf, tex_unit, "\usepackage{graphicx}"
printf, tex_unit, "\usepackage{amsfonts}"
printf, tex_unit, "\usepackage{amsmath}"
printf, tex_unit, "\usepackage{xcolor}"
printf, tex_unit, "\topmargin=-1cm"
printf, tex_unit, "\oddsidemargin=-1cm"
printf, tex_unit, "\evensidemargin=-1cm"
printf, tex_unit, "\textwidth=17cm"
printf, tex_unit, "\textheight=28cm"
printf, tex_unit, "%\textheight=25cm"
printf, tex_unit, "\raggedbottom"
printf, tex_unit, "\sloppy"

a = strsplit( param.source, "_", /extract)
if n_elements(a) eq 2 then source_tex_name = a[0]+"\_"+a[1] else source_tex_name = param.source

printf, tex_unit, "\title{"+strupcase(source_tex_name)+"}"
printf, tex_unit, "\author{NIKA2 IDL Pipeline}"

printf, tex_unit, "\begin{document}"
printf, tex_unit, "\maketitle"

;;--------------------------------------------------------------------------
;; 1 page per scan
nscans = n_elements(scan_list)
scale = 0.35
for iscan=0, nscans-1 do begin

   scan = strtrim(scan_list[iscan])
   init_figure = 0

   file_list = plot_dir+"/"+['speed_flag_', 'toi_decor_1_', 'toi_decor_2_', 'power_spec_']+$
               scan+".eps"

   nfiles = n_elements(file_list)
   for i=0, nfiles-1 do begin
      file = file_list[i]
      if file_test(file) then begin

         if init_figure eq 0 then begin
            printf, tex_unit, "\section{Scan "+strtrim(scan_list[iscan],2)+"}"
            printf, tex_unit, "\begin{figure}[hhh]"
            printf, tex_unit, "\begin{center}"
            init_figure++
         endif
         printf, tex_unit, "\includegraphics[clip, angle=0, scale = "+strtrim(scale,2)+"]{"+file+"}"
      endif
   endfor

   if init_figure ne 0 then begin
;;       caption = "Brightness maps."
;;       printf, tex_unit, "\caption{"+caption+"}"
      printf, tex_unit, "\end{center}"
      printf, tex_unit, "\end{figure}"
      printf, tex_unit, "\clearpage"
   endif
endfor

printf, tex_unit, "\end{document}"
close, tex_unit
free_lun, tex_unit

ext=''
if param.silent ne 0 then ext=' > /dev/null'

if param.latex_pdf eq 1 then begin
   if param.silent eq 0 then message, /info, "Compiling latex report..."
   spawn, "latex -halt-on-error "+filin+ext
   spawn, "latex -halt-on-error "+filin+ext
   dvi_file = "toi_report_"+strtrim(str_replace(param.source," ", "_"),2)+$
              '_'+strtrim( scan_list[0], 2)+ suffix+".dvi"
   if file_test(dvi_file) then spawn, "dvipdf "+dvi_file+ext
   spawn, "\mv toi_report_"+strtrim(str_replace(param.source," ", "_"),2)+$
          '_'+strtrim( scan_list[0], 2)+ suffix+".pdf "+project_dir+"/."
endif

;; if param.clean_tex eq 1 then begin
;;    spawn, "rm -f "+plot_dir+"/*"
;;    spawn, "rm -f *tex *aux *toc *log *dvi"
;; endif

end
