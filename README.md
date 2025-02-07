# Planned Giving Propensity Model

A machine learning solution to optimize planned giving donor targeting for the National Parks Conservation Association.

## Project Overview

This project implements a Random Forest classifier to identify potential planned giving donors, improving mailing efficiency and response rates. The model processes donor data through Snowflake's computing infrastructure and uses SMOTE sampling to handle class imbalance.

## Key Results

- Achieved 0.88 PR-AUC score, demonstrating strong performance on imbalanced data
- Attained 0.8125 F1 score, balancing precision (0.7558) and recall (0.8784)
- Demonstrated 90.9% recall rate in identifying existing planned giving donors
- Identified 1,019 high-potential future donors for targeted outreach
- Enabled data-driven mailing list optimization across 4.5M+ constituent records

## Technical Implementation

### Data Pipeline
- Extracted donor data from CRM system into Snowflake
- Implemented modular Python processing scripts for scalability
- Utilized Snowflake's computing infrastructure for efficient data handling

### [Machine Learning](https://github.com/dbouquin/bequest_modeling/blob/main/snowflake_ml/split_SMOTE_crossval.py)
- Developed Random Forest classifier with cross-validation
- Applied SMOTE for balanced training samples
- Used multiple imputation strategies (MICE, mean, median) for handling missing data
- Engineered temporal features like time between gifts

### [Model Performance and Validation](https://github.com/dbouquin/bequest_modeling/blob/main/snowflake_ml/snowflake_model_evaluation.ipynb)
The model achieved exceptional performance on this imbalanced dataset, with metrics demonstrating its effectiveness in identifying potential planned giving donors:

- The 0.88 PR-AUC score indicates strong ability to distinguish between bequestors and non-bequestors while balancing precision and recall
- An F1 score of 0.8125 shows the model successfully balances false positives and false negatives
- High recall (0.8784) ensures we capture a large proportion of potential donors
- Precision of 0.7558 indicates good accuracy in positive predictions, minimizing unnecessary mailings

Post-modeling analysis revealed strong concurrence with existing donor engagement indicators that were not used in training:
- 66.3% of predicted donors were independently flagged as planned giving prospects
- 37.6% belong to major donor households
- 21.4% are mid-level donors
- 18% are Mather Legacy Society members

This alignment with established indicators validates the model's ability to identify high-potential donors through behavioral patterns.

Feature importance analysis revealed key predictors:
  1. Highest Previous Contribution (22.8%)
  2. Most Recent Contribution (20.1%)
  3. Years Since HPC Gift (14.6%)
  4. Total Amount (14.3%)
  5. Years Since MRC Gift (11.2%)

### Key Demographics of Predicted Donors
- Mean age: 69 years
- Average giving history: 16 years
- Median total donations: $10,932
- Average number of transactions: 18

## Tools and Technologies
- Python (scikit-learn, pandas, numpy)
- Snowflake
- Seaborn/Matplotlib for visualization

## Repository Structure
```
├── data_prep/                        # Data preparation scripts
│   ├── sql/                          # SQL scripts for data extraction
│   └── python/                       # Python scripts for data cleaning
├── model/                      
│   ├── split_SMOTE_crossval.py       # ML model executed on Snowflake
│   └── snowflake_model_evaluation.py # Model evaluation and visualization
├── predictions_analyzed/             # Post-modeling analysis scripts
│   ├── predictions_analyzed.ipynb    # Model concurrance evaluation
│   └── predictions_existing_flags.sql # SQL script for data extraction
└── README.md
```

## Potential Future Improvements
- Schedule automated data refresh and model retraining
- Incorporate additional feature engineering
- Develop dashboard for tracking model performance