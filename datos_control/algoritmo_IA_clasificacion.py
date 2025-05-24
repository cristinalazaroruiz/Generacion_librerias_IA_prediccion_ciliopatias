#Podemos mejorar el algoritmo de clasificacion de los terminos HPO mediante IA
from clasificacion_HPO import clasificar_hpo_terms, graph, category_keywords
from orphanet_informacion import hpo_unicos
import pandas as pd
import string
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score, confusion_matrix, classification_report
from sklearn.svm import SVC


#sobre el dataframe hpo_unicos, podemos aplicar la funcion clasificar_hpo_terms para obtener ejemplos etiquetados y mejorar las etiquetas con IA
#vamos a seleccionar 1000 observaciones para clasificar con la funcion clasificar_hpo_terms y lo revisamos manualmente. De aqui sacamos train y test. 
#el resto del dataframe lo dejamos para el algoritmo
hpo_1000_rows = hpo_unicos.iloc[:1001]
hpo_resto = hpo_unicos.iloc[1001:]

#sobre hpo_300_rows, aplicamos la clasificacion con clasificar_hpo_terms
hpo_list_1000 = list(hpo_1000_rows["HPO_ID"])
clasificados = clasificar_hpo_terms(hpo_list_1000, graph, category_keywords)

for idx, row in hpo_1000_rows.iterrows():
    for categoria, hpo_ids in clasificados.items():
        if row["HPO_ID"] in hpo_ids:
            hpo_1000_rows.at[idx, "Clasificacion"] = categoria
            break  # Para no seguir buscando una vez encontrada la categoría


#!Revisar a mano la clasificacion para asegurar que esta bien

#Pasamos a aplicar IA
#En HPO_term tenemos que convertir las palabras a variables numericas
#Para el tratamiento del texto hay que eliminar los signos especiales (, . /) y palabras que no aporten (of, and, the)

stopwords_english = [
    "a", "about", "above", "after", "again", "against", "all", "am", "an",
    "and", "any", "are", "aren't", "as", "at", "be", "because", "been",
    "before", "being", "below", "between", "both", "but", "by", "can't",
    "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't",
    "doing", "don't", "down", "during", "each", "few", "for", "from", 
    "further", "had", "hadn't", "has", "hasn't", "have", "haven't", 
    "having", "he", "he'd", "he'll", "he's", "her", "here", "here's", 
    "hers", "herself", "him", "himself", "his", "how", "how's", "i", 
    "i'd", "i'll", "i'm", "i've", "if", "in", "into", "is", "isn't", "it", 
    "it's", "its", "itself", "let's", "me", "more", "most", "mustn't", 
    "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", 
    "or", "other", "ought", "our", "ours", "ourselves", "out", "over", 
    "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", 
    "shouldn't", "so", "some", "such", "than", "that", "that's", "the", 
    "their", "theirs", "them", "themselves", "then", "there", "there's", 
    "these", "they", "they'd", "they'll", "they're", "they've", "this", 
    "those", "through", "to", "too", "under", "until", "up", "ve", "very", 
    "was", "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", 
    "weren't", "what", "what's", "when", "when's", "where", "where's", 
    "which", "while", "who", "who's", "whom", "why", "why's", "will", 
    "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", 
    "you're", "you've", "your", "yours", "yourself", "yourselves", "of", "the",
    "and"
]

def tratamiento_texto(stopwords_english, texto):
    # eliminar signos especiales reemplazándolos por espacios
    replace_punctuation = str.maketrans(string.punctuation, ' ' * len(string.punctuation))
    texto_sin_signos = texto.translate(replace_punctuation)
    
    # dividir en palabras
    palabras = texto_sin_signos.lower().split()
    
    # eliminar stopwords
    texto_filtrado = [palabra for palabra in palabras if palabra not in stopwords_english]
    
    # unir de nuevo en string
    return ' '.join(texto_filtrado)

#aplicamos la funcion sobre HPO_terms
hpo_1000_rows["Terminos_Filtrados"] = hpo_1000_rows["HPO_Term"].apply(lambda x: tratamiento_texto(stopwords_english, x))

#seleccionamos nuestra X y nuestra Y
X = hpo_1000_rows[["Terminos_Filtrados"]]
Y = hpo_1000_rows["Clasificacion"]

#Dividir en test y train
X_train, X_test, Y_train, Y_test = train_test_split(X,Y,test_size=0.2, random_state=1)

#Vectorizacion de X
vectorizer = CountVectorizer()
# Representacion de documentos de training a partir de la bolsa de palabras
train_matrix = vectorizer.fit_transform(X_train["Terminos_Filtrados"])
# Representacion de documentos de test a partir de la bolsa de palabras
test_matrix = vectorizer.transform(X_test["Terminos_Filtrados"])

#aplicar decission tree
model = DecisionTreeClassifier()
model.fit(train_matrix, Y_train)
Y_predict = model.predict(test_matrix)

#analizar el rendimiento del modelo con la matriz de confusion
conf_matrix = confusion_matrix(Y_test, Y_predict)
accuracy = accuracy_score(y_true=Y_test, y_pred=Y_predict)
reporte = classification_report(Y_test, Y_predict)

print("La matriz de confusion es: ")
print(conf_matrix)
print("La precision es: ")
print(accuracy)
print("El reporte general del modelo es: ")
print(reporte)

modelo_2 = SVC()
modelo_2.fit(train_matrix, Y_train)
Y_predict2 = modelo_2.predict(test_matrix)

#analizar el rendimiento del modelo con la matriz de confusion
conf_matrix2 = confusion_matrix(Y_test, Y_predict2)
accuracy2 = accuracy_score(y_true=Y_test, y_pred=Y_predict2)
reporte2 = classification_report(Y_test, Y_predict2)

print("La matriz de confusion es: ")
print(conf_matrix2)
print("La precision es: ")
print(accuracy2)
print("El reporte general del modelo es: ")
print(reporte2)