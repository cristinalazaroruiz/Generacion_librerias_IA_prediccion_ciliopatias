library(dplyr)

################################################################################
#                     Cargar todos los csv de CiliaMiner
################################################################################

# Obtener lista de archivos CSV en el directorio
csv_files <- list.files(path = "../CiliaMiner-main/data/", pattern = "*.csv", full.names = TRUE)

# Crear una lista para almacenar los dataframes
df_list <- list()

# Cargar cada CSV y guardarlo en la lista
for (i in 1:length(csv_files)) {
  df_i <- read.csv(csv_files[i])  
  df_list[[i]] <- df_i
  
  # Crear el nombre dinámico para el dataframe
  df_name <- paste("df", i, sep = "")  # Esto genera nombres como df1, df2, df3, etc.
  
  # Asignar el dataframe a la variable con el nombre generado
  assign(df_name, df_i)
  
}

for (i in 1:length(df_list)){
  titulo <- paste("df", i, sep="")
  View(df_list[[i]], title=titulo)
  
}


#Renombrar los dataframes
atypical_ciliopathies <- df1
genes_localizacion <- df2
referencias_pubmed <- df3
sintomas_ciliopatias_primarias <- df4 #si
sintomas_cilipatias_secundarias <- df5 #si
localizacion_cada_gen <- df6 #si
cantidad_tipo_ciliopatias <- df7
hsapiens_cilopathies <- df8 #si
ortologos <- df9
celegans <- df10
creinhardtii <- df11
dreiro <- df12
drosophila <- df13
mmuscullus <- df14
xlaveis <- df15
potencial_ciliopathies_genes <- df16
lista_sintomas_primarios <- df17
publicaciones <- df18
publicaciones2 <- df19
purelist <- df20 #si
purelist2 <- df21 #si
seraching_genes <- df22
clinical_secondary_ciliopathies <- df23 #si
secondary_list <- df24 #si
clinical_primary_cilipathies <- df25 #si
secondary_cilipathies <- df26 #si

################################################################################
#                     Crear nuestras propias librerias
################################################################################
#Sintomas clinicos cilipatias primarias > las tenemos en el df clinical_primary_ciliopathies
#Organizamos la informacion de otra manera
df_primary <- as.data.frame(t(clinical_primary_cilipathies))
ciliopatias_primarias <- colnames(clinical_primary_cilipathies) 
clinical_features <- clinical_primary_cilipathies$Ciliopathy...Clinical.Features
sintomas_primarios_generales <- sintomas_ciliopatias_primarias$General.Titles
colnames(df_primary) <- clinical_features
df_primary <- df_primary[-1, ]

#Convertir los Nas en 0
for (i in 1:length(clinical_features)) {
  df_primary[[clinical_features[i]]][is.na(df_primary[[clinical_features[i]]])] <- 0
}

df_primary <- df_primary[-1, ]

#¿Como agrupamos segun terminos mas generales? > df sintomas_ciliopatias_primarias > group_by()
df <- sintomas_ciliopatias_primarias
df <- replace(df, is.na(df), 0)
ciliopatias_primarias <- colnames(df)
df_agrupado <- df %>%
  group_by(General.Titles) %>%
  summarise(across(everything(), ~ max(.), .names = "{.col}_agrupado"))

#Una vez agrupado, ponemos bien organizada la informacion
df_primary_resumido <- as.data.frame(t(df_agrupado))
sintomas <- df_agrupado$General.Titles
colnames(df_primary_resumido) <- sintomas
rownames(df_primary_resumido) <- ciliopatias_primarias
df_primary_resumido <- df_primary_resumido[-1, ]
#Convertimos los sindromes en una columna, no en los rownames
ciliopatias_primarias <- ciliopatias_primarias[ciliopatias_primarias != "General.Titles"]
df_primary_resumido <- cbind(df_primary_resumido, Ciliopathy = ciliopatias_primarias)
ID_primary <- seq(1,36,1)
rownames(df_primary_resumido) <- ID_primary

