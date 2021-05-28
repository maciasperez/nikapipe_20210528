
;----------------------------------------------------------------------------
PRO mhh_strict, txtlines
;
; Replaces any occurrence of HTML reserved characters (<,>,&,") in the
; given text lines with the appropriate HTML counterpart.
;
; entry:
;       txtlines - String array containing the text line(s) to be altered.
; exit:
;	txtlines - Same as input except that reserved characters have been 
;                  replaced with the appropriate HTML syntax.
;
 COMPILE_OPT hidden

 count = N_ELEMENTS(txtlines)
 FOR i=0,count-1 DO BEGIN
  txt = txtlines[i] 

  ; Ampersands get replaced with &amp.  Must do ampersands first because
  ; they are used to replace other reserved characters in HTML.
  spos = STRPOS(txt,'&')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&amp;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'&',spos+1)
  ENDWHILE
  txtlines[i] = txt

  ; Left angle brackets get replaced with &lt;
  spos = STRPOS(txt,'<')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&lt;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'<',spos+1)
  ENDWHILE
  txtlines[i] = txt

  ; Right angle brackets get replaced with &gt;
  spos = STRPOS(txt,'>')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&gt;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'>',spos+1)
  ENDWHILE
  txtlines[i] = txt

  ; Double quotes get replaced with &quot;
  spos = STRPOS(txt,'"')
  WHILE (spos NE -1) DO BEGIN
   newtxt = STRMID(txt,0,spos)+'&quot;'+STRMID(txt,spos+1,STRLEN(txt)-spos+1)
   txt = newtxt
   spos = STRPOS(txt,'"',spos+1)
  ENDWHILE
  txtlines[i] = txt
 ENDFOR
END

