import numpy as np
import pandas as pd
from sklearn.datasets import load_iris

iris = load_iris()
df = pd.DataFrame(data=np.c_[iris["target"], iris["data"]],
                  columns=["species"] + iris["feature_names"])
df["species"] = df["species"].replace({
    k:v for k,v in enumerate(iris.target_names)
})
print(df.head())

# Overall mean Petal Width
print(df["petal width (cm)"].mean())
print(df.groupby("species")["petal width (cm)"].mean())
