from pathlib import Path
import pandas as pd
import re, os, camelot
from PyPDF2 import PdfFileReader
from docxtpl import DocxTemplate
# import numbers_to_letter
import numpy

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
    return date_credit_num[0] + ' de ' + months[int(date_credit_num[1])] + ' de ' + date_credit_num[2]

def number_text(number):
    from nlt import numlet as nl
    number_text = '{:,.2f}'.format(number)
    return "$ {} ({} PESOS {}/100 M.N.)".format(
                number_text,
                # numbers_to_letter.numero_a_letras(int(float(str(number_text).replace(',','')))).upper(),
                nl.Numero(int(number)).a_letras.upper(),
                str(number_text).split('.')[1])

def generate_contract(fileDirIn, dir_out_files, dirCSVFile, dateGenerate):

    data_csv = pd.read_csv(dirCSVFile, encoding = 'utf-8')

    # name of columns to get data 
    DATA_FILES_PDF =  []    # list to save data in files PDF
    columnas = ['NO CREDITO','NO CLIENTE','TOTAL PAGOS','MONTO A PAGAR','BULLET','FECHA FINAL','NAME','MONTO_TABLA','MONTO_LETRA','VALIDACION DE MONTOS','FECHA_PAGARE','ACCESORIOS', 'ACCESORIOS_TOTAL']
    DATA_FILES_PDF.append(columnas)

    files = fileDirIn # route to find files PDF
    
    dirFiles = os.listdir(files) # list files pdf files in route
    
    for fichero in dirFiles: # each file to do

        # Store data in file
        data_in_file = []

        # store to droute complete of the file
        ficheropath = os.path.join(files, fichero)

        filename = Path(ficheropath).stem

        # validate the file PDF with the name
        if os.path.isfile(ficheropath) and (fichero.endswith('.pdf') or fichero.endswith('.PDF')):  # validate PDF    
            
            # Store the file in the variable, it is temp
            temp = open(os.path.join(files, fichero), 'rb')

            # Read the file with the library
            PDF_read = PdfFileReader(temp)

            # Read the first page of the file
            first_page = PDF_read.getPage(0)

            # extract text of the first page
            text = str(first_page.extractText())

            # Reference to find credit 
            index = text.find("PRINCEPS SAPI DE C.V.")

            # split the file
            parts = text.split()
            # for i in range(len(parts)):
                # print(i, ' - ', parts[i])

            # find name of document, betwen the words "Suscriptor" y "Obligado"
            start_name = text.find('Suscriptor')
            end_name = text.find('Obligado')
            NAME = text[start_name+10: end_name-3]    

            # find the amount
            start_amount = text.find('$')
            end_amount = text.find('M.N.)"Beneficiario"')
            AMOUNT = text[start_amount+1: end_amount+5]   
            #print(AMOUNT) 
            
            #start_nmonths = text.find("0.00%")
            #NUMBER_OF_MONTHS_TEXT = text[start_nmonths+5:start_nmonths+8]
            #print(NUMBER_OF_MONTHS_TEXT)

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
            CREDIT = cc[index-1:len(cc)]
            CLIENT = cc[0:index-1]
            # print(CREDIT + " & " + cliente + " & " + cc)

            tables = camelot.read_pdf(os.path.join(files, fichero)) # find tables in PDF

            df = tables[0].df # in the pays, the tables is in first page
            df_out = pd.DataFrame(df)  
            # print(df_out)

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

            # print(df_out)
    
            # producto_fin = CREDIT.split("-")[1]
            
            for i in range(len(df_out)):
                df_out[0][i] = i
                if i == 9:
                    break


            # index_pay = []
            # for i in range(1, (END_DATA)):
            #     index_pay.append(i)

            # generate table with the list 
            table_data = []
            table_data.append(df_out[0])
            # table_data.append(index_pay)
            table_data.append(df_out[1])
            table_data.append(df_out[9])

            # print(table_data)
            END_DATA = 0
            for i in range(len(df_out)):
            #print(df_out[1][i])
                if df_out[1][i].strip() == '':
                    END_DATA = i
                    #print(i)
                    break
                ACCESORIOS = float(str(df_out[6][1]).replace(',','')) + float(str(df_out[7][1]).replace(',',''))

            partial_income_table = []

            var = 0
            # build the data matrix, list of lists
            # for i in range(1, len(table_data[0])):
            for i in range(1, END_DATA):
                    aux = []
                    aux.append(table_data[0][i])
                    aux.append(table_data[1][i])
                    aux.append(table_data[2][i])
                    partial_income_table.append(aux)
                    var += float(str(table_data[2][i]).replace(",",""))
            #print((AMOUNT.split('(')[0]).replace(' ',''))
            # print(partial_income_table)
            amount_split = float((AMOUNT.split('(')[0]).replace(' ',''))

            dataValues = [] # list of dictionaries 
            
            # iterate the matrix of values
            for row in partial_income_table:
                aux_dic = {}                # crate the dictionary
                aux_dic['cols'] = row       # add value 'list' with the key 
                dataValues.append(aux_dic)  # add dictionary in the list
            # print(dataValues)

            # the date latest is in latest row
            FINAL_DATE = df_out[1][END_DATA - 1]

            # total of elements
            TOTAL_PAYMENTS = END_DATA - 1

            # amount to pay monthly
            MONTHLY_AMOUNT = df_out[9][1]

            # amount total - bullet
            TOTAL_AMOUNT = df_out[9][END_DATA - 1]

            # first amount of table
            AMOUNT_TABLE = df_out[9][1]
            AMOUNT_TABLE = float(str(AMOUNT_TABLE).replace(',',''))


            PDF_read = PdfFileReader(temp)
            second_page = PDF_read.getPage(1)
            textDate = str(second_page.extractText()) # get text of file
            parts = textDate.split()

            DATE_PAY = 'Enero' if 'Enero' in parts else 'Fecha Diferente'

            VALIDATE_AMOUNTS = 'Correcto' if float(str(AMOUNT.split('(')[0]).replace(' ','')) == AMOUNT_TABLE else 'Incorrecto'
            
            #VALIDATE_MONTHS = 'Correcto' if  int(NUMBER_OF_MONTHS_TEXT.replace(' ','')) == TOTAL_PAGOS else 'Incorrecto'

            ACCESORIOS_TOTAL = ACCESORIOS * TOTAL_PAYMENTS

            data_in_file = [CREDIT, TOTAL_PAYMENTS, str(MONTHLY_AMOUNT).replace(',',''), str(TOTAL_AMOUNT).replace(',',''), FINAL_DATE, NAME, AMOUNT_TABLE,AMOUNT, VALIDATE_AMOUNTS,DATE_PAY, ACCESORIOS, ACCESORIOS_TOTAL]
            DATA_FILES_PDF.append(data_in_file)
            # print(DATA_FILES_PDF)
      

            context = {
                    'name' : NAME,
                    'amount_owed'  : '$ {}'.format(AMOUNT),
                    'term_text'  : MONTHS_TEXT,
                    'term_num'  : MONTHS_NUMBER,
                    'credit' : CREDIT,
                    'date'  : dateGenerate,
                    'tbl_data' : dataValues,
                    'final_date' : str(getDateText(str(FINAL_DATE))),
                    'client': CLIENT
                    # 'antec_date': '',
                    # 'antec_credit': '',
                    # 'antec_amount':'',
                    # 'engine':'',
                    # 'serie':'',
                    # 'brand':'',
                    # 'colour':'',
                    # 'model':'',
                    # 'reference_banck': '',
                    # 'rfc_client':'',
                    # 'address':'',
                    # 'email':'email PRINCEPS',
                }
            # print(data_csv)
            # print(data_csv.columns)
            for i in data_csv.index:
                if str(CREDIT).strip() == data_csv['CREDITO'][i]:
                    context['antec_date']= str(getDateText(str(data_csv['FECHA CREDITO ANTERIOR'][i]))) + ','
                    context['antec_credit']= data_csv['CREDITO ANTERIOR'][i]
                    context['antec_amount']= number_text(float(data_csv['MONTO CREDITO ANTERIOR'][i]))
                    # context['antec_amount']= "$ {:,.2f} ({} PESOS {}/100 M.N.)".format(
                    #     float(data_csv['MONTO CREDITO ANTERIOR'][i]),
                    #     numbers_to_letter.numero_a_letras(int(float(data_csv['MONTO CREDITO ANTERIOR'][i]))).upper(),
                    #     str(data_csv['MONTO CREDITO ANTERIOR'][i]).split('.')[1])
                    context['engine']= data_csv['MOTOR'][i]
                    context['serie']= data_csv['VIN'][i]
                    context['brand']= data_csv['MARCA'][i]
                    context['colour']= data_csv['COLOR'][i]
                    context['model']= data_csv['MODELO'][i]
                    context['reference_banck']= str(data_csv['REFERENCIA_MAS_DV'][i]).zfill(11)
                    context['rfc_client']= data_csv['RFC'][i]
                    context['address']= data_csv['DOMICILIO'][i]
                    context['email']= '______________________'

                    MONTHLY_AMOUNT = float(str(MONTHLY_AMOUNT).replace(',',''))
                    TOTAL_AMOUNT = float(str(TOTAL_AMOUNT).replace(',',''))

                    if  TOTAL_AMOUNT > MONTHLY_AMOUNT:

                        context['carta_condonacion'] = True
                        
                        context['credit'] = CREDIT

                        context['nmonths'] = TOTAL_PAYMENTS

                        context['amount_month'] = number_text(MONTHLY_AMOUNT)

                        context['condonation_amount'] = number_text(TOTAL_AMOUNT - MONTHLY_AMOUNT)

                    fileDir = dir_out_files

                    try:
                        os.stat(fileDir)
                    except:
                        os.mkdir(fileDir)
                    
                    if data_csv['ORIGEN DE VENTA'][i] == 'PRIMERA VENTA':
                        print('CONTRATO DE PRIMERA VENTA {}'.format(CREDIT))

                    if data_csv['ORIGEN DE VENTA'][i] == 'SEGUNDA VENTA':
                        PRINCEPS_V2 = DocxTemplate('C:/Projects/render-contracts/src/layouts/GSJ CONVENIO DE RECONOCIMIENTO DE ADEUDO V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + 'PR_V2_' + str(NAME) + "_" + str(CREDIT) + "_" + str(int(MONTHLY_AMOUNT)) + ".docx")             
                        print('PR_V2_' + str(NAME) + "_" + str(CREDIT) + "_" + str(int(MONTHLY_AMOUNT)) + ".docx")
                    if data_csv['ORIGEN DE VENTA'][i] == 'tercera VENTA carpentum':
                        PRINCEPS_V2 = DocxTemplate('C:/Projects/render-contracts/src/layouts/CARPENTUM CONVENIO DE RECONOCIMIENTO DE ADEUDO Y REESTRUCTURA V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + 'PR_V3C_' + str(NAME) + "_" + str(CREDIT) + "_" + str(int(MONTHLY_AMOUNT)) + ".docx")             
                        print('PR_V3C_' + str(NAME) + "_" + str(CREDIT) + "_" + str(int(MONTHLY_AMOUNT)) + ".docx")
                    if data_csv['ORIGEN DE VENTA'][i] == 'tercera VENTA mericulter':
                        PRINCEPS_V2 = DocxTemplate('C:/Projects/render-contracts/src/layouts/MERICULTER CONVENIO DE RECONOCIMIENTO DE ADEUDO Y REESTRUCTURA V2.docx')
                        PRINCEPS_V2.render(context)
                        PRINCEPS_V2.save(fileDir + '/' + 'PR_V3M_' + str(NAME) + "_" + str(CREDIT) + "_" + str(int(MONTHLY_AMOUNT)) + ".docx")             
                        print('PR_V3M_' + str(NAME) + "_" + str(CREDIT) + "_" + str(int(MONTHLY_AMOUNT)) + ".docx")

    # numpy.savetxt("{}/DataFilesPDF_{}.csv".format(dir_out_files,int(MONTHLY_AMOUNT)), delimiter =",",fmt ='% s')


if __name__ == '__main__':

    # directory pdf files inputs
    # dir_in_files = 'C:/Users/Gustavo Blas/OneDrive - Financera Sustentable de México SA de CV SFP/SHARE/2023/PRINCEPS/Pagares/17500'
    dir_in_files = 'C:/JUEVES'
    # dir_in_files = 'C:/Users/Gustavo Blas/Documents/CONTRATOS-24/PRINCEPS/pr2'

    # directory output files
    # dir_out_files = 'C:/Users/Gustavo Blas/OneDrive - Financera Sustentable de México SA de CV SFP/SHARE/2023/PRINCEPS/CONTRATOS SEGUNDA Y TERCERA VENTA/17500_V2'
    dir_out_files = 'C:/JUEVES'
    # dir_out_files = 'C:/Users/Gustavo Blas/Documents/CONTRATOS-24/PRINCEPS/pr2'

    # date of generate the contracts
    dateGenerate = '01 de Enero de 2023'

    # directory CSV data render
    dirCSVFile = 'C:/Projects/render-contracts/src/data/LAYOUT.csv'
    generate_contract(dir_in_files, dir_out_files, dirCSVFile, dateGenerate)

    # print(number_text(43011.10))