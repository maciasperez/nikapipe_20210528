;+
;PURPOSE: Get the source name from IMB_fits 
;
;INPUT: The param structure.
;
;OUTPUT: the param with names
;
;LAST EDITION: - 09/01/2014 creation (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_sourcename, param, $
                          reset_source, $
                          reset_name4file, $
                          reset_output_dir, $
                          reset_logfile_dir, $
                          dir_ant=dir_ant, $
                          silent = silent

  if param.imb_fits_file ne '' then $
     antenna = mrdfits(param.imb_fits_file, 1, head, status=status, /silent) else status=-1
  
  if status ne -1 then begin
     imb_source = strtrim( sxpar(head,'object'), 2)
     message, /info, 'IMBFITS source name: '+imb_source
     imb_name4file = STRJOIN(STRSPLIT(imb_source,/EXTRACT),'_')
     if not keyword_set(dir_ant) then imb_output_dir = !nika.plot_dir+"/"+imb_name4file
     if keyword_set(dir_ant) then imb_output_dir = dir_ant+"/"+imb_name4file
     
     if reset_source eq 'yes' then param.source = imb_source
     if reset_name4file eq 'yes' then param.name4file = imb_name4file
     if reset_output_dir eq 'yes' then param.output_dir = imb_output_dir
     if reset_logfile_dir eq 'yes' then param.logfile_dir = param.output_dir
     if reset_output_dir eq 'yes' then spawn, "mkdir -p "+imb_output_dir

     if reset_source eq 'yes' or $
        reset_name4file eq 'yes' or $
        reset_output_dir eq 'yes' or $
        reset_logfile_dir eq 'yes' then $
        if not keyword_set( silent) then $
          message, /info, 'Warning, you are using the IMB_FITS do define the source or directory names. ' + $
                 'If you combine scans of differents source it will crash when combining the individual maps'
  endif

  if status eq -1 then begin
     if reset_source eq 'yes' then if not keyword_set( silent) then $
        message, 'Since you do no have IMB_FITS, ' + $
                 'you need to give the source name in param.source'
     if reset_name4file eq 'yes' then if not keyword_set( silent) then $
        message, 'Since you do no have IMB_FITS, ' + $
                 'you need to give the name used for files in param.name4file'
     if reset_output_dir eq 'yes' then if not keyword_set( silent) then $
        message, 'Since you do no have IMB_FITS, ' + $
                 'you need to give the name of the output ' + $
                 'directory in param.output_dir'
     if reset_logfile_dir eq 'yes' then if not keyword_set( silent) then $
        message, 'Since you do no have IMB_FITS, ' + $
                 'you need to give the name of the ' + $
                 'logfile output directory in param.logfile_dir'
  endif

  return
end