#Añadir a df_primary_resumido una columna indicado que los sindromes son ciliopatias primarias
dim(df_primary_resumido) #36 filas
primary_cilipathy <- rep("Primary", times = 36)
df_primary_resumido <- cbind(df_primary_resumido, type_ciliopathy=primary_cilipathy)

#Ahora hacemos lo mismo con las ciliopatias secundarias
df_secondary <- replace(sintomas_cilipatias_secundarias, is.na(sintomas_cilipatias_secundarias),0)
ciliopatias_secundarias <- colnames(df_secondary)
df_secondary <- df_secondary %>%
  group_by(General.Titles) %>%
  summarise(across(everything(), ~ max(.), .names = "{.col}_agrupado"))
sintomas_secundarios <- df_secondary$General.Titles
df_secondary <- as.data.frame(t(df_secondary))
colnames(df_secondary) <- sintomas_secundarios
rownames(df_secondary) <- ciliopatias_secundarias
df_secondary <- df_secondary[-1, ]

#Convertimos rownames en una columna a parte
ciliopatias_secundarias <- ciliopatias_secundarias[ciliopatias_secundarias !="General.Titles"]
df_secondary <- cbind(df_secondary, Ciliopathy = ciliopatias_secundarias)
ID_secondary <- seq(37, 60, 1)
rownames(df_secondary) <- ID_secondary

dim(df_secondary) #24 filas
type_secondary <- rep("Secondary", times = 24)
df_secondary <- cbind(df_secondary, type_ciliopathy=type_secondary )


#motile ciliopathies > no estan bien puestas en las tablas
#Primary.Ciliary.Dyskinesia > esta en la lista de primarios
#Birt.Hogg.Dubé.Syndrome
#Juvenile.Myoclonic.Epilepsy

#Lo cambiamos 
df_primary_resumido[27, "type_ciliopathy"] <- "motile"
df_secondary[24, "type_ciliopathy"] <- "motile"
df_secondary[2, "type_ciliopathy"] <- "motile"
df_secondary[6, "type_ciliopathy"] <- "motile"


#Unir tablas df_primary_resumido y df_secondary
#Problema: en df_primary esta la columna Cognitive Anomalies y en df_secondary Others. 
#Solucion: llamar a la columna en los dos casos others para estandarizar

# Renombrar "Cognitive Anomalies" a "Others" en df_primary_resumido
colnames(df_primary_resumido)[colnames(df_primary_resumido) == "Cognitive Anomalies"] <- "Others"

#Ordenar columnas por orden alfabetico, para que tengan el mismo orden
# Ordenar las columnas en orden alfabético en ambos dataframes
df_primary_resumido <- df_primary_resumido[, order(colnames(df_primary_resumido))]
df_secondary <- df_secondary[, order(colnames(df_secondary))]

#Ahora ya lo podemos unir
df_unido <- rbind(df_primary_resumido, df_secondary)

#Comprobamos porque creo que Primary.Ciliary.Dyskinesia esta duplicado
df_prueba <- df_unido %>%filter(Ciliopathy == "Primary.Ciliary.Dyskinesia")
#Eliminamos la fila 60, ya que es repetida de la 27
df_unido <- df_unido[-60, ]

#Añadir genes y localizacion celular. 
#Primero nos quedamos solo con la informacion que nos interesa 
df_genes_localizacion <- hsapiens_cilopathies %>% select(Ciliopathy, 
                                                         Human.Gene.Name, Human.Gene.ID, Subcellular.Localization, 
                                                         Localisation.Reference)


#Usar join > key: Ciliopathies
#Primero nos aseguramos que todas las keys son iguales en ambas tablas
df_genes_localizacion$Ciliopathy <- gsub(" ", ".", df_genes_localizacion$Ciliopathy) #cambiar espacios por puntos
df_genes_localizacion$Ciliopathy <- gsub("-", ".", df_genes_localizacion$Ciliopathy) #cambiar guiones por puntos
df_genes_localizacion$Ciliopathy <- gsub(",", ".", df_genes_localizacion$Ciliopathy) #cambiar comas por puntos
df_genes_localizacion$Ciliopathy <- gsub("–", "-", df_genes_localizacion$Ciliopathy) #cambiar guion largo por puntos
df_genes_localizacion$Ciliopathy <- gsub("-", ".", df_genes_localizacion$Ciliopathy)
df_unido$Ciliopathy <- tolower(df_unido$Ciliopathy) #pasar todo a minusculas
df_genes_localizacion$Ciliopathy <- tolower(df_genes_localizacion$Ciliopathy) #pasar todo a minusculas

