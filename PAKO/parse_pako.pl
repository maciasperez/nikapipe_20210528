#!/usr/bin/perl

if (@ARGV < 1){
    print " Calling sequence is:\n";
    die "parse_pako -in input_xml_file -out output_txt_file \n";
}


#-----------------------------------------------------------------------------------------------
#Parse input commande line
$in_ok  = 0;
$out_ok = 0;
for ($i=0; $i <= $#ARGV; $i++) {
    if ($ARGV[$i] eq "-in") {
	$in_file = $ARGV[$i+1];
	$in_ok = 1;
    }
    if ($ARGV[$i] eq "-out") {
	$out_file = $ARGV[$i+1];
	$out_ok = 1;
    }
}
if ($in_ok  ==0){ die "Error in call of parse_pako.pl: missing -in  input_file argument\n";}
if ($out_ok ==0){ die "Error in call of pare_pako.pl: missing -out output_file argument\n";}

# Read input file
$data = `cat $in_file`;

# Init output file
open OUT, ">$out_file" || die "Failed to open $out_file\n";

#-----------------------------------------------------------------------------------------------
# Nasmyth offsets
$try = 0;
$found_offsets=0;
foreach $line (split(/\n/,$data)) {
    chomp($line);

    # try to read offsets if the line before was detected as pako offset and the current line
    # does not contain "clear"
    if ($try == 1){
	if ($line !~ /clear/){
	    $offsets = $line;
	    $found_offsets++;
	}
    }
    
    # reset
    $try = 0;

    # Search where pako offset is present
    if ($line =~ /pako\\OFFSETS -/){
	$try = 1;
    }
}

$p = 0;
foreach $value (split(/\ /,$offsets)){
#    if ($value != ""){
    if ($value ne "" && $value ne "-"){
	if ($p == 0){
	    print OUT "nas\_offset\_x = $value\n";
	    $p=1;
	}else{
	    print OUT "nas\_offset\_y = $value\n";
	}
    }
}
if ($found_offsets == 0){
    print OUT "nas\_offset\_x = 0.00\n";
    print OUT "nas\_offset\_y = 0.00\n";
}



#-----------------------------------------------------------------------------------------------
# Other information
$p = 0;
$i = 0;
$j = 0;
$purpose ='dummy'; #default
foreach $line (split(/\n/,$data)) {
    chomp($line);
    if ($line =~ /sourceName/){
	($source) = $line =~ /value=\"(.*?)\"/;
	print OUT "source   = \'$source\'\n";
    }
    if ($line =~ /focusCorrectionZ/){
	($focusz) = $line =~ /value=\"(.*?)\"/;
	print OUT "focusz   = $focusz\n";
    }
    if ($line =~ /focusCorrectionX/){
	($focusx) = $line =~ /value=\"(.*?)\"/;
	print OUT "focusx   = $focusx\n";
    }
    if ($line =~ /focusCorrectionY/){
	($focusy) = $line =~ /value=\"(.*?)\"/;
	print OUT "focusy   = $focusy\n";
    }

    if ($line =~ /PARAM(.*)observingMode/){
	($obs_type) = $line =~ /value=\"(.*?)\"/;
	if ($i==0){
	    print OUT "obs_type = \'$obs_type\'\n";
	    $i++;
	}
    }

    if ($line =~ /purpose/){
	($purpose) = $line =~ /value=\"(.*?)\"/;
    }

    if ($line =~ /pointingCorrectionP2/){
	($p2cor) = $line =~ /value=\"(.*?)\"/;
	print OUT "p2cor    = $p2cor\n";
    }
    if ($line =~ /pointingCorrectionP7/){
	($p7cor) = $line =~ /value=\"(.*?)\"/;
	print OUT "p7cor    = $p7cor\n";
    }
    if ($line =~ /focusOffset/){
	if ($line =~ /value/){
	    ($foffset) = $line =~ /value=\"(.*?)\"/;
	    print OUT "foffset$p = $foffset\n";
	    $p++;
	}
    }
    if (($line =~ /systemOffset/) && ($line =~ /value/)){
	($systemoffset) = $line =~ /value=\"(.*?)\"/;
	if ($j == 0) {
	    print OUT "systemOffset = \'$systemoffset\'\n";
	    $j++;
	}
    }

}
print OUT "purpose = \'$purpose\'\n";

close OUT;
