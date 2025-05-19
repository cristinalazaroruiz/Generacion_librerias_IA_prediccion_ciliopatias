from orphanet_info import hpo_unicos
import obonet #para parsear archivos en formato OBO
import networkx
import pandas as pd
from collections import defaultdict
#Vamos a probar a leer el fichero en formato OBO
path_obo = r"C:\Users\crist\Desktop\codigo_TFM\Generacion_librerias_IA_prediccion_ciliopatias\datos_control\hp.obo" 
#este fichero viene del repositorio oficial de HPO; https://github.com/obophenotype/human-phenotype-ontology?tab=readme-ov-file
graph = obonet.read_obo(path_obo)


#palabras clave para cada categoria (elaborado con ayuda de ChatGPT)
category_keywords = {
    "Aural_Anomalies": ["hearing", "ear", "auricular", "otitis", "deaf", "vestibular", "balance", "tinnitus", "external ear", "canal"],
    "Cerebral_Anomalies": ["brain", "corpus callosum", "cerebral", "neurologic","brain", "cerebellum", "cerebral", "cortex",
                            "intellectual", "hippocampus", "mental", "neurologic", "encephalo", "microcephaly", "macrocephaly", "hydrocephalus", "hypotonia", "psychomotor", 
                            "ataxia", "parkinsonism", "seizure", "epilepsy", "spastic", "dysplasia", "cortical", "chiari", "cerebellar", "olivopontocerebellar"],
    "Coronary_and_Vascular_Anomalies": ["vascular", "vessel", "coronary", "artery", "vein",
                                        "heart", "cardio", "vascular", "hypertension", "cardiomyopathy", "tachycardia", "bradycardia", "myocarditis", "artery",
                                        "vein", "septal", "patent ductus arteriosus", "ventriculomegaly", "pericarditis", "cardiac", "aortic"],
    "Digestive_Anomalies": ["digestive", "intestinal", "stomach", "colon", "gut", "diarrhea", "vomiting", "constipation", 
                            "bowel", "pancreatitis", "esophagus", "reflux", "herni", "gastrostomy"],
    "Facial_Anomalies": ["face", "facial", "jaw", "cheek","synophrys", "palate", "micrognathia", "chin", "eyebrow", 
                        "widow's peak", "frontal", "long philtrum", "forehead", "lib", "facies", "mouth", "occiput", "philtrum",
                        "mandibular", "fontanelle"],
    "Nasal_Anomalies": ["nose", "nasal", "nostril", "anteverted nares", "nares", "sinusitis"],
    "Hormonal_Anomalies": ["hormone", "endocrine", "hypothyroidism", "hyperthyroidism", "hyperparathyroidism", "iodine uptake", "pituitary", "thyroid"],
    "Neural_Anomalies": ["neural", "nerve", "neurologic", "nerve", "sensory", "motor", "reflex", "neuropathy", "pyramidal", "fasciculations", 
                        "myelin", "axon", "dystonia", "rigidity", "paraplegia", "intellectual", "cognitive", "speech", "language", "development", 
                        "learning", "delay", "autism", "tremor", "hyperactivity", "jerky movements"],
    "Ophthalmic_Anomalies": ["ocular", "vision", "cornea", "retina", "macula", "palpebral", "nystagmus", "myopia", "proptosis", "amaurosis",
                            "vitreoretinopathy", "electroretinogram", "hypertelorism", "ptosis", "eye", "visual"],
    "Organ_Anomalies": ["organ", "viscera", "alopecia", "skin", "dermatitis", "rash", "scalp", "hair", "nail", "omphalocele", "splenomegaly"],
    "Renal_Anomalies": ["kidney", "renal", "nephro", "renal", "kidney", "hematuria", "proteinuria", "glomerulo", "albuminuria",
                        "ferritin", "urea", "creatinine", "hyperphosphaturia", "urinary", "bladder"],
    "Reproductive_Anomalies": ["reproductive", "genital", "gonad", "uterus", "testis", "ovary",
                            "testicular", "uterus", "hypogonadism", "hypospadias", "amenorrhea", "puberty", "gonad", 
                            "pubertal", " pseudohermaphroditism", " hermaphroditism", "vagina"],
    "Respiratory_Anomalies": ["lung", "respiratory", "breath", "bronchitis", "dyspnea", "apnea", "tachypnea", "pneumonia", "trachea",
                            "larynx", "airway", "laryngotracheomalacia", "pleura", "pulmonary"],
    "Skeletal_Anomalies": ["bone", "skeletal", "spine", "joint", "bone", "joint", "phalanx", "dactyly", "spine", "lordosis", "kyphosis",
                            "osteopenia", "osteoporosis", "limb", "short stature", "synovitis", "fibular hypoplasia",
                            "osteochondrosis", "muscle weakness", "cartilage", "knee", "stature", "femoral", "spina bifida", 
                            "pectus", "sclerosis", "scapulae", "knee", "supraorbital", "radius", "metatarsal", "muscle", "muscular", "femur", "synostosis", "chest",
                            "hip", "legs"],
    "Liver_Anomalies": ["liver", "hepatic"],
    "Others": [] #Por si no coincide con nada
} 



def clasificar_hpo_terms(lista_hpo, graph, palabras_clave):
    clasificados = defaultdict(list)
    
    for hpo_id in lista_hpo:
        if hpo_id not in graph:
            clasificados["Others"].append(hpo_id)
            continue  # salta al siguiente HPO si no existe

        # Obtener ancestros + término original
        ancestros = list(networkx.ancestors(graph, hpo_id))
        terminos = [hpo_id] + ancestros
        nombres = [graph.nodes[tid].get('name', '').lower() for tid in terminos if tid in graph]

        asignado = False
        for categoria, keywords in palabras_clave.items():
            for nombre in nombres:
                if any(keyword in nombre for keyword in keywords):
                    clasificados[categoria].append(hpo_id)
                    asignado = True
                    break
            if asignado:
                break

        if not asignado:
            clasificados["Others"].append(hpo_id)

    return clasificados


#generamos nuestra lista de hpo a partir del dataframe importado
hpo_list = list(hpo_unicos["HPO_ID"])
resultado = clasificar_hpo_terms(hpo_list, graph, category_keywords)

#pasar a dataframe
filas = []
for categoria, lista_hpos in resultado.items():
    for hpo_id in lista_hpos:
        filas.append((hpo_id, categoria))


df_clasificado = pd.DataFrame(filas, columns=["HPO_ID", "Clasificacion"])

#como tenemos muchos others, vamos a recuperar los nombres de los HPO_ID clasificados como Others, para añadir mas terminos a las palabras clave (proceso iterativo)
otros_hpo_ids = resultado.get("Others", [])
nombres = [
    graph.nodes[tid].get("name", "").lower()
    for tid in otros_hpo_ids
    if tid in graph
]
print(nombres)

#TODO: seguir refinando las palabras clave
#TODO: generar el df_clasificado definitivo

if __name__ == "__main__":
    #convertir df_clasificado a excel
    df_clasificado.to_excel("hpo_clasificados_final.xlsx")