#Left join
df_general <- dplyr::left_join(df_unido, df_genes_localizacion, by = "Ciliopathy")

#Cosas a plantear > cambiar localizacion por dentro y fuera del cilio, por ejemplo. Codificar en modo factor.
localizacion <- unique(df_general$Subcellular.Localization)
localizacion
localizacion_cilio <- c("Cilia, Axoneme","Cilia, Axoneme",  "Axoneme" ,"Basal Body, Axoneme" , "Cilia, Axoneme *",
                        "Basal Body, Cilia", "Axoneme *",   "Cilia", "Transition Zone, Axoneme", 
                        "Transition Zone, Axoneme", "Ciliary Membrane",  "Axoneme, Basal Body",
                        "Cilia, Around Basal Body", "Cilia *", "Transition Zone, Basal Body, Axoneme",
                        "Axoneme, Transition Zone", "Cilia, Basal Body",
                        "Cilia, Transition Zone", "Basal Body, Transition Zone", "Transition Zone, Basal Body, 
                        Axoneme", "Transition Zone", "Cilia, Around Basal Body",
                        "Transition Zone, Axoneme, Basal Body", "Axoneme, Transition Zone")

localizacion_cilio <- unique(localizacion_cilio)

any(is.na(df_general$Subcellular.Localization)) #no hay Nas

df_general2 <- df_general

for (i in 1:511){
  
  if(df_general2$Subcellular.Localization[i] %in% localizacion_cilio){
    df_general2$Subcellular.Localization[i] <- 1
    
  }else if (df_general2$Subcellular.Localization[i] == "Not reported") {
    df_general2$Subcellular.Localization[i] <- 2
    
  } else {
    df_general2$Subcellular.Localization[i] <- 0
    
  }
  
  
}

df_general2 <- df_general2 %>%select(-Localisation.Reference, -Human.Gene.ID)
#Guardamos df_general2 como el Anexo A
write.csv(df_general2, file = "Anexo_A.csv")

################################################################################
#                     Aprendizaje no supervisado
################################################################################
#Lo vamos a aplicar sobre el dataframe df_general2.
#El problema es que hay dos variables tipo string: ciliopathy y human gene (type_ciliopathy va a ser la label)
#Hay que recodificar estas dos variables a numerico. Existen diferentes posibilidades, pero vamos a probar
#con frecuency encoding (sustituir por la frecuencia de aparicion de cada valor)

df_no_supervised <- df_general2
df_no_supervised$Ciliopathy <- ave(df_no_supervised$Ciliopathy, 
                                   df_no_supervised$Ciliopathy, FUN = length)




df_no_supervised$Human.Gene.Name <- ave(df_no_supervised$Human.Gene.Name, 
                                   df_no_supervised$Human.Gene.Name, FUN = length)


#La label la dejamos a parte:
label <- as.data.frame(df_general2$type_ciliopathy)
colnames(label) <- "type"
df_no_supervised <- df_no_supervised %>% dplyr::select(-type_ciliopathy)

#Convertimos todas las variables a numericas
variables <- colnames(df_no_supervised)
for (i in 1:length(variables)){
  df_no_supervised[[variables[i]]] <- as.numeric(df_no_supervised[[variables[i]]])
  
}

#Nos aseguramos que no haya datos faltantes
any(is.na(df_no_supervised)) #No hay datos faltantes
#Nos aseguramos que no haya columnas con todo 0
any(colSums(df_no_supervised) == 0)

