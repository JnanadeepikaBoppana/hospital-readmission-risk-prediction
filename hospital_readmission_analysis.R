##############################################
# Hospital Readmissions - Data Preprocessing
##############################################

# 0. Clear environment
rm(list = ls())

# 1. Read the data
data_raw <- read.csv("hospital_readmissions.csv", stringsAsFactors = FALSE)

# Quick check
str(data_raw)
summary(data_raw)

# 2. Work on a copy
data <- data_raw

# 3. Replace common missing codes with NA
data[data == "?"] <- NA
data[data == "Unknown"] <- NA
data[data == "NA"] <- NA

# 4. Convert numeric columns to numeric
numeric_cols <- c("time_in_hospital", "n_lab_procedures", "n_procedures",
                                     "n_medications", "n_outpatient", "n_inpatient", "n_emergency")

for (col in numeric_cols) {
    if (col %in% names(data)) {
          data[[col]] <- as.numeric(data[[col]])
        }
  }

# 5. Convert categorical columns to factors
factor_cols <- c("age", "medical_specialty", "diag_1", "diag_2", "diag_3",
                                   "glucose_test", "A1Ctest", "change", "diabetes_med", "readmitted")

for (col in factor_cols) {
    if (col %in% names(data)) {
          data[[col]] <- as.factor(data[[col]])
        }
  }

# 6. FIX TARGET VARIABLE: readmitted (use existing yes/no)
# dataset has: "no" and "yes"
data$readmitted <- tolower(as.character(data$readmitted))
data$readmitted <- factor(data$readmitted, levels = c("no", "yes"), labels = c("No", "Yes"))

# 7. Feature engineering

# 7a. Total prior visits
data$total_prior_visits <- with(data, n_outpatient + n_inpatient + n_emergency)

# 7b. Multiple prior visits flag
data$multiple_prior_visits <- ifelse(data$total_prior_visits > 2, "Yes", "No")
data$multiple_prior_visits <- factor(data$multiple_prior_visits, levels = c("No", "Yes"))

# 7c. High medication burden flag (e.g., > 10 meds)
data$high_medication_burden <- ifelse(data$n_medications > 10, "Yes", "No")
data$high_medication_burden <- factor(data$high_medication_burden, levels = c("No", "Yes"))

# 8. Remove rows with any NA (simple approach for project)
data_complete <- na.omit(data)
cat("Rows before removing NA:", nrow(data), "\n")
cat("Rows after removing NA :", nrow(data_complete), "\n")

# Ensure target is still correctly set
data_complete$readmitted <- factor(data_complete$readmitted, levels = c("No", "Yes"))

# Check class balance
table(data_complete$readmitted)

# 9. Train-test split (70% train, 30% test)
set.seed(123) # for reproducibility
n <- nrow(data_complete)
train_size <- floor(0.7 * n)
train_indices <- sample(seq_len(n), size = train_size)
train_data <- data_complete[train_indices, ]
test_data <- data_complete[-train_indices, ]

cat("Train rows:", nrow(train_data), "\n")
cat("Test rows :", nrow(test_data), "\n")

# Check target in train/test
table(train_data$readmitted)
table(test_data$readmitted)

##############################################
# IMPORTANT:
# Use 'readmitted' as the target variable
# Example model formula: readmitted ~ .
##############################################

##############################################
# Exploratory Data Analysis (EDA)
##############################################

library(ggplot2)

# 1. Distribution of Readmission
ggplot(train_data, aes(readmitted)) +
  geom_bar() +
  ggtitle("Distribution of Readmission Status") +
  xlab("Readmitted") +
  ylab("Number of Patients")

# 2. Length of Stay vs Readmission
ggplot(train_data, aes(x = readmitted, y = time_in_hospital)) +
  geom_boxplot() +
  ggtitle("Length of Stay by Readmission Status") +
  xlab("Readmitted") +
  ylab("Time in Hospital (days)")

# 3. Number of Medications vs Readmission
ggplot(train_data, aes(x = readmitted, y = n_medications)) +
  geom_boxplot() +
  ggtitle("Medication Count by Readmission Status") +
  xlab("Readmitted") +
  ylab("Number of Medications")

# 4. Total Prior Visits vs Readmission
ggplot(train_data, aes(x = readmitted, y = total_prior_visits)) +
  geom_boxplot() +
  ggtitle("Prior Visits by Readmission Status") +
  xlab("Readmitted") +
  ylab("Total Prior Visits")

# 5. Age vs Readmission (proportions)
ggplot(train_data, aes(x = age, fill = readmitted)) +
  geom_bar(position = "fill") +
  ggtitle("Readmission Rate by Age Group") +
  xlab("Age Group") +
  ylab("Proportion") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

##############################################
# Hypothesis Testing
##############################################

tbl_age <- table(train_data$age, train_data$readmitted)
chisq.test(tbl_age)

tbl_diab <- table(train_data$diabetes_med, train_data$readmitted)
chisq.test(tbl_diab)

t.test(time_in_hospital ~ readmitted, data = train_data)

##############################################
# Modeling
##############################################

library(caret)

# Use all predictors except maybe very high-cardinality ones if needed.
# For now, simple approach: use everything except readmitted as predictor.

log_model <- glm(readmitted ~ ., data = train_data, family = binomial)
summary(log_model)

# Predictions on test set
log_prob <- predict(log_model, newdata = test_data, type = "response")
log_pred <- ifelse(log_prob > 0.5, "Yes", "No")
log_pred <- factor(log_pred, levels = c("No", "Yes"))

# Confusion matrix
cm_log <- confusionMatrix(log_pred, test_data$readmitted, positive = "Yes")
cm_log

library(randomForest)
set.seed(123)
rf_model <- randomForest(readmitted ~ ., data = train_data,
                                                   ntree = 300, mtry = 4, importance = TRUE)
rf_model

# Predict
rf_pred <- predict(rf_model, newdata = test_data)
cm_rf <- confusionMatrix(rf_pred, test_data$readmitted, positive = "Yes")
cm_rf

# Variable importance
varImpPlot(rf_model)

library(gbm)
set.seed(123)
gbm_model <- gbm(
    formula = as.numeric(readmitted) - 1 ~ .,
    data = train_data,
    distribution = "bernoulli",
    n.trees = 500,
    interaction.depth = 3,
    shrinkage = 0.01,
    n.minobsinnode = 20,
    verbose = FALSE
  )

# Predict
gbm_prob <- predict(gbm_model, newdata = test_data, n.trees = 500, type = "response")
gbm_pred <- ifelse(gbm_prob > 0.5, "Yes", "No")
gbm_pred <- factor(gbm_pred, levels = c("No", "Yes"))
cm_gbm <- confusionMatrix(gbm_pred, test_data$readmitted, positive = "Yes")
cm_gbm

# Feature importance
summary(gbm_model)
