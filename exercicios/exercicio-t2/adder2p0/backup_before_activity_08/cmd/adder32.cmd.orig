simSetSimulator "-vcssv" -exec "./simv" -args " " -uvmDebug on
debImport "-i" "-simflow" "-dbdir" "./simv.daidir"
srcTBInvokeSim
verdiSetActWin -dock widgetDock_<Member>
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
simSetSimulator "-vcssv" -exec \
           "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x04-adder2p0/simv" \
           -args
debImport "-dbdir" \
          "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x04-adder2p0/simv.daidir"
srcTBDelAllBrkPnt
wvCreateWindow
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x04-adder2p0/cmd/adder32.fsdb}
srcHBSelect "adder_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "adder_tb.uu_adder32_if" -win $_nTrace1
srcHBSelect "adder_tb" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "adder_tb"
wvSetPosition -win $_nWave3 {("adder_tb" 0)}
wvRenameGroup -win $_nWave3 {G1} {adder_tb}
wvSelectGroup -win $_nWave3 {adder_tb}
verdiSetActWin -win $_nWave3
srcHBSelect "adder_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "adder_tb.uu_adder32_if" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "adder_tb.uu_adder32_if"
wvSetPosition -win $_nWave3 {("uu_adder32_if(adder32_if)" 0)}
wvRenameGroup -win $_nWave3 {adder_tb} {uu_adder32_if(adder32_if)}
wvAddSignal -win $_nWave3 "/adder_tb/uu_adder32_if/clk" \
           "/adder_tb/uu_adder32_if/reset_n" "/adder_tb/uu_adder32_if/en" \
           "/adder_tb/uu_adder32_if/op_a\[31:0\]" \
           "/adder_tb/uu_adder32_if/op_b\[31:0\]" \
           "/adder_tb/uu_adder32_if/adder_out\[31:0\]" \
           "/adder_tb/uu_adder32_if/carry_out"
wvSetPosition -win $_nWave3 {("uu_adder32_if(adder32_if)" 0)}
wvSetPosition -win $_nWave3 {("uu_adder32_if(adder32_if)" 7)}
wvSetPosition -win $_nWave3 {("uu_adder32_if(adder32_if)" 7)}
wvSetPosition -win $_nWave3 {("G2" 0)}
srcTBRunSim
wvSetCursor -win $_nWave3 28398.046563 -snap {("uu_adder32_if(adder32_if)" 0)}
wvSetCursor -win $_nWave3 28440.885906 -snap {("uu_adder32_if(adder32_if)" 2)}
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3