#Guardamos como anexo B la version que si tiene las labels
anexo_2 <- cbind(df_no_supervised, label)
write.csv(anexo_2, file = "Anexo_B.csv")

#Escalado
df_no_supervised_scaled <- as.data.frame(scale(df_no_supervised))

#Ahora ya aplicamos los algoritmos de aprendizaje no supervisado. 
#Primero aplicamos PCA y tSNE
##PCA
library(stats)
library(factoextra)
library(openxlsx)
pca.result <- prcomp(df_no_supervised_scaled, center = TRUE, scale = FALSE)
fviz_eig(pca.result, labels = TRUE) 
tabla_eigenvalues <- get_eigenvalue(pca.result)
df_eigenvalues <- as.data.frame(tabla_eigenvalues)
colnames(df_eigenvalues) <- c("eigenvalues", "porcentaje varianza", "varianza acumulada")
write.xlsx(df_eigenvalues, rowNames = TRUE, "eigenvalues.xlsx")
pca.df <- as.data.frame(pca.result$x)
var <- pca.result$sdev^2
var_explicada <- var/sum(var)
ggplot(pca.df, aes(x = PC1, y = PC2, color = label$type))+
  geom_point(size = 5) +
  scale_color_manual(values=c("red", "blue","orange")) +
  labs(
    title = "Análisis de Componentes Principales",
    x = paste0("PC1", "varianza explicada: ", round(var_explicada[1],3)),
    y = paste0("PC2", "varianza explicada: ", round(var_explicada[2],3)),
    color = "tipo de Ciliopatía"
  )+
  theme_classic() + 
  theme(
    panel.grid.mayor = element_line(color = "gray90"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "gray95"),
    plot.title = element_text(hjust = 0.5)
  )

#Calculamos el KMO (Kaiser-Meyer-Olkin) para comprobar que se podia hacer PCA 
library(psych)
dim(df_no_supervised)
KMO_parameter <- KMO(cor(df_no_supervised_scaled))
print(KMO_parameter)
df_KMO <- as.data.frame(KMO_parameter$MSAi)
colnames(df_KMO) <- "KMO"
df_KMO$KMO <- round(df_KMO$KMO, 2)
write.xlsx(df_KMO, rowNames = TRUE, "KMO_1.xlsx")

#Criterio:
  
#Above 0.90 - Marvelous
#0.80 to 0.90 - Meritorious
#0.7 to 0.80 - Average
#0.60 to 0.70 - Mediocre
#0.50 to 0.60 - Terrible
#Below 0.50 - Unacceptable



#tSNE
library(Rtsne)
set.seed(123)
tsne.result <- Rtsne(X=df_no_supervised_scaled) #me da error y me pide eliminar los duplicados
#Eliminar los duplicados
df_no_supervised_clean <- cbind(df_no_supervised_scaled, type = label$type)
df_no_supervised_clean <- unique(df_no_supervised_clean)
labels_clean <- as.data.frame(df_no_supervised_clean$type)
df_no_supervised_clean <- df_no_supervised_clean %>% dplyr::select(-type)

tsne.result <- Rtsne(X=df_no_supervised_clean)
tsne.df <- as.data.frame(tsne.result$Y)

ggplot(tsne.df, aes(x = V1, y = V2, color = labels_clean$`df_no_supervised_clean$type`)) +
  geom_point(size = 5) +
  scale_color_manual(values = c("red", "blue", "orange")) +
  labs(
    title = "Análisis por t-SNE",
    x = "Dimensión 1",
    y = "Dimensión 2",
    color = "Tipo de Ciliopatía"
  ) +
  theme_classic() + 
  theme(
    panel.grid.major = element_line(color = "gray90"),  # Corregido a "major"
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "gray95"),
    plot.title = element_text(hjust = 0.5)
  )

