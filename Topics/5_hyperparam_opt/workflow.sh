#!/bin/bash
set -eu

# WORKFLOW SH

if [[ ${#} != 1 ]]
then
  echo "Usage: ./workflow.sh EXPERIMENT_ID "
  exit 1
fi
export EXPID=$1

# export TURBINE_LOG=1 TURBINE_DEBUG=1 ADLB_DEBUG=1

# Find my installation directory
export EMEWS_PROJECT_ROOT=$( cd $( dirname $0 ) ; /bin/pwd )

export TURBINE_OUTPUT=$EMEWS_PROJECT_ROOT/experiments/$EXPID
mkdir -pv $TURBINE_OUTPUT

# Total number of processes available to Swift/T
# Of these, 2 are reserved for the system
export PROCS=3

# EMEWS settings
EQPY=$EMEWS_PROJECT_ROOT/ext/EQ-Py
# EMEWS resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

# Set PYTHONPATH
# Location of the Benchmark- edit this if necessary
P1B1=/usb1/dl-tutorial-build/Benchmarks/Pilot1/P1B1
export PYTHONPATH=
PYTHONPATH+=$EQPY:
PYTHONPATH+=$EMEWS_PROJECT_ROOT/python:
PYTHONPATH+=$P1B1
echo PYTHONPATH=$PYTHONPATH

# mlrMBO settings
PARAM_SET_FILE=$EMEWS_PROJECT_ROOT/data/params.R
MAX_CONCURRENT_EVALUATIONS=2
MAX_ITERATIONS=3

# Benchmark settings
BENCHMARK_TIMEOUT=${BENCHMARK_TIMEOUT:-3600}

# Construct the command line given to Swift/T
CMD_LINE_ARGS=( -pp=$MAX_CONCURRENT_EVALUATIONS
                -it=$MAX_ITERATIONS "
                -param_set_file=$PARAM_SET_FILE )
              )

# Scheduler settings for large systems (unused for laptops)
export QUEUE=batch
export WALLTIME=00:10:00
export PPN=16
export TURBINE_JOBNAME="${EXPID}"
# set machine to your schedule type (e.g. pbs, slurm, cobalt etc.),
# or empty for an immediate non-queued unscheduled run
MACHINE=""

if [ -n "$MACHINE" ]
then
  MACHINE="-m $MACHINE"
fi

which swift-t

set -x
swift-t $MACHINE -p -n $PROCS \
        -I $EQPY -r $EQPY \
        $EMEWS_PROJECT_ROOT/workflow.swift ${CMD_LINE_ARGS[@]}
set +x
echo WORKFLOW COMPLETE.
