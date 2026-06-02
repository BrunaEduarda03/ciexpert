set SIM_DIR "."

set FSDB "$SIM_DIR/robot.fsdb"
set RC   "$SIM_DIR/robot-signals.rc"

cd $SIM_DIR

puts "==> Recompiling and rerunning simulation..."
if {[catch {exec sh -c "make robot_comp robot_sim 2>&1"} result]} {
    puts "ERROR during make:"
    puts $result
    return
}
puts $result

puts "==> Getting current nWave window..."
set W [wvGetCurrentWindow]
puts "==> nWave window = $W"

puts "==> Closing old FSDB from nWave..."
catch {wvCloseFile -win $W $FSDB}
catch {wvCloseFile -win $W robot.fsdb}

puts "==> Opening new FSDB..."
wvOpenFile -win $W $FSDB

puts "==> Restoring signals..."
wvRestoreSignal -win $W -openDumpFile $RC

puts "==> Updating waveform view..."
catch {wvSetActiveFile -win $W $FSDB}
catch {wvRefresh -win $W}
catch {wvZoomAll -win $W}

puts "==> OK: robot.fsdb was CLOSED, REOPENED, and the signals were restored."