simSetSimulator "-vcssv" -exec "./simv" -args "-l simv.log" -uvmDebug on \
           -simDelim
debImport "-i" "-simflow" "-dbdir" "./simv.daidir"
srcTBInvokeSim
verdiSetActWin -dock widgetDock_<Member>
verdiWindowResize -win $_Verdi_1 "235" "92" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiSetActWin -win $_InteractiveConsole_2
srcHBSelect "robot_model_tb.u_robot_model" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "robot_model_tb" -win $_nTrace1
simSetSimulator "-vcssv" -exec \
           "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x03-robot-ref/sim/simv" \
           -args -simDelim
debImport "-dbdir" \
          "/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x03-robot-ref/sim/simv.daidir"
srcTBDelAllBrkPnt
wvCreateWindow
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/gabriel.magalhaes/workspace/synopsis-dv-track-prv/prj/0x03-robot-ref/sim/robot_model.fsdb}
srcHBSelect "robot_model_tb.u_robot_model" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "robot_model_tb" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "robot_model_tb"
wvSetPosition -win $_nWave3 {("robot_model_tb" 0)}
wvRenameGroup -win $_nWave3 {G1} {robot_model_tb}
srcHBSelect "robot_model_tb.u_robot_model" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvDumpScope "robot_model_tb.u_robot_model"
wvSetPosition -win $_nWave3 {("u_robot_model" 0)}
wvRenameGroup -win $_nWave3 {robot_model_tb} {u_robot_model}
wvAddSignal -win $_nWave3 "/robot_model_tb/u_robot_model/clock" \
           "/robot_model_tb/u_robot_model/reset_n" \
           "/robot_model_tb/u_robot_model/s0_req" \
           "/robot_model_tb/u_robot_model/s1_req" \
           "/robot_model_tb/u_robot_model/s2_req" \
           "/robot_model_tb/u_robot_model/s3_req" \
           "/robot_model_tb/u_robot_model/s0_unloadstart" \
           "/robot_model_tb/u_robot_model/s1_unloadstart" \
           "/robot_model_tb/u_robot_model/s2_unloadstart" \
           "/robot_model_tb/u_robot_model/s3_unloadstart" \
           "/robot_model_tb/u_robot_model/s0_unload_done" \
           "/robot_model_tb/u_robot_model/s1_unload_done" \
           "/robot_model_tb/u_robot_model/s2_unload_done" \
           "/robot_model_tb/u_robot_model/s3_unload_done" \
           "/robot_model_tb/u_robot_model/load_start"
