
/*
  WORKFLOW.SWIFT
*/

import files;
import string;
import sys;
import io;
import stats;
import math;
import location;
import assert;
import R;

import EQR;

string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string r_ranks[] = split(resident_work_ranks,",");
int propose_points = toint(argv("pp", "3"));
int max_budget = toint(argv("mb", "110"));
int max_iterations = toint(argv("it", "5"));
int design_size = toint(argv("ds", "10"));
string param_set = argv("param_set_file");
string model_name = argv("model_name");
string exp_id = argv("exp_id");
int benchmark_timeout = toint(argv("benchmark_timeout", "-1"));
string obj_param = argv("obj_param", "val_loss");
string site = argv("site");

string FRAMEWORK = "keras";

// Call to objective function: the NN model,
//  then get results from output file
(string result) obj(string params, string run_id)
{
  string model_sh       = getenv("MODEL_SH");
  string turbine_output = getenv("TURBINE_OUTPUT");

  string outdir = "%s/run/%s" % (turbine_output, run_id);
  // printf("running model shell script in: %s", outdir);
  string result_file = outdir/"result.txt";
  wait (run_model(model_sh, params, run_id))
  {
    result = get_results(result_file);
  }
  printf("result(%s): %s", run_id, result);
}

// Run the Python code
app (void o) run_model (string model_sh, string params,
                        string run_id)
{
  //                  1         2      3
  "bash" model_sh FRAMEWORK params run_id;
}

// Get the results from a NN run
(string obj_result) get_results(string result_file)
{
  if (file_exists(result_file))
  {
    file line = input(result_file);
    obj_result = trim(read(line));
  }
  else
  {
    printf("File not found: %s", result_file);
    obj_result = "NaN";
  }
}

(void v) loop(location ME, int ME_rank)
{
  for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    string params =  EQR_get(ME);
    boolean c;

    if (params == "DONE")
    {
      // We are done: store the final results
      string finals =  EQR_get(ME);
      string fname = "%s/final_res.Rds" % (turbine_output);
      printf("See results in %s", fname) =>
        // printf("Results: %s", finals) =>
        v = make_void() =>
        c = false;
    }
    else if (params == "EQR_ABORT")
    {
      printf("EQR aborted: see output for R error") =>
        string why = EQR_get(ME);
      printf("%s", why) =>
        v = propagate() =>
        c = false;
    }
    else
    {
      string param_array[] = split(params, ";");
      string results[];
      foreach p, j in param_array
      {
        results[j] = obj(p, "%000i_%0000i" % (i,j));
      }
      string res = join(results, ";");
      // printf(res);
      EQR_put(ME, res) => c = true;
    }
  }
}

// These must agree with the arguments to the objective function in mlrMBO3.R,
// except param.set.file is removed and processed by the mlrMBO.R algorithm wrapper.
string algo_params_template =
"""
param.set.file='%s',
max.budget = %d,
max.iterations = %d,
design.size=%d,
propose.points=%d
""";

(void o) start(int ME_rank) {
    location ME = locationFromRank(ME_rank);

    // algo_params is the string of parameters used to initialize the
    // R algorithm. We pass these as R code: a comma separated string
    // of variable=value assignments.
    string algo_params = algo_params_template %
      (param_set, max_budget, max_iterations,
       design_size, propose_points);
    string algorithm = emews_root/"mlrMBO3.R";
    EQR_init_script(ME, algorithm) =>
    EQR_get(ME) =>
    EQR_put(ME, algo_params) =>
    loop(ME, ME_rank) => {
        EQR_stop(ME) =>
        EQR_delete_R(ME);
        o = propagate();
    }
}

main() {

  assert(strlen(emews_root) > 0, "Set EMEWS_PROJECT_ROOT!");

  int ME_ranks[];
  foreach r_rank, i in r_ranks{
    ME_ranks[i] = toint(r_rank);
  }

  foreach ME_rank, i in ME_ranks {
    start(ME_rank) =>
    printf("End rank: %d", ME_rank);
  }
}

// Local Variables:
// c-basic-offset: 2
// End:
