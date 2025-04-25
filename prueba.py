#API HPO
import requests

url = "https://clinicaltables.nlm.nih.gov/api/hpo/v3/search"

params = {
    "terms": "Reduced circulating growth hormone concentration",
    "df": "id,name,property.name",
    "maxList": "3"
}

response = requests.get(url, params=params)
if response.status_code == 200:
    resultado = response.json()
    print(resultado)  # Para ver qué devuelve
else:
    print("Algo fue mal")
    print(response.status_code)


import requests


