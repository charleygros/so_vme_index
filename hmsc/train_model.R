#####################################################################
#
# Description:
#   This script trains a Presence-Absence model using HMSC.
#
# Example data can be found in "../example_data/modelling_data.csv"
#       where:
#           - each row represents a training image
#           - columns 1 to 6: metadata
#           - columns 7 to 40: biological data
#           - columns 41 to end: environmental data
#
# Steps:
#   1. Load data
#   2. Set the random and fixed effects
#   3. Create the unfit model
#   4. Set the modelling parameters
#   5. Train the model
#
#####################################################################

# Install packages
list.of.packages <- c("Hmsc")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Load packages
library(Hmsc)

# Load data
df = read.csv("../example_data/modelling_data.csv")
# Bio data
Y_train = as.data.frame(df[, 7:40])
# Environmental data
X_train = as.data.frame(df[, 41:ncol(df)])
names_covariates = colnames(X_train)
# Metadata
m_train = as.data.frame(df[, 1:6])

# Study design
m_train$filename <- factor(m_train$filename)
# Account for the survey, as a proxy for image quality
m_train$survey <- factor(m_train$survey)
studyDesign <- data.frame(filename=m_train$filename, surveyID=m_train$survey)

# Spatial random effect
xy <- m_train[,4:5]
colnames(xy) = c("x","y")
sRL = xy
rownames(sRL) = m_train$filename

# Knots at 200km distance, 250km min distance:
# Add points between AP and Ross Sea
xy.knots <- rbind(xy,
                  c(-2143647,498436),
                  c(-1916289,355285),
                  c(-2000000,100000),
                  c(-1983655,-368890),
                  c(-1739456,-638350),
                  c(-1621567,-975176),
                  c(-1360527,-1160431),
                  c(-900000,-1300000),
                  c(-627930,-1345685))
# Add points to East Antarctica
xy.knots <- rbind(xy.knots,
                  c(710952,-2154067),
                  c(1115144,-2288798),
                  c(2100359,-1724614),
                  c(2529812,-1017280),
                  c(2757170,-629930),
                  c(2824535,-318366),
                  c(2672963,-57326),
                  c(2656122,254237),
                  c(2487709,498436),
                  c(2386661,742635),
                  c(2268772,1256295),
                  c(2125621,1685748),
                  c(1645644,1812057),
                  c(820421,2056256),
                  c(1200000,2000000))
# Add a point to Weddell Sea
xy.knots <- rbind(xy.knots,
                  c(-1503678,1054199),
                  c(-1436312,1300000),
                  c(-1958393,1298398))
Knots = constructKnots(xy.knots, knotDist = 200000, minKnotDist = 250000)
# Uncomment these lines to visualise the knots
#plot(xy.knots[,1],xy.knots[,2],pch=18, asp=1, col='green')
#points(Knots[,1],Knots[,2],col='red',pch=18)

# Random levels
rL = HmscRandomLevel(sData=sRL, sMethod='GPP', sKnot=Knots)
rL.s = HmscRandomLevel(units=levels(m_train$survey))
rL$nfMax=10
rL.s$nfMax=10

# Bio data
Y_pa = (Y_train > 0) * 1

# X formula
XFormula = ~depth+depth2+logslope+tpi+distance2canyons+distance2canyons2+seafloortemperature+seafloorcurrents_mean+npp_mean+seafloorsalinity

# Unfit model
model_raw = Hmsc(Y = Y_pa,
                 XData = X_train,
                 XFormula = XFormula,
                 distr = "probit",
                 studyDesign = studyDesign,
                 ranLevels = list(filename=rL, surveyID=rL.s))

# Params model
model_name <- "20230628_sp_imgLevel_pa"
thin = 10
samples = 800
transient = ceiling(0.5*samples*thin)
nChains = 4
fname_out <- paste(model_name,
                   "_chains_",as.character(nChains),
                   "_thin_", ... = as.character(thin),
                   "_samples_", as.character(samples),
                   sep = "")
fname_out = file.path(paste(fname_out, ".Rdata", sep = ""))

# Train model
model_fit = sampleMcmc(model_raw,
                       samples = samples,
                       thin = thin,
                       transient = transient,
                       nChains = nChains,
                       nParallel = nChains,
                       initPar = "fixed effects",
                       updater = list(GammaEta = FALSE))

# Save model
save(model_fit, file=fname_out)



