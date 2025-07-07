#Script para procesar el XML con las enfermedades raras y sus sintomas HPO, obtenido desde ORPHANET

import xml.etree.ElementTree as ET #cargar y parsear el xml 
import pandas as pd 
from orphanet_API import ciliopathies_diseases_codes #lista con los codigos relacionados con las ciliopatias

# Cargar el XML
tree = ET.parse("en_product4 (1).xml")  # Cambia esto por la ruta a tu archivo
root = tree.getroot()


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


#Convertir a dataframe
df = pd.DataFrame(resultados)

#Si ahora queremos que cada HPO sea una fila distinta:
# Crear una lista de filas donde cada HPO sea una fila distinta
hpo_rows = []

for r in resultados:
    for hpo_id, hpo_term in r["HPO_List"]:
        hpo_rows.append({
            "OrphaCode": r["OrphaCode"],
            "DisorderID": r["DisorderID"],
            "DisorderName": r["DisorderName"],
            "HPO_ID": hpo_id,
            "HPO_Term": hpo_term
        })

# Crear el nuevo DataFrame
df_hpo = pd.DataFrame(hpo_rows)

#De este datafarme habria que eliminar las enfermedades relacionadas con las ciliopatias
#Para ello, eliminamos las filas que contengan ORPHACODES relacionados con las cilipatias (script ORPHANET_API.py)
df_hpo = df_hpo[~df_hpo["OrphaCode"].isin(ciliopathies_diseases_codes)]

#Podemos tambien hacer una doble comprobacion de que no hay ciliopatias, buscando eliminar tambien las filas con palabras clave relacionadas con ciliopatias: 
nombres_cilipatias = [
"acrocallosal",                                                                            
"al gazali bakalinova",                                                                    
"autosomal dominant polycystic kidney",                                                     
"autosomal recessive polycystic kidney",                                                    
"polycystic kidney disease",                                                                        
"infantile polycystic kidney",                                                              
"bilateral polycystic kidney",                                                              
"alström",                                                                                 
"bardet biedl",                                                                            
"bazex dupré christol",                                                                    
"biliary renal neurologic and skeletal",                                                
"caroli",                                                                                   
"cranioectodermal dysplasia",                                                                       
"coach",                                                                                   
"ellis van creveld",                                                                       
"greig cephalopolysyndactyly",                                                             
"hydrolethalus",                                                                           
"joubert",                                                                                 
"kallmann",                                                                                
"mckusick kaufman",                                                                        
"meckel gruber",                                                                           
"morbid obesity and spermatogenic failure",                                                         
"nephronophthisis",                                                                                 
"complex lethal osteochondrodysplasia",                                                             
"lowe oculocerebrorenal",                                                                  
"orofaciodigital",                                                                         
"primary ciliary dyskinesia",                                                                       
"retinal dystrophy",                                                                                
"renal hepatic pancreatic dysplasia",                                                               
"rhyns",                                                                                  
"senior løken",                                                                            
"smith lemli opitz",                                                                       
"spondylometaphyseal",                                                                    
"short rib thoracic",                                                                     
"stromme",                                                                                 
"weyers acrofacial dysostosis",                                                                     
"ataxia telangiectasia like",                                                              
"birt hogg dubé",                                                                          
"cornelia de lange",                                                                       
"cone rod dystrophy",                                                                               
"carpenter",                                                                               
"juvenile myoclonic epilepsy",                                                                      
"congenital heart disease",                                                                         
"holoprosencephaly",                                                                                
"visceral heterotaxy",                                                                              
"leber congenital amaurosis",                                                                       
"laurence moon",                                                                           
"multinucleated neurons anhydramnios renal dysplasia cerebellar hypoplasia and hydranencephaly",
"medulloblastoma",                                                                                  
"mental retardation truncal obesity retinal dystrophy and micropenis",                           
"neonatal sclerosing cholangitis",                                                                  
"pallister hall",                                                                          
"retinitis pigmentosa",                                                                             
"spinocerebellar ataxia",                                                                           
"simpson golabi behmel",                                                                   
"short stature onychodysplasia facial dysmorphism and hypotrichosis",                            
"star syndrome",                                                                                    
"townes brocks",                                                                           
"usher"]

#elaboramos el patron
patron = "|".join(nombres_cilipatias)

df_hpo_sin_ciliopatias = df_hpo[~df_hpo["DisorderName"].str.lower().str.contains(patron, na= False)]

#Tenemos muchos registros, nos vamos a quedar con una muestra aleatoria de 5000 para seguir con el analisis
dfo_sample2 = df_hpo_sin_ciliopatias.sample(n = 5000, random_state = 1)

#Tenemos que convertir los HPO en la clasificacion que tenemos en el dataset con las ciliopatias
# Obtenemos todos los HPOs únicos en forma de diccionario hpo_id:hpo_term y añadimos una columna para la clasificacion
hpo_id = dfo_sample2["HPO_ID"].to_list()
hpo_term = dfo_sample2["HPO_Term"].to_list()
hpo_dict = dict(zip(hpo_id, hpo_term))

#creamos un dataframe con esta informaion
hpo_unicos = pd.DataFrame({
    "HPO_ID": list(hpo_dict.keys()),
    "HPO_Term":list(hpo_dict.values()),
    "Clasificacion": ["NA" for _ in range(len(hpo_dict))]
})


#Ahora hay que agrupar estos HPO en las siguientes categorias > script clasificacion_HPO.py

Aural_Anomalies = []      
Cerebral_Anomalies = []    
Coronary_and_Vascular_Anomalies = []
Digestive_Anomalies = []        
Facial_Anomalies = []                                             
Nasal_Anomalies = []                                                    
Others = []                                                
Hormonal_Anomalies = []             
Neural_Anomalies = []
Ophthalmic_Anomalies = []
Organ_Anomalies = []
Renal_Anomalies = []
Reproductive_Anomalies = []
Respiratory_Anomalies = []
Skeletal_Anomalies = []
Liver_Anomalies = []







if __name__ == "__main__":
    #para ver el XML mejor
    print(ET.tostring(root, encoding='utf8').decode('utf8')) #para ver todo el xml mejor 

    #mostrar los resultados del procesamiento del XML
    mostrar_resultados(resultados)

    # Guardarlo en excel toda la informacion sobre todas las enfermedades
    df_hpo.to_excel("HPO_enfermedad.xlsx", index=False)

    #Guardar enfermedades sin ciliopatias
    df_hpo_sin_ciliopatias.to_excel("Anexo_3.xlsx")

