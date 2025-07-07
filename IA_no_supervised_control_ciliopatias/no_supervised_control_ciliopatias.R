#Librerias
library(readxl)
library(dplyr)
library(stats)
library(factoextra)
library(ggplot2)
library(openxlsx)
library(psych)
library(Rtsne)
library(gridExtra)
library(cluster)

################################################################################
#                         Preparacion de la libreria
################################################################################


#Cargar los conjuntos de datos (control y ciliopatias)
ciliopatias <- read.csv("Anexo_2.csv")
control <- read_excel("Anexo_4.xlsx")

#para que los nombres de las columnas esten igual, hay que cambiar espacios por puntos
colnames(control) <- gsub(" ", ".", colnames(control))


#Ahora nos vamos a quedar solo con las columnas sobre datos clinicos en ambos datasets
columnas_clinicas <- colnames(control)
columnas_clinicas <- columnas_clinicas[columnas_clinicas!= "OrphaCode"]
columnas_clinicas <- columnas_clinicas[columnas_clinicas != "DisorderName"]

ciliopatias <- ciliopatias %>%dplyr::select(all_of(columnas_clinicas))
#guardamos en el control, el orphacode en otro dataframe
orphacodes <- control %>%dplyr::select("OrphaCode")
control <- control %>%dplyr::select(all_of(columnas_clinicas))

#en el dataframe de las ciliopatias, cambiamos type solo por el valor "ciliopathy"
ciliopathy_column <- rep("ciliopathy", times = 511)
ciliopatias["type"] <- ciliopathy_column

#Ahora fusionamos ambos dataframes
df <- rbind(control, ciliopatias)

write.xlsx(df, rowNames = TRUE, "Anexo_5.xlsx")

################################################################################
#                         Algoritmos de aprendizaje no supervisado
################################################################################
#separamos las etiquetas del resto de los datos
labels <- df%>%dplyr::select("type")
df_no_supervised <- df%>%dplyr::select(-"type")

#escalado
df_no_supervised_scaled <- as.data.frame(scale(df_no_supervised))
#comprobar que no hay datos faltantes
any(is.na(df_no_supervised_scaled))
#comprobar que no hay columnas con todo 0
any(colSums(df_no_supervised_scaled) == 0)

####PRIMER ALGORITMO: PCA
pca.result <- prcomp(df_no_supervised_scaled, center = TRUE, scale = FALSE)

fviz_eig(pca.result, labels = TRUE) 

tabla_eigenvalues <- get_eigenvalue(pca.result)

df_eigenvalues <- as.data.frame(tabla_eigenvalues)

colnames(df_eigenvalues) <- c("eigenvalues", "porcentaje varianza", "varianza acumulada")

write.xlsx(df_eigenvalues, rowNames = TRUE, "eigenvalues_2.xlsx")

pca.df <- as.data.frame(pca.result$x)
var <- pca.result$sdev^2
var_explicada <- var/sum(var)

ggplot(pca.df, aes(x = PC1, y = PC2, color = labels$type))+
  geom_point(size = 5) +
  scale_color_manual(values=c("red", "blue")) +
  labs(
    title = "Análisis de Componentes Principales (PCA)",
    x = paste0("PC1", " varianza explicada: ", round(var_explicada[1],3)),
    y = paste0("PC2", " varianza explicada: ", round(var_explicada[2],3)),
    color = "Enfermedad"
  )+
  theme_classic() + 
  theme(
    panel.grid.major = element_line(color = "gray90"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "gray95"),
    plot.title = element_text(hjust = 0.5)
  )

#Hacemos un KMO

KMO_parameter <- KMO(cor(df_no_supervised_scaled))
print(KMO_parameter)
df_KMO <- as.data.frame(KMO_parameter$MSAi)
colnames(df_KMO) <- "KMO"
df_KMO$KMO <- round(df_KMO$KMO, 2)
write.xlsx(df_KMO, rowNames = TRUE, "KMO_2.xlsx")


