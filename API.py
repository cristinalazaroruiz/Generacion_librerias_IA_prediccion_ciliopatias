import requests
import pandas as pd
import json
from prueba import busquedas_2_sample

# Término de búsqueda
query = busquedas_2_sample[0] 
# URL de búsqueda
esearch_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi" #herramienta esearch de e-utilities para recuperar los ids que corresponden con la query
params = {
    "db": "clinvar",       # Base de datos ClinVar
    "term": query,         # Término de búsqueda
    "retmax": 2000,         # Número máximo de resultados
    "retmode": "json",      #Formato de salida JSON
    "usehistory": "y",     # Crear webenv y query_key para usar esummary
}

# Hacer la solicitud para obtener los IDs de las variantes
response = requests.get(esearch_url, params=params)

if response.status_code == 200: #si ha tenido exito esearch
    response_json = response.json() #convertir en formato json
    webenv = response_json["esearchresult"]["webenv"] #recuperar los valores de webenv
    querykey = response_json["esearchresult"]["querykey"] #recuperar los valores de querykey
    start = 0
    total_resultados = 100 #lo reducimos a mil
    esummary_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"
    params = {
        "db": "clinvar",
        "query_key": querykey,
        "WebEnv": webenv,
        "retmode": "json",
        "retmax": 500,
        "restart": start
    }

    variant_info = []
    while start < total_resultados:
        esummary_final_url = requests.get(esummary_url, params=params) #solicitud de esummary

        if esummary_final_url.status_code == 200: #si ha tenido exito la solicitud
            esummary_json = esummary_final_url.json() #convertir a un json
            print(json.dumps(esummary_json, indent=4))


'''            variant_data = esummary_json["result"]["uids"]
            print(json.dumps(esummary_json, indent=4))
            for i in variant_data:
                variant_id = esummary_json["result"][i].get("title", "No title avaiable")
                clasificacion  = esummary_json["result"][i]["germline_classification"]["description"]
                enfermedad = esummary_json["result"][i].get("germline_classification", {}).get("trait_set", [{}])[0].get("trait_name", "No disease info")

                cambio_aa = esummary_json["result"][i].get("protein_change", "No info available")

                variant_info.append((variant_id, clasificacion, enfermedad, cambio_aa))

            start +=500
        else:
            print("Error al obtener los datos de ESummary")

#Convertir variant_info a dataframe
df = pd.DataFrame(variant_info, columns=["Variant ID", "Classification", "Disease", "cambio_aa"])
#Convertir a excel el dataframe
df.to_excel("cilipathies.xlsx", index=False) ''' 