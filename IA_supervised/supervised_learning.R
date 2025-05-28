#librerias
library(readxl)
library(dplyr)
library(caret)
library(randomForest)
library(xgboost)
library(pROC)
library(gridExtra)
library(openxlsx)

#PASO 1: CARGAR LOS DATOS
df <- read_excel("Anexo_6.xlsx")
#eliminamos la columna ...1
df <- df%>%dplyr::select(-...1)

#escalado de variables numericas
df_numeric <- df%>%dplyr::select(-type)
type <- df%>%dplyr::select(type)
df_scaled <- as.data.frame(scale(df_numeric))
any(is.na(df_scaled)) #no hay valores faltantes
any(colSums(df_scaled) == 0) #no hay columnas con todo 0

df_scaled <- cbind(df_scaled, type = type)
#convertir las etiquetas de los datos a factor
df_scaled$type <- as.factor(df_scaled$type)


#PASO 2: SEPARAR EN DATOS DE ENTRENAMIENTO Y PRUEBA

train_index <- createDataPartition(df_scaled$type, p = 0.8, list = FALSE)
df_train <- df_scaled[train_index, ]
df_test = df_scaled[-train_index, ]


################################################################################
#                       SUPPORT VECTOR MACHINE (SVM)
################################################################################

#Vamos a probar con distintos kernels
set.seed(1234)
#KERNEL LINEAL
svmlinear.result <- train(type ~ ., 
                          data = df_train, 
                          method = "svmLinear", 
                          trControl = trainControl(method = "cv", 
                                                   number = 10, 
                                                   ),
                          preProcess = c("center", "scale"),
                          tuneGrid = expand.grid(C = seq(0, 0.5, length.out = 20)),
                          prob.model = TRUE)

#hiperparametro optimo: 0.10 (tras probar varios tuneGrid, la mayor accuracy se obtiene con 0.1)

plot(svmlinear.result)

svmlinear.pred <- predict(svmlinear.result, newdata = df_test)
svmlinear.probs <- predict(svmlinear.result, newdata = df_test, type = "prob")
svmlinear.matrix <- confusionMatrix(svmlinear.pred, df_test$type)

#KERNEL RADIAL

svmradial.result <- train(type ~ ., 
                          data = df_train, 
                          method = "svmRadial", 
                          trControl = trainControl(method = "cv", 
                                                   number = 10, 
                          ),
                          preProcess = c("center", "scale"),
                          tuneLength = 50 ,
                          prob.model = TRUE)



plot(svmradial.result) #se han usado los hiperparametros sigma = 0.05400961 and C = 2

svmradial.pred <- predict(svmradial.result, newdata = df_test)
svmradial.probs <- predict(svmradial.result, newdata = df_test, type = "prob")
svmradial.matrix <- confusionMatrix(svmradial.pred, df_test$type)



################################################################################
#                       RANDOM FOREST
################################################################################

rf.result <- train(type ~ ., 
                   data = df_train, 
                   method = "rf", 
                   trControl = trainControl(method = "cv", 
                                            number = 10, 
                   ),
                   tuneGrid = expand.grid(mtry = seq(5:30)))

plot(rf.result) #mtry = 5


#podemos ver la importancia de las variables
imp <- varImp(rf.result)
df_imp <- as.data.frame(imp$importance)
write.xlsx(df_imp, "importancia_var_rf.xlsx", rowNames = TRUE)
#forma grafica
varImpPlot(rf.result$finalModel)

rf.pred <- predict(rf.result, newdata = df_test)
rf.probs <- predict(rf.result, newdata = df_test, type = "prob")
rf.matrix <- confusionMatrix(rf.pred, df_test$type)



################################################################################
#                       GRADIENT BOOSTING MACHINES
################################################################################

gb.result <-  train(type ~ ., 
                    data = df_train, 
                    method = "gbm", 
                    trControl = trainControl(method = "cv", 
                                             number = 10, 
                    ),
                    tuneLength =30)

plot(gb.result) #n.trees = 100, interaction.depth = 18, shrinkage = 0.1 and n.minobsinnode = 10

gb.pred <- predict(gb.result, newdata = df_test)
gb.probs <- predict(gb.result, newdata = df_test, type = "prob")
gb.matrix <- confusionMatrix(gb.pred, df_test$type)

################################################################################
#                       CURVAS ROC
################################################################################

roc_svmlinear = roc(df_test$type, svmlinear.probs[ ,"ciliopathy"],
                    levels = c("No ciliopathy", "ciliopathy"),
                    direction = "<")
auc_svmlinear <- auc(roc_svmlinear)


roc_svmradial = roc(df_test$type, svmradial.probs[ ,"ciliopathy"],
                    levels = c("No ciliopathy", "ciliopathy"),
                    direction = "<")