wvSetPosition -win $_nWave3 {("u_robot_model" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model" 15)}
wvSetPosition -win $_nWave3 {("u_robot_model" 15)}
wvSetCursor -win $_nWave3 252.032520 -snap {("u_robot_model" 9)}
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3
wvScrollDown -win $_nWave3 1
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollUp -win $_nWave3 1
wvScrollDown -win $_nWave3 1
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvZoom -win $_nWave3 0.000000 376.657459
wvScrollUp -win $_nWave3 6
wvScrollDown -win $_nWave3 4
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollUp -win $_nWave3 4
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvScrollDown -win $_nWave3 0
wvSetCursor -win $_nWave3 53.623363 -snap {("u_robot_model" 4)}
wvZoomAll -win $_nWave3
verdiDockWidgetHide -dock widgetDock_<Watch>
srcTBSetHiddenView -view WatchView
srcTBRunSim
wvSelectGroup -win $_nWave3 {G2}
wvSelectSignal -win $_nWave3 {( "u_robot_model" 1 )} 
wvSelectGroup -win $_nWave3 {u_robot_model}
wvSelectGroup -win $_nWave3 {G2}
wvSetPosition -win $_nWave3 {("u_robot_model" 14)}
wvSetPosition -win $_nWave3 {("u_robot_model" 13)}
wvSetPosition -win $_nWave3 {("u_robot_model" 12)}
wvSetPosition -win $_nWave3 {("u_robot_model" 11)}
wvSetPosition -win $_nWave3 {("u_robot_model" 10)}
wvSetPosition -win $_nWave3 {("u_robot_model" 8)}
wvSetPosition -win $_nWave3 {("u_robot_model" 7)}
wvSetPosition -win $_nWave3 {("u_robot_model" 6)}
wvSetPosition -win $_nWave3 {("u_robot_model" 5)}
wvSetPosition -win $_nWave3 {("u_robot_model" 4)}
wvSetPosition -win $_nWave3 {("u_robot_model" 3)}
wvSetPosition -win $_nWave3 {("u_robot_model" 2)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model" 2)}
wvSetPosition -win $_nWave3 {("u_robot_model" 16)}
wvSetPosition -win $_nWave3 {("u_robot_model" 16)}
wvSetPosition -win $_nWave3 {("u_robot_model" 2)}
wvSelectSignal -win $_nWave3 {( "u_robot_model" 4 )} 
wvSelectSignal -win $_nWave3 {( "u_robot_model" 4 5 6 )} 
wvSelectSignal -win $_nWave3 {( "u_robot_model" 4 5 6 7 )} 
wvSetPosition -win $_nWave3 {("u_robot_model" 4)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 4)}
wvSelectGroup -win $_nWave3 {u_robot_model/G2}
wvRenameGroup -win $_nWave3 {u_robot_model/G2} {Request}
wvSelectGroup -win $_nWave3 {G2}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 3)}
wvSetPosition -win $_nWave3 {("G2" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 3)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 3)}
wvSetPosition -win $_nWave3 {("u_robot_model" 17)}
wvSetPosition -win $_nWave3 {("u_robot_model" 17)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 3)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/Request/G2" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 5)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvSelectSignal -win $_nWave3 {( "u_robot_model" 9 )} 
wvSelectSignal -win $_nWave3 {( "u_robot_model" 9 10 11 12 )} 
wvSetPosition -win $_nWave3 {("u_robot_model" 9)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 4)}
wvSelectGroup -win $_nWave3 {u_robot_model/G2}
wvRenameGroup -win $_nWave3 {u_robot_model/G2} {Unload START}
wvSelectGroup -win $_nWave3 {G2}
wvSelectGroup -win $_nWave3 {G2}
wvSetPosition -win $_nWave3 {("u_robot_model" 17)}
wvSetPosition -win $_nWave3 {("u_robot_model" 16)}
wvSetPosition -win $_nWave3 {("u_robot_model" 15)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 4)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 3)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 4)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 4)}
wvSetPosition -win $_nWave3 {("u_robot_model" 18)}
wvSetPosition -win $_nWave3 {("u_robot_model" 18)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 4)}
wvSelectSignal -win $_nWave3 {( "u_robot_model" 14 )} 
wvSelectSignal -win $_nWave3 {( "u_robot_model" 14 15 16 17 )} 
wvSelectSignal -win $_nWave3 {( "u_robot_model" 14 15 16 17 )} 
wvSetPosition -win $_nWave3 {("u_robot_model" 14)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 4)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model/G2" 4)}
wvSelectGroup -win $_nWave3 {u_robot_model/G2}
wvRenameGroup -win $_nWave3 {u_robot_model/G2} {Unload DONE}
wvSelectSignal -win $_nWave3 {( "u_robot_model" 18 )} 
wvSetPosition -win $_nWave3 {("u_robot_model/Unload DONE" 3)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 4)}
wvSetPosition -win $_nWave3 {("u_robot_model/Unload START" 1)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 3)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 2)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 1)}
wvSetPosition -win $_nWave3 {("u_robot_model/Request" 0)}
wvSetPosition -win $_nWave3 {("u_robot_model" 2)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("u_robot_model" 2)}
wvSetPosition -win $_nWave3 {("u_robot_model" 3)}