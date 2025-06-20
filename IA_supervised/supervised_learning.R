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



################################################################################
#                       CURVAS DE APRENDIZAJE
################################################################################

#curva de aprendizaje para SVMlinear
curvas_error = list()
curvas_precision = list()

set.seed(1234)

# Definir tamaños de entrenamiento
training_sizes <- seq(0.1, 1.0, by = 0.1)  # 10% a 100%

# Vectores para guardar errores y precision
train_errors_svmlinear <- c()
val_errors_svmlinear <- c()
train_accuracy_svmlinear <- c()
val_accuracy_svmlinear <- c()

for (p in training_sizes) {
  # Muestra aleatoria del conjunto de entrenamiento
  indices <- sample(1:nrow(df_train), size = floor(p * nrow(df_train)))
  train_subset <- df_train[indices, ]
  
  # Ajustar modelo con el subconjunto de entrenamiento
  model <- train(type ~ ., 
                 data = train_subset, 
                 method = "svmLinear", 
                 trControl = trainControl(method = "cv", number = 10), 
                 preProcess = c("center", "scale"),
                 tuneGrid = expand.grid(C = 0.1)) 
  
  # Error y precision de entrenamiento
  train_pred <- predict(model, newdata = train_subset)
  train_acc <- mean(train_pred == train_subset$type)
  train_errors_svmlinear <- c(train_errors_svmlinear, 1 - train_acc)
  train_accuracy_svmlinear <- c(train_accuracy_svmlinear, train_acc)
  
  
  # Error de validación (en el conjunto de prueba completo)
  val_pred <- predict(model, newdata = df_test)
  val_acc <- mean(val_pred == df_test$type)
  val_errors_svmlinear <- c(val_errors_svmlinear, 1 - val_acc)
  val_accuracy_svmlinear <- c(val_accuracy_svmlinear, val_acc)
}

# DataFrame para graficar la curva de error
df_curve_error_svmlineal <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingError = train_errors_svmlinear,
  ValidationError = val_errors_svmlinear
)

# Graficar la curva de error 
curva_error_svmlineal <- ggplot(df_curve_error_svmlineal, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingError, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationError, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Error de clasificación",
       color = "Conjunto") + ggtitle("Curva de pérdida - SVM Lineal")+
  theme_minimal()


#Dataframe curva de precision
df_accuracy_svmlinear <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingAccuracy = train_accuracy_svmlinear,
  ValidationAccuracy = val_accuracy_svmlinear
)


#curva de precision
curva_precision_svmlineal <- ggplot(df_accuracy_svmlinear, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingAccuracy, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationAccuracy, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Precisión",
       color = "Conjunto") +ggtitle("Curva de precision - SVM Lineal")+
  theme_minimal()


#añadimos las cruvas a las listas
curvas_error <- c(curvas_error, list(svmlineal = curva_error_svmlineal))
curvas_precision <- c(curvas_precision, list(svmlineal = curva_precision_svmlineal))

#curva de aprendizaje para SVMradial

# Vectores para guardar errores y precision
train_errors_svmradial <- c()
val_errors_svmradial <- c()
train_accuracy_svmradial <- c()
val_accuracy_svmradial <- c()

for (p in training_sizes) {
  # Muestra aleatoria del conjunto de entrenamiento
  indices <- sample(1:nrow(df_train), size = floor(p * nrow(df_train)))
  train_subset <- df_train[indices, ]
  
  # Ajustar modelo con el subconjunto de entrenamiento
  model <- train(type ~ ., 
                 data = train_subset, 
                 method = "svmRadial", 
                 trControl = trainControl(method = "cv", number = 10), 
                 preProcess = c("center", "scale"),
                 tuneGrid = expand.grid(C = 2,sigma = 0.05400961))  
  
  # Error y precision de entrenamiento
  train_pred <- predict(model, newdata = train_subset)
  train_acc <- mean(train_pred == train_subset$type)
  train_errors_svmradial <- c(train_errors_svmradial, 1 - train_acc)
  train_accuracy_svmradial <- c(train_accuracy_svmradial, train_acc)
  
  
  # Error de validación (en el conjunto de prueba completo)
  val_pred <- predict(model, newdata = df_test)
  val_acc <- mean(val_pred == df_test$type)
  val_errors_svmradial <- c(val_errors_svmradial, 1 - val_acc)
  val_accuracy_svmradial <- c(val_accuracy_svmradial, val_acc)
}

# DataFrame para graficar la curva de error
df_curve_error_svmradial <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingError = train_errors_svmradial,
  ValidationError = val_errors_svmradial
)

# Graficar la curva de error 
curva_error_svmradial <- ggplot(df_curve_error_svmradial, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingError, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationError, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Error de clasificación",
       color = "Conjunto") + ggtitle("Curva de pérdida - SVM Radial")+
  theme_minimal()


#Dataframe curva de precision
df_accuracy_svmradial <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingAccuracy = train_accuracy_svmradial,
  ValidationAccuracy = val_accuracy_svmradial
)


#curva de precision
curva_precision_svmradial <- ggplot(df_accuracy_svmradial, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingAccuracy, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationAccuracy, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Precisión",
       color = "Conjunto") +ggtitle("Curva de precision - SVM Radial")+
  theme_minimal()


#añadimos las cruvas a las listas
curvas_error <- c(curvas_error, list(svmradial = curva_error_svmradial))
curvas_precision <- c(curvas_precision, list(svmradial = curva_precision_svmradial))


