#!/bin/bash
set -eu

# WORKFLOW SH
# Main user entry point

if [[ ${#} != 1 ]]
then
  echo "Usage: ./workflow.sh EXPERIMENT_ID"
  exit 1
fi
export EXPID=$1

# Turn off Swift/T debugging
export TURBINE_LOG=0 TURBINE_DEBUG=0 ADLB_DEBUG=0

# Find my installation directory
export EMEWS_PROJECT_ROOT=$( cd $( dirname $0 ) ; /bin/pwd )

export MODEL_SH=$EMEWS_PROJECT_ROOT/model.sh
export MODEL_NAME="nt3"

# Set the output directory
export TURBINE_OUTPUT=$EMEWS_PROJECT_ROOT/experiments/$EXPID
mkdir -pv $TURBINE_OUTPUT

# Total number of processes available to Swift/T
# Of these, 2 are reserved for the system
export PROCS=3

# EMEWS resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

# mlrMBO settings
PARAM_SET_FILE=$EMEWS_PROJECT_ROOT/data/params.R
MAX_CONCURRENT_EVALUATIONS=2
MAX_ITERATIONS=3

# Benchmark settings
BENCHMARK_TIMEOUT=${BENCHMARK_TIMEOUT:-3600}

# Construct the command line given to Swift/T
CMD_LINE_ARGS=( -pp=$MAX_CONCURRENT_EVALUATIONS
                -it=$MAX_ITERATIONS
                -param_set_file=$PARAM_SET_FILE
              )

# USER: Set this to 1 if on Bebop:
BEBOP=0
# BEBOP=1

if (( BEBOP ))
then
  EQR=/home/wozniak/Public/sfw/bebop/EQ-R

  # Scheduler settings for Swift/T on large systems (unused for laptops)
  # export QUEUE=batch
  export WALLTIME=00:10:00
  # Processes per node
  export PPN=1
  # The job name in the scheduler (shows in qstat)
  export TURBINE_JOBNAME="${EXPID}"
  # Set MACHINE to your schedule type (e.g. pbs, slurm, cobalt etc.),
  # or empty for an immediate non-queued unscheduled run
  MACHINE="-m slurm"

  module add bzip2

  # Set up R
  R=/home/wozniak/Public/sfw/bebop/R-3.4.3/lib64/R
  export LD_LIBRARY_PATH=$R/lib:$R/library/Rcpp/lib:$R/library/RInside/lib

  # Set up LD_LIBRARY_PATH for Swift/T
  LLP=$LD_LIBRARY_PATH:/blues/gpfs/home/software/spack-0.10.1/opt/spack/linux-centos7-x86_64/gcc-7.1.0/bzip2-1.0.6-pvvwqlj6u6vvumzqdybb3svmod5qwzbu/lib
  ENVS="-e LD_LIBRARY_PATH=$LLP"

  # Set Swift/T PATHs
  PATH=/soft/jdk/1.8.0_51/bin:$PATH
  PATH=/home/wozniak/Public/sfw/bebop/compute/swift-t-dl/stc/bin:$PATH

else
  EQR=$EMEWS_PROJECT_ROOT/EQ-R
  # USER: set the R variable to your R installation
  R=$HOME/Public/sfw/R-3.4.3/lib/R
  export LD_LIBRARY_PATH=$R/lib:$R/library/Rcpp/lib:$R/library/RInside/lib
  MACHINE=""
  ENVS=""
fi

set -x
swift-t $MACHINE -p -n $PROCS \
        -I $EQR -r $EQR $ENVS \
        $EMEWS_PROJECT_ROOT/workflow.swift ${CMD_LINE_ARGS[@]}
set +x

if (( BEBOP ))
then
  echo WORKFLOW SUBMITTED.
else
  echo WORKFLOW COMPLETE.
fi
