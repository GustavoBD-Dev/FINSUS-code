import os
from docxtpl import DocxTemplate
import pandas as pd

def number_text(number):
    from nlt import numlet as nl
    number_text = '{:,.2f}'.format(number)
    return "$ {} ({} PESOS {}/100 M.N.)".format(
                number_text,
                # numbers_to_letter.numero_a_letras(int(float(str(number_text).replace(',','')))).upper(),
                nl.Numero(int(number)).a_letras.upper(),
                str(number_text).split('.')[1])

# Route of output files
# fileDirOut = "C:/Users/FINSUS-Admin/OneDrive - Financera Sustentable de México SA de CV SFP/SHARE/2023/FEBRERO 2023/FS/CONTRATOS/17500"
fileDirOut = "C:/Users/FINSUS-Admin/Documents/FINSUS/CONTRATOS"

# Route of input layout file CSV
fileDirIn = "C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/data/fs-render.csv"

carta = pd.read_csv(fileDirIn,encoding = 'utf-8')

meses = ['','Enero', 'Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre']

for dt in carta.index:

  if int(carta['render-file'][dt]) == 0:
    # print('no se genera {}'.format(str(carta['credito'][dt])))
    continue

  EnrutaMasConvenioModificatorioCartaCondonacion = DocxTemplate("C:/Users/FINSUS-Admin/Documents/Code Projects/render-contracts/layouts/2022 02 06 Paquete de Firmas Sin Telefono 2 MAS CONVENIO MODIFICATORIO - CARTA_CONDONACION.docx")
  # EnrutaMasConvenioModificatorioCartaCondonacion = DocxTemplate("C:\Projects\render-contracts\src\layouts\2022 02 06 Paquete de Firmas Sin Telefono 2 MAS CONVENIO MODIFICATORIO - CARTA_CONDONACION.docx")

  fecha_text = carta['fechaape'][dt].split('/')
  fecha_nac = carta['fechanacimiento'][dt].split('/')
  reca = '13916-439-035811/01-00414-0122'
  
  monto_total = (carta['mensualidad'][dt] * (carta['plazo'][dt] -1)) + carta['bullet'][dt]
  context = {        
        'credito': carta['credito'][dt],
        'pais': 'México',
        'fecha_texto': fecha_text[0]+ ' de '+ meses[int(fecha_text[1])]+' de '+fecha_text[2],
        'nombre_completo' : carta['nombre'][dt].strip(),
        'ruta' : carta['ruta'][dt].strip(),
        'cuenta_2001' : carta['cuenta_2001'][dt].strip(),
        'direccion_completa': carta['direccion_completa'][dt],
        'pais_nacimiento': carta['paisnacimiento'][dt],
        'entidad_nacimiento': carta['entidadfederativa'][dt],
        'nacionalidad': carta['nacionalidad'][dt],
        'fecha_nacimiento_texto': fecha_nac[0]+ ' de '+ meses[int(fecha_nac[1])]+' de '+fecha_nac[2],
        'edad': carta['edad'][dt],
        'sexo': carta['sexo'][dt],
        'curp': carta['curp'][dt],
        'ocupacion': carta['ocupacion'][dt],
        'monto_max_formato': '{:,.2f}'.format(carta['mensualidad'][dt]),
        #'monto_max_texto': carta['mensualidad_formato'][dt],
        'fecha_apertura_texto': fecha_text[0]+ ' de '+ meses[int(fecha_text[1])]+' de '+fecha_text[2],
        'motor' : carta['motor'][dt],
        'vin': carta['vin'][dt],
        'marca': carta['marca'][dt],
        'modelo': int(carta['modelo'][dt]),
        'modelo_formato': carta['modelo'][dt],
        'color': carta['color'][dt],
        'saldo_insoluto_formato': '{:,.2f}'.format(carta['saldo_insoluto_formato'][dt]),
        'saldo_insoluto_texto': carta['saldo_insoluto_texto'][dt],
        'referencia_bancaria' : str(carta['referencia'][dt]).zfill(10),
        'celular' : str(carta['celular'][dt]).split('.')[0],
        'telefono_fijo' : carta['telefono_fijo'][dt],
        'reca': reca,
        'nombre_obligado_solidario' : '',
        'nombre_aseguradora': '',
        'cat' : carta['cat'][dt],
        'interes_moratorio': '20 %',
        'plazo': carta['plazo'][dt],
        'monto_total' : '{:,.2f}'.format(monto_total),
        'mensualidad': carta['mensualidad'][dt],
        'fecha_corte': 'Pendiente' ,
        'fecha_vencimiento':  carta['fecha_vencimiento'][dt],
        'bullet' : '{:,.2f}'.format(carta['bullet'][dt]),
        'correo' :carta['email'][dt],
        'descripcion_camioneta': carta['descripcion'][dt]+ ' Modelo ' +str(carta['modelo'][dt])+ ' con número de motor ' + carta['motor'][dt]+ ' VIN ' + carta['vin'][dt],
        'rfc': carta['rfc'][dt],
        'ife':carta['ife'][dt]
  }

  # if bullet is greater then montly of payment then add letter condonation 
  if  float(str(carta['bullet'][dt])) > float(str(carta['mensualidad'][dt])):
    context['letter_c'] = True
    # Add the values of the letter
    value_cond = round(float(str(carta['bullet'][dt])) - float(str(carta['mensualidad'][dt])), 2)
    value_cond_format = '{:,.2f}'.format(value_cond)
    # context['cond'] = value_cond_format
    context['cond'] = number_text(value_cond)
    # Add value of condonatio in letter
    # if len(str(value_cond).split('.')) > 0:
    #   context['cond_letra'] = "({} PESOS {}/100 M.N.)".format(
    #     numbers_to_letter.numero_a_letras(int(str(value_cond).split('.')[0])).upper(),
    #     str(str(value_cond).split('.')[1]))
    # else:
    #   context['cond_letra'] = "({} PESOS 00/100 M.N.)".format(
    #       numbers_to_letter.numero_a_letras(int(float(str(value_cond).split('.'))).upper()))
    # Add value of amount of montly in letter
    # context['monto_max_texto'] = "({} PESOS 00/100 M.N.)".format(numbers_to_letter.numero_a_letras(int(float(carta['mensualidad'][dt]))))
    context['monto_mensualidad'] = number_text(int(float(carta['mensualidad'][dt])))
  else: 
    # the letter is not added
    context['letter_c'] = False

  nombreRuta = carta['ruta'][dt].replace("..","")
  for r in ('"', ".", "/","..","\""):
    nombreRuta = nombreRuta.replace(r, "")
    
  fileDir = fileDirOut
  
  try:
    os.stat(fileDir)
  except:
    os.mkdir(fileDir)
  
  EnrutaMasConvenioModificatorioCartaCondonacion.render(context)
  EnrutaMasConvenioModificatorioCartaCondonacion.save(fileDir+"/"+str(carta['nombre'][dt]).strip()+"_"+str(carta['credito'][dt])+"_"+str(carta['vin'][dt])+"_"+str(int(carta['mensualidad'][dt]))+".docx")
  print("[" + str(dt) + '/' + str(len(carta)) + "] >>> " + str(carta['nombre'][dt]).strip()+"_"+str(carta['credito'][dt])+"_"+str(carta['vin'][dt])+"_"+str(int(carta['mensualidad'][dt]))+".docx")