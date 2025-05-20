#script para categorizar los HPO y generar un dataframe con los datos control clasificados
from orphanet_info import hpo_unicos, dfo_sample2
import obonet #para parsear archivos en formato OBO
import networkx
import pandas as pd
from collections import defaultdict
#Leer el fichero en formato OBO
path_obo = r"C:\Users\crist\Desktop\codigo_TFM\Generacion_librerias_IA_prediccion_ciliopatias\datos_control\hp.obo" 
#este fichero viene del repositorio oficial de HPO; https://github.com/obophenotype/human-phenotype-ontology?tab=readme-ov-file
graph = obonet.read_obo(path_obo)


#palabras clave para cada categoria (elaborado con ayuda de ChatGPT)
#!Hay que tener en cuenta que no soy medico, puede no estar bien y no coincidir del todo con la clasificacion de las ciliopatias
category_keywords = {
    "Aural_Anomalies": ["hearing", "ear", "auricular", "otitis", "deaf", "vestibular", "balance", "tinnitus", "external ear", "ear canal", "microtia", "phonophobia",
                        "hypoplastic helices"],
    "Cerebral_Anomalies": ["brain", "corpus callosum", "cerebral", "cerebellum", "cortex", "eeg",
                            "intellectual", "hippocampus", "mental", "encephalo", "microcephaly", "macrocephaly", "hydrocephalus", "psychomotor", 
                            "ataxia", "parkinsonism", "seizure", "epilepsy", "spastic", "cortical", "chiari", "cerebellar", "olivopontocerebellar",
                            "megalencephaly", "hemimegalencephaly", "dysdiadochokinesis", "hypsarrhythmia", "thalamic", "meningitis", "holoprosencephaly",
                            "aphasia", "ischemic", "athetosis", "tetraplegia", "hemiplegia", "ventriculomegaly", "intracranial", "foramen", "gyral",
                            "cisterna magna","meningioma","polymicrogyria","parietal","fontanelle","occiput"],
    "Coronary_and_Vascular_Anomalies": ["vascular", "vessel", "coronary", 
                                        "heart", "cardio", "hypertension", "cardiomyopathy", "tachycardia", "bradycardia", "myocarditis", "artery",
                                        "vein", "septal", "patent ductus arteriosus", "pericarditis", "cardiac", 
                                        "aortic", "angina pectoris", "ventricular", "tricuspid valve", "pericardial", "p wave", "ekg", "ventricle",
                                        "periventricular", "atrioventricular", "stroke", "aorta", "myocardial", "myopathy", "tricuspid", "valve", "arterial",
                                        "endocardial", "ischemia","bundle branch block","hypertensive"],
    "Digestive_Anomalies": ["digestive", "intestinal", "stomach", "colon", "gut", "diarrhea", "vomiting", "constipation", 
                            "bowel", "pancreatitis", "esophagus", "reflux", "herni", "gastrostomy", "oral-pharyngeal dysphagia", "abdominal", 
                            "anal", "meckel diverticulum", "malabsorption", "fecal", "colitis", "achlorhydria", "odynophagia", "polyphagia", "melena",
                            "recti", "tenesmus", "rectal", "gastroenteritis", "volvulus", "colorectal", "esophageal", "gastroschisis",
                            "crohn's disease","nasogastric","hematochezia","achalasia","zollinger-ellison syndrome","omphalocele"],
    "Facial_Anomalies": ["face", "facial", "jaw", "mandible","cheek","synophrys", "palate", "micrognathia", "chin", "eyebrow", 
                        "widow's peak", "frontal", "long philtrum", "forehead", "lip", "facies", "mouth", "philtrum",
                        "mandibular", "vermilion border", "eclabion", "cupid's bow", "retrognathia", "telecanthus", "hypotelorism", "malar",
                        ],
    "Nasal_Anomalies": ["nose", "nasal", "nostril", "anteverted nares", "nares", "sinusitis", "choanal", "cleft ala nasi", "epistaxis", "anosmia",
                        "columella", "naris", "nasopharyngeal", "rhinitis"],
    "Hormonal_Anomalies": ["hormone", "endocrine", "hypothyroidism", "hyperthyroidism", "hyperparathyroidism", "iodine uptake", "pituitary", "thyroid", "aldosterone",
                        "hirsutism", "t4", "testosterone", "estradiol", "acth", "prolactin", "androgen","adrenarche","hyperaldosteronism","cortisol","insulin"],
    "Neural_Anomalies": ["neural", "neurologic", "nerve", "sensory", "motor", "reflex", "neuropathy", "pyramidal", "fasciculations", 
                        "myelin", "axon", "dystonia", "rigidity", "paraplegia", "cognitive", "speech", "language", "development delay", 
                        "learning", "delay", "autism", "tremor", "hyperactivity", "jerky movements", "behavior", "paresthesia", "neuroma",
                        "neurodegeneration", "myelitis", "neuropathic", "neuronal", "nervous", "babinski sign", "emg", "bradykinesia"],
    "Ophthalmic_Anomalies": ["ocular", "vision", "cornea", "retina", "macula", "palpebral", "nystagmus", "myopia", "proptosis", "amaurosis",
                            "vitreoretinopathy", "electroretinogram", "hypertelorism", "ptosis", "eye", "visual", "hypermetropia", 
                            "coloboma", "exophoria", "brushfield spots", "amblyopia", "morning glory anomaly", "iridocyclitis", "pterygium",
                            "diplopia", "iris", "pupil", "photophobia", "vitreous floaters", "keratoconjunctivitis", "microphthalmia", "lentis",
                            "conjunctival", "dyschromatopsia", "chemosis", "lacrimal", "keratitis", "buphthalmos", "trichiasis", "retinopathy",
                            "orbits", "ophthalmoplegia", "dacryocystitis", "blepharitis", "hemianopia", "scotoma", "pseudophakia", "alacrima",
                            "pupillary", "uveitis", "cataract", "aniridia", "conjunctivitis", "visuospatial", "septo-optic", "optic",
                            "anterior chamber", "blepharochalasis", "pseudopapilledema","irides","metamorphopsia","rod-cone","vitreous haze","choroideremia",
                            "sclerae"],
    "Organ_Anomalies": ["organ", "viscera", "alopecia", "skin", "dermatitis", "rash", "scalp", "hair", "nail", 
                        "splenomegaly", "adipose tissue", "stenosis", "pancreatic", "pancreas","asplenia", "capillary", "erythematous",
                        "erythematosus", "jaundice", "urticaria", "melanoma", "cutaneous", "subcutaneous", "exanthema","eruptive","poikiloderma",
                        "lichenification","keratoderma"],
    "Renal_Anomalies": ["kidney", "nephro", "renal", "hematuria", "proteinuria", "glomerulo", "albuminuria",
                        "urea", "creatinine", "hyperphosphaturia", "urinary", "bladder", "cystinuria", "hypophosphaturia", "epispadias",
                        "nocturia", "enuresis", "renin", "dysuria", "carnosinuria", "urethral", "beta 2-microglobulinuria",
                        "oroticaciduria", "ureter", "urethritis", "aspartylglucosaminuria", "hypoproteinemia", "mucopolysacchariduria",
                        "glomerular", "ureterocele", "urine","tubulopathy","urachus","tubulointerstitial"],
    "Reproductive_Anomalies": ["reproductive", "genital", "gonad", "uterus", "testis", "ovary",
                            "testicular", "hypogonadism", "hypospadias", "amenorrhea", "puberty", 
                            "pubertal", "pseudohermaphroditism", "hermaphroditism", "vagina", "cryptorchidism", "infertility", "impotence",
                            "gynecomastia", "penile", "clitoris", "oligozoospermia", "clitoral", "scrotum", "dysmenorrhea", "menstruation",
                            "cervix", "orchitis", "egg", "metrorrhagia", "sex", "ovarian", "intrauterine", "fertility", "dysgerminoma", "microphallus",
                            "labia minora","micropenis","breast","penis","oocyte"],
    "Respiratory_Anomalies": ["lung", "respiratory", "breath", "bronchitis", "dyspnea", "apnea", "tachypnea", "pneumonia", "trachea",
                            "larynx", "airway", "laryngotracheomalacia", "pleura", "pulmonary", "pharyngitis", "wheezing", "asthma", "orthopnea",
                            "alveolar", "bronchodysplasia", "pneumothorax", "laryngomalacia", "bronchogenic", "cough","diaphragmatic","ventilatory",
                            "laryngeal"],
    "Skeletal_Anomalies": ["bone", "skeletal", "spine", "joint", "phalanx", "dactyly", "lordosis", "kyphosis",
                            "osteopenia", "osteoporosis", "limb", "short stature", "synovitis", "fibular hypoplasia",
                            "osteochondrosis", "muscle weakness", "cartilage", "stature", "femoral", "spina bifida", 
                            "pectus", "sclerosis", "scapulae", "knee", "supraorbital", "radius", "metatarsal", "muscle", "muscular", "femur", "synostosis", "chest",
                            "hip", "legs", "hypotonia", "plagiocephaly", "myopathic","ulnar metaphysis", "brachycephaly", "acetabular", "platybasia", "elbow",
                            "ulna", "platyspondyly", "genu recurvatum", "sternocleidomastoid", "thorax", "metacarpal", "ankles", "musculature",
                            "patellar", "spondyloepimetaphyseal dysplasia", "mediastinum", "metatarsus", "ribs", "junction", "scoliosis", "arthritis",
                            "neck", "iliac wing", "shoulders","shoulder", "torticollis", "coxa valga", "clavicle", "vertebral", "metacarpals", "tendon", "contracture",
                            "back", "osteoma", "hand", "dolichocephaly", "sacrum", "tibial", "tibia", "ankle", "arthrogryposis","hemivertebrae",
                            "gowers sign","epiphyseal","triceps","skull","myositis","osteopathia","epiphysis","vertebrae","spondyloepiphyseal","osteosarcoma",
                            "cubitus"],
    "Liver_Anomalies": ["liver", "hepatic", "hepatitis", "cholelithiasis", "biliary", "cirrhosis", "cholangitis", "hyperbilirubinemia","hepatocellular",
                        "hepatoblastoma"],
    "Others": [] #Por si no coincide con nada
} 


