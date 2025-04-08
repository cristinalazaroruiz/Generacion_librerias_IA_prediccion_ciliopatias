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

# Ver cada dataframe en una pestaña de RStudio
#for (i in 1:length(df_list)) {  
#  View(df_list[[i]])  
#}

