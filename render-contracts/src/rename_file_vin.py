from ast import Try
from math import e
import pandas as pd
import re, os, camelot
from PyPDF2 import PdfFileReader
from pathlib import Path
import numpy

files = 'C:/Projects/render-contracts/templates/' # Ruta en la cual encotraremos los pagares en pdf
dirFiles = os.listdir(files) # Listamos todos los archivos de la ruta


# Columnas hardcodeadas
columnas = ['no_pago','fecha_corte','saldo_insoluto','int_devengados','renta_gps_por_pagar','seguros_por_pagar','capital_por_pagar','int_costos_respiro','ind_devengados_por_pagar','int_diferidos_por_pagar','monto_pagar']

dfs = []

producto_fin = ""

for fichero in dirFiles: # Por cada archivo hacemos lo siguiente

    ficheropath = os.path.join(files, fichero) # Ruta completa del archivo

    filename = Path(ficheropath).stem


    if os.path.isfile(ficheropath) and (fichero.endswith('.pdf') or fichero.endswith('.PDF')):  # Válidamos que sea PDF

        temp = open(os.path.join(files, fichero), 'rb')
        PDF_read = PdfFileReader(temp)
        first_page = PDF_read.getPage(1)
        text = str(first_page.extractText()) # Extremos el texto del archivo

        index = text.find("Serie:")  # Esta palabra nos da un indicio de donde encontrar el crédito y el cliente

        parts = text.split()

        # print(files, fichero)
        vin = str(text[index: index+30])
        vin = vin.replace('Serie: ', '')
        vin = vin.replace('Color:', '')
        vin = vin.replace('Color','')
        # print(vin)

        temp.close()

        try: 
            name = files + fichero
            new_name = files + vin + '.pdf'
            os.rename(name, new_name)
        except:
            name = files + fichero
            new_name = files + vin + '_.pdf'
            os.rename(name, new_name)

        print(new_name)