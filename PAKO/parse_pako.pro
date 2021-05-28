
pro parse_pako, scan_num, day, pako_str, verbose=verbose

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "parse_pako, scan_num, day, pako_str"
   return
endif

if not keyword_set(xml_dir) then xml_dir = !nika.xml_dir

;; Ensure correct format for "day"
t = size( day, /type)
if t eq 7 then day = strtrim(day,2) else day = string( day, format="(I8.8)")

nika_find_xml_file, scan_num, day, xml_file, /silent
;; Parse xml file into a temporary ascii file
;print, "xml_file: ", xml_file
;stop
spawn, "parse_pako -in "+xml_file+" -out bidon.txt"

;; Retrieve relevant information
readcol, "bidon.txt", tag, v, format="A,A", /silent, delim="="

;; Clean up
spawn, "rm -f bidon.txt"

;; Create output structure
tag   = strtrim(tag,2)
ntags = n_elements(tag)
cmd   = "pako_str = {"
for i=0, ntags-2 do cmd = cmd+tag[i]+":"+strtrim(v[i],2)+", "
cmd = cmd+tag[ntags-1]+":"+strtrim(v[ntags-1],2)+"}"
junk = execute(cmd)

;; Adjust units
w = where( strupcase(tag) eq "P2COR", nw)
if nw ne 0 then pako_str.(w) = pako_str.(w)*!radeg*3600
w = where( strupcase(tag) eq "P7COR", nw)
if nw ne 0 then pako_str.(w) = pako_str.(w)*!radeg*3600

if keyword_set(verbose) then help, pako_str, /str

end
