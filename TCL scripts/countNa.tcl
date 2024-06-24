# 
# Use with: vmd -dispdev text -e <nameofscript.tcl>
# By Jordi Faraudo March 2017

#
# PROCEDURE 1: BIG DCD
#First of all I include here the BigDCD command
#

proc bigdcd { script type args } {
    global bigdcd_frame bigdcd_proc bigdcd_firstframe vmd_frame bigdcd_running
  
    set bigdcd_running 1
    set bigdcd_frame 0
    set bigdcd_firstframe [molinfo top get numframes]
    set bigdcd_proc $script

    # backwards "compatibility". type flag is omitted.
    if {[file exists $type]} { 
        set args [linsert $args 0 $type] 
        set type auto
    }
  
    uplevel #0 trace variable vmd_frame w bigdcd_callback
    foreach dcd $args {
        if { $type == "auto" } {
            mol addfile $dcd waitfor 0
        } else {
            mol addfile $dcd type $type waitfor 0
        }
    }
    after idle bigdcd_wait
}

proc bigdcd_callback { tracedvar mol op } {
    global bigdcd_frame bigdcd_proc bigdcd_firstframe vmd_frame
    set msg {}
 
    # If we're out of frames, we're also done 
    # AK: (can this happen at all these days???). XXX
    set thisframe $vmd_frame($mol)
    if { $thisframe < $bigdcd_firstframe } {
        puts "end of frames"
        bigdcd_done
        return
    }
 
    incr bigdcd_frame
    if { [catch {uplevel #0 $bigdcd_proc $bigdcd_frame} msg] } { 
        puts stderr "bigdcd aborting at frame $bigdcd_frame\n$msg"
        bigdcd_done
        return
    }
    animate delete beg $thisframe end $thisframe $mol
    return $msg
}

proc bigdcd_done { } {
    global bigdcd_running
    
    if {$bigdcd_running > 0} then {
        uplevel #0 trace vdelete vmd_frame w bigdcd_callback
        puts "bigdcd_done"
        set bigdcd_running 0
    }
}

proc bigdcd_wait { } {
    global bigdcd_running bigdcd_frame
    while {$bigdcd_running > 0} {
        global bigdcd_oldframe
        set bigdcd_oldframe $bigdcd_frame
        # run global processing hooks (including loading of scheduled frames)
        display update ui
        # if we have read a new frame during then the two should be different.
        if { $bigdcd_oldframe == $bigdcd_frame } {bigdcd_done}
    }
}

#
# Define procedure for computing adsorbed Na
#

proc ion_adsorbed { frame } {
  global seleccio fp
  puts "$frame"
  $seleccio frame $frame
  $seleccio update 
  set n [$seleccio num] 
  puts $fp "$frame $n" 
}

#
#Main program
#
# output file
set fp [ open "numNa.dat" w ] 

# open structure file of simulated system
set mol [mol new ../../ionized.psf type psf waitfor all]
# define the interesting thing to calculate
set seleccio [atomselect $mol {type SOD and within 3.0 of resname AIDOA AGLC}]

#perform calculation over each frame using BigDCD
puts "Please wait. Calculating..."
bigdcd ion_adsorbed auto ../heparin_Na_150mM_prod_NpT_aligned.dcd
bigdcd_wait

#close output file          
close $fp 

exit

