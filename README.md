# Generación de Librerias y uso de IA para la prediccion deciliopatias
## Universidad Internacional de la Rioja (UNIR) - Facultad de Ciencias de la Salud - Máster en Bioinformática
Este repositorio forma parte de un proyecto de final de máster (TFM) cuyo objetivo es utilizar diferentes herramientas dentro del aprendizaje automático (machine learning) para el análisis y predicción de las ciliopatías, un gurpo heterogéneo de enfermedades raras y de origen genético. Se incluyen todos los scripts (en R y Python) utilizados para llevar a cabo el estudio sobre el uso de Inteligencia Artificial para el análisis y diagnóstico de ciliopatías. 

# **Bases de datos para obtener información clínica (ciliopatías y datos de control)**


*CiliaMiner*: (https://github.com/thekaplanlab/CiliaMiner)

*Orphanet*: (https://www.orpha.net/)



# **Algoritmos de aprendizaje no supervisado**

Estos algoritmos se han utilizado para evaluar la agrupación de los pacientes según su tipo de ciliopatía (primaria, secundaria y móvil) y para analizar la agrupacion de pacientes según si tienen o no una ciliopatía. 
Concretamente, las técnicas utilizadas han sido: 


*Análisis de Componentes Principales (PCA)*


*Incrustación de vecinos estocásticos distribuidos en t (t-SNE)*


*Clusterización no jerárquica k-means*


*Clusterización jerárquica aglomerativa*

# **Algoritmos de aprendizaje supervisado**

Estos algoritmos se han utilizado para la predicción de pacientes con cilipatías según un conjunto de variables clínicas predictoras. 
Concretamente, las técnicas utilizadas han sido: 


*Bosque Aleatorio*

*Potenciación del Gradiente*

*Máquina de Vectores de Soporte*

Por otro lado, el rendimiento de las prediccciones se ha estimado mediante:

*Matrices de confusión*

*Métricas de precisión, tasa de error, sensibilidad, especificidad y valor predictivo positivo*

*Curvas ROC*

*Curvas de Aprendizaje*

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Library generation and AI aplication for ciliopathies prediction

## Universidad Internacional de la Rioja (UNIR) - Facultad de Ciencias de la Salud - Master in Bioinformatics
This repository is part of a Master's thesis project aimed at using various techniques within machine learning for the analysis and prediction of ciliopathies, a heterogeneous group of rare genetic diseases. It includes R Aand Ptyhon scripts and algorithms of AI used in the study for ciliopathies diagnosis.  

# **Databases for clinical information (ciliopathies and control data)**


*CiliaMiner*: (https://github.com/thekaplanlab/CiliaMiner)

*Orphanet*: (https://www.orpha.net/)



# **Not supervised learning algorithms**

These algorithms have been used to evaluate the clustering of patients according to the type of ciliopathy (primary, secondary, or motile), as well as to analyze the grouping of patients based on the presence or absence of a ciliopathy.
In particular, the techniques used were:  

*Principal Component Analysis (PCA)*


*t-SNE*


*K-means clustering*


*Hierarchical Agglomerative Clustering (HAC)*

# **Supervised learning algorithms**

These algorithms have been used to predict patients with ciliopathies based on a set of clinical predictor variables.
In particular, the techniques used were:

*Random Forest*

*Gradient Boosting (XGBoost)*

*Support Vector Machine (SVM)*

On the other hand, the performance of the predictions was evaluated using the following:


*Confussion matrices*

*Metrics such as accuracy, error rate, sensitivity, specificity, and positive predictive value*

*ROC Curves*

*Learning Curves*
