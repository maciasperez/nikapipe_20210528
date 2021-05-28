
;; Generates index.html, index.tex, param_routine.tex, routine_routine.tex

pro make_doc

;; List all routines in Pipeline directory to init arrays
;; spawn, "ls -d $PIPE/*", dir_list
dir_list = ['Datamanage', $
            'PAKO', $
            'MapReduction', $
            ;'Katana', $
            'Readdata/IDL', $
            'IDLtools', $
            'Realtime', $
            'NIKA_Simu', $
            'NIKA_Pipe', $
            'NIKA_Pipe/Polar']
raw_routines = ['']
for idir=0, n_elements(dir_list)-1 do begin
   spawn, "grep -i 'nk\_' $PIPE/"+dir_list[idir]+"/*pro > bidon.txt"
   delvarx, a
   readcol, "bidon.txt", a, delim=":", comment=';', format='A'
   if defined(a) then raw_routines = [raw_routines, a]
endfor
raw_routines = raw_routines[1:*]
routines = file_basename(raw_routines)
index = UNIQ(routines, SORT(routines))
raw_routines = raw_routines[index]
routines     = routines[index]

nroutines = n_elements(routines)
print, "nroutines: ", nroutines
;; discard ".pro" extension
for i=0, nroutines-1 do begin
   ll = strlen(routines[i])
   routines[i] = strmid( routines[i], 0, ll-4)
endfor

;; Build the routine x routine array in one call !
routine_routine = intarr(nroutines, nroutines)
for idir=0, n_elements(dir_list)-1 do begin
   ;; look for any call to any parameter in all the routines
   spawn, "grep -i 'nk\_' $PIPE/"+dir_list[idir]+"/*pro > bidon.txt"
   delvarx, a
   readcol, "bidon.txt", a, delim=":", comment=';', format='A'
   if defined(a) then begin
      openr, lu, "bidon.txt", /get_lun
      line = ''
      while not EOF(lu) do begin
         readf, lu, line
         ;; Extract the name of the currently scanned routine
         r = strsplit( line, ":", /extract)
         myroutine = file_basename(r[0])
         ll = strlen(myroutine)
         myroutine = strmid( myroutine, 0, ll-4) ; discard .pro extension
         wr = where( strupcase( routines) eq strupcase(myroutine), nwr)
         if nwr ne 0 then begin
;            stop
            ;; extract the called routines
            r = strsplit( strtrim(r[1],2), "nk\_", /regex, /extract)
            nr = n_elements(r)
            if nr ge 1 then begin
               ;; there may be several parameters called on the same line
               for j=0, nr-1 do begin
                  x = strsplit( r[j], " ,=)", /extract)
                  wr1 = where( strupcase(routines) eq strupcase( "nk_"+strtrim(x[0],2)), nwr1)
                  if nwr1 ne 0 then routine_routine[wr,wr1] = 1
               endfor
            endif
         endif
      endwhile
      close, lu
      free_lun, lu
   endif
endfor

;; Extract headers from routines and extended comments along the code
spawn, "mkdir Junk"
for i=0, n_elements(raw_routines)-1 do begin
   r = file_basename( raw_routines[i])
   l = strlen( r)
   ;; extract standard header
   doc_library, strmid(r,0,l-4), print="cat > Junk/"+file_basename(raw_routines[i])
   openw, 1, "Junk/bidon.txt"
   printf, 1, ";+"
   OPENR, lun, "Junk/"+file_basename(raw_routines[i]), /GET_LUN
   WHILE NOT EOF(lun) DO BEGIN
      READF, lun, line
      line = strtrim(line,2)
