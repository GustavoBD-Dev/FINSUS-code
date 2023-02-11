import pandas as pd
import numpy as np
import re, os, camelot
from PyPDF2 import PdfFileReader
from pathlib import Path
import numpy
from docxtpl import DocxTemplate

def getDateText(date_format_num):
    months = [
        '',
        'Enero', 
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre']
    date_credit_num = date_format_num.split('/')
    # print(date_credit_num)
    return date_credit_num[0] + ' de ' + months[int(str(date_credit_num[1]))] + ' de ' + date_credit_num[2]

def number_text(number):
    from nlt import numlet as nl
    number_text = '{:,.2f}'.format(number)
    return "$ {} ({} PESOS {}/100 M.N.)".format(
                number_text,
                # numbers_to_letter.numero_a_letras(int(float(str(number_text).replace(',','')))).upper(),
                nl.Numero(int(number)).a_letras.upper(),
                str(number_text).split('.')[1])


def generateContract(dir_csv, inputs_files, ouput_files, date_generate):

    datacsv = pd.read_csv(dir_csv,encoding = 'utf-8')

    files = inputs_files # route to find files PDF
    dirFiles = os.listdir(files) # list files in route

    CREDIT = None
    CLIENT_NAME = None
    CLIENT_RFC = None
    ANTEC_DATE = None
    ANTEC_CREDIT = None
    ANTEC_AMOUNT = None
    ENGINE = None
    SERIE = None
    BRAND = None
    MODEL = None
    COLOUR = None
    AMOUNT_OWED = None
    REFERENCE = None
    ADDRESS = None
    N_END_PAY = None
    END_DATE_PAY = None
    BULLET = None
    LETTER_COND = False
    AMOUNT_MONTH = None
    DATE = date_generate ######################3
    NUMBER_CLIENT = None ###########
    TYPE_LAYOUT = None

    # data frame
    dfs = []
    for fichero in dirFiles: # each file to do

        print(fichero)

        ficheropath = os.path.join(files, fichero) # complete route of file
        filename = Path(ficheropath).stem

        if os.path.isfile(ficheropath) and (fichero.endswith('.pdf') or fichero.endswith('.PDF')):  # validate PDF

            temp = open(os.path.join(files, fichero), 'rb')
            PDF_read = PdfFileReader(temp)
            first_page = PDF_read.getPage(0)
            text = str(first_page.extractText()) # get text of file

            parts = text.split()
            # for i in range(len(parts)):
            #     print(i, ' - ', parts[i])

            # Find number of credit in document
            start_credit = text.find('1-7200')
            CREDIT = text[start_credit:start_credit+11]
            # print(CREDIT)

            # Search name of cliente with number of credit
            for i in datacsv.index:
                if str(CREDIT).strip() == datacsv['CREDITO'][i]:
                    CLIENT_NAME = str(datacsv['NOMBRE'][i]).strip()
                    AMOUNT_OWED = str(datacsv['ADEUDO'][i]).strip()
                    CLIENT_RFC = str(datacsv['RFC'][i]).strip()
                    NUMBER_CLIENT = str(datacsv['CLIENTE'][i]).strip()
                    ANTEC_CREDIT = datacsv['CTO_ANT'][i]
                    ANTEC_AMOUNT = datacsv['MON_CTO_ANT'][i]
                    ANTEC_DATE = getDateText(datacsv['FECHA_CTO_ANT'][i])
                    ENGINE = str(datacsv['MOTOR'][i]).strip()
                    SERIE = str(datacsv['VIN'][i]).strip()
                    BRAND = str(datacsv['MARCA'][i]).strip()
                    MODEL = str(datacsv['MODELO'][i]).strip()
                    COLOUR = str(datacsv['COLOR'][i]).strip()
                    REFERENCE = datacsv['REFERENCIA'][i]
                    ADDRESS = str(datacsv['DOMICILIO'][i]).strip()
                    TYPE_LAYOUT = str(datacsv['VENTA'][i]).strip()

                    tables = camelot.read_pdf(os.path.join(files, fichero)) # find tables in PDF
                    df = tables[0].df # in the pays, the tables is in first page
                    df_out = pd.DataFrame(df)  
                    # print(df_out)
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
                    # print(table_data[0][len(table_data[0])-1], ' ', table_data[1][len(table_data[0])-1], ' ', table_data[2][len(table_data[0])-1])
                    dataValues = [] # list of dictionaries 
                    # iterate the matrix of values
                    for row in partial_income_table:
                        aux_dic = {}                # crate the dictionary
                        aux_dic['cols'] = row       # add value 'list' with the key 
                        dataValues.append(aux_dic)  # add dictionary in the list
                        # print(aux_dic)

                    N_END_PAY = table_data[0][len(table_data[0])-1]
                    END_DATE_PAY = getDateText(table_data[1][len(table_data[0])-1])
                    BULLET = float(str(table_data[2][len(table_data[0])-1]).replace(',',''))
                    AMOUNT_MONTH = float(str(table_data[2][len(table_data[0])-2]).replace(',',''))

                    context = {
                        'name' : CLIENT_NAME,
                        'client': NUMBER_CLIENT,
                        'antec_date':ANTEC_DATE,
                        'antec_credit':ANTEC_CREDIT,
                        'antec_amount':ANTEC_AMOUNT,
                        'engine':ENGINE,
                        'serie':SERIE,
                        'brand':BRAND,
                        'model':MODEL,
                        'colour':COLOUR,
                        'address':ADDRESS,
                        'rfc_client':CLIENT_RFC,
                        'amount_owed':AMOUNT_OWED,
                        'final_date':END_DATE_PAY,
                        'tbl_data' : dataValues,
                        'reference_banck':REFERENCE,
                        'date':DATE,   
                        'carta_condonacion':LETTER_COND                     
                    }
        
                    if  BULLET > AMOUNT_MONTH:
                        context['carta_condonacion'] = True
                        context['credit'] = CREDIT
                        context['nmonths'] = N_END_PAY
                        context['amount_month'] = number_text(AMOUNT_MONTH)
                        context['condonation_amount'] = number_text(BULLET - AMOUNT_MONTH)

                    # print(context)

                    fileDir = dir_out_files

                    try:
                        os.stat(fileDir)
                    except:
                        os.mkdir(fileDir)

                    if TYPE_LAYOUT == 'OSER':
                        PRINCEPS_V2 = DocxTemplate('C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/layouts/OSER CONVENIO DE RECONOCIMIENTO DE ADEUDO Y REESTRUCTURA V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) +  'PR_V2_' + ".docx")   
                        print(str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) +  'PR_V2_' + ".docx")
                    if TYPE_LAYOUT == 'GSJ':
                        PRINCEPS_V2 = DocxTemplate('C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/layouts/GSJ CONVENIO DE RECONOCIMIENTO DE ADEUDO Y REESTRUCTURA V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) +  'PR_V2_' + ".docx")
                        print(str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) +  'PR_V2_' + ".docx")             
                    if TYPE_LAYOUT == 'CARPENTUM':
                        PRINCEPS_V2 = DocxTemplate('C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/layouts/CARPENTUM CONVENIO DE RECONOCIMIENTO DE ADEUDO Y REESTRUCTURA V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) + 'PR_V3C_' + ".docx")
                        print(str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) + 'PR_V3C_' + ".docx")             
                    if TYPE_LAYOUT == 'MERICULTER':
                        PRINCEPS_V2 = DocxTemplate('C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/layouts/MERICULTER CONVENIO DE RECONOCIMIENTO DE ADEUDO Y REESTRUCTURA V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) + 'PR_V3M_' + ".docx")
                        print(str(CLIENT_NAME) + "_" + str(CREDIT) + "_" + str(int(AMOUNT_MONTH)) + 'PR_V3M_' + ".docx")             

        

if __name__ == '__main__':

    dir_in_files = "C:/Users/FINSUS-Admin/Documents/FINSUS/PAGARES"

    dir_out_files = "C:/Users/FINSUS-Admin/Documents/FINSUS/CONTRATOS"

    # directory CSV data render
    dirCSVFile = 'C:/Users/FINSUS-Admin/Documents/PRINCEPS/PRINCEPS.csv'

    generateContract(dirCSVFile, dir_in_files, dir_out_files, '01 de febrero de 2023')

            