####SEGUNDO ALGORITMO: T-SNE
set.seed(123)
tsne.result <- Rtsne(X=df_no_supervised_scaled) #da error, hay que eliminar los duplicados
df_no_supervised_temp <- cbind(df_no_supervised_scaled, type = labels$type)
df_no_supervised_no_duplicados <- df_no_supervised_temp[!duplicated(df_no_supervised_scaled), ]
labels_clean <- as.data.frame(df_no_supervised_no_duplicados$type)
colnames(labels_clean) <- "type"
df_no_supervised_clean <- df_no_supervised_no_duplicados %>%dplyr::select(-type)
tsne.result <- Rtsne(X=df_no_supervised_clean)
tsne.df <- as.data.frame(tsne.result$Y)

ggplot(tsne.df, aes(x = V1, y = V2, color = labels_clean$type)) +
  geom_point(size = 5) +
  scale_color_manual(values = c("red", "blue", "orange")) +
  labs(
    title = "Análisis por t-SNE",
    x = "Dimensión 1",
    y = "Dimensión 2",
    color = "Enfermedad"
  ) +
  theme_classic() + 
  theme(
    panel.grid.major = element_line(color = "gray90"),  # Corregido a "major"
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "gray95"),
    plot.title = element_text(hjust = 0.5)
  )



####TERCER ALGORITMO: CLUSTERIZACION JERARQUICA

dist_matrix_euclidean <- dist(df_no_supervised_scaled, method = "euclidean")
dist_matrix_manhattan <- dist(df_no_supervised_scaled, method = "manhattan")
hclust_ward_euclidean <- hclust(dist_matrix_euclidean, method = "ward.D")
hclust_ward_manhattan <- hclust(dist_matrix_manhattan, method = "ward.D")
hclust_single_euclidean <- hclust(dist_matrix_euclidean, method = "single")
hclust_single_manhattan <- hclust(dist_matrix_manhattan, method = "single")
hclust_average_euclidean <- hclust(dist_matrix_euclidean, method = "average")
hclust_average_manhattan <- hclust(dist_matrix_manhattan, method = "average")

colors <- c("red", "blue")
clust_ward_euclidean <- fviz_dend(hclust_ward_euclidean,
                                  cex = 0.5,
                                  k = 2, 
                                  palette = colors,
                                  main = "Ward + Euclidiana",
                                  xlab = "Índice de observaciones",
                                  ylab = "Distancia") + theme_classic()
clust_ward_euclidean


clust_ward_manhattan <- fviz_dend(hclust_ward_manhattan,
                                  cex = 0.5,
                                  k = 2, 
                                  palette = colors,
                                  main = "Ward + Manhattan",
                                  xlab = "Índice de observaciones",
                                  ylab = "Distancia") + theme_classic()
clust_ward_manhattan


clust_single_euclidean <- fviz_dend(hclust_single_euclidean,
                                    cex = 0.5,
                                    k = 2, 
                                    palette = colors,
                                    main = "Simple + Euclidiana",
                                    xlab = "Índice de observaciones",
                                    ylab = "Distancia") + theme_classic()
clust_single_euclidean




clust_single_manhattan <- fviz_dend(hclust_single_manhattan,
                                    cex = 0.5,
                                    k = 2, 
                                    palette = colors,
                                    main = "Simple + Manhattan",
                                    xlab = "Índice de observaciones",
                                    ylab = "Distancia") + theme_classic()
clust_single_manhattan


clust_average_euclidean <- fviz_dend(hclust_average_euclidean,
                                     cex = 0.5,
                                     k = 2, 
                                     palette = colors,
                                     main = "Promedio + Euclidiana",
                                     xlab = "Índice de observaciones",
                                     ylab = "Distancia") + theme_classic()

clust_average_manhattan <- fviz_dend(hclust_average_manhattan,
                                     cex = 0.5,
                                     k = 2, 
                                     palette = colors,
                                     main = "Promedio + Manhattan",
                                     xlab = "Índice de observaciones",
                                     ylab = "Distancia") + theme_classic()


grid.arrange(clust_ward_euclidean, clust_ward_manhattan, 
             clust_single_euclidean, clust_single_manhattan, 
             clust_average_euclidean, clust_average_manhattan, nrow =3)



#graficos de barras

# Paso 1: Crear la asignación de grupos con cutree()
grupos_ward_euclidean <- data.frame(grupo = cutree(hclust_ward_euclidean, k = 2))

