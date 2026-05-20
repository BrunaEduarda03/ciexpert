simSetSimulator "-vcssv" -exec "./simv" -args " " -uvmDebug on
debImport "-i" "-simflow" "-dbdir" "./simv.daidir"
srcTBInvokeSim
srcHierTreeSort -win $_nTrace1 -hierAscending
verdiSetActWin -dock widgetDock_<Inst._Tree>
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcHBSelect "mux8x1_tb.uut" -win $_nTrace1
verdiWindowResize -win $_Verdi_1 "126" "27" "1280" "843"
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "mux8x1_tb" -win $_nTrace1
simSetSimulator "-vcssv" -exec \
           "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/simv" \
           -args
debImport "-dbdir" \
          "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/simv.daidir"
srcTBDelAllBrkPnt
wvCreateWindow
verdiSetActWin -win $_nWave3
wvCreateWindow
verdiSetActWin -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 0)}
wvOpenFile -win $_nWave4 \
           {/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/inter.fsdb}
srcHBSelect "mux8x1_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "mux8x1_tb.uut" -win $_nTrace1
srcHBSelect "mux8x1_tb" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "mux8x1_tb"
wvSetPosition -win $_nWave4 {("mux8x1_tb" 0)}
wvRenameGroup -win $_nWave4 {G1} {mux8x1_tb}
wvSelectGroup -win $_nWave4 {mux8x1_tb}
srcHBSelect "mux8x1_tb.uut" -win $_nTrace1
verdiSetActWin -win $_nWave4
srcHBSelect "mux8x1_tb.uut" -win $_nTrace1
srcHBDrag -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
wvDumpScope "mux8x1_tb.uut"
wvSetPosition -win $_nWave4 {("uut" 0)}
wvRenameGroup -win $_nWave4 {mux8x1_tb} {uut}
wvAddSignal -win $_nWave4 "/mux8x1_tb/uut/clk" "/mux8x1_tb/uut/rstn" \
           "/mux8x1_tb/uut/en" "/mux8x1_tb/uut/din\[7:0\]" \
           "/mux8x1_tb/uut/sel\[2:0\]" "/mux8x1_tb/uut/dout"
wvSetPosition -win $_nWave4 {("uut" 0)}
wvSetPosition -win $_nWave4 {("uut" 6)}
wvSetPosition -win $_nWave4 {("uut" 6)}
srcTBInvokeSim
srcTBRunSim
verdiSetActWin -win $_nWave4
srcTBSimReset
wvZoomAll -win $_nWave4
srcTBRunSim
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvSelectSignal -win $_nWave4 {( "uut" 2 )} 
wvSelectGroup -win $_nWave4 {uut}
wvSelectSignal -win $_nWave4 {( "uut" 1 )} 
srcHBSelect "mux8x1_tb.uut" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
verdiSetActWin -win $_nWave4
wvZoomAll -win $_nWave4
wvCloseGetStreamsDialog -win $_nWave4
wvAttrOrderConfigDlg -win $_nWave4 -close
wvCloseDetailsViewDlg -win $_nWave4
wvCloseDetailsViewDlg -win $_nWave4 -streamLevel
wvCloseFilterColorizeDlg -win $_nWave4
wvGetSignalClose -win $_nWave4
wvCloseWindow -win $_nWave4
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/inter.fsdb}
srcHBSelect "mux8x1_tb.uut" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBDrag -win $_nTrace1
wvDumpScope "mux8x1_tb.uut"
wvSetPosition -win $_nWave3 {("uut" 0)}
wvRenameGroup -win $_nWave3 {G1} {uut}
wvAddSignal -win $_nWave3 "/mux8x1_tb/uut/clk" "/mux8x1_tb/uut/rstn" \
           "/mux8x1_tb/uut/en" "/mux8x1_tb/uut/din\[7:0\]" \
           "/mux8x1_tb/uut/sel\[2:0\]" "/mux8x1_tb/uut/dout"
wvSetPosition -win $_nWave3 {("uut" 0)}
wvSetPosition -win $_nWave3 {("uut" 6)}
wvSetPosition -win $_nWave3 {("uut" 6)}
wvSetCursor -win $_nWave3 6513.898810 -snap {("uut" 4)}
wvSetCursor -win $_nWave3 13689.107143 -snap {("uut" 3)}
wvSetCursor -win $_nWave3 15044.791667 -snap {("uut" 1)}
verdiSetActWin -win $_nWave3
srcTBSimReset
srcTBRunSim
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 81671.726190 -snap {("uut" 4)}
wvSetCursor -win $_nWave3 81671.726190 -snap {("uut" 4)}
wvSetCursor -win $_nWave3 18516.666667 -snap {("uut" 3)}
wvSetCursor -win $_nWave3 55880.654762 -snap {("uut" 2)}
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 9588.988095 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 1653.273810 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 2975.892857 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 5290.476190 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 4959.821429 -snap {("uut" 1)}
wvSetCursor -win $_nWave3 14879.464286 -snap {("uut" 1)}
wvSetCursor -win $_nWave3 9258.333333 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 9258.333333 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 19839.285714 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 25460.416667 -snap {("uut" 1)}
wvSetCursor -win $_nWave3 35049.404762 -snap {("uut" 1)}
wvSetCursor -win $_nWave3 35710.714286 -snap {("uut" 1)}
wvSetCursor -win $_nWave3 35049.404762 -snap {("uut" 1)}
wvSelectSignal -win $_nWave3 {( "uut" 4 )} 
wvSelectSignal -win $_nWave3 {( "uut" 4 )} 
wvSetRadix -win $_nWave3 -format Bin
wvSetCursor -win $_nWave3 125318.154762 -snap {("uut" 3)}
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 37033.333333 -snap {("uut" 4)}
wvSetCursor -win $_nWave3 31742.857143 -snap {("uut" 4)}
wvSetCursor -win $_nWave3 37694.642857 -snap {("uut" 2)}
wvSetCursor -win $_nWave3 109116.071429 -snap {("uut" 6)}
wvZoomIn -win $_nWave3
wvSetCursor -win $_nWave3 61667.113095 -snap {("uut" 4)}
wvSetCursor -win $_nWave3 28270.982143 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 26783.035714 -snap {("uut" 6)}
wvSetCursor -win $_nWave3 26783.035714 -snap {("uut" 6)}
wvSetCursor -win $_nWave3 35380.059524 -snap {("uut" 1)}
wvSetCursor -win $_nWave3 21492.559524 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 22649.851190 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 22815.178571 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 33065.476190 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 46291.666667 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 60675.148810 -snap {("uut" 5)}
wvSetCursor -win $_nWave3 108785.416667 -snap {("uut" 1)}
