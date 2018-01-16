import files;
import string;
import sys;
import io;
import stats;
import python;
import math;
import location;
import assert;
import R;

import EQPy;

// EMEWS settings:
string emews_root = getenv("EMEWS_PROJECT_ROOT");
string turbine_output = getenv("TURBINE_OUTPUT");
string resident_work_ranks = getenv("RESIDENT_WORK_RANKS");
string r_ranks[] = split(resident_work_ranks,",");

// DEAP settings:
string strategy = argv("strategy");
string ga_params_file = argv("ga_params");
string init_params_file = argv("init_params", "");
float mut_prob = string2float(argv("mutation_prob", "0.2"));

string model_name = argv("model_name");
string model_sh = argv("model_sh");
string exp_id = argv("exp_id");
int benchmark_timeout = toint(argv("benchmark_timeout", "-1"));
string obj_param = argv("obj_param", "val_loss");

printf("turbine_output: " + turbine_output);
string site = argv("site");

printf("model_sh: %s", model_sh);

(string obj_result) obj(string params,
                        string run_id) {
  string outdir = "%s/run/%s" % (turbine_output, run_id);
  printf("running model shell script in: %s", outdir);
  string result_file = outdir/"result.txt";
  wait (run_model(params, run_id))
  {
    obj_result = get_results(result_file);
  }
  printf("result(%s): %s", run_id, obj_result);
}

app (void o) run_model (string params_string,
                        string run_id)
{
  "bash" "./model.sh" "keras" params_string run_id ;
}

(string obj_result) get_results(string result_file) {
  if (file_exists(result_file)) {
    file line = input(result_file);
    obj_result = trim(read(line));
  } else {
    printf("File not found: %s", result_file);
    obj_result = "NaN";
  }
}

string FRAMEWORK = "keras";

(void v) loop(location ME, int ME_rank) {

  for (boolean b = true, int i = 1;
       b;
       b=c, i = i + 1)
  {
    string params =  EQPy_get(ME);
    boolean c;

    if (params == "DONE")
    {
      string finals =  EQPy_get(ME);
      // TODO if appropriate
      // split finals string and join with "\\n"
      // e.g. finals is a ";" separated string and we want each
      // element on its own line:
      // multi_line_finals = join(split(finals, ";"), "\\n");
      string fname = "%s/final_result_%i" % (turbine_output, ME_rank);
      file results_file <fname> = write(finals) =>
        printf("Writing final result to %s", fname) =>
        // printf("Results: %s", finals) =>
        v = make_void() =>
        c = false;
    }
    else if (params == "EQPY_ABORT")
    {
      printf("EQPy Aborted");
      string why = EQPy_get(ME);
      // TODO handle the abort if necessary
      // e.g. write intermediate results ...
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
      string result = join(results, ";");
      // printf(res);
      EQPy_put(ME, result) => c = true;
    }
  }
}

(void o) start (int ME_rank, int iters, int pop, int trials, int seed) {
  location ME = locationFromRank(ME_rank);
  algo_params = "%d,%d,%d,'%s',%f, '%s', '%s'" %
    (iters, pop, seed, strategy, mut_prob, ga_params_file, init_params_file);
  EQPy_init_package(ME,"deap_ga") =>
    EQPy_get(ME) =>
    EQPy_put(ME, algo_params) =>
    loop(ME, ME_rank) => {
    EQPy_stop(ME);
    o = propagate();
  }
}

main() {

  assert(strlen(emews_root) > 0, "Set EMEWS_PROJECT_ROOT!");

  int random_seed    = string2int(argv("seed", "0"));
  int num_iter       = string2int(argv("ni","100"));
  int num_variations = string2int(argv("nv", "5"));
  int num_pop        = string2int(argv("np","100"));

  printf("NI: %i # num_iter", num_iter);
  printf("NV: %i # num_variations", num_variations);
  printf("NP: %i # num_pop", num_pop);
  printf("MUTPB: %f # mut_prob", mut_prob);

  int ME_ranks[];
  foreach r_rank, i in r_ranks{
    ME_ranks[i] = string2int(r_rank);
  }

  foreach ME_rank, i in ME_ranks {
    start(ME_rank, num_iter, num_pop, num_variations, random_seed) =>
    printf("End rank: %d", ME_rank);
  }
}

// Local Variables:
// c-basic-offset: 4
// End:
