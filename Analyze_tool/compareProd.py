import numpy as np
import pandas as pd

# Read csv


totdf = pd.read_csv("temp.csv",sep=",")


# Pick all without last row
df = totdf[:-1]
last_df = totdf.tail(1)




last_df = last_df.drop(['deltaJ%'],axis=1)


# Sorting 
df = df.sort_values(by=[' oldB'],axis=0,ascending=False)
df = df.reset_index(drop=True)

with pd.option_context('display.max_rows', None,'display.max_columns',None,'display.max_colwidth', -1,'display.width', 1000):  # more options can be specified also
	print(df)
print(" ========= Summary ================================" )
print(last_df)
