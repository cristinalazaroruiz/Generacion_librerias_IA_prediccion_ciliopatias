#script para categorizar los HPO y generar un dataframe con los datos control clasificados

from orphanet_informacion import hpo_unicos, dfo_sample2
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
    "Aural Anomalies": ["hearing", "ear", "auricular", "otitis", "deaf", "vestibular", "balance", "tinnitus", "external ear", "ear canal", "microtia", "phonophobia",
                        "hypoplastic helices"],
    "Cerebral Anomalies": ["brain", "corpus callosum", "cerebral", "cerebellum", "cortex", "eeg",
                            "intellectual", "hippocampus", "mental", "encephalo", "microcephaly", "macrocephaly", "hydrocephalus", "psychomotor", 
                            "ataxia", "parkinsonism", "seizure", "epilepsy", "spastic", "cortical", "chiari", "cerebellar", "olivopontocerebellar",
                            "megalencephaly", "hemimegalencephaly", "dysdiadochokinesis", "hypsarrhythmia", "thalamic", "meningitis", "holoprosencephaly",
                            "aphasia", "ischemic", "athetosis", "mediastinum", "tetraplegia", "hemiplegia", "ventriculomegaly", "intracranial", "foramen", "gyral",
                            "cisterna magna","meningioma","polymicrogyria","parietal","fontanelle","occiput"],
    "Coronary and Vascular Anomalies": ["vascular", "vessel", "coronary", 
                                        "heart", "cardio", "hypertension", "cardiomyopathy", "tachycardia", "bradycardia", "myocarditis", "artery",
                                        "vein", "septal", "patent ductus arteriosus", "pericarditis", "cardiac", 
                                        "aortic", "angina pectoris", "ventricular", "tricuspid valve", "pericardial", "p wave", "ekg", "ventricle",
                                        "periventricular", "atrioventricular", "stroke", "aorta", "myocardial", "myopathy", "tricuspid", "valve", "arterial",
                                        "endocardial", "ischemia","bundle branch block","hypertensive"],
    "Digestive Anomalies": ["digestive", "intestinal", "stomach", "colon", "gut", "diarrhea", "vomiting", "constipation", 
                            "bowel", "pancreatitis", "esophagus", "reflux", "herni", "gastrostomy", "oral-pharyngeal dysphagia", "abdominal", 
                            "anal", "meckel diverticulum", "malabsorption", "fecal", "colitis", "achlorhydria", "odynophagia", "polyphagia", "melena",
                            "recti", "tenesmus", "rectal", "gastroenteritis", "volvulus", "colorectal", "esophageal", "gastroschisis",
                            "crohn's disease","nasogastric","hematochezia","achalasia","zollinger-ellison syndrome","omphalocele"],
    "Facial Anomalies": ["face", "facial", "jaw", "mandible","cheek","synophrys", "palate", "micrognathia", "chin", "eyebrow", 
                        "widow's peak", "frontal", "long philtrum", "forehead", "lip", "facies", "mouth", "philtrum",
                        "mandibular", "vermilion border", "eclabion", "cupid's bow", "retrognathia", "telecanthus", "hypotelorism", "malar",
                        ],
    "Nasal Anomalies": ["nose", "nasal", "nostril", "anteverted nares", "nares", "sinusitis", "choanal", "cleft ala nasi", "epistaxis", "anosmia",
                        "columella", "naris", "nasopharyngeal", "rhinitis"],
    "Hormonal Anomalies": ["hormone", "endocrine", "hypothyroidism", "hyperthyroidism", "hyperparathyroidism", "iodine uptake", "pituitary", "thyroid", "aldosterone",
                        "hirsutism", "t4", "testosterone", "estradiol", "acth", "prolactin", "androgen","adrenarche","hyperaldosteronism","cortisol","insulin",
                        "hypoinsulinemia", "hyperinsulinemia"],
    "Neural Anomalies": ["neural", "neurologic", "nerve", "sensory", "motor", "reflex", "neuropathy", "pyramidal", "fasciculations", 
                        "myelin", "axon", "dystonia", "rigidity", "paraplegia", "cognitive", "speech", "language", "developmental delay", 
                        "learning", "delay", "autism", "tremor", "hyperactivity", "jerky movements", "behavior", "paresthesia", "neuroma",
                        "neurodegeneration", "myelitis", "neuropathic", "neuronal", "nervous", "babinski sign", "emg", "bradykinesia"],
    "Ophthalmic Anomalies": ["ocular", "vision", "cornea", "retina", "macula", "palpebral", "nystagmus", "myopia", "proptosis", "amaurosis",
                            "vitreoretinopathy", "electroretinogram", "hypertelorism", "ptosis", "eye", "visual", "hypermetropia", 
                            "coloboma", "exophoria", "brushfield spots", "amblyopia", "morning glory anomaly", "iridocyclitis", "pterygium",
                            "diplopia", "iris", "pupil", "photophobia", "vitreous floaters", "keratoconjunctivitis", "microphthalmia", "lentis",
                            "conjunctival", "dyschromatopsia", "chemosis", "lacrimal", "keratitis", "buphthalmos", "trichiasis", "retinopathy",
                            "orbits", "ophthalmoplegia", "dacryocystitis", "blepharitis", "hemianopia", "scotoma", "pseudophakia", "alacrima",
                            "pupillary", "uveitis", "cataract", "aniridia", "conjunctivitis", "visuospatial", "septo-optic", "optic",
                            "anterior chamber", "blepharochalasis", "pseudopapilledema","irides","metamorphopsia","rod-cone","vitreous haze","choroideremia",
                            "sclerae"],
    "Organ Anomalies": ["organ", "viscera", "alopecia", "skin", "dermatitis", "rash", "scalp", "hair", "nail", 
                        "splenomegaly", "adipose tissue", "stenosis", "pancreatic", "pancreas","asplenia", "capillary", "erythematous",
                        "erythematosus", "jaundice", "urticaria", "melanoma", "cutaneous", "subcutaneous", "exanthema","eruptive","poikiloderma",
                        "lichenification","keratoderma"],
    "Renal Anomalies": ["kidney", "nephro", "renal", "hematuria", "proteinuria", "glomerulo", "albuminuria",
                        "urea", "creatinine", "hyperphosphaturia", "urinary", "bladder", "cystinuria", "hypophosphaturia", "epispadias",
                        "nocturia", "enuresis", "renin", "dysuria", "carnosinuria", "urethral", "beta 2-microglobulinuria",
                        "oroticaciduria", "ureter", "urethritis", "aspartylglucosaminuria", "hypoproteinemia", "mucopolysacchariduria",
                        "glomerular", "ureterocele", "urine","tubulopathy","urachus","tubulointerstitial"],
    "Reproductive Anomalies": ["reproductive", "genital", "gonad", "uterus", "testis", "ovary",
                            "testicular", "hypogonadism", "hypospadias", "amenorrhea", "puberty", 
                            "pubertal", "pseudohermaphroditism", "hermaphroditism", "vagina", "cryptorchidism", "infertility", "impotence",
                            "gynecomastia", "penile", "clitoris", "oligozoospermia", "clitoral", "scrotum", "dysmenorrhea", "menstruation",
                            "cervix", "orchitis", "egg", "metrorrhagia", "sex", "ovarian", "intrauterine", "fertility", "dysgerminoma", "microphallus",
                            "labia minora","micropenis","breast","penis","oocyte"],
    "Respiratory Anomalies": ["lung", "respiratory", "breath", "bronchitis", "dyspnea", "apnea", "tachypnea", "pneumonia", "trachea",
                            "larynx", "airway", "laryngotracheomalacia", "pleura", "pulmonary", "pharyngitis", "wheezing", "asthma", "orthopnea",
                            "alveolar", "bronchodysplasia", "pneumothorax", "laryngomalacia", "bronchogenic", "cough","diaphragmatic","ventilatory",
                            "laryngeal"],
    "Skeletal Anomalies": ["bone", "skeletal", "spine", "joint", "phalanx", "dactyly", "lordosis", "kyphosis",
                            "osteopenia", "osteoporosis", "limb", "short stature", "synovitis", "fibular hypoplasia",
                            "osteochondrosis", "muscle weakness", "cartilage", "stature", "femoral", "spina bifida", 
                            "pectus", "sclerosis", "scapulae", "knee", "supraorbital", "radius", "metatarsal", "muscle", "muscular", "femur", "synostosis", "chest",
                            "hip", "legs", "hypotonia", "plagiocephaly", "myopathic","ulnar metaphysis", "brachycephaly", "acetabular", "platybasia", "elbow",
                            "ulna", "platyspondyly", "genu recurvatum", "sternocleidomastoid", "thorax", "metacarpal", "ankles", "musculature",
                            "patellar", "spondyloepimetaphyseal dysplasia", "metatarsus", "ribs", "junction", "scoliosis", "arthritis",
                            "neck", "iliac wing", "shoulders","shoulder", "torticollis", "coxa valga", "clavicle", "vertebral", "metacarpals", "tendon", "contracture",
                            "back", "osteoma", "hand", "dolichocephaly", "sacrum", "tibial", "tibia", "ankle", "arthrogryposis","hemivertebrae",
                            "gowers sign","epiphyseal","triceps","skull","myositis","osteopathia","epiphysis","vertebrae","spondyloepiphyseal","osteosarcoma",
                            "cubitus"],
    "Liver Anomalies": ["liver", "hepatic", "hepatitis", "cholelithiasis", "biliary", "cirrhosis", "cholangitis", "hyperbilirubinemia","hepatocellular",
                        "hepatoblastoma"],
    "Others": [] #Por si no coincide con nada
} 


