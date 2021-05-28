

pro geom_kid_selection_2, scan_list, maps_output_dir, kidpars_output_dir, nickname, $
                          iter = iter,  keep_neg = keep_neg, input_kidpar_file = input_kidpar_file, $
                          sub_kidpar_file=sub_kidpar_file


spawn, "ls "+maps_output_dir+"/map_list*"+nickname+"_*.save",  map_list

scan = scan_list[0] ; place holder
nmaps = n_elements(map_list)
scan2daynum, scan, day, scan_num
scan = day+"s"+strtrim(scan_num,2)
nk_scan2run, scan, run
!nika.run = run > 11
init = 0

;; LP's fix to preserve the sorting by increasing numdet
map_list = maps_output_dir+"/map_lists_"+nickname+"_sub_"+strtrim(indgen(nmaps),2)+".save"

;; Restore previously computed maps and beam fits and keep only the
;; valid ones as left by merge_sub_kidpars.
for imap=0, nmaps-1 do begin
;;   for imap=0, 1 do begin
   print, "Restoring imap/(nmaps-1): "+strtrim(imap,2)+"/"+strtrim(nmaps-1,2)
   restore, map_list[imap]
   
   if keyword_set(input_kidpar_file) then begin
      kidpar_ref = mrdfits( input_kidpar_file, 1, /silent)
      ;; Flag out all kids here, the good ones will be given by kidpar_ref
      kidpar.plot_flag = 1
      ;; Copy type and plot_flag info from the ref. kidpar
      for i=0, n_elements(kidpar)-1 do begin
         w = where( kidpar_ref.numdet eq kidpar[i].numdet, nw)
         if nw ne 0 then begin
            kidpar[i].type      = kidpar_ref[w].type
            kidpar[i].plot_flag = kidpar_ref[w].plot_flag
         endif
      endfor
   endif

   ;; Allow for an extra selection to focus on some kids only
   if keyword_set(sub_kidpar_file) then begin
      kidpar.plot_flag = 1
      subkidpar = mrdfits( sub_kidpar_file, 1, /silent)
      for i=0, n_elements(kidpar)-1 do begin
         w = where( subkidpar.numdet eq kidpar[i].numdet, nw)
         if nw ne 0 then kidpar[i].plot_flag = 0
      endfor
   endif

   w = where( kidpar.type eq 1 and kidpar.plot_flag eq 0, nw)
   nkids = n_elements(kidpar)
   if nw ne 0 then begin
      if init eq 0 then begin
         map_list_azel_f     = map_list_azel[w,*,*]
         map_list_nasmyth_f  = map_list_nasmyth[w,*,*]
         kidpar_f            = kidpar[w]
         beam_list_azel_f    = beam_list_azel[w,*,*]
         beam_list_nasmyth_f = beam_list_nasmyth[w,*,*]
         init = 1
      endif else begin
         map_list_azel_f     = [map_list_azel_f,    map_list_azel[w,*,*]]
         map_list_nasmyth_f  = [map_list_nasmyth_f, map_list_nasmyth[w,*,*]]
         kidpar_f            = [kidpar_f, kidpar[w]]
         beam_list_azel_f    = [beam_list_azel_f, beam_list_azel[w,*,*]]
         beam_list_nasmyth_f = [beam_list_nasmyth_f, beam_list_nasmyth[w,*,*]]
      endelse
   endif
endfor                          ; loop on maps

map_list_azel     = map_list_azel_f
map_list_nasmyth  = map_list_nasmyth_f
kidpar            = kidpar_f
beam_list_azel    = beam_list_azel_f
beam_list_nasmyth = beam_list_nasmyth_f

;; ;;*************** CURRENT ****************
;; ;; save on disk and restore. simpler than redoing all coding in katana
;; ;; subroutines with "common" and keywords conflicts...
;; save_file = 'my_preproc_file.save'
;; preproc_index = 100
;; save, file=save_file,$
;;       map_list_azel, map_list_nasmyth, kidpar, beam_list_azel, beam_list_nasmyth, $
;;       param, grid_nasmyth, grid_azel
;; katana_light, scan_num, day, $
;;               /absurd, preproc_file=save_file, $
;;               preproc_index=preproc_index, keep_neg = keep_neg, kidpar=kidpar
;; scan = strtrim(day,2)+"s"+strtrim(scan_num,2)
;; cmd = "mv kidpar_"+strtrim(scan,2)+"_test_"+strtrim(preproc_index,2)+".fits "+$
;;       "kidpar_select_"+strtrim(nickname,2)+".fits"
;; print, "Wrote kidpar_select_"+strtrim(nickname,2)+".fits"
;; spawn, cmd

;;*************** (sept. 21st, 2016) SPLIT IN X to allow larger map display ***************
;; save on disk and restore. simpler than redoing all coding in katana
;; subroutines with "common" and keywords conflicts...
nkids_max = 1000
;; LP begin
if (n_elements(kidpar1) mod nkids_max) eq 0 then nkids_max = nkids_max-2
;; LP end

map_list_azel1     = map_list_azel
map_list_nasmyth1  = map_list_nasmyth
kidpar1            = kidpar
beam_list_azel1    = beam_list_azel
beam_list_nasmyth1 = beam_list_nasmyth
nsplit = long( n_elements(kidpar1)/nkids_max) + 1

for i=0, nsplit-1 do begin
   if i lt (nsplit-1) then begin
      map_list_azel     = map_list_azel1[     i*nkids_max:(i+1)*nkids_max-1,*,*]
      map_list_nasmyth  = map_list_nasmyth1[  i*nkids_max:(i+1)*nkids_max-1,*,*]
      kidpar            = kidpar1[            i*nkids_max:(i+1)*nkids_max-1]
      beam_list_azel    = beam_list_azel1[    i*nkids_max:(i+1)*nkids_max-1,*,*]
      beam_list_nasmyth = beam_list_nasmyth1[ i*nkids_max:(i+1)*nkids_max-1,*,*]
   endif else begin
      map_list_azel     = map_list_azel1[     i*nkids_max:*,*,*]
      map_list_nasmyth  = map_list_nasmyth1[  i*nkids_max:*,*,*]
      kidpar            = kidpar1[            i*nkids_max:*]
      beam_list_azel    = beam_list_azel1[    i*nkids_max:*,*,*]
      beam_list_nasmyth = beam_list_nasmyth1[ i*nkids_max:*,*,*]
   endelse

   save_file = !nika.plot_dir+'/my_preproc_file_split_'+strtrim(i,2)+'.save'
   preproc_index = i
   save, file=save_file,$
         map_list_azel, map_list_nasmyth, kidpar, beam_list_azel, beam_list_nasmyth, $
         grid_nasmyth, grid_azel

   ;;!mamdlib.coltable = 39       ; 4
   coltable = 4; 24;32
   katana_light, scan_num, day, $
                 /absurd, preproc_file=save_file, $
                 preproc_index=preproc_index, keep_neg = keep_neg, kidpar=kidpar, coltable=coltable
endfor

;; Merge the split kidpars into a single final one.
ntags = n_elements(tag_names(kidpar))
for i=0, nsplit-1 do begin
   kidpar = mrdfits( "kidpar_"+scan+"_test_"+strtrim(i,2)+".fits", 1, /silent)
   my_match, kidpar1.numdet, kidpar.numdet, suba, subb
   kidpar1[suba] = kidpar[subb]
endfor
kidpar = kidpar1
nk_write_kidpar, kidpar, "kidpar_select_"+strtrim(nickname,2)+".fits"
print, "Wrote kidpar_select_"+strtrim(nickname,2)+".fits"



end