################################################################################
#                     Clusterizacion
################################################################################
#Al haber hecho frequency encoding, no podemos usar cualquier algoritmo. 
#No es adecuado usar algoritmos que se basen en distancias, como el k-means. 
#Es mas apropiado usar algoritmos de clusterizació aglomerativos. 
#Vamos a usar dos metodos de linkeage: el ward y el complete
dist_matrix_euclidean <- dist(df_no_supervised_scaled, method = "euclidean")
dist_matrix_manhattan <- dist(df_no_supervised_scaled, method = "manhattan")
hclust_ward_euclidean <- hclust(dist_matrix_euclidean, method = "ward.D")
hclust_ward_manhattan <- hclust(dist_matrix_manhattan, method = "ward.D")
hclust_single_euclidean <- hclust(dist_matrix_euclidean, method = "single")
hclust_single_manhattan <- hclust(dist_matrix_manhattan, method = "single")
hclust_average_euclidean <- hclust(dist_matrix_euclidean, method = "average")
hclust_average_manhattan <- hclust(dist_matrix_manhattan, method = "average")



colors <- c("red", "green", "blue")
clust_ward_euclidean <- fviz_dend(hclust_ward_euclidean,
                                  cex = 0.5,
                                  k = 3, 
                                  palette = colors,
                                  main = "Ward + Euclidiana",
                                  xlab = "Índice de observaciones",
                                  ylab = "Distancia") + theme_classic()
clust_ward_euclidean


clust_ward_manhattan <- fviz_dend(hclust_ward_manhattan,
                                  cex = 0.5,
                                  k = 3, 
                                  palette = colors,
                                  main = "Ward + Manhattan",
                                  xlab = "Índice de observaciones",
                                  ylab = "Distancia") + theme_classic()
clust_ward_manhattan


clust_single_euclidean <- fviz_dend(hclust_single_euclidean,
                                  cex = 0.5,
                                  k = 3, 
                                  palette = colors,
                                  main = "Simple + Euclidiana",
                                  xlab = "Índice de observaciones",
                                  ylab = "Distancia") + theme_classic()
clust_single_euclidean




clust_single_manhattan <- fviz_dend(hclust_single_manhattan,
                                      cex = 0.5,
                                      k = 3, 
                                      palette = colors,
                                      main = "Simple + Manhattan",
                                      xlab = "Índice de observaciones",
                                      ylab = "Distancia") + theme_classic()
clust_single_manhattan


clust_average_euclidean <- fviz_dend(hclust_average_euclidean,
                                    cex = 0.5,
                                    k = 3, 
                                    palette = colors,
                                    main = "Promedio + Euclidiana",
                                    xlab = "Índice de observaciones",
                                    ylab = "Distancia") + theme_classic()

clust_average_manhattan <- fviz_dend(hclust_average_manhattan,
                                     cex = 0.5,
                                     k = 3, 
                                     palette = colors,
                                     main = "Promedio + Manhattan",
                                     xlab = "Índice de observaciones",
                                     ylab = "Distancia") + theme_classic()


library(gridExtra)
dendogramas <- grid.arrange(clust_ward_euclidean, clust_ward_manhattan, 
             clust_single_euclidean, clust_single_manhattan, 
             clust_average_euclidean, clust_average_manhattan, nrow =3)

##Comprobar las etiquetas de cada grupo

# Paso 1: Crear la asignación de grupos con cutree()
grupos_ward_euclidean <- data.frame(grupo = cutree(hclust_ward_euclidean, k = 3))

# Paso 2: Añadir la columna de etiquetas
grupos_ward_euclidean$type <- label$type  
# Paso 3: Asignar colores a cada grupo (según los usados en el dendrograma)
colors <- c("blue", "red", "green")
grupos_ward_euclidean$color <- colors[grupos_ward_euclidean$grupo]



#hacemos lo mismo con ward+manhattan
grupos_ward_manhattan <- data.frame(grupo = cutree(hclust_ward_manhattan, k = 3))
colors <- c("blue", "green", "red")
grupos_ward_manhattan$type <- label$type
grupos_ward_manhattan$color <- colors[grupos_ward_manhattan$grupo]



grafico_ward_manhattan <- ggplot(grupos_ward_manhattan, aes(x = type, fill = color))+geom_bar()+
  labs(title = "Clusters Manhattan + Ward",
       x = "Tipos de ciliopatía", y = "Pacientes")+scale_fill_manual(values = c("red" = "red",
                               "blue" = "blue",
                               "green" = "green"))


