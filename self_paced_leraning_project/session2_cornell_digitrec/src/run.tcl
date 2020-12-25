#=============================================================================
# run.tcl 
#=============================================================================
# @brief: A Tcl script for synthesizing the digit recongnition design.
#
# @desc: This script launches a batch of simulation & synthesis runs
# to quickly explore different K parameters.
#
# 1. The user specifies the list of K values.
# 2. Useful simulation & synthesis stats are consolidated into ./result/result.csv

#------------------------------------------------------
# Remove old result file
#------------------------------------------------------
set filename "knn_result.csv"
file delete -force "./result/${filename}"

#------------------------------------------------------
# You can specify a set of parameter K to explore.
#------------------------------------------------------
#set value_k { 1 2 3 4 5 }
set value_k { 3 }
#------------------------------------------------------
# run batch experiments
#------------------------------------------------------
foreach { K } $value_k {

# Define the bitwidth macros from CFLAGs
set CFLAGS "-DK_CONST=${K}"

# Project name
#set hls_prj ${K}-nn.prj
set hls_prj ${K}-nn-opt.prj

# Open/reset the project
open_project ${hls_prj} -reset
# Top function of the design is "digitrec"
set_top digitrec

# Add design and testbench files
add_files digitrec.cpp -cflags $CFLAGS
add_files -tb digitrec_test.cpp -cflags $CFLAGS
add_files -tb data

open_solution "solution1"
# Use Zynq device
set_part {xc7z020clg484-1}

# Target clock period is 10ns
create_clock -period 10

# Do not inline update_knn and knn_vote functions 
set_directive_inline -off update_knn
set_directive_inline -off knn_vote
### You can add your own directives here ###

# Partition the knn_set[][] array so that 10 lanes can work in parallel
set_directive_array_partition -type complete digitrec knn_set

# Partition the training dataset to support 10 outstanding reads
set_directive_array_partition -type block -factor 10 digitrec training_data

# Unroll the inner loop of the main calculation
set_directive_loop_unroll digitrec/DIGITREC_PROC_LOOP_INNER

# Other relevant array partitions
set_directive_array_partition -type complete knn_vote cur_dist
set_directive_array_partition -type complete knn_vote cur_digit
set_directive_array_partition -type complete knn_vote vote

# Other relevant unrollings
set_directive_loop_unroll digitrec/DIGITREC_INIT_LOOP_INNER
set_directive_loop_unroll digitrec/DIGITREC_INIT_LOOP_OUTER
set_directive_loop_unroll update_knn/UPDATE_DIFF_LOOP
set_directive_loop_unroll update_knn/UPDATE_DIST_LOOP
set_directive_loop_unroll knn_vote/VOTE_INIT_DIST_LOOP
set_directive_loop_unroll knn_vote/VOTE_INIT_VOTE_LOOP
set_directive_loop_unroll knn_vote/VOTE_MIN_DIST_DIGIT_LOOP
set_directive_loop_unroll knn_vote/VOTE_MIN_DIST_CONST_LOOP
set_directive_loop_unroll knn_vote/VOTE_MIN_DIST_CUR_CONST_LOOP
set_directive_loop_unroll knn_vote/VOTE_CALC_VOTE_LOOP
set_directive_loop_unroll knn_vote/VOTE_FIND_MAX_VOTE_LOOP

# Simulate the C++ design
csim_design
# Synthesize the design
csynth_design
# Co-simulate the design
#cosim_design

#---------------------------------------------
# Collect & dump out results from HLS reports
#---------------------------------------------
set argv [list $filename $hls_prj]
set argc 2
source "./script/collect_result.tcl"
}
quit