#Funcion para clasificar los terminos HPO teniendo en cuenta las palabras calve definidas y el fichero OBO precuperado
#Esta funcion tiene en cuenta que un mismo HPO puede contener palabras clave de distintas categorias, por lo que se clasifica en la categoria con mas coincidencias
#Para cada HPO se recuperan sus "ancestros" que pueden tener palabras calve mas sencillas relacionadas con las categorias

def clasificar_hpo_terms(lista_hpo, graph, palabras_clave):
    clasificados = defaultdict(list)
    
    for hpo_id in lista_hpo:
        if hpo_id not in graph:
            clasificados["Others"].append(hpo_id)
            continue

        # Obtener ancestros + término original
        ancestros = list(networkx.ancestors(graph, hpo_id))
        terminos = [hpo_id] + ancestros
        nombres = [graph.nodes[tid].get('name', '').lower() for tid in terminos if tid in graph]

        # Contar coincidencias por categoría
        contador = {}
        for categoria, keywords in palabras_clave.items():
            count = 0
            for nombre in nombres:
                count += sum(1 for keyword in keywords if keyword in nombre)
            contador[categoria] = count

        # Evaluar según cantidad de coincidencias
        categoria_mayor = max(contador, key=contador.get)
        max_count = contador[categoria_mayor]

        if max_count == 0:
            clasificados["Others"].append(hpo_id)
        else:
            clasificados[categoria_mayor].append(hpo_id)

    return clasificados


#generamos nuestra lista de HPOs a partir del dataframe importado
hpo_list = list(hpo_unicos["HPO_ID"])
#Clasificamos la lista de HPOs
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


#Para tener las clases balanceadas (misma cantidad ciliopatias y no ciliopatias) nos quedamos con tantos registros como hay en los datos de ciliopatias (511)
df_control = df_binario.sample(n= 511, random_state = 1 ) 

#A este dataframe le añadimos una columna con la etiqueta "no ciliopatia"
df_control["type"] = "No ciliopathy" #!este es el excel con el que vamos a seguir trabajando en R para el aprendizaje supervisado



if __name__ == "__main__":
    #convertir df_clasificado a excel
    df_clasificado.to_excel("hpo_clasificados_final.xlsx")

    #Excel  con los datos control
    df_binario.to_excel("datos_control.xlsx")

    #Sample datos control
    df_control.to_excel("Anexo_D.xlsx")