grafico_ward_euclidean <- ggplot(grupos_ward_euclidean, aes(x = type, fill = color))+geom_bar()+
  labs(title = "Clusters Euclidiana + Ward",
       x = "Tipos de ciliopatía", y = "Pacientes")+scale_fill_manual(values = c("red" = "red",
                                                                                "blue" = "blue",
                                                                                "green" = "green"))


#lo ponemos todo junto

graficos_barras <- grid.arrange(grafico_ward_euclidean,grafico_ward_manhattan, nrow = 1 )


#Kmeans
#Enontrar el numero opitimo de centroides > no funciona demasiado
fviz_nbclust(df_no_supervised_scaled, kmeans, method = "wss")+
  ggtitle("Clusterizacion kmeans", subtitle = "")+
  theme_classic()

kmeans.result <- kmeans(df_no_supervised_scaled, centers = 3, iter.max=100,
                        algorithm = c("Hartigan-Wong", "Lloyd", "Forgy",
                                      "MacQueen"), nstart = 25)

kmeans_euclidean.plot <- fviz_cluster(kmeans.result, data = df_no_supervised_scaled, xlab = "Dimension 1",
             ylab ="Dimension 2")+ggtitle("K-means distancia euclidiana", subtitle = "")+
  theme_minimal() #Parece que si se pueden visualizar tres grupos 

kmeans_euclidean.plot

#Podemos sacar los ID de cada cluster con el siguiente codigo:

df_clusters <- data.frame(ID = rownames(df_no_supervised_scaled),
                          Cluster = kmeans.result$cluster) 

#Añadimos las etiquetas haciendo un join 
#Primero necesito que el ID de cada paciente sea una columna, no el nombre de la fila
ID_labels <- rownames(label)
df_labels_ID <- cbind(label, ID = ID_labels)

df_cluster2 <- dplyr::inner_join(df_clusters, df_labels_ID, by = "ID")

#Para ver mejor los grupos graficamos
library(ggplot2)
df_cluster2$Cluster <- as.factor(df_cluster2$Cluster)

kmeans_euclidean.var <- ggplot(df_cluster2, aes(x = type, fill = Cluster))+geom_bar()+
  labs(title = "Clusters distancia euclidiana",
       x = "Tipos de ciliopatía", y = "Pacientes")
kmeans_euclidean.var

#Tambien se pueden probar otras distancias a parte de la euclidean, pero no se puede usar el algoritmo kmeans()
#Se puede usar pam() de la libreria cluster
library(cluster)
pam.result_manhattan <- pam(df_no_supervised_scaled, k = 3, metric = "manhattan")

kmeans_manhattan.plot <- fviz_cluster(pam.result_manhattan, data = df_no_supervised_scaled, xlab = "Dimension 1",
             ylab ="Dimension 2")+ggtitle("K-means distancia Manhattan", subtitle = "")+
  theme_minimal() #Parece que si se pueden visualizar tres grupos 

kmeans_manhattan.plot

#Pasamos tambien a df y a un grafico
df_cluster_manhattan <- data.frame(ID = rownames(df_no_supervised_scaled),
                                   cluster = pam.result_manhattan$clustering)


df_cluster_manhattan2 <- dplyr::inner_join(df_cluster_manhattan, df_labels_ID, by = "ID")
View(df_cluster_manhattan2)

df_cluster_manhattan2$cluster <- as.factor(df_cluster_manhattan2$cluster)

kmeans_manhattan.var <- ggplot(df_cluster_manhattan2, aes(x = type, fill = cluster))+geom_bar()+
  labs(title = "Clusters distancia Manhattan",
       x = "Tipos de ciliopatía", y = "Pacientes")

kmeans_manhattan.var


grid.arrange(kmeans_euclidean.plot, kmeans_euclidean.var,
             kmeans_manhattan.plot, kmeans_manhattan.var, nrow = 2)


