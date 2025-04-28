#script para conectarse a la API de ORPHACODES y recuperar todos los codigos de ORPHANET relacionados con las ciliopatias

import requests
import pandas as pd 

#desde la interfaz de ORPHANET, podemos recuperar los codigos de los grupos de enfermedades relacionados con las ciliopatias
#A partir de estos codigos de grupo, podemos recuperar los ID de todas las cilipatias via API
ciliopathies_codes = [363250, 156162, 156165, 156183, 156180, 156168, 156171, 156174, 156177]

disorders = []

for group_id in ciliopathies_codes:
    url = f"https://api.orphacode.org/EN/Classification/{group_id}"

    params = {

        "limit": 1000,
        "offset": 0
    }

    response = requests.get(url, params=params)

    if response.status_code == 200:
        data = response.json()

    else: 
        print(f"algo fue mal, el codigo es {response.status_code}")   

df_disorders = pd.DataFrame(disorders)
print(df_disorders)

#Algo no funciona. La documentacion es: https://api.orphacode.org/#/All%20Orphanet%20clinical%20entities/list_entities
#Me da error 401 
#TODO: revisar por que me da error 

#Como no me dan acceso a la API, he tenido que recuperar los codigos de manera manual (a traves de la interfaz de ORPHANET)
#Esto me parece un poco chapucero pero no se me ocurre otra forma

ciliopathies_diseases_codes = [
    122, 65759, 457378, 380, 658805, 2189, 464366, 557003, 508501, 314394, 2666, 64, 730, 88924, 731, 110,  1515, 289, 474, 1454,
    2318, 220497, 444069, 439897, 88949, 2473, 564, 500135, 534, 352540, 672, 140976, 294415,140969, 84081, 3156, 506307, 805,
    88950, 892, 93591,93592, 93589, 64, 289, 474, 454, 220493, 75858, 564, 3085, 506307, 110, 2377, 2473, 110, 220497, 3032,
    294415, 3156, 93591, 93592, 93589, 110, 220497, 3032, 294415, 3156, 791, 1872, 244, 1871, 791, 1872, 65, 886, 363250, 156162, 156165, 156183, 156180,
    156168, 156171, 156174, 156177]