;      if strmid(line,0,5) ne "-----" then printf, 1, "; "+line
      printf, 1, "; "+line
   ENDWHILE
   FREE_LUN, lun

   ;; Look for extended comments
   spawn, "grep @ "+raw_routines[i], r
   if r[0] ne '' then begin
      printf, 1, "; DETAILS:"
      for ir=0, n_elements(r)-1 do begin
         ;; printf, 1, "; "+r[ir]
         line = strtrim(r[ir],2)
         while strmid( line, 0, 1) ne "@" do line = strmid(line,1)
         ;; remove the remaining @
         line = strmid(line,1)
         if strmid(line,0,1) eq "^" then begin
            printf, 1, "; "+strmid(line,1)
         endif else begin
            printf, 1, "; - "+strmid(line,1)
         endelse
      endfor
   endif

   printf, 1, ";-"
   close, 1
   ;; Overwrite current file
   spawn, "\mv Junk/bidon.txt Junk/"+file_basename(raw_routines[i])
endfor

spawn, "ls Junk/*pro", junk_routines

;; Generate html and tex document with headers
;; nika_doc, raw_routines, "index", cross_ref_array=routine_routine
nika_doc, junk_routines, "$PIPE/Documentation/index", cross_ref_array=routine_routine
spawn, "rm -rf Junk"

;; Write output results in a .tex file
openw, lu, "$PIPE/Documentation/routine_routine.tex", /get_lun
printf, lu, "\documentclass[a4paper,10pt]{article}"
printf, lu, "\usepackage{epsfig}"
printf, lu, "\usepackage{latexsym}"
printf, lu, "\usepackage{graphicx}"
printf, lu, "\usepackage{amsfonts}"
printf, lu, "\usepackage{amsmath}"
printf, lu, "\usepackage{xcolor}"
printf, lu, "\topmargin=-1cm"
printf, lu, "\oddsidemargin=-1cm"
printf, lu, "\evensidemargin=-1cm"
printf, lu, "\textwidth=17cm"
printf, lu, "\textheight=25cm"
printf, lu, "\raggedbottom"
printf, lu, "\sloppy"
printf, lu, "\title{Pipeline routines}"
printf, lu, "\author{NP}"
printf, lu, "\begin{document}"
printf, lu, "\maketitle"
printf, lu, "Here is the list of pipeline routines and the pipeline routines that they call."
printf, lu, "\begin{itemize}"
for i=0, nroutines-1 do begin
   w = where( routine_routine[i,*] ne 0, nw)
   if nw ne 0 then begin
      printf, lu, "\item {\bf "+strtrim( str_replace(routines[i],"_","\_",/global),2)+":}\\ "
      for j=0, nw-1 do begin
         if j eq (nw-1) then begin
            printf, lu, str_replace( routines[w[j]], "_", "\_", /global)+'.'
         endif else begin
            printf, lu, str_replace( routines[w[j]], "_", "\_", /global)+', '
         endelse
      endfor
   endif
endfor
printf, lu, "\end{itemize}"
printf, lu, "\end{document}"
close, lu
free_lun, lu

;; Read all pipeline parameters to init arrays
nk_default_param, param
tag_name = tag_names(param)
exclude_list = ['flag', $
                'scanst_scanNothing', $
                'scanst_scanLoaded', $
                'scanst_scanStarted', $
                'scanst_scanDone', $
                'scanst_subscanStarted', $
                'scanst_subscanDone', $
                'scanst_scanbackOnTrack', $
                'scanst_subscan_tuning', $
                'scanst_scan_tuning', $
                'scanst_scan_new_file']
for i=0, n_elements(exclude_list)-1 do begin
   w = where( strupcase(tag_name) eq strupcase(exclude_list[i]), nw)
   if nw ne 0 then tag_name[w] = "junk"
endfor
w = where( strupcase(tag_name) ne "JUNK", nw)
tag_name = tag_name[w]
tag_name = tag_name[ sort( strupcase(tag_name))]
ntags = n_elements(tag_name)
print, "nroutines: ", nroutines
print, "n(parameters): ", n_elements(tag_name)

