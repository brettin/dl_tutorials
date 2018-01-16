#!/bin/bash
set -eu

# MODEL.SH

# Shell wrapper around Keras model

usage()
{
  echo "Usage: model.sh [-t TIMEOUT] FRAMEWORK PARAMS RUNID"
  echo "The environment should have SITE MODEL_NAME EXPID BENCHMARK_TIMEOUT"
  echo "If TIMEOUT is provided, we run under the shell command timeout"
}

echo MODEL.SH $*

TIMEOUT=""
while getopts "t:" OPTION
do
  case OPTION in
    t) TIMEOUT=$OPTARG ;;
  esac
done
shift $(( OPTIND - 1 ))

if [ ${#} != 3 ]
then
  usage
  exit 1
fi

FRAMEWORK=$1 # Usually "keras"
shift

# JSON string of parameters
PARAMS="$1"
echo $PARAMS
shift

RUNID=$1

# loss or corr
OBJ_PARAM=loss

# Each model run, runs in its own "instance" directory
# Set instance_directory to that and cd into it.
INSTANCE_DIRECTORY=$TURBINE_OUTPUT/run/$RUNID

TIMEOUT_CMD=""
if [ -n "$TIMEOUT" ]; then
  TIMEOUT_CMD="timeout $TIMEOUT"
fi

mkdir -p $INSTANCE_DIRECTORY
LOG_FILE=$INSTANCE_DIRECTORY/model.log
# exec >> $LOG_FILE
# exec 2>&1
cd $INSTANCE_DIRECTORY

# USER: Set the location of your Benchmarks
export PYTHONPATH=$HOME/proj/Benchmarks/Pilot1/NT3

# USER: If on Bebop, uncomment this:
# PATH=/home/wozniak/Public/sfw/anaconda3/bin:$PATH

source $EMEWS_PROJECT_ROOT/utils.sh

BENCHMARK_TIMEOUT=${BENCHMARK_TIMEOUT:-0}

arg_array=( "$EMEWS_PROJECT_ROOT/model_runner.py"
            "$PARAMS"
            "$INSTANCE_DIRECTORY"
            "$FRAMEWORK"
            "$RUNID"
            "$OBJ_PARAM"
            "$BENCHMARK_TIMEOUT")
echo
echo "Using python:"
which python
MODEL_CMD="python ${arg_array[@]}"
echo MODEL_CMD: $MODEL_CMD
if ! $TIMEOUT_CMD python "${arg_array[@]}"
then
   # $? is the exit status of the most recently executed command
   # (i.e the line above)
   CODE=$?
   if [ $CODE == 124 ]; then
     echo "Timeout error in $MODEL_CMD"
     exit 0 # This will trigger a NaN (the result file does not exist)
   else
     echo "Error in $MODEL_CMD"
     exit 1 # Unknown error in Python: abort the workflow
   fi
fi

exit 0 # Success
