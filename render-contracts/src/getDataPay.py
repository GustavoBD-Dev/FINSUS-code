"""
    Obtienen los datos del pagare dentro de una carpeta y se guardan en una archivo CSV
    - monto a pagar
    - monto final
    - ultima fecha de pago
    - No. total de pagos
    - No. de credito
    - Nombre
"""


# los datos se encuentran en la tabla por lo que debemos obtener la tabla del archivo
# analizando la tabla, los datos se encuentran en las siguientes posiciones
#    - monto a pagar (primer fila de la columna MONTO A PAGAR)
#    - monto final (ultim fila de la columna MONTO A PAGAR)
#    - ultima fecha de pago (ultima fila de la columna FECHA DE PAGO)
#    - No. total de pagos (ultima fila de la columna No DE PAGO)

from tokenize import Double
import pandas as pd
import numpy as np
import re, os, camelot
from PyPDF2 import PdfFileReader
from pathlib import Path
import numpy

files = "C:/Users/FINSUS-Admin/Documents/FINSUS/PAGARES/" # route to find files PDF
dirFiles = os.listdir(files) # list files in route

DATA_FILES_PDF =  []    # list to save data in files PDF

# name of columns to get data 
columnas = ['NO CREDITO','NO CLIENTE','TOTAL PAGOS','MONTO A PAGAR','BULLET','FECHA FINAL','NOMBRE','MONTO_TABLA','MONTO_LETRA','VALIDACION DE MONTOS','FECHA_PAGARE','ACCESORIOS', 'ACCESORIOS_TOTAL']
DATA_FILES_PDF.append(columnas)

# name of variables to get  
MONTO_A_PAGAR = None
MONTO_TOTAL = None
FECHA_FINAL = None
TOTAL_PAGOS = None
NO_CREDITO = None
NOMBRE = None

# data frame
dfs = []

producto_fin = ""

for fichero in dirFiles: # each file to do

    ficheropath = os.path.join(files, fichero) # complete route of file
    filename = Path(ficheropath).stem

    if os.path.isfile(ficheropath) and (fichero.endswith('.pdf') or fichero.endswith('.PDF')):  # validate PDF

        temp = open(os.path.join(files, fichero), 'rb')
        PDF_read = PdfFileReader(temp)
        first_page = PDF_read.getPage(0)
        text = str(first_page.extractText()) # get text of file

        index = text.find("FINANCIERA SUSTENTABLE DE")  # reference to find credit 
        # index = text.find("PRINCEPS SAPI DE C.V.")  # reference to find credit

        parts = text.split()
        #for i in range(len(parts)):
        #    print(i, ' - ', parts[i])

        # find name of document, betwen the words continuacion y "suscriptor"
        start_name = text.find('Suscriptor')
        end_name = text.find('Obligado')
        NOMBRE = text[start_name+10: end_name-3]    

        # find the amount
        start_amount = text.find('$')
        end_amount = text.find('M.N.)"Beneficiario"')
        AMOUNT = text[start_amount+1: end_amount+5]   
        #print(AMOUNT) 
        
        #start_nmonths = text.find("0.00%")
        #NUMBER_OF_MONTHS_TEXT = text[start_nmonths+5:start_nmonths+8]
        #print(NUMBER_OF_MONTHS_TEXT)

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

        tables = camelot.read_pdf(os.path.join(files, fichero)) # find tables in PDF

        df = tables[0].df # in the pays, the tables is in first page
        df_out = pd.DataFrame(df)  
        # print(df_out)

        # get index of latest element, this is the latest row 
        END_DATA = 0
        ACCESORIOS = 0
        for i in range(len(df_out)):
            #print(df_out[1][i])
            if df_out[1][i].strip() == '':
                END_DATA = i
                #print(i)
                break
            
            ACCESORIOS = float(str(df_out[6][1]).replace(',','')) + float(str(df_out[7][1]).replace(',',''))

        # the date latest is in latest row
        FECHA_FINAL = df_out[1][END_DATA - 1]

        # total of elements
        TOTAL_PAGOS = END_DATA - 1

        # amount to pay monthly
        MONTO_A_PAGAR = df_out[9][1]

        # amount total - bullet
        MONTO_TOTAL = df_out[9][END_DATA - 1]

        # first amount of table
        AMOUNT_TABLE = df_out[2][1]
        AMOUNT_TABLE = float(str(AMOUNT_TABLE).replace(',',''))

        # number of credit and name
        NO_CREDITO = credito 

        # numer of client
        NO_CLIENT = cliente

        PDF_read = PdfFileReader(temp)
        second_page = PDF_read.getPage(1)
        textDate = str(second_page.extractText()) # get text of file
        parts = textDate.split()

        DATE_PAY = 'Febrero' if 'Febrero' in parts else 'Fecha Diferente'

        VALIDATE_AMOUNTS = 'Correcto' if float(str(AMOUNT.split('(')[0]).replace(' ','')) == AMOUNT_TABLE else 'Incorrecto'
        
        #VALIDATE_MONTHS = 'Correcto' if  int(NUMBER_OF_MONTHS_TEXT.replace(' ','')) == TOTAL_PAGOS else 'Incorrecto'

        ACCESORIOS_TOTAL = ACCESORIOS * TOTAL_PAGOS

        data_in_file = [NO_CREDITO, NO_CLIENT.replace('\n',''), TOTAL_PAGOS, str(MONTO_A_PAGAR).replace(',',''), str(MONTO_TOTAL).replace(',',''), FECHA_FINAL, NOMBRE.replace('\n',''), AMOUNT_TABLE,AMOUNT, VALIDATE_AMOUNTS,DATE_PAY, ACCESORIOS, ACCESORIOS_TOTAL]
        print(data_in_file)
        DATA_FILES_PDF.append(data_in_file)

# save data in file CSV
np.savetxt("C:/Users/FINSUS-Admin/Documents/FINSUS/PAGARES/DataPDF.csv", DATA_FILES_PDF, delimiter =",",fmt ='% s')

