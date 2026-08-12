# Hospital Readmission Risk Prediction

Predicting which patients are at risk of being readmitted to the hospital within 30 days of discharge, using a 25,000-patient dataset spanning demographics, clinical history, and treatment intensity.

**Course project — BUAN 6337.501, Group 2.** Built collaboratively with Rufus Vernon and Chaitanya Nimmagadda. My contributions covered data preprocessing and feature engineering, exploratory analysis, and the Random Forest and GBM modeling and evaluation.

## Business Problem

Hospital readmissions cost the U.S. healthcare system billions of dollars a year, and CMS penalizes hospitals with high readmission rates. The goal was to flag at-risk patients at discharge so hospitals can prioritize follow-up care and reduce avoidable readmissions.

## Data

- 25,000 patient records, 17 variables: age, time in hospital, lab procedures, medications, prior visits (outpatient/inpatient/emergency), diagnosis codes, glucose/A1C test results, diabetes medication status, and the readmission outcome.
- - Cleaned missing-value codes (`?`, `Unknown`, `NA`) into true NAs, converted clinical counts to numeric and categorical fields to factors, and removed incomplete rows.
  - - Engineered `total_prior_visits`, `multiple_prior_visits` (>2 visits), and `high_medication_burden` (>10 medications) as additional features.
    - - 70/30 train-test split (17,500 / 7,500 patients), stratified to preserve class balance.
     
      - ## Approach
     
      - 1. Hypothesis testing - chi-square tests on age group and diabetes medication status against readmission, plus a t-test on length of stay, to confirm which factors were worth modeling before building anything.
        2. 2. EDA - distribution of readmission status, length of stay, medication count, and prior visits by outcome, and readmission rate by age group.
           3. 3. Modeling - compared three classifiers on the same train/test split: Logistic Regression (baseline), Decision Tree (rpart), Random Forest (randomForest). A Gradient Boosting model (gbm) was also fit as an additional comparison point.
             
              4. ## Results
             
              5. | Model | Accuracy | Sensitivity | Specificity | Balanced Accuracy | AUC |
              6. |---|---|---|---|---|---|
              7. | Logistic Regression | 61.17% | 0.78 | 0.42 | 0.60 | 0.64 |
              8. | Decision Tree | 59.87% | 0.64 | 0.55 | 0.60 | - |
              9. | Random Forest | 60.65% | 0.69 | 0.51 | 0.6008 | 0.6388 |
             
              10. Logistic Regression had the highest raw accuracy, but that came from defaulting toward the majority "not readmitted" class (high sensitivity, weak specificity). Random Forest was selected as the strongest model because it gave the best balance between correctly catching readmissions and non-readmissions, and its variable importance output was the most useful for the business recommendations below.
             
              11. Top predictors: number of lab procedures, medication count, time in hospital, and prior inpatient visits, pointing to treatment intensity and patient complexity as the strongest readmission signals.
             
              12. ## Business Recommendations
             
              13. - Prioritize patients with high procedure counts, high medication burden, or multiple prior inpatient visits for discharge follow-up and early intervention.
                  - - Strengthen discharge planning with medication reviews and follow-up scheduling for flagged patients.
                    - - Longer-term: embed the Random Forest model as an automated risk score in the hospital's EMR system, with a clinician-facing dashboard flagging high-risk patients at discharge.
                     
                      - ## Repo Contents
                     
                      - - `hospital_readmission_analysis.R` - preprocessing, feature engineering, EDA, hypothesis testing, Logistic Regression, Random Forest, and GBM models.
                        - - `decision_tree_model.R` - the Decision Tree model. Reconstructed from the project's documented methodology since the original code file wasn't available; it uses the same train/test split and target variable as the main script.
                          - - `hospital_readmissions.csv` - the dataset (see note below on how to access it).
                            - - `Predictive_Analytics_Project_Deck.pptx` - the full project presentation, including EDA visuals, hypothesis test results, and the model comparison this README summarizes.
                             
                              - ## Note on Reconstructed Code
                             
                              - `decision_tree_model.R` was rebuilt from the deck's documented approach and reported metrics rather than recovered from an original file. It's flagged in a header comment in that file. The other three models (Logistic Regression, Random Forest, GBM) are the original code as written for the project.
                             
                              - ## Tools
                             
                              - R (caret, randomForest, rpart, gbm, ggplot2)
                              - 
