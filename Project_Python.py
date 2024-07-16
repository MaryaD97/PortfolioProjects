# Import necessary libraries
import pandas as pd
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.pyplot import figure

# Configure plot style and figure size
plt.style.use('ggplot')
figure(figsize=(12, 8))

# Load the dataset
df = pd.read_csv(r'C:\Users\Maryam\Downloads\movies.csv')


# Display the first few rows of the dataframe
print(df.head())

# Check for missing data in each column
for col in df.columns:
    pct_missing = np.mean(df[col].isnull())
    print('{} - {}%'.format(col, pct_missing * 100))

# Drop rows with missing data
df = df.dropna()

# Display data types of columns
print(df.dtypes)

# Convert budget and gross columns to int64 data type
df['budget'] = df['budget'].astype('int64')
df['gross'] = df['gross'].astype('int64')

# Verify data type changes
print(df.dtypes)

# Create a column with the correct year extracted from the released column
df['yearcorrect'] = df['released'].str.extract(r'([0-9]{4})').astype(int)

# Display the first few rows to check the new column
print(df.head())

# Sort the dataframe by the gross column in descending order
df = df.sort_values(by='gross', ascending=False)

# Display all rows
pd.set_option('display.max_rows', None)

# Drop duplicate company names and sort them
df['company'].drop_duplicates().sort_values(ascending=False)

# Scatter plot: Budget vs Gross Earnings
plt.scatter(x=df['budget'], y=df['gross'])
plt.title('Budget vs Gross Earnings')
plt.xlabel('Budget for Film')
plt.ylabel('Gross Earnings')
plt.show()

# Scatter plot using Seaborn: Budget vs Gross Earnings with regression line
sns.regplot(x='budget', y='gross', data=df, scatter_kws={"color": "black"}, line_kws={"color": "purple"})

# Calculate the Pearson correlation matrix for numeric features
correlation_matrix = df.corr(numeric_only=True, method='pearson')

# Heatmap of the Pearson correlation matrix
sns.heatmap(correlation_matrix, annot=True)
plt.title('Correlation Matrix for Numeric Features')
plt.xlabel('Movie Features')
plt.ylabel('Movie Features')
plt.show()

# Convert object columns to category and then to numeric codes
df_numerized = df.copy()
for col_name in df_numerized.columns:
    if df_numerized[col_name].dtype == 'object':
        df_numerized[col_name] = df_numerized[col_name].astype('category').cat.codes

# Calculate the Pearson correlation matrix for the numerized dataframe
correlation_matrix = df_numerized.corr(numeric_only=True, method='pearson')

# Heatmap of the Pearson correlation matrix for numerized dataframe
sns.heatmap(correlation_matrix, annot=True)
plt.title('Correlation Matrix for Numeric Features')
plt.xlabel('Movie Features')
plt.ylabel('Movie Features')
plt.show()

# Display the sorted correlation pairs
correlation_mat = df_numerized.corr()
corr_pairs = correlation_mat.unstack()
sorted_pairs = corr_pairs.sort_values()

# Display high correlation pairs with correlation greater than 0.5
high_corr = sorted_pairs[(sorted_pairs) > 0.5]
print(high_corr)
