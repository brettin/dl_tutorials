
# PARAMS
# Set search space parameters for mlrMBO

param.set <- makeParamSet(
  makeIntegerParam("epochs", lower = 2, upper = 6),
  makeDiscreteParam("dense", values = c("1000 500 100 50"))
)
