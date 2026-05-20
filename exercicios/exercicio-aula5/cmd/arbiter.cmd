simSetSimulator "-vcssv" -exec "./simv" -args " " -uvmDebug on
debImport "-i" "-simflow" "-dbdir" "./simv.daidir"
srcTBInvokeSim
verdiSetActWin -dock widgetDock_<Member>
verdiWindowResize -win $_Verdi_1 "377" "144" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
verdiWindowResize -win $_Verdi_1 "131" "54" "1280" "843"
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "arbiter_tb" -win $_nTrace1
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
srcHBSelect "arbiter_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Member>
verdiDockWidgetSetCurTab -dock widgetDock_<Inst._Tree>
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
srcHBSelect "arbiter_tb" -win $_nTrace1
simSetSimulator "-vcssv" -exec \
           "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/simv" \
           -args
debImport "-dbdir" \
          "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/simv.daidir"
srcTBDelAllBrkPnt
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
wvCreateWindow
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x02-verilog-arb/inter.fsdb}
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
srcHBSelect "arbiter_tb" -win $_nTrace1
srcHBSelect "arbiter_tb.uu_arbiter" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "arbiter_tb.uu_arbiter"
wvSetPosition -win $_nWave3 {("uu_arbiter" 0)}
wvRenameGroup -win $_nWave3 {G1} {uu_arbiter}
wvAddSignal -win $_nWave3 "/arbiter_tb/uu_arbiter/clk" \
           "/arbiter_tb/uu_arbiter/reset_n" \
           "/arbiter_tb/uu_arbiter/priority_sel" \
           "/arbiter_tb/uu_arbiter/client1_req" \
           "/arbiter_tb/uu_arbiter/client2_req" \
           "/arbiter_tb/uu_arbiter/o_grant1" "/arbiter_tb/uu_arbiter/o_grant2"
wvSetPosition -win $_nWave3 {("uu_arbiter" 0)}
wvSetPosition -win $_nWave3 {("uu_arbiter" 7)}
wvSetPosition -win $_nWave3 {("uu_arbiter" 7)}
srcTBInvokeSim
srcTBRunSim
wvSetCursor -win $_nWave3 165213.690476 -snap {("uu_arbiter" 5)}
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 80836.071429 -snap {("uu_arbiter" 1)}
wvSetCursor -win $_nWave3 119008.660714 -snap {("uu_arbiter" 4)}
