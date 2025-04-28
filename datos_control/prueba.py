#Este script es para conectarse a la API de HPO, por si puede servir de algo (buscar informacion de cada HPO o algo asi)
#Documentacion API: https://clinicaltables.nlm.nih.gov/apidoc/hpo/v3/doc.html
import requests
from orphanet_info import hpo_dict

hpo_terms = list(hpo_dict.values())

for termino in hpo_terms: 

    url = "https://clinicaltables.nlm.nih.gov/api/hpo/v3/search"

    params = {
        "terms": termino,
        "df": "id,name,property.name, definition",
        "maxList": "1"
    }

    response = requests.get(url, params=params)
    if response.status_code == 200:
        resultado = response.json() 
    else:
        print("Algo fue mal")
        print(response.status_code)




