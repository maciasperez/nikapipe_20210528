

;; Script to pass parameters from the input .txt file to the various
;; imcm (sub) routines
;;-----------------------------------------------------------------

;; Main script parameters
if file_test(input_txt_file) eq 0 then stop, 'This file does not exist '+input_txt_file
readcol, input_txt_file, command, comment='#', delim=';', $
         format='A', /silent
for i=0, n_elements(command)-1 do junk = execute( command[i])

root_dir = !nika.plot_dir+"/"+ext

;; ; FXD change of directory structure 2021-Jan
if defined( method_num) then begin
   if strtrim( method_num, 2) eq '120' then $
      root_dir = !nika.save_dir+"/"+ext
endif

spawn, "mkdir -p "+root_dir
source_init_param_2, source, 0.d0, param, root_dir, method_num=method_num

dir_basename         = param.project_dir

;; Check if some additional parameters were put in input_txt_file
ptags = tag_names(param)
readcol, input_txt_file, var, value, comment='#', delim='=', $
         format='A,A', /silent
for i=0, n_elements(var)-1 do begin &$
   wtag = where( strupcase(ptags) eq strtrim( strupcase(var[i]),2), nwtag) &$
   if nwtag ne 0 then begin &$
   junk = execute( "param."+var[i]+" = "+value[i]) &$
   endif &$
endfor

if not keyword_set(info) then nk_default_info, info
if param.new_method eq 'NEW_DECOR_ATMB_PER_ARRAY' then begin
   if defined(info_longobj) then info.longobj = info_longobj
   if defined(info_latobj) then info.latobj = info_latobj
endif
