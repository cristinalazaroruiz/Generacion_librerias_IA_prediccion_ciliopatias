En esta carpeta, se encuentran los scripts utilizados para generar los datos control. La información se ha obtenido a partir de OPRHANET, mediante el fichero en_product4(1).xml 
Esta información se ha procesado y clasificado hasta obtener los datos control. 
Primeramente, con el script orphanet_informacion.py, se ha procesado el XML hasta generar el Anexo C, que contiene información sobre todas las enfermedades control y sus términos HPO asociados sin clasificar.
Antes de generar este datset, se han eliminado las enfermedades relativas a las ciliopatías presentes en el XML, mediante el script ophranet_API.py.
Por úlitmo, en el script clasificacion_HPO.py, se han clasificado los términos HPO siguiendo el mismo formato que los datos de ciliopatías, hasta dar lugar al Anexo D. Para esta clasificación, se ha usado el fichero hp.obo, obtenido de https://github.com/obophenotype/human-phenotype-ontology?tab=readme-ov-file
