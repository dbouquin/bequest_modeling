import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col
from sklearn.experimental import enable_iterative_imputer
from sklearn.impute import SimpleImputer, IterativeImputer
from imblearn.over_sampling import SMOTE
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score, precision_recall_curve, auc
from sklearn.model_selection import StratifiedKFold
import pandas as pd
import numpy as np
import json

def main(session: snowpark.Session): 
    # Load data from table
    df = session.table("PUBLIC.BEQUESTS_CLEAN").to_pandas()

    # Define imputers (only mean and mice)
    imputers = {
        'mean': SimpleImputer(strategy='mean'),
        'median': SimpleImputer(strategy='median'),
        'mice': IterativeImputer(random_state=42)
    }

    # Store results
    results_dead = []
    results_alive = []
    results_modeling = []

    # Function to evaluate imputation method
    def evaluate_imputation(df, imputer_name, imputer):
        # Impute BIRTH_YEAR
        df['BIRTH_YEAR'] = imputer.fit_transform(df[['BIRTH_YEAR']])
        
        # Encode categorical variables
        df = pd.get_dummies(df, columns=['REGION_CODE'], drop_first=True)
        
        # Define features after one-hot encoding
        feature_columns = [
            'TOTAL_TRANSACTIONS',
            'TOTAL_AMOUNT',
            'FIRST_GIFT_AMOUNT',
            'MRC_AMOUNT',
            'HPC_AMOUNT',
            'YEARS_SINCE_FIRST_GIFT',
            'YEARS_SINCE_MRC_GIFT',
            'YEARS_SINCE_HPC_GIFT',
            'BIRTH_YEAR'
        ] + [col for col in df.columns if col.startswith('REGION_CODE_')]

        # Separate dead and alive individuals
        df_dead = df[df['DEATH_FLAG'] == 1]
        df_alive = df[df['DEATH_FLAG'] == 0]

        # Train model on dead individuals
        if len(df_dead) > 0:
            X_dead = df_dead[feature_columns]
            y_dead = df_dead['BEQUEST_RECEIVED']
            ROI_FAMILY_ID_dead = df_dead['ROI_FAMILY_ID']
            
            # Cross-validation setup
            skf = StratifiedKFold(n_splits=3, shuffle=True, random_state=42)
            smote = SMOTE(random_state=42)
            model = RandomForestClassifier(random_state=42, n_jobs=-1)  # Use all available cores

            # Cross-validated predictions
            y_pred_dead = np.zeros(len(y_dead))
            y_pred_proba_dead = np.zeros(len(y_dead))
            for train_index, test_index in skf.split(X_dead, y_dead):
                X_train, X_test = X_dead.iloc[train_index], X_dead.iloc[test_index]
                y_train, y_test = y_dead.iloc[train_index], y_dead.iloc[test_index]

                X_train_res, y_train_res = smote.fit_resample(X_train, y_train)
                model.fit(X_train_res, y_train_res)
                y_pred_dead[test_index] = model.predict(X_test)
                y_pred_proba_dead[test_index] = model.predict_proba(X_test)[:, 1]  # Probability for class 1

            # Evaluation for dead individuals
            accuracy_dead = accuracy_score(y_dead, y_pred_dead)
            precision_dead, recall_dead, _ = precision_recall_curve(y_dead, y_pred_proba_dead)
            auc_pr_dead = auc(recall_dead, precision_dead)
            report_dead = classification_report(y_dead, y_pred_dead, output_dict=True)
            model.fit(X_dead, y_dead)
            feature_importance_dead = pd.DataFrame({
                'Feature': X_dead.columns,
                'Importance': model.feature_importances_
            }).sort_values(by='Importance', ascending=False)

            results_dead.append({
                'imputer': imputer_name,
                'accuracy': accuracy_dead,
                'auc_pr': auc_pr_dead,
                'report': pd.DataFrame(report_dead).transpose(),
                'feature_importance': feature_importance_dead,
                'ROI_FAMILY_ID': ROI_FAMILY_ID_dead,
                'y_true': y_dead,
                'y_pred': y_pred_dead
            })

            results_modeling.append({
                'imputer': imputer_name,
                'accuracy': accuracy_dead,
                'auc_pr': auc_pr_dead,
                'classification_report': json.dumps(report_dead),
                'feature_importance': feature_importance_dead.to_dict(orient='list')
            })

        # Predict on alive individuals
        if len(df_alive) > 0:
            X_alive = df_alive[feature_columns]
            y_pred_alive = model.predict(X_alive)
            ROI_FAMILY_ID_alive = df_alive['ROI_FAMILY_ID']

            results_alive.append({
                'imputer': imputer_name,
                'ROI_FAMILY_ID': ROI_FAMILY_ID_alive,
                'y_pred': y_pred_alive
            })

    # Evaluate each imputation method
    for imputer_name, imputer in imputers.items():
        evaluate_imputation(df.copy(), imputer_name, imputer)

    # Print the modeling results for dead individuals
    for result in results_dead:
        print(f"Imputer: {result['imputer']} (Dead)")
        print("Accuracy:", result['accuracy'])
        print("AUC-PR:", result['auc_pr'])
        print("Classification Report:")
        print(result['report'])
        print("Feature Importance:")
        print(result['feature_importance'])
        print("\n" + "-"*50 + "\n")

    # Combine all dead predictions into a single DataFrame
    predictions_dead_df = pd.concat([
        pd.DataFrame({
            'ROI_FAMILY_ID': result['ROI_FAMILY_ID'],
            'imputer': result['imputer'],
            'y_true': result['y_true'],
            'y_pred': result['y_pred'],
            'status': 'dead'
        }) for result in results_dead
    ], ignore_index=True)

    # Combine all alive predictions into a single DataFrame
    predictions_alive_df = pd.concat([
        pd.DataFrame({
            'ROI_FAMILY_ID': result['ROI_FAMILY_ID'],
            'imputer': result['imputer'],
            'y_pred': result['y_pred'],
            'status': 'alive'
        }) for result in results_alive
    ], ignore_index=True)

    # Write the dead predictions DataFrame to a new table
    session.write_pandas(predictions_dead_df, 'BEQUEST_PREDICTIONS_DEAD', auto_create_table=True)

    # Write the alive predictions DataFrame to a new table
    session.write_pandas(predictions_alive_df, 'BEQUEST_PREDICTIONS_ALIVE', auto_create_table=True)

    # Write the modeling results to a new table
    modeling_results_df = pd.DataFrame(results_modeling)
    session.write_pandas(modeling_results_df, 'BEQUEST_MODELING_RESULTS', auto_create_table=True)

    # Return string
    return "Data processing, prediction, and table creation completed successfully."
