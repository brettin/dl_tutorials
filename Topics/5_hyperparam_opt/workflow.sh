#!/bin/bash
set -eu

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

# Location of the Benchmark- edit this if necessary
P1B1_DIR=$HOME/proj/Benchmarks/Pilot1/P1B1
export PYTHONPATH=$EMEWS_PROJECT_ROOT/ext/EQ-Py:$P1B1_DIR
echo PYTHONPATH=$PYTHONPATH

# EMEWS resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANKS=$(( PROCS - 2 ))

# EQ/Py location
EQPY=$EMEWS_PROJECT_ROOT/ext/EQ-Py

# total number of model runs
EVALUATIONS=4
# concurrent model runs
PARAM_BATCH_SIZE=1

SPACE_FILE="$EMEWS_PROJECT_ROOT/data/space_description.txt"
DATA_DIRECTORY="$EMEWS_PROJECT_ROOT/data"

# TODO edit command line arguments, e.g. -nv etc., as appropriate
# for your EQ/Py based run. $* will pass all of this script's
# command line arguments to the swift script
CMD_LINE_ARGS=( $*
                -seed=1234
                -max_evals=$EVALUATIONS
                -param_batch_size=$PARAM_BATCH_SIZE
                -space_description_file=$SPACE_FILE
                -data_directory=$DATA_DIRECTORY )


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
        $EMEWS_PROJECT_ROOT/workflow.swift $CMD_LINE_ARGS