auc_svmradial <- auc(roc_svmradial)


roc_rf <- roc(df_test$type, rf.probs[ ,"ciliopathy"],
              levels = c("No ciliopathy", "ciliopathy"),
              direction = "<")
auc_rf <- auc(roc_rf)


roc_gb <- roc(df_test$type, gb.probs[ ,"ciliopathy"],
              levels = c("No ciliopathy", "ciliopathy"),
              direction = "<")
auc_gb <- auc(roc_gb)


#Combinamos en un solo panel todas las graficas
plot(roc_svmlinear, col = "blue", main = "Curvas ROC", lwd = 2,
     xlab = "1- Especificidad", ylab = "Sensibilidad")
plot(roc_svmradial, col = "red", add = TRUE, lwd = 2)
plot(roc_rf, col = "green", add = TRUE, lwd = 2)
plot(roc_gb, col = "purple", add = TRUE, lwd = 2)

svmlinear_legend = paste("AUC SVM LINEAL: ", round(auc_svmlinear, 2))
svmradial_legend = paste("AUC SVM RADIAL: ", round(auc_svmradial, 2))
rf_legend = paste("AUC BOSQUE ALEATORIO: ", round(auc_rf, 2))
gb_legend = paste("AUC POTENCIACIÓN GRADIENTE: ", round(auc_gb, 2))
legend("bottomright", legend = c(svmlinear_legend, svmradial_legend, rf_legend,
                                 gb_legend), col = c("blue", "red", "green",
                                                     "purple"), lwd = 2)


#Tabla con parametros sacados de las matrices de confusion
matrices_confusion = list(svmlinear.matrix, svmradial.matrix,
                          rf.matrix, gb.matrix)


#en la tabla vamos a poner la precision (overall), sensibilidad, especifidad
#y valor predictivo positivo (byClass)

matrices_dataframe <- data.frame(Precision =rep("NA", times = 4), 
                                 Sensibilidad =rep("NA", times = 4),
                                      Especificidad = rep("NA", times = 4),
                                          Valor.Predictivo.Positivo = rep("NA", times = 4),
                                              Tasa.Error =rep("NA", times = 4) )


rownames(matrices_dataframe) <- c("SVM Lineal", "SVM Radial", "Bosque Aleatorio",
                                  "Potenciación Gradiente")

matrices_dataframe$Precision = c (round(svmlinear.matrix$byClass[5],2),  
  round(svmradial.matrix$byClass[5],2), round(rf.matrix$byClass[5],2),
  round(gb.matrix$byClass[5],2))



matrices_dataframe$Sensibilidad = c (round(svmlinear.matrix$byClass[1],2),  
                                  round(svmradial.matrix$byClass[1],2), round(rf.matrix$byClass[1],2),
                                  round(gb.matrix$byClass[1],2))




matrices_dataframe$Especificidad = c (round(svmlinear.matrix$byClass[2],2),  
                                  round(svmradial.matrix$byClass[2],2), round(rf.matrix$byClass[2],2),
                                  round(gb.matrix$byClass[2],2))



matrices_dataframe$Valor.Predictivo.Positivo = c (round(svmlinear.matrix$byClass[3],2),  
                                  round(svmradial.matrix$byClass[3],2), round(rf.matrix$byClass[3],2),
                                  round(gb.matrix$byClass[3],2))



#Tasa de error: 1-Accuracy 

error_rate_svm_lineal = 1- round(svmlinear.matrix$byClass[5],2)
error_rate_svm_radial = 1- round(svmradial.matrix$byClass[5],2)
error_rate_rf = 1- round(rf.matrix$byClass[5],2)
error_gb = 1- round(gb.matrix$byClass[5],2)


matrices_dataframe$Tasa.Error = c(error_rate_svm_lineal,
                                  error_rate_svm_radial,
                                  error_rate_rf,
                                  error_gb)


#guardamos como excel
write.xlsx(matrices_dataframe, file = "Anexo 7.xlsx", rowNames = TRUE)


df.confusion.svmlinear <- as.data.frame(svmlinear.matrix$table)
df.confusion.svmradial <- as.data.frame(svmradial.matrix$table)
df.confusion.rf <- as.data.frame(rf.matrix$table)
df.confusion.gb <- as.data.frame(gb.matrix$table)

write.xlsx(df.confusion.svmlinear, file = "matriz_svmlinear.xlsx")
write.xlsx(df.confusion.svmradial, file = "matriz_svmradial.xlsx")
write.xlsx(df.confusion.rf, file = "matriz_rf.xlsx")
write.xlsx(df.confusion.gb, file = "matriz_gb.xlsx")





