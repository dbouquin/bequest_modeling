import pandas as pd

def split_csv(filename):
    # Load the CSV file
    data = pd.read_csv(filename)
    
    # Calculate the index to split the dataframe
    split_index = len(data) // 2
    
    # Split the dataframe into two halves
    first_half = data.iloc[:split_index]
    second_half = data.iloc[split_index:]
    
    # Save the first half to a new CSV file
    first_half.to_csv('first_half.csv', index=False)
    
    # Save the second half to a new CSV file
    second_half.to_csv('second_half.csv', index=False)

# split bequests file
split_csv('bequests_cleaned.csv')
