##############################################
# Hospital Readmissions - Decision Tree Model
##############################################
# NOTE: This script was reconstructed from the project's documented
# methodology (see Predictive_Analytics_Project_Deck.pptx, slide 12) because
# the original Decision Tree code file was not available. It assumes the
# same preprocessing, train/test split, and target variable defined in
# hospital_readmission_analysis.R. The deck reports test accuracy 59.87%,
# sensitivity 0.64, specificity 0.55, balanced accuracy 0.60, with the
# primary split on total_prior_visits - run this after
# hospital_readmission_analysis.R (through the train/test split step) to
# reproduce a comparable model; exact metrics will vary slightly by R/rpart
# version and are not guaranteed to match the original run precisely.
##############################################

library(rpart)
library(rpart.plot)
library(caret)

# Fit the decision tree on the same train_data used for the other models
set.seed(123)
dt_model <- rpart(readmitted ~ ., data = train_data, method = "class",
                                     control = rpart.control(cp = 0.001, minsplit = 20))

# Inspect the tree and its most important early split
print(dt_model)
rpart.plot(dt_model, main = "Decision Tree - Readmission Risk")

# Predict on the held-out test set
dt_pred <- predict(dt_model, newdata = test_data, type = "class")

# Confusion matrix
cm_dt <- confusionMatrix(dt_pred, test_data$readmitted, positive = "Yes")
cm_dt

# Variable importance
dt_model$variable.importance