#curva de aprendizaje para RandonForest

# Vectores para guardar errores y precision
train_errors_rf <- c()
val_errors_rf <- c()
train_accuracy_rf <- c()
val_accuracy_rf <- c()

for (p in training_sizes) {
  # Muestra aleatoria del conjunto de entrenamiento
  indices <- sample(1:nrow(df_train), size = floor(p * nrow(df_train)))
  train_subset <- df_train[indices, ]
  
  # Ajustar modelo con el subconjunto de entrenamiento
  model <- train(type ~ ., 
                 data = train_subset, 
                 method = "rf", 
                 trControl = trainControl(method = "cv", number = 10), 
                 preProcess = c("center", "scale"),
                 tuneGrid = expand.grid(mtry = 5))  
  
  # Error y precision de entrenamiento
  train_pred <- predict(model, newdata = train_subset)
  train_acc <- mean(train_pred == train_subset$type)
  train_errors_rf <- c(train_errors_rf, 1 - train_acc)
  train_accuracy_rf <- c(train_accuracy_rf, train_acc)
  
  
  # Error de validación (en el conjunto de prueba completo)
  val_pred <- predict(model, newdata = df_test)
  val_acc <- mean(val_pred == df_test$type)
  val_errors_rf <- c(val_errors_rf, 1 - val_acc)
  val_accuracy_rf <- c(val_accuracy_rf, val_acc)
}

# DataFrame para graficar la curva de error
df_curve_error_rf <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingError = train_errors_rf,
  ValidationError = val_errors_rf
)

# Graficar la curva de error 
curva_error_rf <- ggplot(df_curve_error_rf, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingError, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationError, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Error de clasificación",
       color = "Conjunto") + ggtitle("Curva de pérdida - Bosque Aleatorio")+
  theme_minimal()


#Dataframe curva de precision
df_accuracy_rf <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingAccuracy = train_accuracy_rf,
  ValidationAccuracy = val_accuracy_rf
)


#curva de precision
curva_precision_rf <- ggplot(df_accuracy_rf, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingAccuracy, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationAccuracy, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Precisión",
       color = "Conjunto") +ggtitle("Curva de precision - Bosque Aleatorio")+
  theme_minimal()


#añadimos las cruvas a las listas
curvas_error <- c(curvas_error, list(rf = curva_error_rf))
curvas_precision <- c(curvas_precision, list(rf = curva_precision_rf))




#curva de aprendizaje para xgboost

# Vectores para guardar errores y precision
train_errors_gb <- c()
val_errors_gb <- c()
train_accuracy_gb <- c()
val_accuracy_gb <- c()

for (p in training_sizes) {
  # Muestra aleatoria del conjunto de entrenamiento
  indices <- sample(1:nrow(df_train), size = floor(p * nrow(df_train)))
  train_subset <- df_train[indices, ]
  
  # Ajustar modelo con el subconjunto de entrenamiento
  model <- train(type ~ ., 
                 data = train_subset, 
                 method = "gbm", 
                 trControl = trainControl(method = "cv", number = 10), 
                 preProcess = c("center", "scale"),
                 tuneGrid = expand.grid(n.trees = 100,
                                        interaction.depth = 18,
                                        shrinkage = 0.1,
                                        n.minobsinnode = 10))  
  
  # Error y precision de entrenamiento
  train_pred <- predict(model, newdata = train_subset)
  train_acc <- mean(train_pred == train_subset$type)
  train_errors_gb <- c(train_errors_gb, 1 - train_acc)
  train_accuracy_gb <- c(train_accuracy_gb, train_acc)
  
  
  # Error de validación (en el conjunto de prueba completo)
  val_pred <- predict(model, newdata = df_test)
  val_acc <- mean(val_pred == df_test$type)
  val_errors_gb <- c(val_errors_gb, 1 - val_acc)
  val_accuracy_gb <- c(val_accuracy_gb, val_acc)
}

# DataFrame para graficar la curva de error
df_curve_error_gb <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingError = train_errors_gb,
  ValidationError = val_errors_gb
)

# Graficar la curva de error 
curva_error_gb <- ggplot(df_curve_error_gb, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingError, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationError, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Error de clasificación",
       color = "Conjunto") + ggtitle("Curva de pérdida - Descenso de Gradiente")+
  theme_minimal()


#Dataframe curva de precision
df_accuracy_gb <- data.frame(
  TrainingSize = training_sizes * 100,
  TrainingAccuracy = train_accuracy_gb,
  ValidationAccuracy = val_accuracy_gb
)


#curva de precision
curva_precision_gb <- ggplot(df_accuracy_gb, aes(x = TrainingSize)) +
  geom_line(aes(y = TrainingAccuracy, color = "Entrenamiento")) +
  geom_line(aes(y = ValidationAccuracy, color = "Validación")) +
  labs(x = "Tamaño de conjunto de entrenamiento (%)",
       y = "Precisión",
       color = "Conjunto") +ggtitle("Curva de precision - Descenso de Gradiente")+
  theme_minimal()


#añadimos las cruvas a las listas
curvas_error <- c(curvas_error, list(gb = curva_error_gb))
curvas_precision <- c(curvas_precision, list(gb = curva_precision_gb))

grid.arrange(grobs = curvas_error, ncol = 2)
grid.arrange(grobs = curvas_precision, ncol = 2)


