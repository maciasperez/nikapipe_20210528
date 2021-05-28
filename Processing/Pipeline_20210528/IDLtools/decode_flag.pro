
;; Translates pixel flag into meaningful terms

pro decode_flag, flag, meaning, print=print

  case flag of
     0: meaning = "BLIND"                 ; not connected
     1: meaning = ""                      ; valid kid, nothing special to mention
     2: meaning = "OFF"
     3: meaning = "COMB"                  ; single beam after combination of several kids
     4: meaning = "MULT"                  ; multiple beams, not separated
     5: meaning = "TBC"                   ; problematic kid for yet unclear reason
     6: meaning = "UNSTABLE"              ; may be valid on one scan and then double or weird on another scan
     7: meaning = "bug"                   ; debugging value
     8: meaning = "bug"                   ; debugging value
  endcase

if keyword_set(print) then print, meaning


end
