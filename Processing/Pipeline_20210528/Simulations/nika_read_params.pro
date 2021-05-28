

pro nika_read_params, param_file, params

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_read_params, param_file, params"
   print, ""
   print, "param_file must be an ascii file of the form:"
   print, "# type, variable name, value, description"
   print, "double, dummy, 1d-10, amplitude of dummy"
   print, "string, directory, /scratch/my_directory, input directory"
   return
endif

restore, !nika.SOFT_DIR+"/NIKA_lib/Simulations/Paramfiles/nika_ascii_template.save"

m = read_ascii( param_file, template=nika_ascii_template)

;; Init
params = create_struct("date", systime(0))

nfields = n_elements( m.(0))
for ifield=0, nfields-1 do begin
   type = (m.(0))[ifield]

   case strupcase(type) of
      "DOUBLE": value = double( (m.(2))[ifield])
      "FLOAT":  value = float(  (m.(2))[ifield])
      "INT":    value = long(    (m.(2))[ifield])
      "LONG":   value = long(   (m.(2))[ifield])
      "STRING": value =         (m.(2))[ifield]
   endcase

   params = create_struct( params, (m.(1))[ifield], value)
endfor

end
