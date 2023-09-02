#####################################################################
#
# Description:
#   This script infer the prediction of VME indicator taxa using
#   a model trained with the "train_model.R" script.
#
#   Because inference areas are often very large, we used a for loop
#   One subarea at a time, save it, go to the next one.
#
#####################################################################

# Install packages
list.of.packages <- c("Hmsc", "dplyr", "raster", "plyr", "tidyverse")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Load packages
library(Hmsc)
library(dplyr)
library(raster)
library(plyr)
library(tidyverse)

# Load trained model
load("../example_data/trained_model.Rdata")
names_covariates = colnames(model_fit$X)
names_covariates = names_covariates[2:length(names_covariates)]

# Load the environmental data of the inference locations
path_df_env_full = "modelling/df_env_full.csv"
df_env_full_clean = read.csv("../example_data/df_inference_env.csv")

# We break down the inference space in chunks, to make it computationally bearable
n_cells = 1000
n_chunks <- round(nrow(df_env_full_clean) / n_cells) + 1

# Loop
for (it in 1:n_chunks) {
    # Filename of the predictions for the ith chunk
    fname_out = paste0("../example_data/pred_",
                     str_pad(((it-1) * n_cells + 1), 6, pad = "0", side = "left"),
                     "_",
                     str_pad((it * n_cells), 6, "0", side = "left"),
                     '.Rdata')
    # Check if the predictions have already been done for this chunk, if so, skip it
    if (!file.exists(fname_out)) {
        # Get the environmental values for the current locations
        env_chunk <- df_env_full_clean[((it-1) * n_cells + 1):(it * n_cells),]
        X = env_chunk[, names_covariates]

        # Get spatial data
        xy <- chunk[,2:3]
        colnames(xy) = c("x","y")
        sRL = xy
        rownames(sRL) = chunk$cellID

        # Run predictions
        gradient = Hmsc::prepareGradient(hM = model_fit,
                                         XDataNew = as.data.frame(X),
                                         sDataNew = list(filename=sRL))
        Y_pred = predict(model_fit,
                          nParallel=4,
                          useSocket=FALSE,
                          Gradient=gradient,
                          expected = TRUE)
        rm(gradient)
        rm(X)

        # Get posterior mean
        predY_E = as.data.frame(apply(simplify2array(Y_pred), 1:2, mean))

        # Credible interval
        predY_CI95 <- as.data.frame(apply(simplify2array(Y_pred), 1:2, quantile, probs=0.95))
        rm(Y_pred)

        # Add cellID and coordinates to the results
        predY_E = cbind(chunk[,1:3], predY_E)
        predY_CI95 = cbind(chunk[,1:3], predY_CI95)

        # Round results, to save memory
        predY_E <- predY_E %>% mutate_if(is.numeric, round, digits=3)
        predY_CI95 <- predY_CI95 %>% mutate_if(is.numeric, round, digits=3)

        # Package and save
        lst_result <- list(predY_E = predY_E,
                           predY_CI95 = predY_CI95)
        save(lst_result, file=fname_out)

        # Clean up
        rm(predY_E)
        rm(predY_CI95)
        rm(lst_result)
        gc()
  }
}