# Paso 2: Añadir la columna de etiquetas
grupos_ward_euclidean$type <- labels$type  
# Paso 3: Asignar colores a cada grupo (según los usados en el dendrograma)
colors <- c("red", "blue")
grupos_ward_euclidean$color <- colors[grupos_ward_euclidean$grupo]


#hacemos lo mismo con ward+manhattan
colors <- c("blue", "red")
grupos_ward_manhattan <- data.frame(grupo = cutree(hclust_ward_manhattan, k = 2))
grupos_ward_manhattan$type <- labels$type
grupos_ward_manhattan$color <- colors[grupos_ward_manhattan$grupo]



grafico_ward_manhattan <- ggplot(grupos_ward_manhattan, aes(x = type, fill = color))+geom_bar()+
  labs(title = "Clusters Manhattan + Ward",
       x = "Enfermedad", y = "Pacientes")+scale_fill_manual(values = c("red" = "red",
                                                                                "blue" = "blue"
                                                                                ))
grafico_ward_manhattan

grafico_ward_euclidean <- ggplot(grupos_ward_euclidean, aes(x = type, fill = color))+geom_bar()+
  labs(title = "Clusters Euclidiana + Ward",
       x = "Enfermedad", y = "Pacientes")+scale_fill_manual(values = c("red" = "red",
                                                                                "blue" = "blue"
                                                                                ))
grafico_ward_euclidean

graficos_barras <- grid.arrange(grafico_ward_euclidean,grafico_ward_manhattan, nrow = 1 )

####CUARTO ALGORITMO: CLUSTERIZACION K-MEANS
#distancia euclidiana
kmeans.result.euclidean <- kmeans(df_no_supervised_scaled, centers = 2, iter.max=100,
                        algorithm = c("Hartigan-Wong", "Lloyd", "Forgy",
                                      "MacQueen"), nstart = 25)



kmeans_euclidean.plot <- fviz_cluster(kmeans.result.euclidean, data = df_no_supervised_scaled, xlab = "Dimension 1",
                                      ylab ="Dimension 2")+ggtitle("K-Means distancia euclidiana", subtitle = "")+
  theme_minimal() 

kmeans_euclidean.plot

#Podemos sacar los ID de cada cluster con el siguiente codigo:

df_clusters <- data.frame(ID = rownames(df_no_supervised_scaled),
                          Cluster = kmeans.result.euclidean$cluster) 

#Añadimos las etiquetas haciendo un join 
#Primero necesito que el ID de cada paciente sea una columna, no el nombre de la fila
ID_labels <- rownames(labels)
df_labels_ID <- cbind(labels, ID = ID_labels)

df_cluster2 <- dplyr::inner_join(df_clusters, df_labels_ID, by = "ID")

#Para ver mejor los grupos graficamos
df_cluster2$Cluster <- as.factor(df_cluster2$Cluster)

kmeans_euclidean.var <- ggplot(df_cluster2, aes(x = type, fill = Cluster))+geom_bar()+
  labs(title = "Clusters Distancia Euclidiana",
       x = "Enfermedad", y = "Pacientes")
kmeans_euclidean.var


#Distancia Manhattan

pam.result_manhattan <- pam(df_no_supervised_scaled, k = 2, metric = "manhattan")

kmeans_manhattan.plot <- fviz_cluster(pam.result_manhattan, data = df_no_supervised_scaled, xlab = "Dimension 1",
                                      ylab ="Dimension 2")+ggtitle("K-means distancia Manhattan", subtitle = "")+
  theme_minimal()

kmeans_manhattan.plot

#Pasamos tambien a df y a un grafico
df_cluster_manhattan <- data.frame(ID = rownames(df_no_supervised_scaled),
                                   cluster = pam.result_manhattan$clustering)


df_cluster_manhattan2 <- dplyr::inner_join(df_cluster_manhattan, df_labels_ID, by = "ID")

df_cluster_manhattan2$cluster <- as.factor(df_cluster_manhattan2$cluster)

kmeans_manhattan.var <- ggplot(df_cluster_manhattan2, aes(x = type, fill = cluster))+geom_bar()+
  labs(title = "Clusters distancia Manhattan",
       x = "Enfermedad", y = "Pacientes")

kmeans_manhattan.var


grid.arrange(kmeans_euclidean.plot, kmeans_euclidean.var,
             kmeans_manhattan.plot, kmeans_manhattan.var, nrow = 2)


