
; spawn, "grep ':' nk_default_param.pro > param_list.txt"

;; Read all pipeline parameters
readcol, 'param_list.txt', tag, format='A', comment=';'
ntags = n_elements(tag)
tag_name = strarr(ntags)
for i=0, ntags-1 do begin
   r = strsplit(tag[i], ':', /extract)
   tag_name[i] = r[0]
endfor

;; List all routines in Pipeline directory
spawn, "find $PIPE/NIKA_Pipe -name '*.pro' -print", routine_list

;; Look for parameters in the routines
nroutines = n_elements(routine_list)
param_routine_list = strarr( ntags, nroutines)

message, /info, "fix me:"
ntags = 60 ; to test
stop

for i=0, ntags-1 do begin
   percent_status, i, ntags, 10
   p=0
   for j=0, nroutines-1 do begin
      do_list = 0
      spawn, "grep -i "+tag_name[i]+" "+routine_list[j]+" | grep -i param", junk
      if strlen(junk[0]) ne 0 then begin
         param_routine_list[i,p] = file_basename( routine_list[j])
         p++
      endif
   endfor
endfor

;; Output result
for i=0, ntags-1 do begin
   p=0
   print, ""
   print, tag_name[i]+":"
   while strlen( param_routine_list[i,p]) ne 0 do begin
      print, strtrim(param_routine_list[i,p],2)
      p++
   endwhile
   if p eq 0 then print, tag_name[i]+" not used ?!"
endfor

openw, 1, "params.tex"
printf, 1, "\hline"
for i=0, ntags-1 do begin
   w = where( strlen(param_routine_list[i,*]) ne 0, nw)
   if nw ne 0 then begin
      printf, 1, "\hline"
      printf, 1, strtrim(tag_name[i],2)+" & \\"
      str = strtrim(param_routine_list[i,w[0]],2)
      if nw eq 1 then begin
         printf, 1, " & "+str+"\\"
      endif else begin
         for j=1, nw-1 do begin
            str += strtrim(param_routine_list[i,w[j]],2)+", "
            if ((j mod 3) eq 0) or (j eq nw-1) then begin
               printf, 1, " & "+str+"\\"
               str = ''
            endif
         endfor
      endelse
   endif
endfor

openw, 1, "params.tex"
printf, 1, "\documentclass[a4paper,10pt]{article}"
printf, 1, "\usepackage{epsfig}"
printf, 1, "\usepackage{latexsym}"
printf, 1, "\usepackage{graphicx}"
printf, 1, "\usepackage{amsfonts}"
printf, 1, "\usepackage{amsmath}"
printf, 1, "\usepackage{xcolor}"
printf, 1, "\topmargin=-1cm"
printf, 1, "\oddsidemargin=-1cm"
printf, 1, "\evensidemargin=-1cm"
printf, 1, "\textwidth=17cm"
printf, 1, "\textheight=25cm"
printf, 1, "\raggedbottom"
printf, 1, "\sloppy"
printf, 1, "\title{Pipeline parameters and associated routines}"
printf, 1, "\author{NP}"
printf, 1, "\begin{document}"
printf, 1, "\begin{table}"
printf, 1, "\begin{center}"
printf, 1, "\begin{tabular}{|l|l|}"
printf, 1, "\hline"
for i=0, ntags-1 do begin
   w = where( strlen(param_routine_list[i,*]) ne 0, nw)
   if nw ne 0 then begin
      printf, 1, "\hline"
      printf, 1, strtrim(tag_name[i],2)+" & \\"
      str = strtrim(param_routine_list[i,w[0]],2)+", "
      if nw eq 1 then begin
         printf, 1, " & "+str+"\\"
      endif else begin
         for j=1, nw-1 do begin
            str += strtrim(param_routine_list[i,w[j]],2)+", "
            if ((j mod 2) eq 0) or (j eq nw-1) then begin
               printf, 1, " & "+str+"\\"
               str = ''
            endif
         endfor
      endelse
   endif
endfor

printf, 1, "\end{tabular}"
printf, 1, "\end{center}"
printf, 1, "\end{table}"
printf, 1, "\end{document}"
close, 1

end
