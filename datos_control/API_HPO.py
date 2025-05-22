#Este script es para conectarse a la API de HPO, aunque al final no se ha usado para el estudio
#Documentacion API: https://clinicaltables.nlm.nih.gov/apidoc/hpo/v3/doc.html
import requests
from orphanet_informacion import hpo_dict

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




