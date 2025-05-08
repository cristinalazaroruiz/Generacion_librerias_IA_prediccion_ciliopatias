from rdflib import Graph
from orphanet_info import hpo_unicos2

# URL del archivo OWL de HPO (Human Phenotype Ontology) > fichero con la relacion entre los HPO y sus categorias padre
hpo_owl_url = "https://raw.githubusercontent.com/obophenotype/human-phenotype-ontology/master/hp.obo"

#! Lista de términos HPO (ejemplo)
hpo_terms = hpo_unicos2["HPO_ID"].to_list()



# Cargar el archivo OWL en un grafo RDF > fichero pensado para ser leido por un ordenador y analizar la informacion
graph = Graph()
graph.parse(hpo_owl_url, format="ttl")

# Función para obtener las categorías padres de un término HPO
def get_parent_categories(hpo_term):
    query = f"""
    SELECT ?parent WHERE {{
        ?term rdfs:subClassOf ?parent .
        ?term rdfs:label "{hpo_term}"@en .
    }}
    """
    results = graph.query(query)
    parents = [str(result[0]) for result in results]
    return parents

# Clasificación de términos
classification = {
    "Aural_Anomalies": [],
    "Cerebral_Anomalies": [],
    "Coronary_and_Vascular_Anomalies": [],
    "Digestive_Anomalies": [],
    "Facial_Anomalies": [],
    "Nasal_Anomalies": [],
    "Others": [],
    "Hormonal_Anomalies": [],
    "Neural_Anomalies": [],
    "Ophthalmic_Anomalies": [],
    "Organ_Anomalies": [],
    "Renal_Anomalies": [],
    "Reproductive_Anomalies": [],
    "Respiratory_Anomalies": [],
    "Skeletal_Anomalies": [],
    "Liver_Anomalies": [],
}

#! Asignar categorías (esto es un ejemplo, ajustar según la jerarquía)
def classify_terms(hpo_terms):
    for term in hpo_terms:
        parents = get_parent_categories(term)
        print(f"Term: {term} | Parents: {parents}")
        
        # Clasificación según los padres
        if "Anomaly of the ear" in parents:
            classification["Aural_Anomalies"].append(term)
        elif "Anomaly of the brain" in parents:
            classification["Cerebral_Anomalies"].append(term)
        elif "Anomaly of the heart" in parents:
            classification["Coronary_and_Vascular_Anomalies"].append(term)
        elif "Anomaly of the gastrointestinal system" in parents:
            classification["Digestive_Anomalies"].append(term)
        elif "Facial dysmorphism" in parents:
            classification["Facial_Anomalies"].append(term)
        elif "Nasal anomaly" in parents:
            classification["Nasal_Anomalies"].append(term)
        else:
            classification["Others"].append(term)

# Llamar a la función para clasificar los términos
classify_terms(hpo_terms)

# Imprimir la clasificación final
for category, terms in classification.items():
    print(f"{category}: {terms}")

#TODO: esto no funciona > no se bien como tratar los archivos RDF