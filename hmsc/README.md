## Training
The script `train_model.R` trains a Presence-Absence model using HMSC.

Example data can be found in "../example_data/modelling_data.csv", where:
- each row represents a training image
- columns 1 to 6: metadata
- columns 7 to 40: biological data
- columns 41 to end: environmental data

## Inference
The script `infer_distribution.R` infers the Presence-Absence of VME indicator taxa beyond training locations. It computes the posterior mean and the credible interval. The inference is performed for one sub-area at a time.

As inputs, it takes a model trained with `train_model.R` and the environmental predictors at the inference locations.
Example data for the `df_inference_env` is provided in `../example_data`. But not for `trained_model.Rdata` because large files can't easily be hosted on Github.