#Funcion para clasificar los terminos HPO teniendo en cuenta las palabras calve definidas y el fichero OBO precuperado
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
#Clasificamos la lista de HPO
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

#Analizamos estos HPO clasificados como others en un fichero txt y añadimos palabras calve de forma iterativa
with open("clasificacion_others.txt", mode = "w") as fichero:
    fichero.write(str(nombres))


#Una vez que hemos refinado la clasificacion, generamos el dataframe final con los datos control
#tienen que tener el mismo formato que los datos de ciliopatias: cada categoria una columna con 1 y 0
#Fusionamos el df_clasificado con el df_sample2, que tiene los datos sobre las enfermedades asociadas a los HPO

dfo_merge = dfo_sample2.merge(df_clasificado, on = "HPO_ID")
df_binario = pd.crosstab(
    [dfo_merge['OrphaCode'], dfo_merge['DisorderName']],
    dfo_merge['Clasificacion']
).map(lambda x: 1 if x > 0 else 0) #por si hay mas de un HPO clasificado en un mismo grupo para una enfermedad



#TODO: seguir refinando las palabras clave > pasar por CHATGPT
#TODO: seleccionar tantos registros de datos control como datos de ciliopatias haya

if __name__ == "__main__":
    #convertir df_clasificado a excel
    df_clasificado.to_excel("hpo_clasificados_final.xlsx")

    #Excel final con los datos control finales
    df_binario.to_excel("datos_control.xlsx")