import xml.etree.ElementTree as ET #cargar y parsear el xml 
import pandas as pd 


# Cargar el XML
tree = ET.parse("en_product4 (1).xml")  # Cambia esto por la ruta a tu archivo
root = tree.getroot()

# print(ET.tostring(root, encoding='utf8').decode('utf8')) #para ver todo el xml mejor 


# Recorremos cada enfermedad con OrphaCode
resultados = []
for disorder in root.findall(".//Disorder"):
    orpha_code = disorder.findtext("OrphaCode")
    if orpha_code:
        disorder_id = disorder.attrib.get("id")
        disorder_name = disorder.find("Name").text
        
        # Creamos una lista para guardar los HPO
        hpo_list = []

        for hpo_assoc in disorder.findall(".//HPODisorderAssociation"):
            hpo_id = hpo_assoc.find(".//HPOId").text
            hpo_term = hpo_assoc.find(".//HPOTerm").text
            hpo_list.append((hpo_id, hpo_term))
        
        resultados.append({
            "OrphaCode": orpha_code,
            "DisorderID": disorder_id,
            "DisorderName": disorder_name,
            "HPO_List": hpo_list
        })

def mostrar_resultados(lista):
    for r in lista:
        print(f"Enfermedad: {r['DisorderName']} (ID: {r['DisorderID']}, OrphaCode: {r['OrphaCode']})")
        print("HPO asociados:")
        for hpo_id, hpo_term in r["HPO_List"]:
            print(f"  - {hpo_id}: {hpo_term}")
        print("------") 

#Si queremos mostrar los resultados: 
#mostrar_resultados(resultados)

# Obtener todos los HPOs únicos
hpos_terms = set()
hpo_ids = set()

for r in resultados:
    for hpo_id, hpo_term in r["HPO_List"]:
        hpos_terms.add((hpo_term))
        hpo_ids.add(hpo_id)


#TODO: convertir los HPOs terms en los terminos de busqueda que tenemos en R
#TODO: convertir la informacion en un dataframe 

for l in resultados:
    print(l)