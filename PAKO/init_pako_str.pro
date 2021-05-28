
;; Creates a pako_Str structure as place holder when the xml file is not present

pro init_pako_str, pako_str

  pako_Str = {nas_offset_x:0.d0, $
              nas_offset_y:0.d0, $
              source:'a', $
              purpose:'dummy', $
              p2cor:0.d0, $
              p7cor:0.d0, $
              focusx:0.d0, $
              focusy:0.d0, $
              focusz:0.d0, $
              obs_type:"p"}

end
