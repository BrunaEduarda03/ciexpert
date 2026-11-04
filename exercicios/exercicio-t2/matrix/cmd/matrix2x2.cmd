simSetSimulator "-vcssv" -exec "./simv" -args " " -uvmDebug on
debImport "-i" "-simflow" "-dbdir" "./simv.daidir"
srcTBInvokeSim
verdiSetActWin -dock widgetDock_<Member>
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
simSetSimulator "-vcssv" -exec \
           "/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/matrix/simv" \
           -args
debImport "-dbdir" \
          "/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/matrix/simv.daidir"
srcTBDelAllBrkPnt
wvCreateWindow
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/bruna.maciel/Bruna_Maciel_DV_Atividade2/matrix/matrix2x2.fsdb}
srcHBSelect "matrix_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "matrix_tb.uu_matrix_if" -win $_nTrace1
srcHBSelect "matrix_tb" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "matrix_tb"
wvSetPosition -win $_nWave3 {("matrix_tb" 0)}
wvRenameGroup -win $_nWave3 {G1} {matrix_tb}
wvSelectGroup -win $_nWave3 {matrix_tb}
verdiSetActWin -win $_nWave3
srcHBSelect "matrix_tb" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "matrix_tb.uu_matrix_if" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "matrix_tb.uu_matrix_if"
wvSetPosition -win $_nWave3 {("uu_matrix_if(matrix_if)" 0)}
wvRenameGroup -win $_nWave3 {matrix_tb} {uu_matrix_if(matrix_if)}
wvAddSignal -win $_nWave3 "/matrix_tb/uu_matrix_if/clk" \
           "/matrix_tb/uu_matrix_if/rstn" "/matrix_tb/uu_matrix_if/en" \
           "/matrix_tb/uu_matrix_if/A\[31:0\]" \
           "/matrix_tb/uu_matrix_if/B\[31:0\]" \
           "/matrix_tb/uu_matrix_if/Res\[31:0\]"
wvSetPosition -win $_nWave3 {("uu_matrix_if(matrix_if)" 0)}
wvSetPosition -win $_nWave3 {("G2" 0)}
srcTBRunSim
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3
