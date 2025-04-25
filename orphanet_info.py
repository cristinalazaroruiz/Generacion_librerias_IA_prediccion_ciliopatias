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

#Convertir a dataframe
df = pd.DataFrame(resultados)
df.to_excel("Anexo 4.xlsx")

#TODO: poner cada HPO como una variable distinta (pero ya la forma reducida)


# Obtener todos los HPOs únicos
'''hpos_terms = set()
hpo_ids = set()

for r in resultados:
    for hpo_id, hpo_term in r["HPO_List"]:
        hpos_terms.add((hpo_term))
        hpo_ids.add(hpo_id)'''

hpo_dict = dict()

for r in resultados:
    for hpo_id, hpo_term in r["HPO_List"]:
        hpo_dict[hpo_id] = hpo_term
        

hpo_df = pd.DataFrame(list(hpo_dict.items()), columns=["HPO_ID", "HPO_Term"])
hpo_df_unique = hpo_df.drop_duplicates(subset=["HPO_ID", "HPO_Term"])
hpo_df_unique.to_excel("HPO_codigo_nombre.xlsx")


#TODO: convertir los HPOs terms en los terminos de busqueda que tenemos en R
#TODO: convertir la informacion en un dataframe 






#Los nombres de las variables clinicas son:
'''Aural_Anomalies = ["Atresia of the external auditory canal"]      
Cerebral_Anomalies = []    
Coronary_and_Vascular_Anomalies = [
    "Jaw claudication", "Chylopericardium", "Bradycardia", "Vascular ring"]
Digestive_Anomalies = ["Episodic vomiting", "Megarectum", "Dysphagia"]        
Facial_Anomalies = [
    "Elfin facies", "Midline nasal groove", "Round face", "Cleft lower lip",
    "Single transverse palmar crease", "Downslanted palpebral fissures"]                                             
Nasal_Anomalies = []                                                    
Others = [
    "Generalized hyperkeratosis", "Anti-angiotensin receptor type-1 antibody positivity",
    "Congenital hemolytic anemia", "Hypochloremia", "Low alkaline phosphatase", "Neonatal death",
    "Decreased biotinidase activity", "Decreased biotinidase activity", "Cutaneous photosensitivity",
    "Cutaneous sclerotic plaque", "Hodgkin lymphoma", "Oral mucosal blisters", "Decreased activity of mitochondrial ATP synthase complex",
    "Atrophic scars","Trichilemmoma"]                                                
Hormonal_Anomalies = ["Premature pubarche", "Neonatal hypoglycemia"]             
Neural_Anomalies = [
    "Neuronal loss in basal ganglia", "Chiari type I malformation", "Disinhibition",
"Dysgenesis of the basal ganglia", "EEG with burst suppression", "EEG with generalized sharp slow waves",
"Steppage gait", "Abnormal third ventricle morphology", "Cerebellar hemangioblastoma", "Myotonia of the jaw",
"Low voltage EEG", "Profound global developmental delay", "Arachnoid hemangiomatosis",
"Peripheral nerve compression"]
Ophthalmic_Anomalies = [
    "Optic nerve compression", "Abnormal pupillary function", "Peripheral visual field loss",
    "Blepharospasm", "Presenile cataracts", "Abnormal foveal morphology on macular OCT"]
Organ_Anomalies = [
    "Pancreatic hyperplasia", "Hypersplenism"
]
Renal_Anomalies = []
Reproductive_Anomalies = []
Respiratory_Anomalies = [
    "Abnormal mucociliary clearance", "Air crescent sign", "Laryngomalacia",
    "Bronchitis"
]
Skeletal_Anomalies = [
    "Shoulder subluxation", "Abnormal bone structure", "Scapuloperoneal amyotrophy", "Tip-toe gait",
    "Tip-toe gait", "Short femoral neck", "Muscular dystrophy","Generalized muscle weakness",
    "Inability to walk by childhood/adolescence", "Symphalangism of the thumb", "Ulnar radial head dislocation",
    "Congenital foot contractures", "Thoracic platyspondyly", "Complete duplication of distal phalanx of the thumb",
    "Humeroradial synostosis", "Corner fracture of metaphysis", "Kyphosis", "Delayed femoral head ossification",
    "Plantar flexion contractures"]
Liver_Anomalies = []


for r in hpo_ids:
    print(r)''' 