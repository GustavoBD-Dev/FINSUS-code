from ast import Try
from math import e
import pandas as pd
import re, os, camelot
from PyPDF2 import PdfFileReader
from pathlib import Path
import numpy

files = 'C:/Projects/render-contracts/templates' # Ruta en la cual encotraremos los pagares en pdf
dirFiles = os.listdir(files) # Listamos todos los archivos de la ruta


# Columnas hardcodeadas
columnas = ['no_pago','fecha_corte','saldo_insoluto','int_devengados','renta_gps_por_pagar','seguros_por_pagar','capital_por_pagar','int_costos_respiro','ind_devengados_por_pagar','int_diferidos_por_pagar','monto_pagar']

dfs = []

producto_fin = ""

for fichero in dirFiles: # Por cada archivo hacemos lo siguiente

    ficheropath = os.path.join(files, fichero) # Ruta completa del archivo

    filename = Path(ficheropath).stem


    if os.path.isfile(ficheropath) and (fichero.endswith('.pdf') or fichero.endswith('.PDF')):  # Válidamos que sea PDF
        print(filename)

        temp = open(os.path.join(files, fichero), 'rb')
        PDF_read = PdfFileReader(temp)
        first_page = PDF_read.getPage(0)
        text = str(first_page.extractText()) # Extremos el texto del archivo

        index = text.find("PRINCEPS SAPI DE C.V.")  # Esta palabra nos da un indicio de donde encontrar el crédito y el cliente

        if(index < 0):
            index = text.find("POSIBILIDADES  VERDES  S.A")

        cc = text[index-30:index]

        index = cc.find("-")
        cc = cc[index-1:-1]

        index = cc.rfind("-")
        index = cc.rfind("-", 0, index)
        credito = cc[index-1:len(cc)]
        cliente = cc[0:index-1]
        print(credito + " & " + cliente + " & " + cc)

        tables = camelot.read_pdf(os.path.join(files, fichero)) # Buscamos las tablas en todo el archivo.

        df = tables[0].df # Para los pagares, la tabla de amortización se encuentran en la primer hoja
        df_out = pd.DataFrame(df)        

        column_name = ""
        column_content = []

        count = 0

        for column in df:

            if(count < numpy.size(columnas)):
                for row in df.index: 
                    if(row == 0):
                        column_name = columnas[count] # Para la primer fila solo quitamos los saltos de línea
                    else:
                        column_content = re.split("\\n| ", df[column][row]) # Para las demás filas hay que hacer split en saltos de linea y espacios
                if(column_content and column_content[0] != '') :
                    df_out[column_name] = column_content # Acomodamos la información procesada 

            count += 1
    
        producto_fin = credito.split("-")[1]

        df_out.insert(0, 'producto', producto_fin)
        df_out.insert(0, 'cliente', cliente)
        df_out.insert(0, 'credito', credito)
        # df_out['credito'] = credito
        # df_out['cliente'] = cliente
        # df_out['producto'] = credito.split("-")[1]

    

        dfs.append(df_out)  
        print(df_out)
        df_out.to_csv('C:/Projects/render-contracts/templates/'+credito+" "+filename+".csv", index=False)
        

# join = pd.concat(dfs)
# join.to_csv("C:/Pagares/extract_table_pdf/concentrado/" + producto_fin + "-concentrado_PAGARES_20-09-2022.csv", index=False)