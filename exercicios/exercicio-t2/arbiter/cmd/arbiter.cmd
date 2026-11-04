simSetSimulator "-vcssv" -exec "./simv" -args " " -uvmDebug on
debImport "-i" "-simflow" "-dbdir" "./simv.daidir"
srcTBInvokeSim
verdiSetActWin -dock widgetDock_<Member>
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
simSetSimulator "-vcssv" -exec \
           "/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/arbiter/simv" \
           -args
debImport "-dbdir" \
          "/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/arbiter/simv.daidir"
srcTBDelAllBrkPnt
wvCreateWindow
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/arbiter/arbiter.fsdb}
srcHBSelect "arbiter_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "arbiter_tb.uu_arbiter_if" -win $_nTrace1
srcHBSelect "arbiter_tb" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "arbiter_tb"
wvSetPosition -win $_nWave3 {("arbiter_tb" 0)}
wvRenameGroup -win $_nWave3 {G1} {arbiter_tb}
wvSelectGroup -win $_nWave3 {arbiter_tb}
verdiSetActWin -win $_nWave3
srcHBSelect "arbiter_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "arbiter_tb.uu_arbiter_if" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "arbiter_tb.uu_arbiter_if"
wvSetPosition -win $_nWave3 {("uu_arbiter_if(arbiter_if)" 0)}
wvRenameGroup -win $_nWave3 {arbiter_tb} {uu_arbiter_if(arbiter_if)}
wvAddSignal -win $_nWave3 "/arbiter_tb/uu_arbiter_if/clk" \
           "/arbiter_tb/uu_arbiter_if/reset_n" \
           "/arbiter_tb/uu_arbiter_if/priority_sel" \
           "/arbiter_tb/uu_arbiter_if/client1_req" \
           "/arbiter_tb/uu_arbiter_if/client2_req" \
           "/arbiter_tb/uu_arbiter_if/o_grant1" \
           "/arbiter_tb/uu_arbiter_if/o_grant2" \
           "/arbiter_tb/uu_arbiter/curr_state" \
           "/arbiter_tb/uu_arbiter/client1_req_d" \
           "/arbiter_tb/uu_arbiter/client2_req_d"
wvSetPosition -win $_nWave3 {("uu_arbiter_if(arbiter_if)" 0)}
wvSetPosition -win $_nWave3 {("G2" 0)}
srcTBRunSim
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3
