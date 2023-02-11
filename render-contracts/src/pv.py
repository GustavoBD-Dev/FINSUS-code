from multiprocessing import context
from tokenize import Double
import pandas as pd
import re, os, camelot
from PyPDF2 import PdfFileReader
from pathlib import Path
import os
from docxtpl import DocxTemplate
import numpy as np
from csv import reader
# import numbers_to_letter
from MyDataBase import MyDataBase

# Create connection to data base
openfin_s = 'user=iflores_c password=Flores.36 host=172.17.100.14 port=5432 dbname=openfin_b'
db =  MyDataBase(openfin_s)

def number_text(number):
    from nlt import numlet as nl
    number_text = '{:,.2f}'.format(number)
    return "$ {} ({} PESOS {}/100 M.N.)".format(
                number_text,
                # numbers_to_letter.numero_a_letras(int(float(str(number_text).replace(',','')))).upper(),
                nl.Numero(int(number)).a_letras.upper(),
                str(number_text).split('.')[1])

# execute query
def execute_query(query_exec):
    # print(query_exec)
    try:
        # Execute query
        db.query(query_exec)
        # Set value to row var
        row = db.cur.fetchone()
        if not row:
            return False
        else:
            return row
    except:
        return False


def getDataPay(fileDirIn, fileDirOut, dateGenerate):
    DATA_FILES_PDF = []
    # columns = ['CREDITO','NOMBRE','FECHA PAGARE','COMENTARIO']
    # DATA_FILES_PDF.append(columns)

    # directory of template file Word
    convenioPV = DocxTemplate("C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/layouts/CONVENIO MODIFICATORIO_ARRENDAMIENTO PV_SUBSISTE SEGURO DE VIDA.docx") 

    files = fileDirIn # route to find files PDF
    dirFiles = os.listdir(files) # list files in route

    # name of columns to get data 
    meses = ['','Enero', 'Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre']


    for fichero in dirFiles: # each file to do

        data_in_file = []

        ficheropath = os.path.join(files, fichero) # complete route of file

        if os.path.isfile(ficheropath) and (fichero.endswith('.pdf') or fichero.endswith('.PDF')):  # validate PDF

            temp = open(os.path.join(files, fichero), 'rb')
            PDF_read = PdfFileReader(temp)
            first_page = PDF_read.getPage(0)
            text = str(first_page.extractText()) # get text of file

            index = text.find("FINANCIERA SUSTENTABLE DE")  # reference to find credit 

            parts = text.split()
            # for i in range(len(parts)):
            #     print(i, ' - ', parts[i])

            # fin the numer of client
            start_nclient = text.find('M.N.)')
            # end_nclient = text.find('1-6')
            end_nclient = text.find('"POSIBILIDADES  VERDES  S.A"')
            N_CLIENT = text[start_nclient+5 : end_nclient-50]
            N_CLIENT = str(N_CLIENT).split(' ')[0]
            data_in_file.append(N_CLIENT)

            # find name of document, betwen the words continuacion y "suscriptor"
            start_name = text.find('continuación:')
            end_name = text.find('"Suscriptor"')
            NOMBRE = text[start_name+13: end_name] 
            NOMBRE = NOMBRE.strip('\n')
            data_in_file.append(NOMBRE)

            # find amount 
            start_amount = text.find('"Beneficiario"')
            end_amount = text.find('M.N.)')
            #print(">>>>>>>>",start_amount)
            #print(end_amount)
            AMOUNT = text[start_amount+16: end_amount+5] 
            data_in_file.append(AMOUNT)

            # find number of months
            start_months = text.find('durante')
            end_months = text.find('sucesivas')
            MONTHS_TEXT = text[start_months+12: end_months-7] 
            # get number of months in text
            MONTHS_NUMBER = text[start_months+8: start_months+10] 
            data_in_file.append(MONTHS_NUMBER)
            data_in_file.append(MONTHS_TEXT)

            if(index < 0):
                index = text.find("POSIBILIDADES  VERDES  S.A")

            cc = text[index-30:index]

            index = cc.find("-")
            cc = cc[index-1:-1]

            index = cc.rfind("-")
            index = cc.rfind("-", 0, index)
            credito = cc[index-1:len(cc)]
            cliente = cc[0:index-1]
            #print(credito + " & " + cliente + " & " + cc)
            data_in_file.append(credito)

            tables = camelot.read_pdf(os.path.join(files, fichero)) # find tables in PDF

            df = tables[0].df # in the pays, the tables is in first page
            df_out = pd.DataFrame(df)  

            # get number of pay
            pay =  re.split("\\n| ", df_out[0][1])

            # get date of pay
            dates = re.split("\\n| ", df_out[1][1])

            # get month pay
            months =  re.split("\\n| ", df_out[2][1])

            # generate table with the list 
            table_data = []
            table_data.append(pay)
            table_data.append(dates)
            table_data.append(months)

            partial_income_table = []

            var = 0
            # build the data matrix, list of lists
            for i in range(len(table_data[0])):
                    aux = []
                    aux.append(table_data[0][i])
                    aux.append(table_data[1][i])
                    aux.append(table_data[2][i])
                    partial_income_table.append(aux)
                    var += float(str(table_data[2][i]).replace(",",""))
            #print((AMOUNT.split('(')[0]).replace(' ',''))
            amount_split = float((AMOUNT.split('(')[0]).replace(' ',''))

            dataValues = [] # list of dictionaries 
            
            # iterate the matrix of values
            for row in partial_income_table:
                aux_dic = {}                # crate the dictionary
                aux_dic['cols'] = row       # add value 'list' with the key 
                dataValues.append(aux_dic)  # add dictionary in the list

            # # get data 'ANTECEDENTES'
            # print(N_CLIENT, ' - ', credito)
            idsucursal, idrol, idasociado = str(N_CLIENT).split('-')
            idsucaux, idproducto, idauxiliar = str(credito).split('-')
            query_antec = """
                SELECT  idsucauxantec || '-' || idproductoantec || '-' || idauxiliarantec AS creditoantec,
                        to_char(fechaantec, 'DD/MM/YYYY')
                  FROM  linea_pv
                 WHERE  (linea_pv.idsucsux,linea_pv.idproducto,linea_pv.idauxiliar)=({},{},{});
            """.format(idsucaux, idproducto, idauxiliar)
            
            query_reference = """
                SELECT 
                        '69'|+of_rellena(kauxiliar::TEXT,7,'0',2)||of_dv_gen('69'|+of_rellena(kauxiliar::TEXT,7,'0',2))
                  FROM  deudores d 
                 WHERE  (idsucaux,idproducto,idauxiliar) = ({},{},{});
            """.format(idsucaux,idproducto, idauxiliar)

            query_vin ="""
                SELECT  vin
                  FROM  linea_pv
                 WHERE  (linea_pv.idsucsux,linea_pv.idproducto,linea_pv.idauxiliar)=({},{},{});
            """.format(idsucaux, idproducto, idauxiliar)
            
            data_in_query = execute_query(query_antec)
            data_in_query_ref = execute_query(query_reference)
            data_inquery_vin = execute_query(query_vin)
            print(data_inquery_vin)
            
            if data_in_query and data_in_query_ref:
                print(data_in_query, ' ' , data_in_query_ref)

                date_antec = str(data_in_query[1]).split('/')
                # build context with data of the PDF
                context = {
                    'nombre' : NOMBRE,
                    'monto'  : '$ {}'.format(AMOUNT),
                    'plazo_texto'  : MONTHS_TEXT,
                    'plazo_numero'  : MONTHS_NUMBER,
                    'fecha'  : dateGenerate,
                    'tbl_data' : dataValues,
                    'fecha_antecedentes': date_antec[0]+ ' de '+ meses[int(date_antec[1])]+' de '+date_antec[2],# data_in_query[1],
                    'no_arrendamiento': data_in_query[0],
                    'credit' : credito,
                    'referencia_bancaria': data_in_query_ref[0],
                    'vin' : data_inquery_vin[0]
                }

                # add letter condonation
                # if bullet is more amounth, bullet less amounth
                # bullet is the latest row in table
                BULLET = float(str(dataValues[-1]['cols'][-1]).replace(",",""))
                MONTHLY_PAYMENT = float(str(months[0]).replace(",",""))
                #print(BULLET)
                data_in_file.append(BULLET)
                data_in_file.append(MONTHLY_PAYMENT)
                #print(MONTHLY_PAYMENT)
                CONDONATION  = 0
                if BULLET > MONTHLY_PAYMENT:
                    CONDONATION = BULLET - MONTHLY_PAYMENT
                    # generate letter condonation
                    context['letter'] = True
                    # context['condonation_number'] = '{:,.2f}'.format(CONDONATION)
                    # context['condonation_string'] = "({} PESOS {}/100 M.N.)".format(
                    #     numbers_to_letter.numero_a_letras(int(CONDONATION)), 
                    #     (str(CONDONATION).split('.')[1]).zfill(2))
                    # context['amount_number'] = '{:,.2f}'.format(amount_split)
                    context['condonation_amount'] = number_text(CONDONATION)

                    context['amount_month'] = number_text(MONTHLY_PAYMENT)

                    # context['amount_string'] = "({} PESOS {}/100 M.N.)".format(
                    #     numbers_to_letter.numero_a_letras(amount_split),
                    #     (str(amount_split).split('.')[1]).zfill(2))
                    # context['monthly_payment_number'] = '{:,.2f}'.format(MONTHLY_PAYMENT)
                    # context['monthly_payment_string'] = "({} PESOS {}/100 M.N.)".format(
                    #     numbers_to_letter.numero_a_letras(int(MONTHLY_PAYMENT)),
                    #     (str(MONTHLY_PAYMENT).split('.')[1]).zfill(2))
                    
                PDF_read = PdfFileReader(temp)
                second_page = PDF_read.getPage(1)
                textDate = str(second_page.extractText()) # get text of file
                parts = textDate.split()
                DATE_PAY = 'Febrero' if 'Febrero' in parts else 'Error en fecha'
                data_in_file.append(DATE_PAY)
                
                # generate the files Word with the data file PDF (table and other variables)
                # print(f'{NOMBRE}  {credito}  {months[0]}')
                fileDir = fileDirOut
                try:
                    os.stat(fileDir)
                except:
                    os.mkdir(fileDir)
                convenioPV.render(context)
                convenioPV.save(fileDir+"/PV_"+str(NOMBRE).strip()+"_"+str(credito)+"_"+str(cliente).strip()+"_"+str(int(str(table_data[2][0]).replace(',','').split('.')[0]))+".docx")
                print("PV_"+str(NOMBRE).strip()+"_"+str(credito)+"_"+str(cliente).strip()+"_"+str(int(str(table_data[2][0]).replace(',','').split('.')[0]))+".docx")

            else:
                print('No hay datos de antecedentes')
                print(query_antec)
                print(query_reference)
        DATA_FILES_PDF.append(data_in_file)    
        # print(data_in_file)
    # np.savetxt("C:\\GeneracionContratos\\outputs\\DataPDF_PV_17500_wertyui.csv", DATA_FILES_PDF, delimiter =",",fmt ='% s')       


if __name__ == '__main__' :
    # fileDirOut = 'C:/Users/Gustavo Blas/OneDrive - Financera Sustentable de México SA de CV SFP/SHARE/2023/PV/Contratos/17500'
    fileDirOut = "C:/Users/FINSUS-Admin/Documents/FINSUS/CONTRATOS"
    fileDirIn = 'C:/Users/FINSUS-Admin/Documents/FINSUS/PAGAREPV/'
    dateGenerate = '01 de febrero de 2023'
    getDataPay(fileDirIn, fileDirOut, dateGenerate)