;; Build the parameter/routine array in one call !
procedures = ['']
param_routine = intarr( ntags, nroutines)
for idir=0, n_elements(dir_list)-1 do begin
   ;; look for any call to any parameter in all the routines
   spawn, "grep -i 'param\.' $PIPE/"+dir_list[idir]+"/*pro > bidon.txt"
   delvarx, a
   readcol, "bidon.txt", a, delim=":", comment=';', format='A'
   if defined(a) then begin
      procedures = [procedures, a]

      openr, lu, "bidon.txt", /get_lun
      array = ''
      line = ''
      while not EOF(lu) do begin
         readf, lu, line
         ;; Extract the name of the currently scanned routine
         r = strsplit( line, ":", /extract)
         myroutine = file_basename(r[0])
         ll = strlen(myroutine)
         myroutine = strmid( myroutine, 0, ll-4) ; discard .pro extension
         wr = where( strupcase(routines) eq strupcase(myroutine), nwr)
         ;; extract the parameter names
         r = strsplit( line, "param\.", /regex, /extract)
         nr = n_elements(r)
         if nr gt 1 then begin
            ;; there may be several parameters called on the same line
            for j=1, nr-1 do begin
               x = strsplit( r[j], " ,=)", /extract)
               wtag = where( strupcase(tag_name) eq strupcase( strtrim(x[0],2)), nwtag)
               if nwtag ne 0 then param_routine[wtag,wr] = 1
            endfor
         endif
      endwhile
      close, lu
      free_lun, lu
   endif
endfor

;; Write output results in a .tex file
openw, lu, "$PIPE/Documentation/param_routine.tex", /get_lun
printf, lu, "\documentclass[a4paper,10pt]{article}"
printf, lu, "\usepackage{epsfig}"
printf, lu, "\usepackage{latexsym}"
printf, lu, "\usepackage{graphicx}"
printf, lu, "\usepackage{amsfonts}"
printf, lu, "\usepackage{amsmath}"
printf, lu, "\usepackage{xcolor}"
printf, lu, "\topmargin=-1cm"
printf, lu, "\oddsidemargin=-1cm"
printf, lu, "\evensidemargin=-1cm"
printf, lu, "\textwidth=17cm"
printf, lu, "\textheight=25cm"
printf, lu, "\raggedbottom"
printf, lu, "\sloppy"
printf, lu, "\title{Pipeline parameters and associated routines}"
printf, lu, "\author{NP}"
printf, lu, "\begin{document}"
printf, lu, "\maketitle"
printf, lu, "\section{Parameters}"
printf, lu, "Here is the list of the pipeline parameters (sorted by alphabetical order) and the routines in which these parameters are used."
printf, lu, "\begin{itemize}"
for i=0, ntags-1 do begin
   w = where( param_routine[i,*] ne 0, nw)
   if nw ne 0 then begin
      printf, lu, "\item {\bf "+strtrim( str_replace(tag_name[i],"_","\_",/global),2)+":}\\ "
      for j=0, nw-1 do begin
         if j eq (nw-1) then begin
            printf, lu, str_replace( routines[w[j]], "_", "\_", /global)+'.'
         endif else begin
            printf, lu, str_replace( routines[w[j]], "_", "\_", /global)+', '
         endelse
      endfor
   endif
endfor
printf, lu, "\end{itemize}"

printf, lu, "\section{Routines}"
printf, lu, "Here is the list of pipeline routines and the parameters that they call"
printf, lu, "\begin{itemize}"
for i=0, nroutines-1 do begin
   printf, lu, "\item {\bf "+strtrim( strupcase(str_replace(routines[i],"_","\_",/global)),2)+":}"
   w = where( param_routine[*,i] ne 0, nw)
   if nw ne 0 then begin
      for j=0, nw-1 do begin
         if j eq (nw-1) then begin
            printf, lu, strtrim( strlowcase(str_replace(tag_name[w[j]],"_","\_",/global)), 2)+". "
         endif else begin
            printf, lu, strtrim( strlowcase(str_replace(tag_name[w[j]],"_","\_",/global)), 2)+", "
         endelse
      endfor
   endif
endfor
printf, lu, "\end{itemize}"

printf, lu, "\end{document}"
close, lu
free_lun, lu

spawn, "rm -f bidon.txt"
end