;----------------------------------------------------------------------------
PRO  mhh_grab_hdr,name,dict,infile_indx,txt_file,verbose,strict
;
; Searches an input file for all text between the ;+ and ;- comments, and
; updates the scratch text file appropriately. Note that this routine
; will extract multiple comment blocks from a single source file if they are
; present.
;
; entry:
;	name - Name of file containing documentation header(s).
;  dict[] - Dictionary entries for each documentation block in the .PRO
;           file.  Each dictionary entry is a structure with an index to 
;           the source filename, a subject name, scratch file offset,
;           unique id (for duplicate names), and number of lines of
;           documentation text.  
;           This parameter may be originally undefined at entry.
;  infile_indx - Index of the source .pro filename.
;	txt_file - Scratch file to which the documentation header will
;             be written.
;	verbose - TRUE if the routine should output a descriptive message
;            when it finds the documentation header.
;  strict - If nonzero, the routine will adhere strictly to HTML format.
;           The document headers will be scanned for characters that are
;           reserved in HTML (<,>,&,"), which are then converted to the 
;           appropriate HTML syntax in the output file.
;
; exit:
;	txt_file -  Updated as necessary. Positioned at EOF.
;  dict[] - Updated array of new dictionary entries.
;

 COMPILE_OPT hidden

 ; Under DOS, formatted output ends up with a carriage return linefeed
 ; pair at the end of every record. The resulting file would not be
 ; compatible with Unix. Therefore, we use unformatted output, and
 ; explicity add the linefeed, which has ASCII value 10.
 LF=10B

 OPENR, in_file, /GET, name

 IF (verbose NE 0) THEN MESSAGE,/INFO, 'File = '+name
 WHILE (1) DO BEGIN
  ; Find the opening line of the next header.
  tmp = ''
  found = 0
  num = 0
  header = ''
  ON_IOERROR, DONE
  WHILE (NOT found) DO BEGIN
   READF, in_file, tmp
   IF (STRMID(tmp,0,2) EQ ';+') THEN found = 1
  ENDWHILE

  IF (found) THEN BEGIN
   ; Find the matching closing line of the header.
   found = 0
   WHILE (NOT found) DO BEGIN
    READF,in_file,tmp
    IF (STRMID(tmp,0,2) EQ ';-') THEN BEGIN
     found =1
    ENDIF ELSE BEGIN
     tmp = strmid(tmp, 1, 1000)
     header = [header, tmp]
     num = num + 1
    ENDELSE
   ENDWHILE

   IF (strict) THEN mhh_strict,header
   ; Done with one block of header

   ; Keep track of current scratch file offset, then write doc text.
   POINT_LUN,-txt_file,pos
   FOR i=1, num DO BEGIN
    WRITEU, txt_file, header[i],LF
   ENDFOR

   ; Search for the subject. It is the line following name.
   index = WHERE(STRTRIM(header, 2) EQ 'NAME:', count)
   IF (count eq 1) THEN BEGIN
    sub = STRUPCASE(STRTRIM(header[index[0]+1], 2))
    IF (verbose NE 0) THEN MESSAGE,/INFO, 'Routine = '+sub

   ; If the NAME field was not present, set the subject to the name of the 
   ; source text file.
   ENDIF ELSE BEGIN
    MESSAGE,/INFO,'Properly formatted NAME entry not found...'
    ifname = name

    tok = PATH_SEP()

    ; Cut the path.
    sp0 = 0
    spos = STRPOS(ifname,tok,sp0)
    WHILE (spos NE -1) DO BEGIN
     sp0 = spos+1
     spos = STRPOS(ifname,tok,sp0)
    ENDWHILE
    ifname = STRMID(ifname,sp0,(STRLEN(ifname)-sp0))

    ; Cut the suffix.
    spos = STRPOS(ifname,'.')
    IF (spos NE -1) THEN ifname = STRMID(ifname,0,spos[0])
    IF (strict) THEN mhh_strict, ifname
    sub = STRUPCASE(ifname)
    MESSAGE,/INFO,'  Setting subject to filename: '+sub+'.'
   ENDELSE

   ; Calculate unique id in case of duplicate subject names.
   IF (N_ELEMENTS(dict) EQ 0) THEN $
    ndup=0 $
   ELSE BEGIN
    dpos = WHERE(dict.subject EQ sub,ndup)
    IF (ndup EQ 1) THEN dict[dpos[0]].id = 1
    IF (ndup GE 1) THEN ndup = ndup + 1
   ENDELSE

   ; Create a dictionary entry for the document header.
   entry = {DICT_STR,subject:sub,indx:infile_indx, $
            id:ndup,offset:pos,nline:num}
   IF (N_ELEMENTS(dict) EQ 0) THEN dict = [entry] ELSE dict = [dict,entry]
  ENDIF
 ENDWHILE

DONE: 
 ON_IOERROR, NULL
 FREE_LUN, in_file
END


;----------------------------------------------------------------------------
PRO mhh_gen_file_html,dict,txt_file,infiles,outfile,verbose,title,strict, $
                      sources=sources, cross_ref_array=cross_ref_array
;
; Build a .HTML file with the constituent parts.
;
; entry:
;  dict - Array of dictionary entries. Each entry is a structure
;         with a subject name, scratch file offset, number of lines
;         of documentation text, etc.
;  infiles - String array containing the name(s) of .pro files 
;            for which help is being generated.
;	txt_file - Scratch file containing the documentation text.
;	outfile - NAME of final HELP file to be generated.
;	verbose - TRUE if the routine should output a descriptive message
;            when it finds the documentation header.
;	title - Scalar string containing the name to go at the top of the
;          HTML help page.
;  strict - If nonzero, the routine will adhere strictly to HTML format.
;           The document headers will be scanned for characters that are
;           reserved in HTML (<,>,&,"), which are then converted to the 
;           appropriate HTML syntax in the output file.
;
; exit:
;	outfile has been created.
;	txt_file has been closed via FREE_LUN.
;

 COMPILE_OPT hidden

 IF (N_ELEMENTS(dict) EQ 0) THEN BEGIN
    MESSAGE, 'No documentation headers found', LEVEL=-1, /CONTINUE
    PRINT, ' '
    PRINT, 'None of the specified files contain documentation header'
    PRINT, 'information in the DOC_LIBRARY format. See the documentation'
    PRINT, 'for MK_HTML_HELP and DOC_LIBRARY for details.'
    PRINT, ' '
    PRINT, 'No HTML files were created.'
    PRINT, ' '
    IF((N_ELEMENTS(txt_file) NE 0) && ((FSTAT(txt_file)).open EQ 1)) $
       THEN FREE_LUN, txt_file
    RETURN
 ENDIF

 ; Append unique numbers to any duplicate subject names.
 dpos = WHERE(dict.id GT 0,ndup) 
 FOR i=0,ndup-1 DO BEGIN
  entry = dict[dpos[i]]
  dict[dpos[i]].subject = entry.subject+'['+STRTRIM(STRING(entry.id),2)+']'
 ENDFOR

 ; Sort the subjects alphabetically.
 count = N_ELEMENTS(dict)
 indices = SORT(dict.subject)

 ; Open the final file.
 OPENW,final_file,outfile,/GET_LUN
 IF (verbose NE 0) THEN MESSAGE,/INFO,'Building '+outfile+'...'

 ; Print a comment indicating how the file was generated.
 PRINTF,final_file,'<!-- This file was generated by mk_html_help.pro -->'

 ; Header stuff.
 PRINTF,final_file,'<html>'
 PRINTF,final_file,' '

 ; Title.
 PRINTF,final_file,'<head>'
 PRINTF,final_file,'<TITLE>',title,'</TITLE>'
 PRINTF,final_file,'</head>'
 PRINTF,final_file,' '

 ; Title and intro info.
 PRINTF,final_file,'<body>'
 PRINTF,final_file,'<H1>',title,'</H1>'
 PRINTF,final_file,'<P>'
 PRINTF,final_file,'This page was created by <CODE>nika_doc.pro</CODE>.<P> '
 PRINTF,final_file,'<STRONG>Last modified: </STRONG>',SYSTIME(),'.<P>'
 PRINTF,final_file,' '
 PRINTF,final_file,'<HR>'
 PRINTF,final_file,' '

 ; Index.
 PRINTF,final_file,'<A NAME="ROUTINELIST">'
 PRINTF,final_file,'<H1>List of Routines</H1></A>'
 PRINTF,final_file,'<UL>'
 FOR i=0,count-1 DO BEGIN
  entry = dict[indices[i]]

  IF (entry.nline GT 0) THEN $
   PRINTF,final_file,'<LI><A HREF="#',entry.subject,'">',entry.subject,'</A>'
 ENDFOR
 PRINTF,final_file,'</UL><P>'
 PRINTF,final_file,' '

 PRINTF,final_file,'<HR>'
 PRINTF,final_file,' '

 ; Descriptions.
 PRINTF,final_file,'<H1>Routine Descriptions</H1>'
 ON_IOERROR,TXT_DONE
 FOR i=0,count-1 DO BEGIN
  entry = dict[indices[i]]
  IF (entry.nline GT 0) THEN BEGIN
   PRINTF,final_file,'<A NAME="',entry.subject,'">'
   PRINTF,final_file,'<H2>',entry.subject,'</H2></A>'

   prev_i = i - 1
   IF (prev_i LT 0) THEN $
    dostep = 0 $ 
   ELSE BEGIN
    prev_ent = dict[indices[prev_i]]
    dostep = prev_ent.nline EQ 0
   ENDELSE
   WHILE dostep DO BEGIN
    prev_i = prev_i - 1
    IF (prev_i LT 0) THEN $
     dostep = 0 $
    ELSE BEGIN
     prev_ent = dict[indices[prev_i]]
     dostep = prev_ent.nline EQ 0
    ENDELSE
   ENDWHILE
;   IF (prev_i GE 0) THEN $
;    PRINTF,final_file,'<A HREF="#',prev_ent.subject,'">[Previous Routine]</A>'

   next_i = i + 1
   IF (next_i GE count) THEN $
    dostep = 0 $
   ELSE BEGIN
    next_ent = dict[indices[next_i]]
    dostep = next_ent.nline EQ 0
   ENDELSE
   WHILE dostep DO BEGIN
    next_i = next_i + 1
    IF (next_i GE count) THEN $
     dostep = 0 $
    ELSE BEGIN
     next_ent = dict[indices[next_i]]
     dostep = next_ent.nline EQ 0
    ENDELSE
   ENDWHILE
;   IF (next_i LT count) THEN $
;    PRINTF,final_file,'<A HREF="#',next_ent.subject,'">[Next Routine]</A>'

   PRINTF,final_file,'<A HREF="#ROUTINELIST">[List of Routines]</A>'

;; printf, final_file, "<p>List of called subroutines:</p>"
;; ;print, entry.subject
;; ;stop
;; 
;; myfile = !nika.pipeline_dir+"/Doc_scripts/"+strtrim(strlowcase(entry.subject),2)+$
;;          "_subroutine_list.txt"
;; if file_test(myfile) then begin
;;    readcol, myfile, subr, format="A", /silent
;;    nsubr = n_elements( subr)
;;    printf, final_file, '<UL>'
;;    for k=0, nsubr-1 do begin
;;       my_string = strtrim(subr[k],2)
;;       my_link   = my_string
;;       
;;       PRINTF,final_file,'<LI><A HREF="#',strupcase(my_link),'">',my_string,'</A>'
;;    endfor
;;    printf, final_file, "</UL><br/>"
;; endif
;; printf, final_file, " "

   if keyword_set(cross_ref_array) then begin
      routines = file_basename(sources)
      nroutines = n_elements(routines)
      for ii=0, nroutines-1 do begin
         ll = strlen(routines[ii])
         routines[ii] = strmid( routines[ii], 0, ll-4)
      endfor
      w = where( strupcase(routines) eq strtrim(strupcase(entry.subject),2), nw)
      if nw ne 0 then begin
         w1 = where( cross_ref_array[w,*] ne 0, nw1)
         if nw1 ne 0 then begin
            printf, final_file, '<UL>'
            for ii=0, nw1-1 do begin
               printf, final_file, '<LI><A HREF="#', strupcase( routines[w1[ii]]),'">',strupcase( routines[w1[ii]]),'</A>'
            endfor
            printf, final_file, "</UL><br/>"
         endif
      endif
   endif


   PRINTF,final_file,'<PRE>'
   tmp = ''

   POINT_LUN,txt_file,entry.offset
   FOR j=1,entry.nline DO BEGIN
    READF,txt_file,tmp
    PRINTF,final_file,tmp
   ENDFOR
   PRINTF,final_file,'</PRE><P>'
   fname = infiles[entry.indx]
   IF (strict) THEN mhh_strict,fname
;   PRINTF,final_file,'<STRONG>(See '+fname+')</STRONG><P>'
   PRINTF,final_file,'<HR>'
   PRINTF,final_file,' '
  ENDIF
 ENDFOR
TXT_DONE:
 ON_IOERROR,NULL
 FREE_LUN,txt_file

 ; Footer.
 PRINTF,final_file,'</body>'
 PRINTF,final_file,'</html>'
 FREE_LUN,final_file

 ; Tell the user the file was created.
 MESSAGE, 'Created file '+(FILE_INFO(outfile)).name, /INFORMATIONAL, LEVEL=-1
END

;----------------------------------------------------------------------------
PRO mhh_gen_file_tex,dict,txt_file,infiles,outfile,verbose,title,strict
;
; Build a .tex file with the constituent parts.
;
; entry:
;  dict - Array of dictionary entries. Each entry is a structure
;         with a subject name, scratch file offset, number of lines
;         of documentation text, etc.
;  infiles - String array containing the name(s) of .pro files 
;            for which help is being generated.
;	txt_file - Scratch file containing the documentation text.
;	outfile - NAME of final HELP file to be generated.
;	verbose - TRUE if the routine should output a descriptive message
;            when it finds the documentation header.
;	title - Scalar string containing the name to go at the top of the
;          HTML help page.
;  strict - If nonzero, the routine will adhere strictly to HTML format.
;           The document headers will be scanned for characters that are
;           reserved in HTML (<,>,&,"), which are then converted to the 
;           appropriate HTML syntax in the output file.
;
; exit:
;	outfile has been created.
;	txt_file has been closed via FREE_LUN.
;

 COMPILE_OPT hidden

 IF (N_ELEMENTS(dict) EQ 0) THEN BEGIN
    MESSAGE, 'No documentation headers found', LEVEL=-1, /CONTINUE
    PRINT, ' '
    PRINT, 'None of the specified files contain documentation header'
    PRINT, 'information in the DOC_LIBRARY format. See the documentation'
    PRINT, 'for MK_HTML_HELP and DOC_LIBRARY for details.'
    PRINT, ' '
    PRINT, 'No HTML files were created.'
    PRINT, ' '
    IF((N_ELEMENTS(txt_file) NE 0) && ((FSTAT(txt_file)).open EQ 1)) $
       THEN FREE_LUN, txt_file
    RETURN
 ENDIF

 ; Append unique numbers to any duplicate subject names.
 dpos = WHERE(dict.id GT 0,ndup) 
 FOR i=0,ndup-1 DO BEGIN
  entry = dict[dpos[i]]
  dict[dpos[i]].subject = entry.subject+'['+STRTRIM(STRING(entry.id),2)+']'
 ENDFOR

 ; Sort the subjects alphabetically.
 count = N_ELEMENTS(dict)
 indices = SORT(dict.subject)

 ; Open the final file.
 OPENW,final_file,outfile,/GET_LUN

printf, final_file, "\documentclass[a4paper,10pt]{article}"
printf, final_file, "\usepackage{epsfig}"
printf, final_file, "\usepackage{latexsym}"
printf, final_file, "\usepackage{graphicx}"
printf, final_file, "\usepackage{amsfonts}"
printf, final_file, "\usepackage{amsmath}"
printf, final_file, "\usepackage{xcolor}"
printf, final_file, "\usepackage[colorlinks=true, linkcolor=blue]{hyperref}"
printf, final_file, "\topmargin=-1cm"
printf, final_file, "\oddsidemargin=-1cm"
printf, final_file, "\evensidemargin=-1cm"
printf, final_file, "\textwidth=17cm"
printf, final_file, "\textheight=25cm"
printf, final_file, "\raggedbottom"
printf, final_file, "\sloppy"
printf, final_file, "\title{LAKOTA: The NIKA data reduction pipeline}"
printf, final_file, "\author{The Authors}"
printf, final_file, "\begin{document}"
printf, final_file, "\maketitle"
printf, final_file, "\tableofcontents"
printf, final_file, ""
printf, final_file, "\input{pipeline_intro}"
printf, final_file, ""
printf, final_file, "\section{List of routines}"

 IF (verbose NE 0) THEN MESSAGE,/INFO,'Building '+outfile+'...'

 ; Descriptions.
 ON_IOERROR,TXT_DONE
 FOR i=0,count-1 DO BEGIN
  entry = dict[indices[i]]
  IF (entry.nline GT 0) THEN BEGIN
     printf, final_file, "\noindent\line(1,0){500}"
     my_string = strtrim(entry.subject,2)
     my_link   = str_replace( my_string, "_", "", /global)
     my_string = str_replace( my_string, "_", "\_", /global)
     PRINTF,final_file,'\subsection{'+my_string+'}'
     printf, final_file, "\hypertarget{"+strlowcase(my_link)+"}{}"


;; printf, final_file, "{\bf Called subroutines:}"
;; myfile = !nika.soft_dir+"/Pipeline/Doc_scripts/"+strtrim(entry.subject,2)+$
;;          "_subroutine_list.txt"
;; if file_test(myfile) then begin
;;    readcol, myfile, subr, format="A", /silent
;;    nsubr = n_elements( subr)
;;    for k=0, nsubr-1 do begin
;;       my_string = strtrim(subr[k],2)
;;       my_link   = str_replace( my_string, "_", "", /global)
;;       my_string = str_replace( my_string, "_", "\_", /global)
;;       my_string = "\hyperlink{"+strlowcase(my_link)+"}{"+my_string+"}"
;;       if k ne nsubr-1 then $
;;          printf, final_file, my_string+", " else $
;;             printf, final_file, my_string+"\\"
;;    endfor
;; endif


   prev_i = i - 1
   IF (prev_i LT 0) THEN $
    dostep = 0 $ 
   ELSE BEGIN
    prev_ent = dict[indices[prev_i]]
    dostep = prev_ent.nline EQ 0
   ENDELSE
   WHILE dostep DO BEGIN
    prev_i = prev_i - 1
    IF (prev_i LT 0) THEN $
     dostep = 0 $
    ELSE BEGIN
     prev_ent = dict[indices[prev_i]]
     dostep = prev_ent.nline EQ 0
    ENDELSE
   ENDWHILE

   next_i = i + 1
   IF (next_i GE count) THEN $
    dostep = 0 $
   ELSE BEGIN
    next_ent = dict[indices[next_i]]
    dostep = next_ent.nline EQ 0
   ENDELSE
   WHILE dostep DO BEGIN
    next_i = next_i + 1
    IF (next_i GE count) THEN $
     dostep = 0 $
    ELSE BEGIN
     next_ent = dict[indices[next_i]]
     dostep = next_ent.nline EQ 0
    ENDELSE
   ENDWHILE

printf, final_file, "{\tt"
   tmp = ''

   POINT_LUN,txt_file,entry.offset
   FOR j=1,entry.nline DO BEGIN
    READF,txt_file,tmp
    ;; Deal with characters that are special to Latex
    tmp = str_replace( tmp, "_", "\_", /global)
    tmp = str_replace( tmp, "\^", "\^", /global)
    tmp = str_replace( tmp, "\$", "\$", /global)
    tmp = str_replace( tmp, "\&", "\&", /global)

    ;; I couldn't get str_replace to deal with [ or ] and latex, then
    ;; apply the same method as in mhh_strict

    ;; Left square brackets get replaced with $[$;
    spos = STRPOS(tmp,'[')
    WHILE (spos NE -1) DO BEGIN
       newtxt = STRMID(tmp,0,spos)+'$[$'+STRMID(tmp,spos+1,STRLEN(tmp)-spos+1)
       tmp = newtxt
       spos = STRPOS(tmp,'[',spos+3)
    ENDWHILE

    ;; Right square brackets get replaced with $[$;
    spos = STRPOS(tmp,']')
    WHILE (spos NE -1) DO BEGIN
       newtxt = STRMID(tmp,0,spos)+'$]$'+STRMID(tmp,spos+1,STRLEN(tmp)-spos+1)
       tmp = newtxt
       spos = STRPOS(tmp,']',spos+3)
    ENDWHILE

    tmp = strtrim( tmp,2)
    if strlen(tmp) ge 1 then tmp = tmp+"\\"
    PRINTF,final_file,tmp
   ENDFOR
printf, final_file, "}"
   fname = infiles[entry.indx]
   IF (strict) THEN mhh_strict,fname
  ENDIF
 ENDFOR
TXT_DONE:
 ON_IOERROR,NULL
 FREE_LUN,txt_file

 printf, final_file, "\begin{thebibliography}{}"
 printf, final_file, "\end{thebibliography}"
 printf, final_file, "\end{document}"
 FREE_LUN,final_file

 ; Tell the user the file was created.
 MESSAGE, 'Created file '+(FILE_INFO(outfile)).name, /INFORMATIONAL, LEVEL=-1
END

;----------------------------------------------------------------------------
PRO nika_doc_tex, sources, outfile, VERBOSE=verbose, TITLE=title, STRICT=strict, cross_ref_array=cross_ref_array

 ON_ERROR, 2

 ; Establish a catch block so that we can close the scratch file on error.
 catch, err
 if (err ne 0) then begin
    catch,/cancel
    ; If we got as far as opening the scratch file, then close it.
    ; It will be deleted on close because it was opened with /DELETE.
    IF((n_elements(txt_file) ne 0) && ((FSTAT(txt_file)).open EQ 1)) $
	THEN FREE_LUN,txt_file
    MESSAGE,/REISSUE_LAST
 endif

 IF (NOT KEYWORD_SET(verbose)) THEN verbose=0
 IF (NOT KEYWORD_SET(title)) THEN title="Extended IDL Help" 
 IF (NOT KEYWORD_SET(strict)) THEN strict=0

 infiles = ''

 count = N_ELEMENTS(sources)
 IF (count EQ 0) THEN BEGIN
  MESSAGE,/INFO,'No source IDL directories found.'
  RETURN
 ENDIF

 ; Open a temporary file for the documentation text.
 OPENW, txt_file, FILEPATH('userhtml.txt', /TMP), /GET_LUN, /DELETE

 ; Loop on sources. 
 FOR i=0, count-1 DO BEGIN
  src = sources[i]

  ; Test if the file is a .PRO file.
  IF (STRUPCASE(STRMID(src, STRLEN(src)-4,4)) EQ '.PRO') THEN BEGIN 
    infiles = [infiles,src]
  ENDIF ELSE BEGIN	; Not a .PRO file, treat it as a directory.
    ; Get a list of all .pro files in the directory.
    flist = FILE_SEARCH(src+PATH_SEP()+'*.pro',COUNT=npro)
    IF (npro GT 0) THEN infiles = [infiles,flist]
  ENDELSE
 ENDFOR

 count = N_ELEMENTS(infiles)
 IF (count EQ 1) THEN BEGIN
  MESSAGE,/INFO,'No IDL files found.'
  IF((FSTAT(txt_file)).open EQ 1) THEN FREE_LUN,txt_file
  RETURN
 ENDIF 
 infiles = infiles[1:*]
 count = count-1
 
 ; Loop on all files.
 FOR i=0,count-1 DO BEGIN
   name = infiles[i]
   mhh_grab_hdr,name,dict,i,txt_file,verbose,strict
 ENDFOR

 ;; Generate the .tex file.
 mhh_gen_file_tex, dict, txt_file, infiles, outfile+'.tex', verbose, title, strict

; ;; Generate the .html file
; mhh_gen_file_html, dict, txt_file, infiles, outfile+".html", verbose, title, strict


END

;----------------------------------------------------------------------------
PRO nika_doc_html, sources, outfile, VERBOSE=verbose, TITLE=title, STRICT=strict, cross_ref_array=cross_ref_array

 ON_ERROR, 2

 ; Establish a catch block so that we can close the scratch file on error.
 catch, err
 if (err ne 0) then begin
    catch,/cancel
    ; If we got as far as opening the scratch file, then close it.
    ; It will be deleted on close because it was opened with /DELETE.
    IF((n_elements(txt_file) ne 0) && ((FSTAT(txt_file)).open EQ 1)) $
	THEN FREE_LUN,txt_file
    MESSAGE,/REISSUE_LAST
 endif

 IF (NOT KEYWORD_SET(verbose)) THEN verbose=0
 IF (NOT KEYWORD_SET(title)) THEN title="Extended IDL Help" 
 IF (NOT KEYWORD_SET(strict)) THEN strict=0

 infiles = ''

 count = N_ELEMENTS(sources)
 IF (count EQ 0) THEN BEGIN
  MESSAGE,/INFO,'No source IDL directories found.'
  RETURN
 ENDIF

 ; Open a temporary file for the documentation text.
 OPENW, txt_file, FILEPATH('userhtml.txt', /TMP), /GET_LUN, /DELETE

 ; Loop on sources. 
 FOR i=0, count-1 DO BEGIN
  src = sources[i]

  ; Test if the file is a .PRO file.
  IF (STRUPCASE(STRMID(src, STRLEN(src)-4,4)) EQ '.PRO') THEN BEGIN 
    infiles = [infiles,src]
  ENDIF ELSE BEGIN	; Not a .PRO file, treat it as a directory.
    ; Get a list of all .pro files in the directory.
    flist = FILE_SEARCH(src+PATH_SEP()+'*.pro',COUNT=npro)
    IF (npro GT 0) THEN infiles = [infiles,flist]
  ENDELSE
 ENDFOR

 count = N_ELEMENTS(infiles)
 IF (count EQ 1) THEN BEGIN
  MESSAGE,/INFO,'No IDL files found.'
  IF((FSTAT(txt_file)).open EQ 1) THEN FREE_LUN,txt_file
  RETURN
 ENDIF 
 infiles = infiles[1:*]
 count = count-1
 
 ; Loop on all files.
 FOR i=0,count-1 DO BEGIN
   name = infiles[i]
   mhh_grab_hdr,name,dict,i,txt_file,verbose,strict
 ENDFOR

 ;; Generate the .tex file.
;; mhh_gen_file_tex, dict, txt_file, infiles, outfile+'.tex', verbose, title, strict

; ;; Generate the .html file
mhh_gen_file_html, dict, txt_file, infiles, outfile+".html", verbose, title, strict, $
                   sources=sources, cross_ref_array=cross_ref_array


END

;;============================================================
PRO nika_doc, sources, outfile, VERBOSE=verbose, TITLE=title, STRICT=strict, cross_ref_array=cross_ref_array
  
  nika_doc_html, sources, outfile, VERBOSE=verbose, TITLE=title, STRICT=strict, cross_ref_array=cross_ref_array
;  nika_doc_tex, sources, outfile, VERBOSE=verbose, TITLE=title, STRICT=strict, cross_ref_array=cross_ref_array
end
