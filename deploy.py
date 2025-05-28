import pandas as pd
from io import StringIO

# Simulate reading from CSV
csv_data = """year,month,day,hour,seconds,transaction_id,amount
2025,1,15,15,59,AA,1
2025,2,14,23,55,B,2
2021,10,13,22,55,AA,1
2023,11,12,8,50,AA,2
2025,3,11,7,45,AA,1
1990,4,10,2,45,B,2
2001,4,9,11,45,B,1
1990,4,10,2,45,B,2
2021,10,13,22,55,AA,1"""

# Load into DataFrame
df = pd.read_csv(StringIO(csv_data))

# Step 1: Standardize date format
df['date'] = pd.to_datetime(df[['year', 'month', 'day', 'hour']].assign(minute=0, second=df['seconds']))

# Step 2: Remove duplicates
df = df.drop_duplicates()

# Step 3: Aggregate on transaction_id
aggregated = df.groupby('transaction_id', as_index=False).agg({
    'date': 'min',  # earliest transaction date
    'amount': 'sum'  # total amount
})

# Final output
print(aggregated)
