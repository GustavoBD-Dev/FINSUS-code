-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_forma_ec_estandar
-- Estado de Cuenta
-- 20/06/2016

/*
SELECT of_param_sesion_set('vsr_vars','ps_idsucaux','1');
SELECT of_param_sesion_set('vsr_vars','ps_idproducto','5200');
SELECT of_param_sesion_set('vsr_vars','ps_idauxiliar','14740');
SELECT of_param_sesion_set('vsr_vars','ps_dfecha','01/03/2022');
SELECT of_param_sesion_set('vsr_vars','ps_afecha','31/03/2022');
*/
CREATE OR REPLACE FUNCTION ofx_estado_cuenta_rutas___ini()
 RETURNS boolean AS $$

DECLARE
  --JCGE: En estas dos primeras variables, si no consigue estar en expediente tomara la informacion de gestoria, y en caso
  --      de que no se cumpla, mandara el mensaje de error.
  tv_auxiliares       TEXT[]:= COALESCE(of_ofx_get('tv_axso_1')::TEXT[], of_ofx_get('tlv_soc_aux_1')::TEXT[]);     --> Auxiliares Disponibles en el Treeview.
  _auxiliar_deseado   INTEGER:= COALESCE(of_ofx_get_INTEGER('tv_axso_row'), of_ofx_get_INTEGER('tlv_soc_aux_row')); --> Fila de auxiliar deseado en el Treeview.
  _lp_arr             TEXT[];     --> Auxiliar separado por comas desde _cuentas.
  _cuenta             TEXT;       --> Auxiliar separado en el Treeview.
  _idsucaux           INTEGER:=0;       --> Clave de idsucaux.
  _idproducto         INTEGER:=0;       --> Clave de idproducto.
  _idauxiliar         INTEGER:=0;       --> Clave de idauxiliar.
  _continua           BOOLEAN:=TRUE;    --> Debe contituar?.
  _fechoperacion      DATE;
  _det_mov            BOOLEAN:=FALSE;   --> Parametro activa leyenda personalizado en detalle de movimientos.
  _descripcion_det    TEXT:='';         --> Leyenda personalizado en detalle de movimientos.
  _estatus            INTEGER:=0;       --> Estatus del crédito consultado.
  _usuario            TEXT:=of_param_sesion_get('global','usuario');

BEGIN
  -- PERFORM of_param_sesion_raise(null);
  -- Revisando versiones
  -- Temporal FIXME para revisión de versión. 
  /*IF (NOT of_ofx_check_version('1.16.6-0')) THEN
    raise notice '----------------  >>>>>>>  si';
    PERFORM of_ofx_set('bt_flag','hide=true');
  ELSE
    raise notice '----------------  >>>>>>>  no  % ',of_ofx_check_version('1.16.6-0');
    PERFORM of_ofx_set('bt_aceptar','hide=true');
  --  RETURN FALSE;
  END IF;*/
  -- Crear permiso de configuracion si no existe.
  PERFORM of_acceso('_'|+_usuario,'_esp_conf_forma_edocta');
  _fechoperacion       := of_param_sesion_get('global','fecha');
  IF (_auxiliar_deseado IS NULL) THEN -- Si no hay fila seleccionada marcamos error.
    PERFORM of_notice(null,'error','Error: Favor de Seleccionar una fila en el resumen de Auxiliares!!');
    _continua    := FALSE;
  ELSE  -- De otra forma Obtenemos el auxiliar.
    _cuenta              := tv_auxiliares[_auxiliar_deseado]; -- Tomar el auxiliar deseado.
    _lp_arr              := string_to_array(_cuenta,'-'); -- Separar el auxiliar por comas (,).
    _idsucaux            := _lp_arr[1];
    _idproducto          := _lp_arr[2];
    _idauxiliar          := _lp_arr[3];
    IF (of_producto_subtipo(_idproducto)<>'PRE') THEN
      PERFORM of_ofx_notice('error','La cuenta seleccionada no es válido para deudores!');
      RETURN FALSE;
    ELSE
      -- DGZZH 29/07/2016 Consultar creditos liquidados?
      IF NOT (of_params_get_boolean('/formatos/ofx_estado_cuenta_rutas','cuentas_liquidadas')) THEN
        SELECT INTO _estatus estatus
          FROM deudores
         WHERE (idsucaux,idproducto,idauxiliar)=(_idsucaux,_idproducto,_idauxiliar);
        -- verificar si está activo el crédito.
        IF (_estatus <> 3) THEN
          PERFORM of_ofx_notice('error','La cuenta que desea consultar no está activo!');
          RETURN FALSE;
        END IF;
      ELSE
      END IF;
        -- Creando parametros si no existen.
        -- Activa leyenda personalizado en detalle de movimientos.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_mov','Mostrar leyenda personalizado',
                              'Mostrará la descripcion de detalle de movimientos','BOOLEAN','FALSE');

        -- Activa leyenda personalizado en detalle de movimientos para  todas las polizas.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_activa_leyenda_all','Activa leyenda personalizado',
                              'Activa  leyenda de topo tipo de detalle de movimientos','BOOLEAN','FALSE');

        -- Activa leyenda personalizado en detalle de movimientos (Ingresos).
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_activa_leyenda_ingreso','Activa leyenda personalizado',
                              'Mostrar leyenda de detalle de movimientos en ingresos','BOOLEAN','FALSE');

        -- Leyenda personalizado en detalle de movimientos. (Ingresos)
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_leyenda_mov_ingreso','Descripción detalle de movimientos',
                              'Leyenda que mostrará en la descripcion de detalle de movimientos cuando son ingresos','TEXT','x');

        -- Activa leyenda personalizado en detalle de movimientos (Egresos).
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_activa_leyenda_egreso','Activa leyenda personalizado',
                              'Mostrar leyenda de detalle de movimientos en egresos','BOOLEAN','FALSE');

        -- Leyenda personalizado en detalle de movimientos. (Egresos)
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_leyenda_mov_egreso','Descripción detalle de movimientos',
                              'Leyenda que mostrará en la descripcion de detalle de movimientos cuando son egresos','TEXT','x');

        -- Activa leyenda personalizado en detalle de movimientos (Diario).
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_activa_leyenda_diario','Activa leyenda personalizado',
                              'Mostrar leyenda de detalle de movimientos en diario','BOOLEAN','FALSE');

        -- Leyenda personalizado en detalle de movimientos. (Diario)
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_leyenda_mov_diario','Descripción detalle de movimientos',
                              'Leyenda que mostrará en la descripcion de detalle de movimientos cuando son tipo diario','TEXT','x');

        -- Leyenda personalizado en detalle de movimientos. (Cargo)
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_leyenda_mov_cargo','Descripción detalle de movimientos',
                              'Leyenda que mostrará en la descripcion de detalle de movimientos cuando es un cargo','TEXT','x');

        -- Numero de registro ante conducef
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','conducef','Número de conducef',
                                      'Número de registro ante conducef para este formato','TEXT','00000-00-00');

        -- Formato de los decimales definido por el cliente
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','formato_io','Formato de la tasa',
                              'Formato de tasa en los decimales','TEXT','FM999.00');

        -- Foramto del CAT para los decimales.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','formato_cat','Formato del CAT',
                              'Formato de CAT para los decimales','TEXT','FM999.00');


        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','lista','Lista de productos',
                                      'Productos disponibles para este producto','TEXT','');

        -- Saldo inicial cero
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','saldoini_cero','Saldo inicial cero',
                                      'Si esta prendido el parametro inicia con saldo cero','BOOLEAN','FALSE');
        
        -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_dinamico','Detalle de movimientos en segundo plano',
                              'Si es necesario mas de una hoja, se insertan hojas adicionales para el detalle de forma dinamica','BOOLEAN','FALSE');

        -- Tipo de detalle Estandar/Otros.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_base','Tipo de detalle estandar',
                              'El tipo de detalle por defaul es el estandar Columas:' |+ E'\n'|+
                              'FECHA | TICKET | DESCRIPCION | CARGO | ABONO | SALDO' |+ E'\n'|+
                              'La otra opcion trae las columnas:'|+ E'\n'|+
                              'FECHA | TICKET | DESCRIPCION | CAPITAL | IO | IM | IVA'|+ E'\n'|+
                              'Detalle Base estandar su valor en TRUE','BOOLEAN','TRUE');

        -- Pago inmediato.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','tolerante_prox_pago','Tolerante en próximo abono',
                              'Tolerante en el proximo abono, de lo contrario desactivar su valor.','BOOLEAN','TRUE');

        -- Impresión masiva.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','print_masiva','Impresión masiva',
                              'Activar opción para generar impresión masiva con valor FALSE','BOOLEAN','TRUE');
        
        -- Limite de detalle
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_limite','Limite de numero de movimientos',
                              'Limite o tope que tendrá el detalle de movimientos','INTEGER','13');

        -- Longitud para la descripcion de detalle.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_length_desc','Longitud descripcion de detalle',
                              'Longitud máxima para la descripcion de los detalles de movimientos ','INTEGER','90');

        --------------------------------- Solo para el detalle de movimientos ------------------------------
        ----------------------------------------------------------------------------------------------------
        -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_detalle_ec','dt_limite','Limite de numero de movimientos',
                              'Limite o tope que tendrá el detalle de movimientos','INTEGER','10'); 

        -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_detalle_ec','idsucaux','clave de sucursal',
                              'Clave de sucursal a cosultar','INTEGER','0');

        -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_detalle_ec','idproducto','Clave de idproducto',
                              'Clave de producto a cosultar','INTEGER','0');

        -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_detalle_ec','idauxiliar','Clave de auxiliar',
                              'Clave de auxiliar a cosultar','INTEGER','0');

        -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_detalle_ec','fechaini','Fecha inicial',
                              'Fecha inicial para la consulta del periodo','TEXT','');

              -- Limite o tope de detalle para los movimientos.
        PERFORM of_params_get('/formatos/ofx_detalle_ec','fechafin','Fecha Final',
                              'Fecha Final de consulta de periodo','TEXT','');
        
        -- DGZZH 09/08/2016 Funcion principal de fijos
        -- Funcion principal.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','fx_principal','Función principal',
                              'Función principal a ejecutar','TEXT','ofx_estado_cuenta_rutas');

        -- Generación de pdfs masivos
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','gen_pdfs','Genera pdfs',
                              'Generación de pdfs masivos en directorio','BOOLEAN','FALSE');

         -- ¿Generar registros de detalle?
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','gen_detalle','Generar detalle',
                              'Generar detalle de movimientos','BOOLEAN','TRUE');

        -- DGZZH 29/07/2016 Consultar cuentas liquidados.
        PERFORM of_params_get('/formatos/ofx_estado_cuenta_rutas','cuentas_liquidadas','Considerar cuentas liquidadas',
                              'Consultar cuentas liquidadas','BOOLEAN','FALSE');

        -- Asignar los valores en los widget's.
        -- Revisar si tiene activado el permiso para configurar los parámetros del estado de cuenta.
        PERFORM * FROM perfil_tarea WHERE idperfil='_'|+_usuario AND idtarea = '_esp_conf_forma_edocta';
        IF (FOUND) THEN
          PERFORM of_ofx_set('hpaned3','hide=false');
        END IF;
        -- Por defual es Individual.
        PERFORM of_params_update('/formatos/ofx_estado_cuenta_rutas','fijos',of_params_get('/formatos/ofx_estado_cuenta_rutas','fx_principal'));
        PERFORM of_ofx_set('ps_idsucaux',  'set='||_idsucaux::TEXT);
        PERFORM of_ofx_set('ps_idproducto','set='||_idproducto::TEXT);
        PERFORM of_ofx_set('ps_idauxiliar','set='||_idauxiliar::TEXT);
        --PERFORM of_ofx_set('ps_dfecha','set='||of_fecha_dpm(_fechoperacion)::TEXT);
        PERFORM of_ofx_set('ps_dfecha','set='||of_ofx_get('fecha1')::TEXT);
        PERFORM of_ofx_set('ps_afecha','set='||of_ofx_get('fecha2')::TEXT);
        PERFORM of_ofx_set('c_todos','show='||of_params_get('/formatos/ofx_estado_cuenta_rutas','print_masiva'));
        PERFORM of_ofx_set('titulo','set='||of_params_get('/formatos/ofx_estado_cuenta_rutas','titulo'));
        PERFORM of_ofx_set('lista','set='||replace(of_params_get('/formatos/ofx_estado_cuenta_rutas','lista'),',','\,'));
        PERFORM of_ofx_set('lista_roles_excluir','set='||replace(ofpt('/formatos/ofx_estado_cuenta_rutas', 'lista_roles_excluir', ''),',','\,'));
        PERFORM of_ofx_set('conducef','set='||of_params_get('/formatos/ofx_estado_cuenta_rutas','conducef'));
        PERFORM of_ofx_set('limite_detalle','set='||of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_limite'));
        PERFORM of_notice(NULL,'info','Generando Estado de Cuenta Individual...');
    END IF;
  END IF;
  PERFORM of_ofx_set('bt_ofqueue', 'show=' || ofpt('/sinc/ofstore/email','ofqueue','FALSE'));
RETURN _continua;
END;$$
LANGUAGE plpgsql;


--Validate
CREATE OR REPLACE FUNCTION ofx_estado_cuenta_rutas___val(p_variable text, p_valor text)
 RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  _dateoper           DATE;       -- Fecha de operación.
  r                   RECORD;
  ps_sucursal          BIGINT:= of_ofx_get('ps_sucursal');
  ps_idsucursal        BIGINT:= of_ofx_get('idsucursal');
  ps_idrol            INTEGER:= of_ofx_get_integer('idrol');
  ps_idasociado        BIGINT:= of_ofx_get('idasociado');
  ps_idsucaux          BIGINT:= of_ofx_get('ps_idsucaux');
  ps_idproducto       INTEGER:= of_ofx_get_integer('ps_idproducto');
  ps_idauxiliar        BIGINT:= of_ofx_get('ps_idauxiliar');
  _dfecha             DATE:= of_ofx_get_date('ps_dfecha');
  _afecha             DATE:= of_ofx_get_date('ps_afecha');
  _titulo             TEXT:= of_ofx_get('titulo');
  _lista              TEXT[]:= string_to_array(NULLIF(trim(of_ofx_get('lista')),''),',');
  _conducef           TEXT:= of_ofx_get('conducef');
  _limit_det          TEXT:= of_ofx_get('limite_detalle');
  _gen_pdfs           BOOLEAN;
  n                   INTEGER:=0;
  i                   INTEGER:=0;

BEGIN

  -- Por default todo es válido
  -- PERFORM of_param_sesion_raise(NULL);
  PERFORM of_param_sesion_set_boolean('vsr_execute_validate','validate',TRUE);
  _dateoper      := of_param_sesion_get('global','fecha')::DATE;

  -- Validando el checkbox Individual
  IF (p_variable = 'c_individual') THEN
    IF (p_valor) THEN
      PERFORM of_params_update('/formatos/ofx_estado_cuenta_rutas','fijos',
              of_params_get('/formatos/ofx_estado_cuenta_rutas','fx_principal'));
      PERFORM of_ofx_set('l_idsucaux','show=true');
      PERFORM of_ofx_set('ps_idsucaux','show=true');
      PERFORM of_ofx_set('ps_idproducto','show=true');
      PERFORM of_ofx_set('ps_idauxiliar','show=true');
      PERFORM of_ofx_set('c_asociado','set=false');
      PERFORM of_ofx_set('c_sucursal','set=false');
      PERFORM of_ofx_set('c_todos','set=false');
      PERFORM of_ofx_set('bt_aceptar','focus=true,sensitive=true');
    ELSE
      PERFORM of_ofx_set('l_idsucaux',   'hide=true');
      PERFORM of_ofx_set('ps_idsucaux',  'hide=true');
      PERFORM of_ofx_set('ps_idproducto','hide=true');
      PERFORM of_ofx_set('ps_idauxiliar','hide=true');
      --PERFORM of_ofx_set('bt_aceptar','sensitive=false');
    END IF;
  END IF;

  -- Clave de sucursal
  IF (p_variable = 'ps_idsucaux') THEN
    PERFORM * FROM params WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idsucaux');
    IF (FOUND) THEN
      UPDATE params SET valor = p_valor WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idsucaux');
    END IF;
  END IF;

  IF (p_variable = 'ps_idproducto') THEN
    PERFORM *
       FROM params
      WHERE (idparam,idelemento)=('/formatos/ofx_estado_cuenta_deudores','lista') AND
            valor LIKE '%'||ps_idproducto::TEXT||'%';
    IF (NOT FOUND) THEN
      PERFORM of_ofx_notice('error','El reporte no es válido para el producto '||ps_idproducto::TEXT);
      --PERFORM of_param_sesion_set_boolean('vsr_execute_validate','validate',FALSE);
      RETURN FALSE;
    ELSE
      PERFORM * FROM params WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idproducto');
      IF (FOUND) THEN
        UPDATE params SET valor = p_valor WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idproducto');
      END IF;
    END IF;
  END IF;

  -- Validando la clave de auxiliar.
  IF (p_variable = 'ps_idauxiliar') THEN
     
    PERFORM idsucaux,idproducto,idauxiliar
       FROM deudores
      WHERE (idsucaux::BIGINT,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
    IF (NOT FOUND) THEN
      PERFORM of_notice(null,'error','La clave de auxiliar '
                                     |+ ps_idsucaux::TEXT|+'-'|+ps_idproducto::TEXT|+'-'|+ps_idauxiliar::TEXT
                                     |+ ' no existe.');
      RETURN FALSE;
    ELSE
      PERFORM of_notice(null,'info','Consultando la cuenta '|+ ps_idsucaux::TEXT|+'-'|+ps_idproducto::TEXT|+'-'|+ps_idauxiliar::TEXT);
      PERFORM * FROM params WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idauxiliar');
      IF (FOUND) THEN
        UPDATE params SET valor = p_valor WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idauxiliar');
      END IF;
    END IF;
  END IF;

  -- Validamos el checkbox por Asociado
  IF (p_variable = 'c_asociado') THEN
    IF (p_valor) THEN
      UPDATE params
         SET valor = 'ofx_forma_ec_masiva_rutas_fs'
       WHERE (idparam,idelemento)=('/formatos/ofx_estado_cuenta_rutas','fijos'); -- Masiva
      PERFORM of_ofx_set('l_cliente',    'show=true');
      PERFORM of_ofx_set('ps_idsucursal','show=true,set='||ps_idsucursal::TEXT);
      PERFORM of_ofx_set('ps_idrol',     'show=true,set='||ps_idrol::TEXT);
      PERFORM of_ofx_set('ps_idasociado','show=true,set='||ps_idasociado::TEXT);
      PERFORM of_ofx_set('bt_aceptar',   'focus=true,sensitive=true');
      PERFORM of_ofx_set('c_individual', 'set=false');
      PERFORM of_ofx_set('c_sucursal', 'set=false');
      PERFORM of_ofx_set('c_todos', 'set=false');
      PERFORM of_notice(NULL,'info','Estado de Cuenta masiva por Asociado...');
    ELSE
      PERFORM of_ofx_set('l_cliente',    'hide=true');
      PERFORM of_ofx_set('ps_idsucursal','hide=true');
      PERFORM of_ofx_set('ps_idrol',     'hide=true');
      PERFORM of_ofx_set('ps_idasociado','hide=true');
      --PERFORM of_ofx_set('bt_aceptar',   'sensitive=false');
    END IF;
  END IF;

  --Validando la clave de asociado.
  IF (p_variable = 'ps_idasociado') THEN
    ps_idsucursal := of_ofx_get_integer('ps_idsucursal');
    ps_idrol      := of_ofx_get_integer('ps_idrol');
    ps_idasociado := of_ofx_get_integer('ps_idasociado');
    PERFORM *
       FROM asociados
      WHERE (idsucursal,idrol,idasociado)=(ps_idsucursal,ps_idrol,ps_idasociado);
    IF (NOT FOUND) THEN
      PERFORM of_notice(null,'error','La clave de cliente '
                                     |+ ps_idsucursal::TEXT|+'-'|+ps_idrol::TEXT|+'-'|+ps_idasociado::TEXT
                                     |+ ' no existe.');
      RETURN FALSE;
    ELSE
      PERFORM *
         FROM deudores AS d
        INNER JOIN asociados USING(idsucursal,idrol,idasociado)
        WHERE (d.idsucursal,d.idrol,d.idasociado)=(ps_idsucursal,ps_idrol,ps_idasociado) AND
              idproducto::TEXT = ANY(_lista) AND d.estatus IN (3,4);
      IF (NOT FOUND) THEN
        PERFORM of_notice(null,'error','El cliente '|+ ps_idsucursal::TEXT|+'-'|+ps_idrol::TEXT|+'-'|+ps_idasociado::TEXT|+
                                       ' no tiene cuentas activas para los productos especificados');
        RETURN FALSE;
      ELSE
        PERFORM of_notice(null,'info','Consultando cliente '|+ ps_idsucursal::TEXT|+'-'|+ps_idrol::TEXT|+'-'|+ps_idasociado::TEXT);
        RETURN TRUE;
      END IF;
    END IF;
  END IF;
  
  -- Validando el checkbox Por sucursal.
  IF (p_variable = 'c_sucursal') THEN
    IF (p_valor) THEN
      SELECT INTO r idsucursal,nombre
        FROM sucursales
       WHERE idsucursal = ps_idsucursal;
      UPDATE params
         SET valor = 'ofx_forma_ec_masiva_rutas_fs'
       WHERE (idparam,idelemento)=('/formatos/ofx_estado_cuenta_rutas','fijos'); -- Masiva
      PERFORM of_ofx_set('l_sucursal',     'show=true');
      PERFORM of_ofx_set('ps_sucursal',    'show=true,set='||ps_idsucursal::TEXT);
      PERFORM of_ofx_set('ps_nom_sucursal','show=true,set='||r.nombre);
      PERFORM of_ofx_set('c_individual',   'set=false');
      PERFORM of_ofx_set('c_asociado',     'set=false');
      PERFORM of_ofx_set('c_todos',        'set=false');
      PERFORM of_ofx_set('bt_aceptar',     'focus=true,sensitive=true');
      PERFORM of_notice(NULL,'info','Estado de Cuenta masiva por Sucursal...');
    ELSE
      PERFORM of_ofx_set('l_sucursal',        'hide=true');
      PERFORM of_ofx_set('ps_sucursal',       'hide=true');
      PERFORM of_ofx_set('ps_nom_sucursal',   'hide=true');
    END IF;
  END IF;

  -- Validando el campo de sucursal.
  IF (p_variable = 'ps_sucursal') THEN
      SELECT INTO r idsucursal,nombre
        FROM sucursales
       WHERE idsucursal = p_valor::BIGINT;
    IF NOT (FOUND) THEN
      PERFORM of_notice(NULL,'error','La sucursal '|+ p_valor |+' no existe!');
      PERFORM of_ofx_set('ps_nom_sucursal','show=true,set= *No definido*');
      RETURN FALSE;
    ELSE
      PERFORM of_ofx_set('ps_sucursal',    'show=true,set='||p_valor::TEXT);
      PERFORM of_ofx_set('ps_nom_sucursal','show=true,set='||r.nombre);
      PERFORM of_ofx_set('bt_aceptar',     'focus=true');
    END IF;
  END IF;

  
  -- Validando el checkbox de "Por todos"
  IF (p_variable = 'c_todos') THEN
    --RAISE NOTICE 'TODOOOOOOOOOOOOOOOOOOS';
    _gen_pdfs := of_params_get_boolean('/formatos/ofx_estado_cuenta_rutas','gen_pdfs');
    IF (p_valor) THEN
      --RAISE NOTICE 'valorrrrr';
      UPDATE params
         SET valor = 'ofx_forma_ec_masiva_rutas_fs'
       WHERE (idparam,idelemento)=('/formatos/ofx_estado_cuenta_rutas','fijos'); -- Masiva
      PERFORM of_ofx_set('c_individual', 'set=false');
      PERFORM of_ofx_set('c_asociado',   'set=false');
      PERFORM of_ofx_set('c_sucursal',   'set=false');
      -- DGZZH 12/08/2016 Generación de pdfs en directorio
      IF (_gen_pdfs) THEN
        --RAISE NOTICE 'ENTRRA PDF';
        PERFORM of_ofx_set('bt_aceptar',   'sensitive=false');
        PERFORM of_ofx_set('bt_gen_pdfs',  'hide=false');
        PERFORM of_ofx_set('hboxg_pdf'  ,  'hide=false');
      END IF;
      --PERFORM of_ofx_set('bt_aceptar',   'focus=true');
      PERFORM of_notice(NULL,'info','Estado de Cuenta masiva solo activos...');
    ELSE
      IF (_gen_pdfs) THEN
        PERFORM of_ofx_set('bt_aceptar',   'hide=false');
        PERFORM of_ofx_set('bt_gen_pdfs',  'hide=true');
         PERFORM of_ofx_set('hboxg_pdf'  ,  'hide=true');
      END IF;
    END IF;
  END IF;

  -- Validando parámetro de lista.
  IF (p_variable = 'lista') THEN
    n := array_upper(_lista,1);
    FOR i IN 1.. n LOOP
     IF NOT (trim(_lista[i]) = '') THEN
       PERFORM * FROM productos WHERE idproducto::TEXT = _lista[i]::TEXT;
       IF (FOUND) THEN
         IF NOT (of_producto_subtipo(_lista[i]::INT) = 'PRE') THEN
           PERFORM of_notice(NULL,'error','Producto '|+ _lista[i]::TEXT |+ ' no válido en parámetro de lista!');
           RETURN FALSE;
         END IF;
       ELSE
         PERFORM of_notice(NULL,'error','Producto '|+ _lista[i]::TEXT |+ ' no existe!');
         RETURN FALSE;
       END IF;
     END IF;
    END LOOP;
  END IF;

    -- Validando fecha incial.
  IF (p_variable = 'ps_dfecha') THEN
    PERFORM * FROM params WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','fechaini');
    IF (FOUND) THEN
      UPDATE params SET valor = p_valor WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','fechaini');
    END IF;
  END IF;
   
    -- Validando a fecha.
  IF (p_variable = 'ps_afecha') THEN
    IF (_afecha <  _dfecha) THEN
      PERFORM of_notice(NULL,'error','Error: La fecha Final debe de ser mayor a la fecha Inicial...!');
      RETURN FALSE;
    ELSE
      PERFORM of_notice(NULL,'info','Periodo del '|+to_char(_dfecha,'FMDD ')|+ to_char(_dfecha,'FMMonth')  -- El primer día del mes.
                                                  |+' - '
                                                  |+to_char(_afecha,'FMDD ')|+ to_char(_afecha,'FMMonth '));
      PERFORM * FROM params WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','idauxiliar');
      IF (FOUND) THEN
        UPDATE params SET valor = p_valor WHERE (idparam,idelemento)=('/formatos/ofx_detalle_ec','fechafin');
      END IF;
    END IF;
  END IF;
  
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;



 
SELECT of_db_drop_type('ofx_estado_cuenta_rutas','CASCADE');
CREATE TYPE ofx_estado_cuenta_rutas AS (
 suc_matriz_idsucursal    INTEGER,  
 suc_matriz_nom_sucursal  TEXT,     
 suc_matriz_calle         TEXT,     
 suc_matriz_colonia       TEXT,     
 suc_matriz_municipio     TEXT,     
 suc_matriz_estado        TEXT,     
 suc_matriz_rfc           TEXT,     
 idsucursal               INTEGER,   
 nom_sucursal             TEXT,     
 suc_calle                TEXT,     
 suc_colonia              TEXT,     
 suc_municipio            TEXT,     
 suc_estado               TEXT,     
 suc_rfc                  TEXT,     
 asociado                 TEXT,     
 nombre                   TEXT,     
 rfc                      TEXT,     
 curp                     TEXT,     
 email                    TEXT,     
 calle                    TEXT,     
 colonia                  TEXT,     
 municipio                TEXT,     
 estado                   TEXT,     
 periodo                  TEXT,     
 cuenta                   TEXT,     
 idsucaux                 TEXT,     
 idproducto               TEXT,     
 idauxiliar               TEXT,     
 credito                  TEXT,     
 tipoptmo                 TEXT,     
 montosolicitado          TEXT,     
 montoentregado           TEXT,     
 fechaentrega             DATE,     
 tasaio                   TEXT,     
 tasaio_venta             TEXT,     
 tasaio_x12               TEXT,     
 tasaim                   TEXT,     
 tasaim_venta             TEXT,     
 tasaim_x12               TEXT,     
 cat                      TEXT,     
 finalidad                TEXT,     
 plazo                    TEXT,     
 diasxplazo               TEXT,     
 vence                    DATE,     
 ultimomovimiento         DATE,     
 proximo_abono            DATE,     
 fe_limite_pago           TEXT,     
 tipoabono                TEXT,     
 saldofcha                TEXT,     
 gastos_cobranza          TEXT,     
 monto_vencido_cap        TEXT,     
 abono                    TEXT,     
 interes                  TEXT,     
 moratorio                TEXT,     
 comisiones               TEXT,     
 iva                      TEXT,     
 montopago                TEXT,     
 deudatotal               TEXT,     
 estatuscartera           TEXT,     
 diasmoracapital          TEXT,     
 diasmorainteres          TEXT,     
 xcentajecubierto         TEXT,     
 comision_pagado          TEXT,     
 fpago_comision           DATE,     
 pgovencido               TEXT,     
 pago_exijible            TEXT,     
 dt_fhora                 TEXT,     
 dt_ticket                TEXT,     
 dt_concepto              TEXT,     
 dt_cargo                 TEXT,     
 dt_abono                 TEXT,     
 dt_saldo                 TEXT,     
 dt_referencia            TEXT,     
 dt_capital               TEXT,     
 dt_interes               TEXT,     
 dt_moratorio             TEXT,     
 dt_iva                   TEXT,     
 psaldoini                TEXT,     
 pcargos                  TEXT,     
 pabonos                  TEXT,     
 psaldofin                TEXT,     
 tot_cargo                TEXT,     
 tot_capital              TEXT,     
 tot_interes              TEXT,     
 tot_moratorios           TEXT,     
 tot_iva                  TEXT,     
 tot_pago                 TEXT,     
 conducef                 TEXT,     
 fechreal                 DATE,     
 fechoperacion            DATE,     
 fechformato              TEXT,     
 dfecha                   DATE,     
 afecha                   DATE,     
 horas                    TEXT,     
 titulo                   TEXT,     
 pagina                   INTEGER,  
 npaginas                 INTEGER,  
 kv_data                  TEXT[],   
 diasperiodo              TEXT,     
 paginas                  INTEGER,  
 __params                 TEXT,

 totrecaudo               TEXT,                                      
 totmensualidad           TEXT,                                          
 totdeposito              TEXT,                                       
 totpago_finsus           TEXT,                                          
 totpago_terceros         TEXT,                                            
 otros_creditos               TEXT[],
 otros_creditos_mto_liquidar  TEXT[],
 otros_creditos_mesanterior   TEXT[],
 otros_creditos_mensualidad   TEXT[],
 otros_creditos_abcapital     TEXT[],
 otros_creditos_apcredito     TEXT[],
 otros_creditos_sdofinal      TEXT[],
 otros_creditos_capvigente    TEXT[],
 otros_creditos_capvencido    TEXT[],
 otros_creditos_intpendiente  TEXT[],
 otros_creditos_segauto       TEXT[],
 otros_creditos_segvida       TEXT[],
 otros_creditos_gps           TEXT[],
 otros_creditos_intdif        TEXT[],
 otros_creditos_adeudo        TEXT[],
 otros_creditos_nopago        TEXT[],
 otros_creditos_prod          TEXT[],
 otros_creditos_saldoliquidar  TEXT[],

 otros_creditos_proxmensualidad TEXT[],
 otros_creditos_proxvence       TEXT[],
 otros_creditos_noref           TEXT[],

 -- Datos prox mensualidad
 otros_creditos_proxabono    TEXT[],
 otros_creditos_proxinteres  TEXT[],
 otros_creditos_proxsegauto  TEXT[],
 otros_creditos_proxsegvida  TEXT[],
 otros_creditos_proxgps      TEXT[],
 otros_creditos_proxnopago   TEXT[],

 otros_creditos_fechaini     TEXT[], 
 otros_creditos_fechavence   TEXT[], 
 otros_creditos_cat          TEXT[], 
 otros_creditos_tasaio       TEXT[], 
 otros_creditos_tasaim       TEXT[], 
 otros_creditos_montoentregado TEXT[], 

 otros_creditos_detfecha      TEXT[],      
 otros_creditos_detconcepto   TEXT[],         
 otros_creditos_detreferencia   TEXT[],         
 otros_creditos_detcargo      TEXT[],      
 otros_creditos_detabono      TEXT[],      
 otros_creditos_detsaldo      TEXT[],      


 otros_creditos_prod_lc          TEXT[],
 otros_creditos_lc                TEXT[],
 otros_creditos_mesanterior_lc    TEXT[],
 otros_creditos_disposiciones_lc  TEXT[],
 otros_creditos_interes_lc  TEXT[],
 otros_creditos_apcredito_lc TEXT[],
 otros_creditos_sdofinal_lc  TEXT[],
 otros_creditos_capvigente_lc   TEXT[],
 otros_creditos_capvencido_lc   TEXT[],
 otros_creditos_intvenc_lc      TEXT[],
 otros_creditos_adeudo_lc      TEXT[],

 otros_creditos_proxmensualidad_lc TEXT[],
 otros_creditos_proxvence_lc       TEXT[],
 otros_creditos_noref_lc           TEXT[],
 otros_creditos_proxabono_lc       TEXT[],
 otros_creditos_proxinteres_lc     TEXT[], 
 otros_creditos_nopago_lc          TEXT[],

 otros_creditos_fechaini_lc        TEXT[], 
 otros_creditos_fechavence_lc      TEXT[], 
 otros_creditos_cat_lc             TEXT[], 
 otros_creditos_tasaio_lc          TEXT[], 
 otros_creditos_tasaim_lc          TEXT[], 
 otros_creditos_limite_lc          TEXT[],

otros_creditos_detfecha_lc        TEXT[],      
otros_creditos_detconcepto_lc     TEXT[],         
otros_creditos_detreferencia_lc   TEXT[],         
otros_creditos_detcargo_lc        TEXT[],      
otros_creditos_detabono_lc        TEXT[],      
otros_creditos_detsaldo_lc        TEXT[]      

);


CREATE OR REPLACE FUNCTION ofx_estado_cuenta_rutas() 
                   RETURNS SETOF ofx_estado_cuenta_rutas AS $$
DECLARE

  -- Variables
  r                       ofx_estado_cuenta_rutas%ROWTYPE;
  ra                      RECORD;
  rac                     RECORD;
  rdt                     RECORD;
  rco                     RECORD;
  rsdofdet                RECORD;
  rsdofdm                 RECORD;
  rcreddet                RECORD; 
  rctas                   RECORD;
  rctassdo                RECORD;
  rctasp                  RECORD; 
  rmasdat                 RECORD; 
  rlin                    RECORD; 
  rocc                    RECORD; 
  rocdm                    RECORD; 
  rctassdode             RECORD; 
  rctassdodet            RECORD;
  rlc                    RECORD;
  rdalc                   RECORD;
  rmclc                   RECORD;
  rretsf                  RECORD;
  rdepsf                  RECORD;

  ps_idsucaux             INTEGER:=0;
  ps_idproducto           INTEGER:=0;
  ps_idauxiliar           INTEGER:=0;
  ps_dfecha               DATE;
  ps_afecha               DATE;
  ps_idsucursal           INTEGER:=0;
  _nmovimientos           INTEGER;
  _limit_det              INTEGER;
  _kauxiliar              INTEGER;
  _detalle                TEXT;
  _res_mensual            TEXT:='';
  _tot_transaccion        NUMERIC:=0;
  _tot_litros             NUMERIC:=0;
  _tot_recaudo            NUMERIC:=0;
  _tot_precioxlt          NUMERIC:=0;
  _totales                TEXT;
  _recaudo                NUMERIC:=0;
  _deposito               NUMERIC:=0;
  pg_monto_fijo_segvida   NUMERIC;
  pg_monto_fijo_segunidad NUMERIC;
  pg_monto_fijo_gps       NUMERIC;
  factor_iva_io           NUMERIC;
  base_iva_io             NUMERIC;
  _seguro_vida            NUMERIC;
  _seguro_unidad          NUMERIC;
  _suguro_gps             NUMERIC;
  _mensualidad            NUMERIC:=0;
  _pago_finsus            NUMERIC:=0;
  _pago_terceros          NUMERIC:=0;
  _dt                     INTEGER;
  _idpago                 INTEGER;
  _vence                  DATE;
  _folio_ticket           INTEGER:=-1;
  _idsucauxref            INTEGER;
  _idproductoref          INTEGER;
  _idauxiliarref          INTEGER;
  _idcuenta_terceros      TEXT:='24010206001000000';
  _recaudo_periodo        NUMERIC:=0;
  _deposito_periodo       NUMERIC:=0;
  _pgo_terceros_periodo   NUMERIC:=0;
  _pgo_finsus_periodo     NUMERIC:=0;
  _saldo_periodo          NUMERIC:=0;
  --_fecha_mov              DATE;
  _finsus                 BOOLEAN; -- CLiente FINSUS
  _saldo_corte            NUMERIC:=0;
  _saldo_favor            NUMERIC:=0;
  _saldo_inicial          NUMERIC:=0;
  _dep_saldo_favor        NUMERIC:=0;
  _ret_saldo_favor        NUMERIC:=0;
  _saldo_anterior         NUMERIC:=0;
  _monto_pago             NUMERIC:=0;
  i                       INTEGER;
  _aplicacion_sdofavor    NUMERIC:=0;
  _saldo_favor_final      NUMERIC:=0;
  _deuda_inicial          NUMERIC:=0;
  _saldo_corte_ant        NUMERIC:=0;
  _recaudo_favor          NUMERIC:=0;
  _dv                     INTEGER; -- DGZZH Digito verificador
  _codigo                 TEXT;
  _referencia             TEXT;    -- Numero de referencia para acreditar depositos
  _referencia2            TEXT;    -- Numero de referencia para acreditar depositos
  _rocccodigo             INTEGER;      
  _roccdv                 TEXT;  
  _roccreferencia         TEXT;            
  _retiros_sdof NUMERIC;
  _sdoof                  NUMERIC;
  _sdoaf                  NUMERIC;
  _resumen_manual         BOOLEAN:=FALSE;
  _key                    INTEGER;
  _flag                   BOOLEAN:=FALSE;
  ii                      INTEGER:=0;
  _limit_det_recaudo      INTEGER:=0;
  _valid_emial            INTEGER;
  _nombrepfd              TEXT;
  _gen_pdfs               BOOLEAN;
  _ajuste4006oct          NUMERIC;
  _ajusterecaudooct       NUMERIC; 
  _ajustesdofavoroct      NUMERIC; 
  _r4006  RECORD;
  _pago4006    NUMERIC;

  -- detalle saldo a favor
  sdofavor_det_fecha      TEXT:='';                
  sdofavor_det_concepto   TEXT:='';                   
  sdofavor_det_referencia TEXT:='';                     
  sdofavor_det_retiro     TEXT:='';                 
  sdofavor_det_deposito   TEXT:='';                   
  sdofavor_det_saldo      TEXT:='';                

  credito_det_fecha       TEXT:='';                
  credito_det_concepto    TEXT:='';                   
  credito_det_referencia  TEXT:='';                     
  credito_det_retiro      TEXT:='';                 
  credito_det_deposito    TEXT:='';                   
  credito_det_saldo       TEXT:='';    

  recaudo_fecha          TEXT:='';               
  recaudo_transaccion    TEXT:='';                     
  recaudo_contrato_gazel TEXT:='';                        
  recaudo_litros         TEXT:='';                
  recaudo_precioxlt      TEXT:='';                   
  recaudo_recaudo        TEXT:='';                               

  nmsdo                   INTEGER:=0;
  _spd_sdofav             NUMERIC:=0.00;
  _tasabruta              NUMERIC;
  sdo_favor_sdoini        TEXT;
  sdo_favor_dep           TEXT;        
  sdo_favor_reca          TEXT;         
  sdo_favor_ret           TEXT;        
  sdo_favor_io            TEXT;       
  sdo_favor_sdocorte      TEXT;        
  _segvida                NUMERIC:=0.00;
  _segunidad              NUMERIC:=0.00;
  _gps                    NUMERIC:=0.00;
  _com                    NUMERIC:=0.00;
  _comdif                    NUMERIC:=0.00;
  _comact                 NUMERIC:=0.00;
  mensualidad_periodo    NUMERIC:=0.00;
  _res_ctas              TEXT:='';               
  _res_ctas_saldos       TEXT:='';   
  _res_ctas_saldos_sum   NUMERIC:=0.00;

  _poliza_seg_auto       TEXT:='';                     
  _numeco                TEXT:='';            
  _vin                   TEXT:='';         
  _vigencia_polsegauto   DATE:=NULL;  
  _noc                   INTEGER:=0;
  _nocl                   INTEGER:=0;
  _segautooc            NUMERIC;      
  _segvidaoc            NUMERIC;      
  _gpsoc                NUMERIC;  
  _idpagopp              INTEGER;
  _ocdeuda              NUMERIC;
  _idpagoppact          INTEGER;  
  _ocmensualidad        NUMERIC;    
  _menssegvida          NUMERIC;    
  _menssegauto          NUMERIC;    
  pg_factor_iva_io  NUMERIC:=0.00; 
  _mensgps          NUMERIC; 

  _venceppsig              DATE;
  _abonoppsig             NUMERIC;   
  _ioppsig                NUMERIC; 
  _idpagoppsig            INTEGER;

  _rctasvence             TEXT;
  _rctascat               TEXT;

  _otros_creditos_detfecha   TEXT;
  _otros_creditos_detconcepto   TEXT;
  _otros_creditos_detreferencia   TEXT;
  _otros_creditos_detcargo   TEXT;
  _otros_creditos_detabono   TEXT;
  _otros_creditos_detsaldo   TEXT;

  _otros_creditos_detfecha_lc   TEXT;
  _otros_creditos_detconcepto_lc   TEXT;
  _otros_creditos_detreferencia_lc   TEXT;
  _otros_creditos_detcargo_lc   TEXT;
  _otros_creditos_detabono_lc   TEXT;
  _otros_creditos_detsaldo_lc   TEXT;

  _disposiciones            NUMERIC;
  _interes                  NUMERIC;
  _capvigente               NUMERIC;
  _abcapital                NUMERIC;

  _deudaanterior            NUMERIC;
  _credidpagoppsig          INTEGER;       
  _credvenceppsig           DATE;      
  _credabonoppsig           NUMERIC;      
  _credioppsig              NUMERIC;   
  _proxsegvida              NUMERIC;  
  _proxsegauto                 NUMERIC;  
  _proxsegunidad            NUMERIC;      
  _proxgps                  NUMERIC;
  _proxcom                  NUMERIC;  
  _credproxsegvida         NUMERIC;         
  _credproxsegunidad       NUMERIC;           
  _credproxgps             NUMERIC;     
  _credproxcom             NUMERIC;
  _credproxcomdif             NUMERIC;
  _idpagoppactcre          INTEGER;      
  _segvidaact              NUMERIC;  
  _segunidadact            NUMERIC;    
  _gpsact                  NUMERIC;      
  _credproxmensualidad     NUMERIC;      
  _iodesc                  NUMERIC;      
  _iodincr                  NUMERIC;
   _iodifex                  NUMERIC;
   _iodifnoex             NUMERIC;
   _comdifact             NUMERIC;
   _menscom               NUMERIC;  
   _menscomdif            NUMERIC; 
   rctassdosaldo          NUMERIC;
   rctassdosaldofav       NUMERIC;
   _pnombre          TEXT;
   _iopagado         NUMERIC;
   _intdif            NUMERIC;
   _referenciad          TEXT;
   _deudamesanterior    NUMERIC;
   _credidpagoppact    INTEGER;           
   _credvenceppact     DATE;          
   _credabonoppact     NUMERIC;          
   _credioppact        NUMERIC;  
   _segvidaactm        NUMERIC;        
   _segunidadactm      NUMERIC;           
   _gpsactm            NUMERIC;    
   _comactm            NUMERIC;    
   _comdifactm         NUMERIC;              
   _saldoc             NUMERIC;  
   _montovencidoc      NUMERIC;  
   _deudamesactual    NUMERIC;       
   _comdifid          INTEGER;
   _credproxcomdesc   NUMERIC;
   _comisiondifca    NUMERIC;  
   _comisiondifcaab  NUMERIC; 
   _montovencidoanterior  NUMERIC;
   _saldoanterior        NUMERIC;
   _iopendant            NUMERIC;
   _abcredito           NUMERIC;
   _disposicionesm      NUMERIC:=0.00;
   _cargoslc            NUMERIC:=0.00;
   _dispacreidot        NUMERIC:=0.00;
   _totrecaudo          NUMERIC:=0.00;     
   _totmensualidad      NUMERIC:=0.00;         
   _totdeposito         NUMERIC:=0.00;      
   _totpago_finsus      NUMERIC:=0.00;         
   _totpago_terceros    NUMERIC:=0.00;   
   _tipoprestamo        INTEGER;    
   _credioimpsig        NUMERIC:=0.00;
   _pagouno        DATE;    
   _fechaultperiodoant  DATE;
   _adeudopendiente       TEXT;  
BEGIN 
  pg_factor_iva_io := ROUND(ofpn('/socios/productos/prestamos','iva_io',0.00)/100.00,2) * 
                      ROUND(ofpn('/socios/productos/prestamos','base_iva_io',0.00)/100.00,2);
  
  ps_idsucaux      := of_ofx_get('ps_idsucaux');
  ps_idproducto    := of_ofx_get('ps_idproducto');
  ps_idauxiliar    := of_ofx_get('ps_idauxiliar');
  ps_dfecha        := of_ofx_get('ps_dfecha');
  ps_afecha        := of_ofx_get('ps_afecha');

  r.otros_creditos_prod           := '{}';           
  r.otros_creditos_prod_lc           := '{}';   
  r.otros_creditos                := '{}';          
  r.otros_creditos_mto_liquidar   := '{}';                       
  r.otros_creditos_mesanterior    := '{}';                      
  r.otros_creditos_mensualidad    := '{}';                      
  r.otros_creditos_abcapital      := '{}';                    
  r.otros_creditos_apcredito      := '{}';                    
  r.otros_creditos_sdofinal       := '{}';                   
  r.otros_creditos_capvigente     := '{}';                     
  r.otros_creditos_capvencido     := '{}';                     
  r.otros_creditos_intpendiente   := '{}';                       
  r.otros_creditos_segauto        := '{}';                  
  r.otros_creditos_segvida        := '{}';                  
  r.otros_creditos_gps            := '{}';              
  r.otros_creditos_intdif         := '{}';                 
  r.otros_creditos_adeudo         := '{}'; 
  r.otros_creditos_saldoliquidar  := '{}';        
  
  r.otros_creditos_proxmensualidad := '{}';
  r.otros_creditos_proxvence       := '{}';
  r.otros_creditos_noref           := '{}';

 -- Datos prox mensualidad
 r.otros_creditos_proxabono       := '{}';
 r.otros_creditos_proxinteres     := '{}';
 r.otros_creditos_proxsegauto     := '{}';
 r.otros_creditos_proxsegvida     := '{}';
 r.otros_creditos_proxgps         := '{}';
 r.otros_creditos_proxnopago      := '{}';
  r.otros_creditos_fechaini       := '{}';             
  r.otros_creditos_fechavence     := '{}';               
  r.otros_creditos_cat            := '{}';        
  r.otros_creditos_tasaio         := '{}';           
  r.otros_creditos_tasaim         := '{}';           
  r.otros_creditos_montoentregado := '{}';                   

  r.otros_creditos_detfecha       := '{}';       
  r.otros_creditos_detconcepto    := '{}';          
  r.otros_creditos_detconcepto    := '{}';          
  r.otros_creditos_detcargo       := '{}';       
  r.otros_creditos_detabono       := '{}';       
  r.otros_creditos_detsaldo       := '{}';    

  _otros_creditos_detfecha        :='';        
  _otros_creditos_detconcepto     :='';           
  _otros_creditos_detreferencia   :='';             
  _otros_creditos_detcargo        :='';        
  _otros_creditos_detabono        :='';        
  _otros_creditos_detsaldo        :='';             

  r.otros_creditos_mesanterior_lc  := '{}';  
  r.otros_creditos_disposiciones_lc := '{}';
  r.otros_creditos_interes_lc        := '{}';
  r.otros_creditos_apcredito_lc        := '{}';
  r.otros_creditos_sdofinal_lc   := '{}';     
  r.otros_creditos_capvigente_lc := '{}';
  r.otros_creditos_capvencido_lc := '{}';
  r.otros_creditos_intvenc_lc    := '{}';
  r.otros_creditos_adeudo_lc     := '{}';

  r.otros_creditos_proxmensualidad_lc :='{}';
  r.otros_creditos_proxvence_lc       :='{}';
  r.otros_creditos_noref_lc           :='{}';
  r.otros_creditos_proxabono_lc       :='{}';
  r.otros_creditos_proxinteres_lc     :='{}';
  r.otros_creditos_nopago_lc          :='{}';
  
  r.otros_creditos_fechaini_lc   := '{}';            
  r.otros_creditos_fechavence_lc := '{}';              
  r.otros_creditos_cat_lc        := '{}';       
  r.otros_creditos_tasaio_lc     := '{}';          
  r.otros_creditos_tasaim_lc     := '{}';          
  r.otros_creditos_limite_lc     := '{}';  

  r.otros_creditos_detfecha_lc      := '{}';
  r.otros_creditos_detconcepto_lc   := '{}';
  r.otros_creditos_detreferencia_lc := '{}';
  r.otros_creditos_detcargo_lc      := '{}';
  r.otros_creditos_detabono_lc      := '{}';
  r.otros_creditos_detsaldo_lc      := '{}';
  _otros_creditos_detfecha_lc        :='';        
  _otros_creditos_detconcepto_lc     :='';           
  _otros_creditos_detreferencia_lc   :='';             
  _otros_creditos_detcargo_lc        :='';        
  _otros_creditos_detabono_lc        :='';        
  _otros_creditos_detsaldo_lc        :='';     


  PERFORM of_param_sesion_set('vsr_vars','ps_idsucaux',ps_idsucaux::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_idproducto',ps_idproducto::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_idauxiliar',ps_idauxiliar::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_dfecha',ps_dfecha::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_afecha',ps_afecha::TEXT);

  factor_iva_io    := of_params_get('/socios/productos/prestamos','iva_io');
  base_iva_io      := of_params_get('/socios/productos/prestamos','base_iva_io');
  factor_iva_io    := ROUND((factor_iva_io /100.00),2);
  base_iva_io      := ROUND((base_iva_io /100.00),2);
  factor_iva_io    := factor_iva_io * base_iva_io;
  -- Obteniendo el limite de detalle para los movimientos.
  _limit_det_recaudo := of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_limite');
  _gen_pdfs          := of_params_get_boolean('/formatos/ofx_estado_cuenta_rutas','gen_pdfs');
  
  SELECT INTO r * FROM ofx_forma_ec_estandar();
  DELETE FROM resumen_mensual 
        WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
  --SELECT INTO res * FROM resumen_mensual WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
  --RAISE NOTICE 'resumen %',res;  
  r.__params := 'glds=gld01;gld02;gld03;gld04;gld05;';
  -- RFC de SUSTENTABLE para definir columna PAGO DE FINANCIERA SUSTENTABLE
  IF (r.suc_matriz_rfc = 'FSM121019LM6') THEN
    _finsus        := TRUE;
  ELSE
    _finsus        := FALSE;
  END IF;
  _idcuenta_terceros := of_params_get('/formatos/ofx_estado_cuenta_rutas','idcuenta_tercero');
  _detalle           := '';
  i                  := 0 ;
  --ps_idsucursal    := of_ofx_get('idsucaux');
  --PERFORM of_param_sesion_raise(NULL);
  -- Obniendo clave de kauxiliar
  SELECT INTO _kauxiliar,_referenciad,_tipoprestamo kauxiliar,referencia,tipoprestamo
    FROM deudores
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);

  PERFORM * FROM edocta_res_mensual WHERE trim(auxiliar) = ps_idsucaux|+'-'|+ps_idproducto|+'-'|+ps_idauxiliar LIMIT 1;
  IF (FOUND) THEN -- Resumen mensual manipulado de forma manual por el usuario

    FOR ra IN SELECT *
                FROM edocta_res_mensual
               WHERE trim(auxiliar) = ps_idsucaux|+'-'|+ps_idproducto|+'-'|+ps_idauxiliar ORDER BY id LOOP
      _res_mensual     := _res_mensual |+
                          of_rellena(ra.fecha,24,' ',1)                        |+ ' ' |+ -- FECHA
                          to_char(coalesce(ra.recaudo,0),'999,999,990.00')     |+ ' ' |+ -- RECAUDOS
                          to_char(coalesce(ra.mensualidad,0),'999,999,990.00') |+ ' ' |+ -- MENSUALIDAD
                          to_char(coalesce(ra.deposito,0),'999,999,990.00')    |+ ' ' |+ -- DEPOSITOS
                          of_si(_finsus,'',to_char(coalesce(ra.pgo_tercero,0),'999,999,990.00') |+ ' ') |+ -- PGO FINSUS
                          to_char(of_si(_finsus,coalesce(ra.pgo_tercero),0),'999,999,990.00') |+ ' ' |+ -- PGO TERCEROS SIEMPRE EN CEROS PARA BEXICA
                          to_char(ra.saldo_mes,'999,999,990.00')               |+ ' ' |+ -- SALDO DEL MES
                          to_char(coalesce(ra.saldo_corte ,0),'999,999,990.00')|+ ' ' |+ -- SALDO AL CORTE
                          E'\n';
      _saldo_anterior := ra.saldo_corte;
      IF (lower(of_fecha_nombre(of_fecha_dum(ps_afecha),1)) = lower(trim(ra.fecha))) THEN
        _recaudo_periodo      := coalesce(ra.recaudo,0);
        _deposito_periodo     := coalesce(ra.deposito,0);
        _pgo_terceros_periodo := of_(_finsus,ra.pgo_tercero,0);
        _pgo_finsus_periodo   := ra.pgo_tercero;
        _monto_pago           := ra.mensualidad;
      END IF;
    END LOOP;
    _resumen_manual := TRUE;
  END IF;
  -- Obteniedo saldo a favor con producto 2001
  SELECT INTO  _idsucauxref, _idproductoref, _idauxiliarref
         idsucauxref,idproductoref,idauxiliarref
    FROM of_auxiliar_ref(ps_idsucaux,ps_idproducto,ps_idauxiliar,2001);
  
  -- La fecha de corte o inicial es al día 29/02/2016
  SELECT INTO _deuda_inicial sum(abono+interes_total+costos_asociados)
    FROM cartera
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND fecha='29/02/2016';
  
  SELECT INTO _saldo_favor,_tasabruta saldoinicial,tasa
    FROM acreedores 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) AND referencia='import';
  
  SELECT INTO _tasabruta tasa
    FROM acreedores 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) ;   
  _tasabruta := COALESCE(_tasabruta,0.00);
  --IF (NOT FOUND) THEN
  --  _saldo_favor  := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,'29/02/2016');
  --END IF;
  SELECT INTO _pagouno vence 
    FROM planpago
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND idpago=1;
  
  _fechaultperiodoant := of_fecha_dpm(_pagouno)-1;  
  _saldo_favor  := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,_fechaultperiodoant);
  _saldo_favor  := COALESCE(_saldo_favor,0.00);
  --RAISE NOTICE 'DEUDA INICIAL %',_deuda_inicial;  
  -- _saldo_corte_ant := _saldo_favor  + (_deuda_inicial*-1);
  -- _saldo_corte := _saldo_favor  + (_deuda_inicial*-1);
  _saldo_corte_ant := (coalesce(_deuda_inicial,0)*-1) + coalesce(_saldo_favor,0);
  RAISE NOTICE 'SALDO INI: %',_saldo_corte_ant;
  --_saldo_inicial  := _saldo_favor + _saldo_corte_ant;

  IF (NOT _resumen_manual) THEN
    _res_mensual  := of_rellena(' ',24,' ', 1)   |+ ' ' |+ -- FECHA
                     of_rellena('0.00',15,' ',2) |+ ' ' |+ -- RECAUDOS
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                      to_char(coalesce(_saldo_corte_ant,0),'999,999,990.00')|+ E'\n';
  END IF;
  -- Obniendo Numero de contrato GAZEL
  -- DGZZH 04/08/2016 contrato_gazel guardarlo en una variable aparte
  SELECT INTO rco contrato_gazel FROM ofx_multicampos_auxiliar_masdatos_sus(_kauxiliar);
  -- Obteniedo numero de detalle de movimientos
  SELECT INTO _nmovimientos count(*)
    FROM planpago
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
         vence BETWEEN '01/03/2016' AND ps_afecha;
  _nmovimientos := coalesce(_nmovimientos,0);
  
  IF (_nmovimientos > 0) THEN
    SELECT INTO pg_monto_fijo_segvida, pg_monto_fijo_segunidad, pg_monto_fijo_gps
                COALESCE(segvida,0.00), COALESCE(segunidad,0.00), COALESCE(gps,0.00)
      FROM ofx_multicampos_sustentable.auxiliar_masdatos
     WHERE kauxiliar = _kauxiliar;

    --FOR ra IN  SELECT count(*), periodo
    --             FROM detalle_auxiliar
    --            WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
    --                  fecha BETWEEN ps_dfecha AND ps_afecha AND cargo = 0
    --            GROUP BY periodo
    --            ORDER BY periodo ASC LOOP

    --FOR ra IN SELECT of_periodo(vence)::INT AS periodo
    --            FROM planpago
    --           WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
    --                 --vence='31/05/2016' ORDER BY idpago ASC LOOP
    --                 vence BETWEEN '01/03/2016' AND ps_afecha ORDER BY idpago ASC LOOP
    FOR ra IN SELECT * FROM of_periodos_entre_fechas(of_si(_pagouno <= '31/03/2016', '31/03/2016', _pagouno::TEXT)::DATE, ps_afecha) LOOP                     
      i := i + 1;
      --RAISE NOTICE 'PERIODO %',ra.periodo;
      -- RFC de SUSTENTABLE para definir columna PAGO DE FINANCIERA SUSTENTABLE
      SELECT INTO _pago_finsus coalesce(sum(cargo),0)
        FROM detalle_auxiliar AS dt
        LEFT JOIN detalle_polizas USING(idsucpol,periodo,tipopol,idpoliza)
       WHERE (dt.idsucaux,dt.idproducto,dt.idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) AND
             idcuenta = _idcuenta_terceros AND dt.periodo = ra.periodo;
      --_saldo_corte_ant := _saldo_corte_ant - _retiros_sdof;

      IF (r.suc_matriz_rfc = 'FSM121019LM6') THEN
       -- _pago_terceros := _pago_finsus;
       -- _pago_finsus   := 0;
        _finsus        := TRUE;
      ELSE
        _finsus        := FALSE;
      END IF;
      _saldo_periodo        := 0.00;
      _recaudo              := 0.00;
      _deposito             := 0.00;
      _aplicacion_sdofavor  := 0.00;      
      -- Obtenemos la mensualidad.
      
      SELECT INTO _vence, _idpago, _mensualidad vence, idpago,
                  of_si(of_iva_general(ps_idsucaux,ps_idproducto,ps_idsucaux,_tipoprestamo,ps_afecha),
                   (round(abono + io,2) + round((round(io,2)*round(factor_iva_io,2)),2)), abono + io )  AS mensualidad
        FROM planpago
       WHERE (idsucaux,idproducto,idauxiliar) = (ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
             of_periodo(vence)::INT = ra.periodo;
      --RAISE NOTICE '============= 0 _mensualidad %',_mensualidad;
      IF (coalesce(_idpago,0) = 1) THEN
        _dt            :=  _vence - r.fechaentrega;
        
        SELECT INTO _seguro_vida segvid_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
        IF (COALESCE(_seguro_vida,0.00)=0.00) THEN
          _seguro_vida   := COALESCE(trunc(((pg_monto_fijo_segvida / 30) * _dt::INTEGER),2),0.00); -- Sin iva
        END IF;
        
        SELECT INTO _seguro_unidad seguni_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
        IF (COALESCE(_seguro_unidad,0.00)=0.00) THEN
          _seguro_unidad   := COALESCE(trunc(((pg_monto_fijo_segunidad / 30) * _dt::INTEGER),2),0.00); -- Sin iva
        END IF;

        SELECT INTO _suguro_gps gps_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
        IF (COALESCE(_suguro_gps,0.00)=0.00) THEN
          _suguro_gps   := COALESCE(trunc(((pg_monto_fijo_gps / 30) * _dt::INTEGER),2),0.00); -- Sin iva
        END IF;              
      ELSE
        _seguro_vida   := COALESCE(trunc(pg_monto_fijo_segvida,2),0.00);
        _seguro_unidad := COALESCE(trunc(pg_monto_fijo_segunidad,2),0.00);
        _suguro_gps    := COALESCE(trunc(pg_monto_fijo_gps,2),0.00);
        --RAISE NOTICE 'MENSUALIDADDDDDDD %, %, %',_seguro_vida, _seguro_unidad, _suguro_gps;             
      END IF; 
      _seguro_unidad   := of_si(TRUE,_seguro_unidad * (round(factor_iva_io,2)) + _seguro_unidad, _seguro_unidad);
      _suguro_gps      := of_si(TRUE,_suguro_gps * (round(factor_iva_io,2)) + _suguro_gps, _suguro_gps);      
      --RAISE NOTICE 'MENSUALIDAD %',_seguro_vida + _seguro_unidad + _suguro_gps;             
      SELECT INTO _iodesc, _iodincr io_desc,io_incr
        FROM ppv.planpago_escalonado 
       WHERE kauxiliar=_kauxiliar AND idpago=_idpago;  
      _iodesc   :=  COALESCE(_iodesc,0.00);
      _iodincr  :=  COALESCE(_iodincr,0.00);   
      SELECT INTO _comdifactm,_comdifid comision_id,com_id_cero FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
      IF (_idpago<=_comdifid) THEN
        _comdifactm := 0.00;
      END IF;
      _comdifactm := COALESCE(_comdifactm,0.00);

      --_mensualidad := _mensualidad-(_iodesc+_iodincr);
      -- Sim importar si traía vencido del periodo anterior el saldo del periodo siempre es igual a la mensualidad. :/ raro...
      --RAISE NOTICE ' 1 _saldo_periodo %, _mensualidad %, _seguro_vida % _seguro_unidad % _suguro_gps %', _saldo_periodo, _mensualidad, _seguro_vida, _seguro_unidad, _suguro_gps;
      --_saldo_periodo := ROUND((_mensualidad + (_seguro_vida + _seguro_unidad + _suguro_gps))* -1,2);
      _saldo_periodo := ROUND(((_mensualidad-(_iodesc+_iodincr))+(_comdifactm) + (_seguro_vida + _seguro_unidad + _suguro_gps))* -1,2);
      --RAISE NOTICE ' 2 _saldo_periodo %, _mensualidad %, _seguro_vida % _seguro_unidad % _suguro_gps %', _saldo_periodo, _mensualidad, _seguro_vida, _seguro_unidad, _suguro_gps;
      _mensualidad   := _saldo_periodo*-1; -- A negativo porque está en contra del cliente.
      _comdifactm := 0.00;
      
      /** Nuevo código para el armado del resumen del mes.**/
      -- El recaudo sale del detalle cargado por el archivo.
      IF (of_periodo(_pagouno)::INTEGER<=202106) THEN
        SELECT INTO _recaudo sum(recaudo)
          FROM ofx_recaudo.detalle_auxiliar
         WHERE trim(contrato_gazel)= trim(rco.contrato_gazel) AND of_periodo(fecha)::INTEGER=ra.periodo GROUP BY contrato_gazel;
      ELSE
        SELECT INTO _recaudo sum(abono) 
          FROM detalle_auxiliar WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) AND periodo=ra.periodo AND referencia='Recaudo de abonos';
      END IF;       
      _recaudo := COALESCE(_recaudo,0.00);
      -- Todos los depositos al producto de saldo a favor.
      SELECT INTO _dep_saldo_favor sum(abono) 
        FROM detalle_auxiliar 
       WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) AND periodo=ra.periodo AND referencia!~'Recaudo';

      IF (ra.periodo=201611) THEN
        SELECT INTO _ajustesdofavoroct COALESCE(abono,0.00) FROM detalle_auxiliar                                                              
          WHERE (idsucpol,periodo,tipopol,idpoliza)=(1,201611,3,2) AND 
                (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref); 

        _dep_saldo_favor := _dep_saldo_favor - COALESCE(_ajustesdofavoroct,0.00);
      END IF;       

      
      IF (ra.periodo=201610) THEN
        
        SELECT INTO _ajustesdofavoroct COALESCE(abono,0.00) FROM detalle_auxiliar                                                              
          WHERE (idsucpol,periodo,tipopol,idpoliza)=(1,201611,3,2) AND 
                (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref); 

        _dep_saldo_favor := _dep_saldo_favor + COALESCE(_ajustesdofavoroct,0.00);

      END IF;       
      
      SELECT INTO _retiros_sdof coalesce(sum(cargo),0)
        FROM detalle_auxiliar
       WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) AND periodo=ra.periodo;

      _dep_saldo_favor := COALESCE(_dep_saldo_favor,0.00) ;--- COALESCE(_retiros_sdof,0.00);
      -- Todos los depositos al préstamo.
      SELECT INTO _deposito,_abcapital sum(abono+montoio+montoca+montoimp),sum(abono) 
        FROM detalle_auxiliar 
       WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND periodo=ra.periodo;
      _deposito := COALESCE(_deposito,0.00);

      SELECT INTO _iopagado sum(montoio)
        FROM detalle_auxiliar 
       WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) ;

       --RAISE NOTICE 'Periodo: % DEPOSITO: deposito %, dep saldo favor: %, _retiros_sdof %',ra.periodo,COALESCE(_deposito,0.00),COALESCE(_dep_saldo_favor,0.00),COALESCE(_retiros_sdof,0.00);
      _deposito := (COALESCE(_deposito,0.00) + COALESCE(_dep_saldo_favor,0.00)) - COALESCE(_retiros_sdof,0.00);
       --RAISE NOTICE ' 2 oPeriodo: % DEPOSITO: deposito %, dep saldo favor: %, _retiros_sdof %',ra.periodo,COALESCE(_deposito,0.00),COALESCE(_dep_saldo_favor,0.00),COALESCE(_retiros_sdof,0.00);
      IF (ra.periodo=201610) THEN
        SELECT INTO _ajusterecaudooct COALESCE(abono+montoio+montoca,0.00) FROM detalle_auxiliar 
          WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
                fecha='01/11/2016' AND referencia='ajuste recaudo';
        _deposito := _deposito + COALESCE(_ajusterecaudooct,0.00);
        --RAISE NOTICE 'AQUIIIIIIIIIIIIIIIIIIIIIIIIIIIIII';
              --RAISE NOTICE 'DEPOSITO 2 %',_ajusterecaudooct;

      END IF;

      IF (ra.periodo>=201611) THEN
      _pago4006  := 0.00;
        SELECT INTO _r4006 * FROM auxiliares_ref 
          WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
                idproductoref=4006; 
        
        SELECT INTO _pago4006 sum(abono) 
          FROM detalle_auxiliar 
         WHERE (idsucaux,idproducto,idauxiliar)=(_r4006.idsucauxref,_r4006.idproductoref,_r4006.idauxiliarref) AND periodo=ra.periodo;
        
        _deposito := _deposito + COALESCE(_pago4006,0.00);

      END IF;      

      
      -- Productos de linea de credito ligados al crédito principal
      FOR rlc IN SELECT idsucauxref,idproductoref,idauxiliarref 
                   FROM auxiliares_ref 
                  WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
                        of_producto_subtipo(idproductoref)='PRE' AND 
                        (SELECT tipocalculo FROM productos WHERE idproducto=auxiliares_ref.idproductoref)=9970 
                   GROUP BY idsucauxref,idproductoref,idauxiliarref,of_producto_subtipo(idproductoref) 
                   ORDER BY of_producto_subtipo(idproductoref),idproductoref LOOP
        
        SELECT INTO _cargoslc sum(cargo)
          FROM detalle_auxiliar 
         WHERE (idsucaux,idproducto,idauxiliar)=(rlc.idsucauxref,rlc.idproductoref,rlc.idauxiliarref) AND periodo=ra.periodo::integer AND cargo>0.00 ;

--        -- Buscamos los cargos
--        FOR rdalc IN SELECT cargo,abono,folio_ticket
--                       FROM detalle_auxiliar 
--                      WHERE (idsucaux,idproducto,idauxiliar)=(rlc.idsucauxref,rlc.idproductoref,rlc.idauxiliarref) AND periodo=ra.periodo::integer AND cargo>0.00 LOOP
--          -- Los sumamos 
--          _cargoslc       := _cargoslc + rdalc.cargo;
--          
--          -- Buscamos si el cargo se aplicó al crédito principal
--          SELECT INTO rmclc cargo,abono,montoio,montoim,montoimp,montoca 
--            FROM detalle_auxiliar 
--           WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND folio_ticket=rdalc.folio_ticket;
--          IF (FOUND) THEN -- se aplicó, 
--            _dispacreidot := _dispacreidot + rdalc.cargo;
--          END IF;
--
--        END LOOP;
        _disposicionesm := _disposicionesm + COALESCE(_cargoslc,0.00);
--       _cargoslc := 0.00;
--
      END LOOP;

      _retiros_sdof  := 0.00;
      _pago_terceros := 0.00;
      FOR rretsf IN SELECT *
                       FROM detalle_auxiliar
                      WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) AND periodo=ra.periodo and cargo>0.00 AND 
                            referencia!~'aplicación a crédito'
      LOOP
        _retiros_sdof  := _retiros_sdof + COALESCE(rretsf.cargo,0.00);
        _pago_terceros := _pago_terceros + COALESCE(rretsf.cargo,0.00);
        --RAISE NOTICE 'ra.periodo % _retiros_sdof %, _pago_terceros %',ra.periodo,_retiros_sdof,_pago_terceros;
        SELECT INTO rdepsf sum(abono+montoio+montoim+montoimp+montoca) AS abono 
          FROM detalle_auxiliar 
         WHERE folio_ticket = rretsf.folio_ticket  AND  (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
        --IF (FOUND) THEN
        --_pago_terceros := _pago_terceros + _retiros_sdof;
        --  --RAISE NOTICE 'antes ra.periodo % _pago_terceros, % abono %',ra.periodo,_pago_terceros,COALESCE(rdepsf.abono,0.00);
        _pago_terceros := _pago_terceros - COALESCE(rdepsf.abono,0.00);
        --  RAISE NOTICE 'ra.periodo % _pago_terceros %',ra.periodo,_pago_terceros;
        --END IF;
      END LOOP;

     -- RAISE NOTICE '_deposito % _dispacreidot %',_deposito,_dispacreidot;
      _deposito := _deposito - _disposicionesm;

      --RAISE NOTICE ' DEPOSITO MIO %',_deposito;
      --_deposito := of_si(_deposito<0,0.00,_deposito);
      --RAISE NOTICE '===================== sdo periodo %',_saldo_periodo;
      _saldo_periodo := COALESCE(_saldo_periodo,0) + (COALESCE(_recaudo,0)+COALESCE(_deposito,0)- COALESCE(_pago_terceros,0.00)) + COALESCE(_disposicionesm,0);
      --RAISE NOTICE '===================== sdo periodo %, %, %',COALESCE(_saldo_periodo,0) ,COALESCE(_recaudo,0),COALESCE(_deposito,0);
      
      IF (ra.periodo=201610) THEN
        SELECT INTO _ajuste4006oct COALESCE(montoref,0.00) FROM auxiliares_ref 
          WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
                idproductoref=4006; 
        _saldo_periodo := _saldo_periodo - COALESCE(_ajuste4006oct,0.00);
      END IF;

     -- IF (ra.periodo>=201611) THEN
     -- _pago4006  := 0.00;
     --   SELECT INTO _r4006 * FROM auxiliares_ref 
     --     WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
     --           idproductoref=4006; 
     --   
     --   SELECT INTO _pago4006 sum(abono) 
     --     FROM detalle_auxiliar 
     --    WHERE (idsucaux,idproducto,idauxiliar)=(_r4006.idsucaux,_r4006.idproducto,_r4006.idauxiliar) AND periodo=ra.periodo;
--
--     --   _saldo_periodo := _saldo_periodo + COALESCE(_pago4006,0.00);
     -- END IF;

      _saldo_corte := (_saldo_periodo) + (_saldo_corte_ant) ;--- COALESCE(_retiros_sdof,0.00);

      IF (i = _nmovimientos-1) THEN
        IF (_resumen_manual AND ra.periodo >= 201607) THEN
          _saldo_anterior := _saldo_corte;
        ELSIF (NOT _resumen_manual) THEN
          _saldo_anterior := _saldo_corte;
        END IF;
      END IF;

      IF (of_periodo(ps_afecha)::INT = ra.periodo) THEN
        _recaudo_periodo  := coalesce(_recaudo,0);
        _deposito_periodo := coalesce(_deposito,0);
        _pgo_terceros_periodo := _pago_terceros;
        _pgo_finsus_periodo   := _pago_finsus;
        _monto_pago           := _mensualidad;
        --_mensualidad_periodo  := _mensualidad;
      END IF;
      
     -- SELECT INTO _sdoof abono+interes_total+costos_asociados from of_deudor(ps_idsucaux,ps_idproducto,ps_idauxiliar,'31/07/2016');

     -- SELECT INTO _sdoaf saldo FROM acreedores WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref);

      --IF (ra.periodo=201607) THEN
      --  IF (_saldo_corte <= 0) THEN
      --    INSERT INTO revision_saldos VALUES (ps_idsucaux,ps_idproducto,ps_idauxiliar,_saldo_corte*-1,COALESCE(_sdoof,0));
      --  ELSE
      --    INSERT INTO revision_saldos VALUES (_idsucauxref,_idproductoref,_idauxiliarref,_saldo_corte,COALESCE(_sdoaf,0));
      --  END IF;
      --END IF;
      --_monto_pago := coalesce(of_si(_saldo_periodo < 0,_saldo_periodo * -1,-_saldo_periodo)::NUMERIC,0);
      _totrecaudo       := _totrecaudo + COALESCE(_recaudo,0.00);
      _totmensualidad   := _totmensualidad + COALESCE(_mensualidad,0.00);
      _totdeposito      := _totdeposito + COALESCE(_deposito,0.00);
      _totpago_finsus   := _totpago_finsus + COALESCE(_pago_finsus,0.00);
      _totpago_terceros := _totpago_terceros + COALESCE(_pago_terceros,0.00);

      _totrecaudo       := COALESCE(_totrecaudo,0.00);     
      _totmensualidad   := COALESCE(_totmensualidad,0.00);         
      _totdeposito      := COALESCE(_totdeposito,0.00);      
      _totpago_finsus   := COALESCE(_totpago_finsus,0.00);         
      _totpago_terceros := COALESCE(_totpago_terceros,0.00);           


      IF (NOT _resumen_manual) THEN
        _res_mensual     := _res_mensual |+
                            of_rellena(of_fecha_nombre(of_periodo_dum(ra.periodo),1)::TEXT,24,' ',1) |+ ' ' |+ -- FECHA
                            to_char(coalesce(_recaudo    ,0),'999,999,990.00') |+ ' ' |+                       -- RECAUDOS
                            to_char(coalesce(_mensualidad,0),'999,999,990.00') |+ ' ' |+                       -- MENSUALIDAD
                            to_char(coalesce(_deposito   ,0),'999,999,990.00') |+ ' ' |+                       -- DEPOSITOS
                            to_char(coalesce(_disposicionesm   ,0),'999,999,990.00') |+ ' ' |+                       -- DEPOSITOS
                            of_si(_finsus,'',to_char(coalesce(_pago_finsus,0),'999,999,990.00') |+ ' ') |+     -- *PGO FINSUS
                            to_char(coalesce(_pago_terceros,0),'999,999,990.00') |+ ' ' |+                     -- *PGO TERCEROS
                            to_char(_saldo_periodo,'999,999,990.00') |+ ' ' |+ -- SALDO DEL MES
                            to_char(coalesce(_saldo_corte,0),'999,999,990.00')|+ ' '|+ -- SALDO AL CORTE
                            E'\n';
      ELSIF (ra.periodo>201606) THEN
       _res_mensual     := _res_mensual |+
                            of_rellena(of_fecha_nombre(of_periodo_dum(ra.periodo),1)::TEXT,24,' ',1) |+ ' ' |+ -- FECHA
                            to_char(coalesce(_recaudo    ,0),'999,999,990.00') |+ ' ' |+                       -- RECAUDOS
                            to_char(coalesce(_mensualidad,0),'999,999,990.00') |+ ' ' |+                       -- MENSUALIDAD
                            to_char(coalesce(_deposito   ,0),'999,999,990.00') |+ ' ' |+                       -- DEPOSITOS
                            of_si(_finsus,'',to_char(coalesce(_pago_finsus,0),'999,999,990.00') |+ ' ') |+     -- *PGO FINSUS
                            to_char(coalesce(_pago_terceros,0),'999,999,990.00') |+ ' ' |+                     -- *PGO TERCEROS
                            to_char(_saldo_periodo,'999,999,990.00') |+ ' ' |+ -- SALDO DEL MES
                            to_char(coalesce(_saldo_corte ,0),'999,999,990.00')|+ ' '|+ -- SALDO AL CORTE
                            E'\n';      
      END IF;

      INSERT INTO resumen_mensual 
        VALUES (ps_idsucaux,ps_idproducto,ps_idauxiliar,of_fecha_nombre(of_periodo_dum(ra.periodo),1),
                coalesce(_recaudo    ,0),coalesce(_mensualidad,0),coalesce(_deposito   ,0),coalesce(_pago_finsus,0),
                coalesce(_pago_terceros,0),coalesce(_saldo_periodo,0),coalesce(_saldo_corte ,0),COALESCE(_disposicionesm,0));

      _disposicionesm  := 0.00;
      _mensualidad     := 0;      
      _saldo_corte_ant := coalesce(_saldo_corte,0.00);
    END LOOP;    
  END IF;
  -- 
  r.totrecaudo       := to_char(COALESCE(_totrecaudo,0.00),'FM999,999,990.90');
  r.totmensualidad   := to_char(COALESCE(_totmensualidad,0.00),'FM999,999,990.90');
  r.totdeposito      := to_char(COALESCE(_totdeposito,0.00),'FM999,999,990.90');
  r.totpago_finsus   := to_char(COALESCE(_totpago_finsus,0.00),'FM999,999,990.90');
  r.totpago_terceros := to_char(COALESCE(_totpago_terceros,0.00),'FM999,999,990.90');
  

  SELECT INTO _idpagoppactcre idpago 
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence=ps_afecha;

  SELECT INTO _iodifex, _iodifnoex sum(io_desc),sum(io_incr) 
    FROM ppv.planpago_escalonado 
   WHERE kauxiliar=_kauxiliar AND idpago<=_idpagoppactcre;

  -- DGZZH Días del periodo, solo considerar el ultimo mes del periodo consultado
  r.plazo       := of_solo_numeros(r.plazo)|+ ' MESES';
  r.diasperiodo := extract(day FROM of_fecha_dum(ps_afecha));
  -- Monto pago
  r.montopago   := to_char(_monto_pago,'FM999,999,990.00');
  r.psaldofin   := to_char(coalesce((_saldo_corte)*-1,0),'FM999,999,990.00');
  r.psaldoini   := to_char(coalesce(_saldo_anterior,0),'FM999,999,990.00');
  _codigo       := of_rellena(_kauxiliar::TEXT,9,'0',2);
  _dv           := of_dv_gen(_codigo);
  _referencia2  := _kauxiliar::TEXT |+ _dv;
  _referencia   := _codigo |+ _dv;
  
  SELECT INTO _credidpagoppsig,_credvenceppsig,_credabonoppsig,_credioppsig,_credioimpsig 
              idpago,vence,abono,io,
              of_si(of_iva_general(ps_idsucaux,ps_idproducto,ps_idsucaux,_tipoprestamo,ps_afecha),round((round(io,2)*round(factor_iva_io,2)),2),0.00)
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence=r.proximo_abono::DATE;

  SELECT INTO _credidpagoppact,_credvenceppact,_credabonoppact,_credioppact 
              idpago,vence,abono,io 
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence=ps_afecha;  

  --RAISE NOTICE 'PLANPAGO ================== %, %, %',ps_idauxiliar,ps_idproducto,ps_idauxiliar;

  SELECT INTO _segvida COALESCE(abono,0.00) FROM of_ca_seguro_vida_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,1,ps_afecha,FALSE);
  SELECT INTO _segunidad COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_seguro_unidad_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,2,ps_afecha,FALSE);
  SELECT INTO _gps COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_gps_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,3,ps_afecha,FALSE);
  SELECT INTO _com COALESCE(abono,0.00) FROM of_ca_entresinplacas_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,4,ps_afecha,FALSE);
  SELECT INTO _comdif COALESCE(abono,0.00) FROM of_ca_interes_diferido(ps_idsucaux,ps_idproducto,ps_idauxiliar,5,ps_afecha,FALSE);

/*
  SELECT INTO _segvidaact valor 
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
  SELECT INTO _segunidadact round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

  SELECT INTO _gpsact round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

  SELECT INTO _comact round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;  

  SELECT INTO _comdifact round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;           
*/
  -- CORREGIR Y TOMAR AUXILIARES_CA y DETALLE_AUXILIAR_CA 
  --SELECT INTO _segvidaact COALESCE(abono,0.00) FROM of_ca_seguro_vida_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,1,ps_afecha,FALSE);
  --SELECT INTO _segunidadact COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_seguro_unidad_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,2,ps_afecha,FALSE);
  --SELECT INTO _gpsact COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_gps_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,3,ps_afecha,FALSE);
  --SELECT INTO _comact COALESCE(abono,0.00) FROM of_ca_entresinplacas_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,4,ps_afecha,FALSE);
  --SELECT INTO _comdifact COALESCE(abono,0.00) FROM of_ca_interes_diferido(ps_idsucaux,ps_idproducto,ps_idauxiliar,5,ps_afecha,FALSE);
  SELECT INTO _segvidaact saldo FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=1;
  SELECT INTO _segunidadact saldo*(pg_factor_iva_io+1) FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=2;
  SELECT INTO _gpsact saldo*(pg_factor_iva_io+1) FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=3;
  SELECT INTO _comact saldo FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=4;
  SELECT INTO _comdifact saldo FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=5;
  r.psaldofin   := to_char(round(of_numeric(r.psaldofin)-COALESCE(_iodifex,0.00)+COALESCE(_comdifact,0.00),2),'FM999,999,990.90');  
  _segvidaact   := COALESCE(_segvidaact,0.00);          
  _segunidadact := COALESCE(_segunidadact,0.00);            
  _gpsact       := COALESCE(_gpsact,0.00);      
  _comact       := COALESCE(_comact,0.00);      
  _comdifact    := COALESCE(_comdifact,0.00);         

  RAISE NOTICE 'r.proximo_abono %',_credidpagoppsig;
  --SELECT INTO _credproxsegvida COALESCE(abono,0.00) FROM of_ca_seguro_vida_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,1,r.proximo_abono,FALSE);
  --SELECT INTO _credproxsegunidad COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_seguro_unidad_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,2,r.proximo_abono,FALSE);
  --SELECT INTO _credproxgps COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_gps_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,3,r.proximo_abono,FALSE);
  SELECT INTO _credproxcom COALESCE(abono,0.00) FROM of_ca_entresinplacas_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,4,r.proximo_abono,FALSE);
  SELECT INTO _credproxcomdif COALESCE(abono,0.00) FROM of_ca_interes_diferido(ps_idsucaux,ps_idproducto,ps_idauxiliar,5,r.proximo_abono,FALSE);
  SELECT INTO _credproxsegvida * FROM of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_credidpagoppsig,1,3);
  SELECT INTO _credproxsegunidad * FROM of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_credidpagoppsig,2,3);
  SELECT INTO _credproxgps * FROM of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_credidpagoppsig,3,3);
  RAISE NOTICE '_credproxsegvida %',_credproxsegvida;
  _credproxsegvida   := COALESCE(_credproxsegvida,0.00);
  _credproxsegunidad := COALESCE(_credproxsegunidad,0.00);
  _credproxgps       := COALESCE(_credproxgps,0.00);
  _credproxcom       := COALESCE(_credproxcom,0.00);
  _credproxcomdif    := COALESCE(_credproxcomdif,0.00);

  --_credproxsegvida := _credproxsegvida - _segvidaact;
  --_credproxsegunidad := _credproxsegunidad - _segunidadact;
  
  --RAISE NOTICE '+++++ gps %, %',_credproxgps, _gpsact;
  --_credproxgps := _credproxgps - _gpsact;
  _credproxcom    := _credproxcom - _comact;
  _credproxcomdif := _credproxcomdif - _comdifact;


  IF (_credidpagoppact=1) THEN
    _dt            :=  _credvenceppact - r.fechaentrega;
    SELECT INTO _segvidaactm segvid_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
    IF (COALESCE(_segvidaactm,0.00)=0.00) THEN
      _segvidaactm   := COALESCE(trunc(((pg_monto_fijo_segvida / 30) * _dt::INTEGER),2),0.00); -- Sin iva
    END IF;

    SELECT INTO _segunidadactm seguni_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
    IF (COALESCE(_segunidadactm,0.00)=0.00) THEN
      _segunidadactm   := COALESCE(trunc(((pg_monto_fijo_segunidad / 30) * _dt::INTEGER),2),0.00); -- Sin iva
    END IF;

    SELECT INTO _gpsactm gps_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
    IF (COALESCE(_gpsactm,0.00)=0.00) THEN
      _gpsactm   := COALESCE(trunc(((pg_monto_fijo_gps / 30) * _dt::INTEGER),2),0.00); -- Sin iva
    END IF;     
    _segunidadactm := round(_segunidadactm*(pg_factor_iva_io+1),2);
    _gpsactm       := round(_gpsactm*(pg_factor_iva_io+1),2);
  ELSE
    SELECT INTO _segvidaactm valor 
        FROM auxiliares_anexo 
       WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_credidpagoppact AND 
             kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
    SELECT INTO _segunidadactm round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
        FROM auxiliares_anexo 
       WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_credidpagoppact AND 
             kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

    SELECT INTO _gpsactm round(valor::NUMERIC*(pg_factor_iva_io+1),2)
        FROM auxiliares_anexo 
       WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_credidpagoppact AND 
             kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
  END IF;

  SELECT INTO _comactm round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_credidpagoppact AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

  --SELECT INTO _comdifactm round(valor::NUMERIC,2)
  --    FROM auxiliares_anexo 
  --   WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_credidpagoppact AND 
  --         kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;     
  -- QUITAR DIFERIDO REVISAR COMISION PORQUE DEBE ESTAR EN CERO (ID 5) _comdif
  SELECT INTO _comdifactm,_comdifid comision_id,com_id_cero FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
  IF (_credidpagoppact<=_comdifid) THEN
    _comdifactm := 0.00;
  END IF;
  _comdifactm := COALESCE(_comdifactm,0.00);
  mensualidad_periodo := COALESCE(_credabonoppact,0.00) + COALESCE(_credioppact,0.00) +  COALESCE(_segvidaactm,0.00) +  COALESCE(_segunidadactm,0.00) +  COALESCE(_gpsactm,0.00) + COALESCE(_comactm,0.00) + COALESCE(_comdifactm,0.00); 

  sdofavor_det_fecha      := '';           
  sdofavor_det_concepto   := '';              
  sdofavor_det_referencia := '';                
  sdofavor_det_retiro     := '';            
  sdofavor_det_deposito   := '';              
  sdofavor_det_saldo      := '';  
  
  credito_det_fecha      := '';           
  credito_det_concepto   := '';              
  credito_det_referencia := '';                
  credito_det_retiro     := '';            
  credito_det_deposito   := '';              
  credito_det_saldo      := '';          
  nmsdo                   := 0;   
  _spd_sdofav             := round(of_auxiliar_spd(_idsucauxref,_idproductoref,_idauxiliarref,of_fecha_dpm(ps_afecha),ps_afecha),2);
  sdo_favor_sdoini        := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,of_fecha_dpm(ps_afecha));
  sdo_favor_sdocorte    := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,ps_afecha);


  
  SELECT INTO rsdofdm COALESCE(sum(montoimp)+sum(montoio),0.00) AS int_isr
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha); 
  
  SELECT INTO sdo_favor_dep sum(abono)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha) AND referencia!~'Recaudo' AND referencia!~'Int'; 

  SELECT INTO sdo_favor_reca sum(abono)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha) AND referencia~'Recaudo'; 

  SELECT INTO sdo_favor_ret sum(cargo)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha) AND cargo>0;

  SELECT INTO sdo_favor_io sum(montoio)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha); 

  sdo_favor_dep  := COALESCE(sdo_favor_dep,'0.00');   
  sdo_favor_reca := COALESCE(sdo_favor_reca,'0.00');    
  sdo_favor_ret  := COALESCE(sdo_favor_ret,'0.00');   
  sdo_favor_io   := COALESCE(sdo_favor_io,'0.00');  

  FOR rsdofdet IN SELECT fecha,concepto,retiro,deposito,saldo,
                         of_si(referencia~'Retencion',
                               (SELECT of_si(arr[1]::TEXT~'Pago Interes',
                                       substring(arr[1]::TEXT,1,12),
                                       of_si(arr[1]::TEXT~'Capitaliza Interes',
                                             substring(arr[1]::TEXT,1,18),
                                             arr[1]::TEXT))||', '||arr[2] 
                                  FROM string_to_array(referencia,',') as arr),
                               referencia) AS referencia
                    FROM of_edoctaxaux(_idsucauxref,_idproductoref,_idauxiliarref,ps_dfecha,ps_afecha) where folio_ticket<>0 ORDER BY secuencia LOOP
    sdofavor_det_fecha := sdofavor_det_fecha |+ COALESCE(rsdofdet.fecha::TEXT,'') |+ E'\n';
    IF (rsdofdet.concepto~'Depósito en Ahorro') THEN
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(substring(rsdofdet.concepto,1,19),'') |+ E'\n';
    ELSIF (rsdofdet.concepto~'Retiro de Ahorro') THEN
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(substring(rsdofdet.concepto,1,16),'') |+ E'\n';
    ELSIF (rsdofdet.concepto~'Pago de Interés Bruto') THEN
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(substring(rsdofdet.concepto,1,16),'') |+ E'\n';
    ELSE
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(rsdofdet.concepto::TEXT,'') |+ E'\n';
    END IF;

    sdofavor_det_referencia := sdofavor_det_referencia |+ COALESCE(rsdofdet.referencia,'') |+ E'\n';
    sdofavor_det_retiro     := sdofavor_det_retiro |+ COALESCE(to_char(rsdofdet.retiro,'FM999,999,990.90'),'') |+ E'\n';
    sdofavor_det_deposito   := sdofavor_det_deposito |+ COALESCE(to_char(rsdofdet.deposito,'FM999,999,990.90'),'') |+ E'\n';
    sdofavor_det_saldo      := sdofavor_det_saldo |+ COALESCE(to_char(rsdofdet.saldo,'FM999,999,990.90'),'') |+ E'\n';
    nmsdo := nmsdo + 1;
    IF (nmsdo >= 23) THEN
      _flag           := TRUE; -- Detalle de recaudos mas de una hoja
      r.__params      := 'glds=gld01,gld02,gld03,gld04,gld05,gld06,gld07,gld08,gld09,gld10';-- Impresion de la hoja 3 (Detalle de recaudos)
      --RAISE NOTICE '============================================ notice 1';
      RETURN NEXT r;   
      sdofavor_det_fecha      := '';            
      sdofavor_det_concepto   := '';               
      sdofavor_det_referencia := '';                
      sdofavor_det_retiro     := '';             
      sdofavor_det_deposito   := '';               
      sdofavor_det_saldo      := '';                  
      nmsdo := 0; 
    END IF;
  END LOOP;
  _saldo_favor_final := rsdofdet.saldo;

FOR rcreddet IN SELECT fecha,concepto,retiro,deposito,saldo,referencia
                    FROM of_edoctaxaux(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha,ps_afecha) where folio_ticket<>0 LOOP
  --RAISE NOTICE 'rcreddet %',rcreddet;                    
    credito_det_fecha := credito_det_fecha |+ COALESCE(rcreddet.fecha::TEXT,'') |+ E'\n';
    credito_det_concepto := credito_det_concepto |+ COALESCE(rcreddet.concepto::TEXT,'') |+ E'\n';
    credito_det_referencia := credito_det_referencia |+ of_si(rcreddet.referencia~'Abonos bancarios','Abonos bancarios',COALESCE(rcreddet.referencia::TEXT,'')) |+ E'\n';
    credito_det_retiro     := credito_det_retiro |+ COALESCE(to_char(rcreddet.retiro,'FM999,999,990.90'),'') |+ E'\n';
    credito_det_deposito   := credito_det_deposito |+ COALESCE(to_char(rcreddet.deposito,'FM999,999,990.90'),'') |+ E'\n';
    credito_det_saldo      := credito_det_saldo |+ COALESCE(to_char(rcreddet.saldo,'FM999,999,990.90'),'') |+ E'\n';
    nmsdo := nmsdo + 1;
    IF (nmsdo >= 21) THEN
      _flag           := TRUE; -- Detalle de recaudos mas de una hoja
      r.__params      := 'gld01,gld02,gld03,gld04,gld05,gld06,gld07,gld08,gld09,gld10';-- Impresion de la hoja 3 (Detalle de recaudos)
      --RAISE NOTICE '============================================ notice 2';
      RETURN NEXT r;   
      credito_det_fecha      := '';            
      credito_det_concepto   := '';               
      credito_det_referencia := '';                
      credito_det_retiro     := '';             
      credito_det_deposito   := '';               
      credito_det_saldo      := '';                  
      nmsdo := 0; 
    END IF;
  END LOOP;  

  FOR rctas IN SELECT idsucauxref,idproductoref,idauxiliarref FROM auxiliares_ref 
                 WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) GROUP BY idsucauxref,idproductoref,idauxiliarref,of_producto_subtipo(idproductoref) 
                 ORDER BY of_producto_subtipo(idproductoref),idproductoref LOOP
    
    SELECT INTO rctassdo idsucaux,idproducto,idauxiliar,saldo,kauxiliar FROM auxiliares WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref);
    
    IF (rctassdo.saldo>0.00) THEN
      SELECT INTO rctasp idproducto,nombre,tipocalculo FROM productos WHERE idproducto=rctassdo.idproducto;
      SELECT INTO rocc * FROM cartera 
        WHERE fecha=of_fecha_dum(ps_afecha) AND (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);      
      IF (of_producto_subtipo(rctassdo.idproducto)='PRE' AND rctasp.tipocalculo=99) THEN
        _noc := _noc + 1;      
        --RAISE NOTICE '_noc %', _noc;
        IF (_noc=1) THEN
          r.__params := r.__params |+ 'gld06;';
        ELSIF (_noc=2) THEN
          r.__params := r.__params |+ 'gld07;';
        ELSIF (_noc=3) THEN
          r.__params := r.__params |+ 'gld08;';
        END IF;        
        
        _rocccodigo       := of_rellena(rctassdo.kauxiliar::TEXT,9,'0',2);
        _roccdv           := of_dv_gen(_rocccodigo::TEXT);
        _roccreferencia   := _rocccodigo |+ _roccdv;
        r.otros_creditos_noref := r.otros_creditos_noref + COALESCE(_roccreferencia::TEXT,'');
        
        SELECT INTO rctassdode idsucaux,idproducto,idauxiliar,saldo,kauxiliar,fechaactivacion,tasaio,tasaim,montoentregado,plazo
          FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref); 

        FOR rctassdodet IN SELECT fecha,concepto,retiro,deposito,saldo,referencia
                            FROM of_edoctaxaux(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,ps_dfecha,ps_afecha) where folio_ticket<>0 LOOP
 
          _otros_creditos_detfecha := _otros_creditos_detfecha |+ rctassdodet.fecha |+ E'\n';
          _otros_creditos_detconcepto := _otros_creditos_detconcepto |+ rctassdodet.concepto |+ E'\n';  
          _otros_creditos_detreferencia := _otros_creditos_detreferencia |+ rctassdodet.concepto |+ E'\n';                            
          _otros_creditos_detcargo := _otros_creditos_detcargo |+ rctassdodet.retiro |+ E'\n';                
          _otros_creditos_detabono := _otros_creditos_detabono |+ rctassdodet.deposito |+ E'\n';                
          _otros_creditos_detsaldo := _otros_creditos_detsaldo |+ rctassdodet.saldo |+ E'\n';                             
        END LOOP;                            
          r.otros_creditos_detfecha    := r.otros_creditos_detfecha + COALESCE(_otros_creditos_detfecha::TEXT,'');      
          r.otros_creditos_detconcepto := r.otros_creditos_detconcepto + COALESCE(_otros_creditos_detconcepto::TEXT,'');         
          r.otros_creditos_detreferencia := r.otros_creditos_detreferencia + COALESCE(_otros_creditos_detreferencia::TEXT,'');         
          r.otros_creditos_detcargo    := r.otros_creditos_detcargo + COALESCE(_otros_creditos_detcargo::TEXT,'');      
          r.otros_creditos_detabono    := r.otros_creditos_detabono + COALESCE(_otros_creditos_detabono::TEXT,'');      
          r.otros_creditos_detsaldo    := r.otros_creditos_detsaldo + COALESCE(_otros_creditos_detsaldo::TEXT,'');           


        r.otros_creditos_saldoliquidar := r.otros_creditos_saldoliquidar + COALESCE((rocc.saldo + rocc.interes_total + rocc.impuesto_total + rocc.costos_asociados)::TEXT,'');
        r.otros_creditos_prod := r.otros_creditos_prod + COALESCE(rctasp.nombre::TEXT,'');
        r.otros_creditos   := r.otros_creditos + COALESCE((rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar)::TEXT,'');
        r.otros_creditos_mto_liquidar := r.otros_creditos_mto_liquidar + COALESCE((rocc.saldo+rocc.interes_total+rocc.impuesto_total+rocc.costos_asociados)::TEXT,'');
        r.otros_creditos_capvigente   := r.otros_creditos_capvigente + COALESCE((rocc.saldo - rocc.montovencido)::TEXT,'');
        r.otros_creditos_capvencido   := r.otros_creditos_capvencido + COALESCE(rocc.montovencido::TEXT,'');                           
        r.otros_creditos_intpendiente := r.otros_creditos_intpendiente + COALESCE(rocc.interes_total::TEXT,'');
        
        SELECT INTO _idpagopp idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence<=ps_afecha ORDER BY idpago DESC limit 1;

        r.otros_creditos_nopago       := r.otros_creditos_nopago + COALESCE(_idpagopp::TEXT,'1');
        SELECT INTO _segautooc abono FROM of_ca_seguro_vida_sust(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,2,ps_afecha,FALSE);
        r.otros_creditos_segauto      := r.otros_creditos_segauto + COALESCE(_segautooc::TEXT,'');
        SELECT INTO _segvidaoc abono FROM  of_ca_seguro_vida_sust(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,1,ps_afecha,FALSE);
        r.otros_creditos_segvida      := r.otros_creditos_segvida + COALESCE(_segvidaoc::TEXT,'');
        SELECT INTO _gpsoc abono FROM  of_ca_seguro_vida_sust(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,3,ps_afecha,FALSE);
        r.otros_creditos_gps          := r.otros_creditos_gps + COALESCE(_gpsoc::TEXT,'');

        SELECT INTO rocdm sum(abono) as abcapital,sum(montoio) as abint,sum(montoimp) as abimp,sum(montoca) as abca
          FROM detalle_auxiliar 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) 
               AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha); 

        r.otros_creditos_abcapital    := r.otros_creditos_abcapital + COALESCE(rocdm.abca,0.00)::TEXT;
        
        SELECT INTO _ocdeuda abono+interes_total+impuesto_total+costos_asociados AS deuda -- 09/09/2021 Cambiar por saldo
          FROM cartera 
          WHERE fecha=ps_afecha AND (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);
        rctassdosaldo := _ocdeuda; 
        r.otros_creditos_mesanterior  := r.otros_creditos_mesanterior + COALESCE(_ocdeuda,0.00)::TEXT;            

        SELECT INTO _idpagoppsig,_venceppsig,_abonoppsig,_ioppsig idpago,vence,abono,io 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence>ps_afecha ORDER BY idpago LIMIT 1;
        r.otros_creditos_proxmensualidad := r.otros_creditos_proxmensualidad + '0.00';
        r.otros_creditos_proxvence       := r.otros_creditos_proxvence + COALESCE(_venceppsig::TEXT,'');
        --r.otros_creditos_noref           := r.otros_creditos_noref + ''     
        r.otros_creditos_proxabono       := r.otros_creditos_proxabono + COALESCE(_abonoppsig::TEXT,'');        
        r.otros_creditos_proxinteres     := r.otros_creditos_proxinteres + COALESCE(_ioppsig::TEXT,'');          
        r.otros_creditos_proxnopago      := r.otros_creditos_proxnopago + COALESCE(_idpagoppsig::TEXT,'');

        SELECT INTO _idpagoppact idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence=ps_afecha;
        _idpagoppact:= COALESCE(_idpagoppact,0);
        SELECT INTO _proxsegvida valor 
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact+1 AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
        SELECT INTO _proxsegauto round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppact+1 AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

        SELECT INTO _proxgps round(valor::NUMERIC*(pg_factor_iva_io+1),2)
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppact+1 AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;


        r.otros_creditos_proxsegauto     := r.otros_creditos_proxsegauto + COALESCE(_menssegauto,0.00)::TEXT;           
        r.otros_creditos_proxsegvida     := r.otros_creditos_proxsegvida + COALESCE(_proxsegvida,0.00)::TEXT;
        r.otros_creditos_proxgps         := r.otros_creditos_proxgps + COALESCE(_mensgps,0.00)::TEXT;

        r.otros_creditos_fechaini       := r.otros_creditos_fechaini + COALESCE(rctassdode.fechaactivacion::TEXT,'');
        r.otros_creditos_tasaio         := r.otros_creditos_tasaio + COALESCE(rctassdode.tasaio::TEXT,'');         
        r.otros_creditos_tasaim         := r.otros_creditos_tasaim + COALESCE(rctassdode.tasaim::TEXT,'');         
        r.otros_creditos_montoentregado := r.otros_creditos_montoentregado + COALESCE(rctassdode.montoentregado::TEXT,'');

        SELECT INTO  _rctasvence vence
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              idpago=rctassdode.plazo;

        r.otros_creditos_fechavence     := r.otros_creditos_fechavence + COALESCE(_rctasvence::TEXT,'');
        SELECT INTO _rctascat valor FROM valores_anexos WHERE (idtabla,idcolumna,idelemento)=('deudores',rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar,'CAT');
        _rctascat := round(_rctascat::numeric,2);
        r.otros_creditos_cat            := r.otros_creditos_cat + COALESCE(_rctascat,'0.00');

        SELECT INTO _idpagoppact idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence=ps_afecha;

        IF (NOT FOUND) THEN              
          r.otros_creditos_mensualidad      := r.otros_creditos_mensualidad + '0.00';
        ELSE
          SELECT INTO _ocmensualidad abono+io 
            FROM planpago 
           WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND idpago=_idpagoppact;

          SELECT INTO _menssegvida valor 
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
          SELECT INTO _menssegauto round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

          SELECT INTO _mensgps round(valor::NUMERIC*(pg_factor_iva_io+1),2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscom round(valor::NUMERIC*(pg_factor_iva_io+1),2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscomdif round(valor::NUMERIC,2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                                      

          _ocmensualidad   := COALESCE(_ocmensualidad,0.00); 
          _menssegvida     := COALESCE(_menssegvida,0.00); 
          _menssegauto     := COALESCE(_menssegauto,0.00); 
          _mensgps         := COALESCE(_mensgps,0.00); 
          _menscom         := COALESCE(_menscom,0.00);      
          _menscomdif      := COALESCE(_menscomdif,0.00);         
          r.otros_creditos_mensualidad  := r.otros_creditos_mensualidad + COALESCE((_ocmensualidad+_menssegvida+_menssegauto+_mensgps+_menscom+_menscomdif)::TEXT,'0.00');
        END IF;    

        r.otros_creditos_apcredito    := r.otros_creditos_apcredito + '0.00';
        r.otros_creditos_sdofinal     := r.otros_creditos_sdofinal + COALESCE((COALESCE(_ocdeuda,0.00) + COALESCE(_ocmensualidad,0.00) + COALESCE(_menssegvida,0.00) + COALESCE(_menssegauto,0.00) +COALESCE(_mensgps,0.00) + 
                                                                       COALESCE(_menscom,0.00) + COALESCE(_menscomdif,0.00))::TEXT,'0.00');
        r.otros_creditos_intdif       := r.otros_creditos_intdif + '0.00';
        r.otros_creditos_adeudo       := r.otros_creditos_adeudo + '0.00';
      END IF;

      IF (rctasp.tipocalculo=9970) THEN  
        _nocl := _nocl + 1;     
        
        IF (_nocl=1) THEN
          r.__params := r.__params |+ 'gld09;';
        ELSIF (_nocl=2) THEN
          r.__params := r.__params |+ 'gld10;';
        ELSIF (_nocl=3) THEN
          r.__params := r.__params |+ 'gld11;';
        END IF;        
        r.otros_creditos_prod_lc := r.otros_creditos_prod_lc + COALESCE(rctasp.nombre,'');
      
        SELECT INTO rctassdode idsucaux,idproducto,idauxiliar,saldo,kauxiliar,fechaactivacion,tasaio,tasaim,montoentregado,plazo
          FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref); 


        _rocccodigo       := of_rellena(rctassdo.kauxiliar::TEXT,9,'0',2);
        _roccdv           := of_dv_gen(_rocccodigo::TEXT);
        _roccreferencia   := _rocccodigo |+ _roccdv;
        r.otros_creditos_noref_lc := r.otros_creditos_noref_lc + COALESCE(_roccreferencia::TEXT,'');        
        r.otros_creditos_lc   := r.otros_creditos_lc + (rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar)::TEXT;
        SELECT INTO _ocdeuda saldo+interes_total+impuesto_total+costos_asociados AS deuda --Roberto
        --SELECT INTO _ocdeuda abono+interes_total+impuesto_total+costos_asociados AS deuda
          FROM cartera 
         WHERE fecha=ps_afecha AND (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);
        rctassdosaldo := _ocdeuda;
        r.otros_creditos_mesanterior_lc  := r.otros_creditos_mesanterior_lc + COALESCE(_ocdeuda,0.00)::TEXT;    

        SELECT INTO _disposiciones sum(cargo) 
          FROM detalle_auxiliar 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref) AND 
               periodo=of_periodo(ps_afecha)::INTEGER;

        SELECT INTO _interes sum(cargo) 
          FROM deudores_ddcc 
          INNER JOIN polizas USING (kpoliza) 
         WHERE kauxiliar = rctassdo.kauxiliar AND cargo_desc~'iodnc' AND periodo=of_periodo(ps_afecha)::INTEGER;

        r.otros_creditos_disposiciones_lc := r.otros_creditos_disposiciones_lc + COALESCE(_disposiciones::TEXT,'0.00');
        r.otros_creditos_interes_lc       := r.otros_creditos_interes_lc + COALESCE(_interes::TEXT,'0.00');
        r.otros_creditos_apcredito_lc     := r.otros_creditos_apcredito_lc + '0.00';
        

        SELECT INTO _idpagoppact idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence=ps_afecha;
        _idpagoppact := COALESCE(_idpagoppact,0);
        SELECT INTO _ocmensualidad abono+io 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND idpago=_idpagoppact;

        SELECT INTO _menssegvida valor 
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
        SELECT INTO _menssegauto round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppact AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

        SELECT INTO _mensgps round(valor::NUMERIC*(pg_factor_iva_io+1),2)
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppact AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscom round(valor::NUMERIC*(pg_factor_iva_io+1),2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscomdif round(valor::NUMERIC,2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;  

        _ocmensualidad   := COALESCE(_ocmensualidad,0.00); 
        _menssegvida     := COALESCE(_menssegvida,0.00); 
        _menssegauto     := COALESCE(_menssegauto,0.00); 
        _mensgps         := COALESCE(_mensgps,0.00); 
        _menscom         := COALESCE(_menscom,0.00);      
        _menscomdif      := COALESCE(_menscomdif,0.00);  
        r.otros_creditos_sdofinal_lc := r.otros_creditos_sdofinal_lc + (COALESCE(_ocdeuda,0.00) + COALESCE(_ocmensualidad,0.00) + COALESCE(_menssegvida,0.00) + COALESCE(_menssegauto,0.00) +COALESCE(_mensgps,0.00) +
                                                                        COALESCE(_menscom,0.00) + COALESCE(_menscomdif,0.00))::TEXT;
        r.otros_creditos_capvigente_lc  := r.otros_creditos_capvigente_lc + COALESCE((rocc.saldo - rocc.montovencido),0.00)::TEXT;
        r.otros_creditos_capvencido_lc  := r.otros_creditos_capvencido_lc + COALESCE(rocc.montovencido,0.00)::TEXT;
        r.otros_creditos_intvenc_lc     := r.otros_creditos_intvenc_lc + COALESCE(rocc.interes_total,0.00)::TEXT;
        r.otros_creditos_adeudo_lc := r.otros_creditos_adeudo_lc + (COALESCE(_ocdeuda,0.00) + COALESCE(_ocmensualidad,0.00) + COALESCE(_menssegvida,0.00) + COALESCE(_menssegauto,0.00) +COALESCE(_mensgps,0.00)+
                                                                    COALESCE(_menscom,0.00) + COALESCE(_menscomdif,0.00))::TEXT;

        SELECT INTO _idpagoppsig,_venceppsig,_abonoppsig,_ioppsig idpago,vence,abono,io 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence>ps_afecha ORDER BY idpago LIMIT 1;


        r.otros_creditos_proxmensualidad_lc := r.otros_creditos_proxmensualidad_lc + '0.00';                        
        r.otros_creditos_proxvence_lc       := r.otros_creditos_proxvence_lc + COALESCE(_venceppsig::TEXT,'');
        --r.otros_creditos_noref_lc           := r.otros_creditos_noref_lc + '';              
        r.otros_creditos_proxabono_lc       := r.otros_creditos_proxabono_lc + COALESCE(_abonoppsig::TEXT,'');
        r.otros_creditos_proxinteres_lc     := r.otros_creditos_proxinteres_lc + COALESCE(_ioppsig::TEXT,'');
        r.otros_creditos_nopago_lc          := r.otros_creditos_nopago_lc + COALESCE(_idpagoppsig::TEXT,'');

        r.otros_creditos_fechaini_lc      := r.otros_creditos_fechaini_lc + COALESCE(rctassdode.fechaactivacion::TEXT,'');
        r.otros_creditos_tasaio_lc        := r.otros_creditos_tasaio_lc + COALESCE(rctassdode.tasaio::TEXT,'');         
        r.otros_creditos_tasaim_lc        := r.otros_creditos_tasaim_lc + COALESCE(rctassdode.tasaim::TEXT,'');     
        r.otros_creditos_limite_lc        := r.otros_creditos_limite_lc + COALESCE(rctassdode.montoentregado::TEXT,'');    

        SELECT INTO  _rctasvence vence
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              idpago=rctassdode.plazo;

        r.otros_creditos_fechavence_lc     := r.otros_creditos_fechavence + COALESCE(_rctasvence::TEXT,'');
        SELECT INTO _rctascat valor FROM valores_anexos WHERE (idtabla,idcolumna,idelemento)=('deudores',rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar,'CAT');
        
        r.otros_creditos_cat_lc            := r.otros_creditos_cat + COALESCE(_rctascat::TEXT,'0.00');
        

        FOR rlin IN SELECT * 
                      FROM (SELECT fecha,concepto,'Programa Respiro',retiro,deposito,saldo 
                              FROM of_edoctaxaux(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref,of_fecha_dpm(ps_afecha),of_fecha_dum(ps_afecha)) 
                             WHERE folio_ticket<>0 
                     UNION SELECT fecha,'Dev. Int Ord','Devengamiento',cargo,0.00,0.00 
                             FROM deudores_ddcc 
                             INNER JOIN polizas USING (kpoliza) 
                            WHERE kauxiliar = rctassdo.kauxiliar AND polizas.periodo=of_periodo(ps_afecha)::INTEGER AND 
                                  cargo_desc~'iodnc' AND periodo=of_periodo(fecha)::INTEGER ORDER BY 1) AS xx LOOP 
          _otros_creditos_detfecha_lc := _otros_creditos_detfecha_lc |+ rlin.fecha |+ E'\n';
          _otros_creditos_detconcepto_lc := _otros_creditos_detconcepto_lc |+ rlin.concepto |+ E'\n';  
          _otros_creditos_detreferencia_lc := _otros_creditos_detreferencia_lc |+ rlin.concepto |+ E'\n';                            
          _otros_creditos_detcargo_lc := _otros_creditos_detcargo_lc |+ rlin.retiro |+ E'\n';                
          _otros_creditos_detabono_lc := _otros_creditos_detabono_lc |+ rlin.deposito |+ E'\n';                
          _otros_creditos_detsaldo_lc := _otros_creditos_detsaldo_lc |+ rlin.saldo |+ E'\n';                        

        END LOOP;
        r.otros_creditos_detfecha_lc    := r.otros_creditos_detfecha_lc + COALESCE(_otros_creditos_detfecha_lc::TEXT,'');      
        r.otros_creditos_detconcepto_lc := r.otros_creditos_detconcepto_lc + COALESCE(_otros_creditos_detconcepto_lc::TEXT,'');         
        r.otros_creditos_detreferencia_lc := r.otros_creditos_detreferencia_lc + COALESCE(_otros_creditos_detreferencia_lc::TEXT,'');         
        r.otros_creditos_detcargo_lc    := r.otros_creditos_detcargo_lc + COALESCE(_otros_creditos_detcargo_lc::TEXT,'');      
        r.otros_creditos_detabono_lc    := r.otros_creditos_detabono_lc + COALESCE(_otros_creditos_detabono_lc::TEXT,'');      
        r.otros_creditos_detsaldo_lc    := r.otros_creditos_detsaldo_lc + COALESCE(_otros_creditos_detsaldo_lc::TEXT,'');             
      END IF;
      IF (rctasp.idproducto BETWEEN 4000 AND 4999) THEN
        SELECT INTO rctassdosaldo saldo FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);
      END IF;
      IF (rctassdo.idproducto = 2001) THEN
        rctassdosaldo := rctassdo.saldo;
        rctassdosaldofav := rctassdo.saldo;
      END IF;
      _res_ctas          := _res_ctas |+ COALESCE(rctasp.nombre,'')|+' ('||rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar||')' |+ E'\n';
      _res_ctas_saldos   := _res_ctas_saldos |+ '$'||to_char(COALESCE(rctassdosaldo,0.00),'FM999,999,990.90') |+ E'\n';
      _res_ctas_saldos_sum := _res_ctas_saldos_sum  + COALESCE(rctassdosaldo-COALESCE(rctassdosaldofav,0.00),0.00);
    END IF; 
  END LOOP;


  --IF (_nocl=1) THEN
  --  r.__params := r.__params |+ 'gld09;';
  --ELSIF (_nocl=2) THEN
  --  r.__params := r.__params |+ 'gld010;';
  --ELSIF (_nocl=3) THEN
  --  r.__params := r.__params |+ 'gld011;';
  --END IF;  
  
  SELECT INTO rmasdat * FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  IF (FOUND) THEN
    _poliza_seg_auto     := rmasdat.poliza_seg_auto;
    _numeco              := rmasdat.numeco;
    _vin                 := rmasdat.vin;
    _vigencia_polsegauto := rmasdat.vigencia_polsegauto;
  END IF;
  
  -- deudaanterior := sumar montoid
  SELECT INTO _deudaanterior,_pnombre,_saldoc,_montovencidoc,_deudamesactual saldo+interes_total+impuesto_total+costos_asociados AS deuda,p.nombre,saldo,montovencido,abono+interes_total+impuesto_total+costos_asociados
    FROM cartera 
    INNER JOIN productos AS p USING (idproducto) 
    WHERE fecha=ps_afecha AND (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
 
  _capvigente             := round(_saldoc-_montovencidoc,2);

  SELECT INTO _deudamesanterior,_montovencidoanterior,_saldoanterior,_iopendant abono+interes_total+impuesto_total+costos_asociados,montovencido AS deuda,saldo,iopend
    FROM cartera 
    WHERE fecha=of_fecha_dpm(ps_afecha)-1 AND (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);

  _comisiondifca        := rmasdat.total_id;
  _comisiondifca        := COALESCE(_comisiondifca,0.00);
  _montovencidoanterior := COALESCE(_montovencidoanterior,0.00);
  _saldoanterior := COALESCE(_saldoanterior,0.00);
  _iopendant     := COALESCE(_iopendant,0.00);

  SELECT INTO _comisiondifcaab sum(daca.abono) 
    FROM detalle_auxiliar 
    INNER JOIN detalle_auxiliar_ca AS daca USING (secuencia) 
    WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND idcosto=5;
  _comisiondifcaab := COALESCE(_comisiondifcaab,0.00);

  _res_ctas          := _res_ctas |+ _pnombre|+' ('||ps_idsucaux||'-'||ps_idproducto||'-'||ps_idauxiliar||')' |+ E'\n';
  _res_ctas_saldos   := _res_ctas_saldos |+ '$'||to_char(COALESCE(_deudaanterior+(_comisiondifca-_comisiondifcaab) - COALESCE(_comdif,0.00),0.00),'FM999,999,990.90') |+ E'\n';
  _res_ctas_saldos_sum := _res_ctas_saldos_sum  + COALESCE(_deudaanterior - COALESCE(_comdif,0.00) + (_comisiondifca-_comisiondifcaab) - COALESCE(_comdifact,0.00),0.00) ;     
  
 
  -- QUITAR TAMBIEN ppv
  SELECT INTO _credproxcomdesc io_desc 
    FROM ppv.planpago_escalonado WHERE idpago=_credidpagoppsig AND kauxiliar=_kauxiliar;

  _credproxmensualidad := COALESCE(_credabonoppsig,0.00) + COALESCE(_credioppsig,0.00) + COALESCE(_credioimpsig,0.00) + COALESCE(_credproxsegvida,0.00) + COALESCE(_credproxsegunidad,0.00) + COALESCE(_credproxgps,0.00) +
                          COALESCE(_credproxcom,0.00) + COALESCE(_credproxcomdif,0.00) - COALESCE(_credproxcomdesc,0.00) ;

  recaudo_fecha          :='';           
  recaudo_transaccion    :='';                 
  recaudo_contrato_gazel :='';                    
  recaudo_litros         :='';            
  recaudo_precioxlt      :='';               
  recaudo_recaudo        :='';                                       
  FOR ra IN SELECT *
              FROM ofx_recaudo.detalle_auxiliar
             WHERE trim(contrato_gazel)= trim(rco.contrato_gazel) AND 
                   fecha BETWEEN of_fecha_dpm(ps_afecha) AND
                                 of_fecha_dum(ps_afecha)
             ORDER BY fecha LOOP
    recaudo_fecha          := recaudo_fecha          |+ COALESCE(ra.fecha::TEXT,'') |+ E'\n';
    recaudo_transaccion    := recaudo_transaccion    |+ COALESCE(ra.transaccion::TEXT,'') |+ E'\n';
    recaudo_contrato_gazel := recaudo_contrato_gazel |+ COALESCE(ra.contrato_gazel::TEXT,'') |+ E'\n';
    recaudo_litros         := recaudo_litros         |+ COALESCE(ra.litros::TEXT,'') |+ E'\n';
    recaudo_precioxlt      := recaudo_precioxlt      |+ COALESCE(ra.precioxlt::TEXT,'') |+ E'\n';
    recaudo_recaudo        := recaudo_recaudo        |+ COALESCE(ra.recaudo::TEXT,'') |+ E'\n';
  END LOOP;                

  SELECT INTO _abcredito sum(abono+montoio+montoca+montoimp)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND periodo=of_periodo(ps_afecha)::INTEGER;

  _adeudopendiente := to_char(of_numeric(r.monto_vencido_cap)+(round(of_numeric(r.interes)-COALESCE(_intdif,0),2))+COALESCE(_segunidad,0.00)+COALESCE(_segvida,0.00)+COALESCE(_gps,0.00)+COALESCE(_com,0.00)+COALESCE(_comdif,0.00)+COALESCE(_iodifnoex,0.00),'FM999,999,990.90');
  _adeudopendiente := of_numeric(_adeudopendiente);

  DELETE FROM validacion_edo_cta 
    WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);

  INSERT INTO validacion_edo_cta
    VALUES (ps_idsucaux,ps_idproducto,ps_idauxiliar,of_numeric(_adeudopendiente),round(of_numeric(sdo_favor_sdocorte),2));

  _intdif := round(_iodifex,2);
  r.__params := r.__params |+ 'gld12;';  
  r.kv_data     := ARRAY['contrato_gazel'          , coalesce(rco.contrato_gazel::TEXT,''),
                         'periodo_mes'             , upper(of_enum_mes(to_char(ps_afecha,'MM')::INT)),
                         'recaudo_periodo'         , to_char(_recaudo_periodo ,'FM999,999,990.00'),
                         'pagos_finsus'            , to_char(_pgo_finsus_periodo ,'FM999,999,990.00'),
                         'deposito_periodo'        , to_char(_deposito_periodo,'FM999,999,990.00'),
                         'pagos_tercero'           , to_char(_pgo_terceros_periodo,'FM999,999,990.00'),
                         'montopago_exijible'      , to_char(of_si(COALESCE(_saldo_corte,0.00)<0,COALESCE(_saldo_corte,0.00),0.00),'FM999,999,990.00'),
                         'res_mensual'             , _res_mensual,
                         'referencia'              , _referencia,
                         'referencia2'             , _referencia2,
                         'chip'                    , _referenciad,
                         'deudaanterior'           , COALESCE(to_char(_deudaanterior,'FM999,999,990.90'),'0.00'),
                         'deta_recaudo'            , '',
                         'sdo_favor'               , _idsucauxref||'-'||_idproductoref||'-'||_idauxiliarref,
                         'sdo_favor_spd'           , to_char(COALESCE(_spd_sdofav,0.00),'FM999,999,990.90'),
                         'sdo_favor_dp'            , (ps_afecha-of_fecha_dpm(ps_afecha))::TEXT,
                         'sdo_favor_ioisr'         , rsdofdm.int_isr::TEXT,
                         'sdo_favor_tasabruta'     , _tasabruta::TEXT,
                         'sdo_favor_fec'           , sdofavor_det_fecha,
                         'sdo_favor_concepto'      , sdofavor_det_concepto,
                         'sdo_favor_referencia'    , sdofavor_det_referencia,
                         'sdo_favor_retiro'        , sdofavor_det_retiro,
                         'sdo_favor_deposito'      , sdofavor_det_deposito,
                         'sdo_favor_saldo'         , sdofavor_det_saldo,
                         'sdo_favor_sdoini'        , sdo_favor_sdoini,
                         'sdo_favor_dep'           , sdo_favor_dep,
                         'sdo_favor_reca'          , sdo_favor_reca,
                         'sdo_favor_ret'           , sdo_favor_ret,
                         'sdo_favor_io'            , sdo_favor_io,
                         'sdo_favor_sdocorte'      , sdo_favor_sdocorte,
                         'saldooanterior'          , COALESCE(to_char(_saldoanterior,'FM999,999,990.90'),'0.00'),
                         'montovencidoanterior'    , COALESCE(to_char(_montovencidoanterior,'FM999,999,990.90')),
                         'saldooanteriormenosvenc' , to_char(COALESCE(_saldoanterior,0)-COALESCE(_montovencidoanterior),'FM999,999,990.90'),
                         'iopendant'               , to_char(COALESCE(_iopendant,0.00),'FM999,999,990.90'),
                         'saldo_favor_final'       , COALESCE(to_char(_saldo_favor_final,'FM999,999,990.90'),'0.00'),
                         'proxmensualidad'         , to_char(COALESCE(_credproxmensualidad,0.00),'FM999,999,990.90'),
                         'proxcap'                 , to_char(COALESCE(_credabonoppsig,0.00),'FM999,999,990.90'),
                         'proxio'                  , to_char(COALESCE(_credioppsig,0.00),'FM999,999,990.90'),
                         'proximp'                  , to_char(COALESCE(_credioimpsig,0.00),'FM999,999,990.90'),
                         'proxidpago'              , COALESCE(_credidpagoppsig::TEXT,r.diasxplazo::TEXT),
                         'proxsegvida'             , COALESCE(to_char(_credproxsegvida,'FM999,999,990.90'),'0.00'),             
                         'proxsegunidad'           , COALESCE(to_char(_credproxsegunidad,'FM999,999,990.90'),'0.00'),              
                         'proxgps'                 , COALESCE(to_char(_credproxgps,'FM999,999,990.90'),'0.00'),        
                         'proxcom'                 , COALESCE(to_char(_credproxcom,'FM999,999,990.90'),'0.00'),         
                         'proxcomdif'              , COALESCE(to_char(_credproxcomdif,'FM999,999,990.90'),'0.00'), 
                         'abonoppact'              , COALESCE(to_char(_credabonoppact,'FM999,999,990.90'),'0.00'),
                         'sdofinalmes'             , to_char(COALESCE(_deudaanterior+(_comisiondifca-_comisiondifcaab) - COALESCE(_comdif,0.00),0.00),'FM999,999,990.90'),
                         'idpagom'                 , COALESCE(_credidpagoppact::TEXT,r.plazo),  
                         'abcapitalm'              , COALESCE(to_char(_credabonoppact,'FM999,999,990.90'),'0.00'),
                         'iom'                     , COALESCE(to_char(_credioppact,'FM999,999,990.90'),'0.00'),  
                         'segvidaactm'             , COALESCE(to_char(_segvidaactm,'FM999,999,990.90'),'0.00'),
                         'segunidadactm'           , COALESCE(to_char(_segunidadactm,'FM999,999,990.90'),'0.00'),
                         'gpsactm'                 , COALESCE(to_char(_gpsactm,'FM999,999,990.90'),'0.00'),
                         'comactm'                 , COALESCE(to_char(_comactm,'FM999,999,990.90'),'0.00'),
                         'comdifactm'              , COALESCE(to_char(_comdifactm,'FM999,999,990.90'),'0.00'),
                         'pandemia'                , COALESCE(to_char((_comisiondifca-_comdifact),'FM999,999,990.90'),'0.00'),
                         'deudaanteriormesanterior', COALESCE(to_char(((_comisiondifca-_comisiondifcaab)+(_saldoanterior+_iopendant)),'FM999,999,990.90'),'0.00'),
                         'pandemiamensual'         , COALESCE(to_char((_comdifactm),'FM999,999,990.90'),'0.00'),
                         'credito_det_fec'         , credito_det_fecha,                   
                         'credito_det_concepto'    , credito_det_concepto,                      
                         'credito_det_referencia'  , credito_det_referencia,                        
                         'credito_det_retiro'      , credito_det_retiro,                    
                         'credito_det_deposito'    , credito_det_deposito,                      
                         'credito_det_saldo'       , credito_det_saldo,  
                         'recaudo_fec'             , recaudo_fecha,          
                         'recaudo_transaccion'    , recaudo_transaccion,                
                         'recaudo_contrato_gazel' , recaudo_contrato_gazel,                   
                         'recaudo_litros'         , recaudo_litros,           
                         'recaudo_precioxlt'      , recaudo_precioxlt,              
                         'recaudo_recaudo'        , recaudo_recaudo,     
                         'audeudopendiente'       , to_char(of_numeric(r.monto_vencido_cap)+(round(of_numeric(r.interes)-COALESCE(_intdif,0),2))+COALESCE(_segunidad,0.00)+COALESCE(_segvida,0.00)+COALESCE(_gps,0.00)+COALESCE(_com,0.00)+COALESCE(_comdif,0.00),'FM999,999,990.90'),
                         --      
                         'interesp'                , to_char(round(of_numeric(r.interes)-COALESCE(_intdif,0),2),'FM999,999,990.90'),
                         'abcredito'               , to_char(COALESCE(_abcredito,0.00),'FM999,999,990.90'),
                         'segvida'                 , to_char(COALESCE(_segvida,0.00),'FM999,999,990.90'),
                         'segunidad'               , to_char(COALESCE(_segunidad,0.00),'FM999,999,990.90'),
                         'gps'                     , to_char(COALESCE(_gps,0.00),'FM999,999,990.90'),
                         'comision'                , to_char(COALESCE(_com,0.00),'FM999,999,990.90'),        
                         'comision_dif'             , to_char(COALESCE(_comdif,0.00),'FM999,999,990.90'),    
                         'capvigente'              , to_char(COALESCE(_capvigente,0.00),'FM999,999,990.90'),  
                         'mensualidad'             , to_char(COALESCE(mensualidad_periodo,0.00),'FM999,999,990.90'),
                         'saldo_corte'             , to_char(COALESCE(_saldo_corte,0.00),'FM999,999,990.90'),
                         'iodifnoex'               , to_char(coalesce(_intdif,0.00),'FM999,999,990.90'),
                         'res_ctas'                , _res_ctas::TEXT,
                         'res_ctas_saldos'         , _res_ctas_saldos::TEXT,
                         'res_ctas_saldos_sum'     , to_char(_res_ctas_saldos_sum,'FM999,999,990.90'),
                         'poliza_seg_auto'         , COALESCE(_poliza_seg_auto,''),
                         'numeco'                  , COALESCE(_numeco,''),
                         'vin'                     , COALESCE(_vin,''),
                         'vigencia_polsegauto'     , COALESCE(_vigencia_polsegauto::TEXT,'')
                         ];
  -- DETALLE DE RECAUDOS --
  -- Validar que existan registros de recaudos
  SELECT INTO rco contrato_gazel FROM ofx_multicampos_auxiliar_masdatos_sus(_kauxiliar);
  PERFORM kauxiliar FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE contrato_gazel = rco.contrato_gazel;
  
  CASE WHEN of_validate_email(r.email) THEN _valid_emial := 1; ELSE _valid_emial := 0; END CASE;
--_valid_emial := 
  SELECT INTO _nmovimientos count(*)
    FROM ofx_recaudo.detalle_auxiliar
   WHERE trim(contrato_gazel) = trim(rco.contrato_gazel) AND 
         fecha BETWEEN of_fecha_dpm(ps_afecha) AND
                       of_fecha_dum(ps_afecha);


  --r.__params := 'glds=gld01;gld02;gld03;gld04;gld05;gld06;gld07;gld08;gld09;gld10;';

  IF (of_ofx_check_version('1.16.6-0')) THEN
  --RAISE NOTICE '============================================ notice 3';
    RETURN NEXT r;
  END IF;
  --i   := 0;
  --IF (_nmovimientos > 0) THEN
  --  -- Obniendo Detalle de Recaudos. 
  --  FOR ra IN SELECT *
  --              FROM ofx_recaudo.detalle_auxiliar
  --             WHERE contrato_gazel= rco.contrato_gazel AND 
  --                   fecha BETWEEN of_fecha_dpm(ps_afecha) AND
  --                                 of_fecha_dum(ps_afecha)
  --             ORDER BY fecha LOOP
  --  
  --    i  := i  + 1;
  --    ii := ii + 1;
  --    _detalle         := _detalle |+ 
  --                        of_rellena(ra.fecha::TEXT                     ,11,' ',1) |+ ' ' |+
  --                        of_rellena(to_char(coalesce(ra.transaccion    ,0),'999,999,990.00'),16,' ',2) |+ repeat(' ',4) |+
  --                        of_rellena(coalesce(rco.contrato_gazel::TEXT,'0')::TEXT,18,' ',1) |+ ' ' |+
  --                        of_rellena(coalesce(ra.litros        ,0)::TEXT,12,' ',2) |+ repeat(' ',3) |+
  --                        of_rellena(to_char(coalesce(ra.precioxlt      ,0),'999,999,990.00'),18,' ',2) |+ repeat(' ',2) |+
  --                        of_rellena(to_char(coalesce(ra.recaudo        ,0),'999,999,990.00'),18,' ',2) |+ E'\n';
  --    _tot_transaccion := _tot_transaccion + coalesce(ra.transaccion,0);
  --    _tot_litros      := _tot_litros      + coalesce(ra.litros     ,0);
  --    _tot_precioxlt   := _tot_precioxlt   + coalesce(ra.litros     ,0);
  --    _tot_recaudo     := _tot_recaudo     + coalesce(ra.recaudo    ,0);
  --    IF (i = _limit_det_recaudo) THEN
  --      _key            := of_array_find(r.kv_data,'deta_recaudo') + 1;
  --      r.kv_data[_key] := _detalle; -- Asigacion del valor de detalle de recaudo
  --      IF (_nmovimientos != _limit_det_recaudo) THEN -- No se debe retornar el registro si el numero de movimientos conicide con el limite, el registro generado se retorna mas abajo
  --        r.__params      := 'glds=gld3';-- Impresion de la hoja 3 (Detalle de recaudos)
  --        RAISE NOTICE '============================================ notice 4';
  --        RETURN NEXT r;
  --        _detalle        := '';
  --        i               := 0 ;
  --      END IF;
  --    END IF;
  --  END LOOP;
  --  IF (i > 0) THEN
  --    _totales        := of_rellena('TOTALES',11,' ',1)   |+ ' ' |+
  --                       of_rellena(to_char(_tot_transaccion,'999,999,990.00'),16,' ',2) |+ repeat(' ',4) |+
  --                       of_rellena(' ',18,' ',1)      |+ ' ' |+
  --                       of_rellena(_tot_litros::TEXT,12,' ',2) |+ repeat(' ',3) |+
  --                       of_rellena(to_char(_tot_precioxlt,'999,999,990.00'),18,' ',2) |+ repeat(' ',2) |+
  --                       of_rellena(to_char(_tot_recaudo,'999,999,990.00'),18,' ',2);
  --    _key            := of_array_find(r.kv_data,'deta_recaudo') + 1;
  --    _detalle        := _detalle |+ E'\n'|+ _totales;
  --    r.kv_data[_key] := _detalle; -- Asigacion del valor de detalle de recaudo
  --    IF (_gen_pdfs) THEN
  --      _nombrepfd    := r.asociado|+'-'|+_valid_emial::TEXT|+'-'|+ r.idauxiliar;
  --      r.__params    := 'glds=gld3,fname='|+_nombrepfd|+'-'|+of_periodo(ps_afecha);
  --    END IF;
  --    RAISE NOTICE '============================================ notice 5';
  --   -- RETURN NEXT r;
  --  END IF;
  --ELSE
  --  IF (_gen_pdfs) THEN
  --    _nombrepfd := r.asociado|+'-'|+_valid_emial::TEXT|+'-'|+ r.idauxiliar;
  --    r.__params := 'glds=gld3,fname='|+_nombrepfd|+'-'|+of_periodo(ps_afecha);
  --  END IF;
  --  RAISE NOTICE '============================================ notice 6';
  --  RETURN NEXT r;
  --END IF;
  RETURN;
END;$$
LANGUAGE plpgsql;


-- ------------------------------------------------------------------
-- DGZZH 09/06/2016 Obteniedo mas dados de auxiliar
SELECT of_db_drop_type('ofx_multicampos_auxiliar_masdatos_sus','CASCADE');
CREATE TYPE ofx_multicampos_auxiliar_masdatos_sus AS (
 kauxiliar      INTEGER,  -- Clave unca de auxiliar
 contrato_gazel TEXT ,  -- Numero de Contrato GAZEL 
 idconversion   INTEGER,  -- Numero de Conversion
 idunidad       INTEGER,  -- Numero de Unidad
 litrosconsumo  NUMERIC,  -- Numero de litros de consumo
 segvida        NUMERIC,  -- Seguro de Vida
 segunidad      NUMERIC,  -- Seguro de Unidad
 gps            NUMERIC,  -- Seguro de GPS
 idagencia      INTEGER   -- Numero de Agencia
);
CREATE OR REPLACE FUNCTION ofx_multicampos_auxiliar_masdatos_sus(p_kauxiliar INTEGER)
                   RETURNS SETOF ofx_multicampos_auxiliar_masdatos_sus AS $$
DECLARE

  -- Variables
  r   ofx_multicampos_auxiliar_masdatos_sus%ROWTYPE;
  ra  RECORD;   
  
BEGIN
  IF (p_kauxiliar IS NULL) THEN
    RETURN;
  ELSE
    PERFORM kauxiliar FROM deudores WHERE kauxiliar = p_kauxiliar;
    IF (FOUND) THEN
      SELECT INTO ra * FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = p_kauxiliar;
      r.kauxiliar      := coalesce(ra.kauxiliar,'0');
      r.contrato_gazel := coalesce(ra.contrato_gazel,'0');
      r.idconversion   := coalesce(ra.idconversion,'0');
      r.idunidad       := coalesce(ra.idunidad,'0');
      r.litrosconsumo  := coalesce(ra.litrosconsumo,'0');
      r.segvida        := coalesce(ra.segvida,'0.00');
      r.segunidad      := coalesce(ra.segunidad,'0.00');
      r.gps            := coalesce(ra.gps,'0.00');
      r.idagencia      := coalesce(ra.idagencia,'0');
      RETURN NEXT r;
    ELSE
      RETURN;
    END IF;
  END IF;
END;$$
LANGUAGE plpgsql;

-- ------------------------------------------------------------------
-- DGZZH 09/06/2016 Obteniedo datos de recaudo
SELECT of_db_drop_type('ofx_recaudo_detalle_auxiliar_sus','CASCADE');
CREATE TYPE ofx_recaudo_detalle_auxiliar_sus AS (
  fecha          TEXT   , -- 
  transaccion    TEXT, -- 
  contrato_gazel TEXT, -- 
  litros         TEXT, -- 
  precioxlt      TEXT, -- 
  recaudo        TEXT  -- 

);
CREATE OR REPLACE FUNCTION ofx_recaudo_detalle_auxiliar_sus(p_cont_gazel BIGINT)
                   RETURNS SETOF ofx_recaudo_detalle_auxiliar_sus AS $$
DECLARE

  -- Variables
  r   ofx_recaudo_detalle_auxiliar_sus%ROWTYPE;
  ra  RECORD;   
  
BEGIN
  IF (p_cont_gazel IS NULL) THEN
    RETURN;
  ELSE
    r.fecha          := '';
    r.transaccion    := '';
    r.contrato_gazel := '';
    r.litros         := '';
    r.precioxlt      := '';
    r.recaudo        := '';
    PERFORM kauxiliar FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE contrato_gazel = p_cont_gazel;
    IF (FOUND) THEN
      FOR ra IN SELECT *
                  FROM ofx_recaudo.detalle_auxiliar
                 WHERE trim(contrato_gazel)= trim(p_cont_gazel) LOOP
         r.fecha          := r.fecha          |+ ra.fecha::TEXT          |+ E'\n';
         r.transaccion    := r.transaccion    |+ coalesce(ra.transaccion,0)    |+ E'\n';
         r.contrato_gazel := r.contrato_gazel |+ coalesce(ra.contrato_gazel,'0') |+ E'\n';
         r.litros         := r.litros         |+ coalesce(ra.litros,0)         |+ E'\n';
         r.precioxlt      := r.precioxlt      |+ coalesce(ra.precioxlt,0)      |+ E'\n';
         r.recaudo        := r.recaudo        |+ coalesce(ra.recaudo,0)        |+ E'\n';
      END LOOP;
      RETURN NEXT r;
    ELSE
      RETURN;
    END IF;
  END IF;
END;$$
LANGUAGE plpgsql;

-- --------------------------------------------------------------------
-- DGZZH 17/08/2016 Resumen mensual llenado de forma manual
CREATE OR REPLACE FUNCTION of_create_table_temp_edocta_res_mesual_sus()
                   RETURNS BOOLEAN AS $$
DECLARE

  -- Variables
  
BEGIN
 
 CREATE TABLE edocta_res_mensual (
  id           SERIAL,
  auxiliar     TEXT NOT NULL,
  fecha        TEXT NOT NULL,
  recaudo      NUMERIC NOT NULL,
  mensualidad  NUMERIC NOT NULL,
  deposito     NUMERIC NOT NULL,
  pgo_tercero  NUMERIC NOT NULL,
  saldo_mes    NUMERIC NOT NULL,
  saldo_corte  NUMERIC NOT NULL,
  pagos_finsus NUMERIC
  );

 RETURN TRUE;
END;$$
LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------------
-- DGZZH Inicio: 03/12/2012
-- Imprime el formato del estado de Cuenta en forma Maasiva.
-- ------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ofx_forma_ec_masiva_rutas_fs ()
                   RETURNS SETOF ofx_estado_cuenta_rutas AS $$
DECLARE
  -- Variables
  t                 ofx_estado_cuenta_rutas%ROWTYPE;
  r                 RECORD;
  ps_idsucursal      BIGINT:= of_ofx_get('ps_idsucursal');  -- Parámetros de sesión Idsucursal.
  ps_idrol          INTEGER:= of_ofx_get_integer('ps_idrol');  --> 
  ps_idasociado     INTEGER:= of_ofx_get('ps_idasociado');  -->
  ps_sucursal        BIGINT:= of_ofx_get('ps_sucursal');
  x_asociado        BOOLEAN:= of_ofx_get_boolean('c_asociado');
  x_sucursal        BOOLEAN:= of_ofx_get_boolean('c_sucursal');
  x_todos           BOOLEAN:= of_ofx_get_boolean('c_todos');
  _productos        TEXT   := of_ofx_get('lista'); -- Productos a considerar.
  _productos_arr    TEXT[];
  _defecha          DATE:=of_ofx_get_date('ps_dfecha');
  _afecha           DATE:=of_ofx_get_date('ps_afecha');
  i                 INTEGER:=0;
  c                 TEXT;
_count              INTEGER:=0;
 _valid_emial      INTEGER;
  _gen_pdfs         BOOLEAN;
  _nombrepfd        TEXT:='';
  _fx               BOOLEAN  := ofpb('/formatos/ofx_estado_cuenta_rutas', 'funcion_post', FALSE);
BEGIN

  --PERFORM of_param_sesion_raise(null);
  PERFORM of_param_sesion_set('vsr_email','idproceso', ofx_inicio_proceso_email());
  --PERFORM of_ofx_set('bt_gen_pdfs',  'sensitive=false');
  c                 := of_params_get('/formatos/ofx_estado_cuenta_rutas','fx_principal');
  _gen_pdfs         := of_params_get_boolean('/formatos/ofx_estado_cuenta_rutas','gen_pdfs');
  _productos_arr    := string_to_array(NULLIF(trim(_productos),''),',');
  --RAISE NOTICE '===================================================================================================================AQUI MASIVA';
  FOR r IN SELECT idsucaux,idproducto,idauxiliar,idsucursal,idrol,idasociado
             FROM deudores
            WHERE idproducto::TEXT = ANY (_productos_arr) AND
                  estatus = 3  AND saldo > 0 AND
                  ((x_asociado AND (idsucursal,idrol,idasociado)=(ps_idsucursal,ps_idrol,ps_idasociado)) OR 
                  (x_sucursal  AND idsucursal IN (SELECT idsucursal
                                                    FROM sucursales
                                                   WHERE idsucursal = ps_sucursal)) OR
                  (x_todos))
              --WHERE estatus = 3 AND idproducto=5200
            ORDER BY idsucaux ASC LOOP
    
    i := i + 1;
    RAISE NOTICE '================ %',i;
    PERFORM of_param_sesion_set('vsr_vars','ps_idsucaux',r.idsucaux::TEXT);     -- Obteniendo el valor de Idsucaux.
    PERFORM of_param_sesion_set('vsr_vars','ps_idproducto',r.idproducto::TEXT); -- Obteniendo el valor de Idproducto.
    PERFORM of_param_sesion_set('vsr_vars','ps_idauxiliar',r.idauxiliar::TEXT); -- Obteniendo el valor de Idauxiliar.
    PERFORM of_param_sesion_set('vsr_vars','ps_dfecha',_defecha::TEXT); -- Obteniendo el valor de Idauxiliar.
    PERFORM of_param_sesion_set('vsr_vars','ps_afecha',_afecha::TEXT); -- Obteniendo el valor de Idauxiliar.
    --PERFORM of_ofx_notice('info','Numero de registro => '||i::TEXT);
    FOR t IN EXECUTE 'SELECT * FROM '||c||'()' LOOP -- Vaciar toda la info en el TYPE.
      _count := _count + 1;
      IF (_gen_pdfs) THEN
        SELECT INTO _valid_emial  CASE WHEN of_validate_email(email) THEN 1 ELSE 0 END
          FROM asociados
          LEFT JOIN directorio USING(idsucdir,iddir)
         WHERE (idsucursal,idrol,idasociado)=(r.idsucursal,r.idrol,r.idasociado);
        
        _nombrepfd := r.idsucursal::TEXT |+ '-'|+ r.idrol::TEXT |+ '-'|+ r.idasociado::TEXT|+'-'|+_valid_emial::TEXT|+'-'|+ r.idauxiliar;
        t.__params := t.__params || format(',fname=%s-%s%s',_nombrepfd, of_periodo(_afecha), of_si(_fx, ',fxpost=ofx_estado_cuenta_rutas__fxpost', ''));
        RAISE NOTICE '======== t.__params %',t.__params;
      END IF;
      RETURN NEXT t;
    END LOOP;
    -- Borra el auxiliar por cada ciclo.
    PERFORM of_param_sesion_unset('vsr_vars','ps_idsucaux');
    PERFORM of_param_sesion_unset('vsr_vars','ps_idproducto');
    PERFORM of_param_sesion_unset('vsr_vars','ps_idauxiliar');
    PERFORM of_param_sesion_unset('vsr_vars','ps_dfecha');
    PERFORM of_param_sesion_unset('vsr_vars','ps_afecha');
  END LOOP; 
RETURN ;
END;$$
LANGUAGE plpgsql;


-- FXPOST
CREATE OR REPLACE FUNCTION ofx_estado_cuenta_rutas__fxpost(p_type ofx_estado_cuenta_rutas, p_idproceso integer, p_imagen text)
 RETURNS void
AS $$
DECLARE
  -- Variables
  _email      TEXT  := COALESCE(p_type.email, 'SIN EMAIL');
  _nombrepfd  TEXT;
  _id         TEXT;
  _asunto     TEXT  := ofpt('/formatos/ofx_estado_cuenta_rutas','asunto','Estado de cuenta');
  _mensaje    TEXT  := ofpt('/formatos/ofx_estado_cuenta_rutas','mensaje','Estimado cliente. Envíamos su estado de cuenta del mes.');
  _kasociado  INTEGER;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  SELECT INTO _id,_kasociado idsucursal || '-' || idrol ||'-'|| idasociado, kasociado 
    FROM asociados  
   WHERE (idsucursal||'-'||idrol||'-'||idasociado) = 
         (p_type.asociado) LIMIT 1;
  --RAISE NOTICE 'EXECUTE';
  _nombrepfd := _id                                                             || '-' ||
                of_si(COALESCE(ofx_validate_email(p_type.email), FALSE),'1','0')|| '-' || 
                p_type.idauxiliar                                               || '.pdf';
  --INSERT INTO envioss values (p_type.asociado,_kasociado);                
  INSERT INTO email_envios (idproceso, kasociado, para, asunto, mensaje, jdata) 
  VALUES (p_idproceso, _kasociado, _email, _asunto, _mensaje, jsonb_build_object(COALESCE(_nombrepfd, 'EstadoDeCuenta.pdf'), p_imagen));
  RETURN;
END;$$
LANGUAGE plpgsql;


SELECT of_db_drop_type('ofx_estado_cuenta_rutas_x_vence_v2','CASCADE');
CREATE TYPE ofx_estado_cuenta_rutas_x_vence_v2 AS (
 suc_matriz_idsucursal    INTEGER,  
 suc_matriz_nom_sucursal  TEXT,     
 suc_matriz_calle         TEXT,     
 suc_matriz_colonia       TEXT,     
 suc_matriz_municipio     TEXT,     
 suc_matriz_estado        TEXT,     
 suc_matriz_rfc           TEXT,     
 idsucursal               INTEGER,   
 nom_sucursal             TEXT,     
 suc_calle                TEXT,     
 suc_colonia              TEXT,     
 suc_municipio            TEXT,     
 suc_estado               TEXT,     
 suc_rfc                  TEXT,     
 asociado                 TEXT,     
 nombre                   TEXT,     
 rfc                      TEXT,     
 curp                     TEXT,     
 email                    TEXT,     
 calle                    TEXT,     
 colonia                  TEXT,     
 municipio                TEXT,     
 estado                   TEXT,     
 periodo                  TEXT,     
 cuenta                   TEXT,     
 idsucaux                 TEXT,     
 idproducto               TEXT,     
 idauxiliar               TEXT,     
 credito                  TEXT,     
 tipoptmo                 TEXT,     
 montosolicitado          TEXT,     
 montoentregado           TEXT,     
 fechaentrega             DATE,     
 tasaio                   TEXT,     
 tasaio_venta             TEXT,     
 tasaio_x12               TEXT,     
 tasaim                   TEXT,     
 tasaim_venta             TEXT,     
 tasaim_x12               TEXT,     
 cat                      TEXT,     
 finalidad                TEXT,     
 plazo                    TEXT,     
 diasxplazo               TEXT,     
 vence                    DATE,     
 ultimomovimiento         DATE,     
 proximo_abono            DATE,     
 fe_limite_pago           TEXT,     
 tipoabono                TEXT,     
 saldofcha                TEXT,     
 gastos_cobranza          TEXT,     
 monto_vencido_cap        TEXT,     
 abono                    TEXT,     
 interes                  TEXT,     
 moratorio                TEXT,     
 comisiones               TEXT,     
 iva                      TEXT,     
 montopago                TEXT,     
 deudatotal               TEXT,     
 estatuscartera           TEXT,     
 diasmoracapital          TEXT,     
 diasmorainteres          TEXT,     
 xcentajecubierto         TEXT,     
 comision_pagado          TEXT,     
 fpago_comision           DATE,     
 pgovencido               TEXT,     
 pago_exijible            TEXT,     
 dt_fhora                 TEXT,     
 dt_ticket                TEXT,     
 dt_concepto              TEXT,     
 dt_cargo                 TEXT,     
 dt_abono                 TEXT,     
 dt_saldo                 TEXT,     
 dt_referencia            TEXT,     
 dt_capital               TEXT,     
 dt_interes               TEXT,     
 dt_moratorio             TEXT,     
 dt_iva                   TEXT,     
 psaldoini                TEXT,     
 pcargos                  TEXT,     
 pabonos                  TEXT,     
 psaldofin                TEXT,     
 tot_cargo                TEXT,     
 tot_capital              TEXT,     
 tot_interes              TEXT,     
 tot_moratorios           TEXT,     
 tot_iva                  TEXT,     
 tot_pago                 TEXT,     
 conducef                 TEXT,     
 fechreal                 DATE,     
 fechoperacion            DATE,     
 fechformato              TEXT,     
 dfecha                   DATE,     
 afecha                   DATE,     
 horas                    TEXT,     
 titulo                   TEXT,     
 pagina                   INTEGER,  
 npaginas                 INTEGER,  
 kv_data                  TEXT[],   
 diasperiodo              TEXT,     
 paginas                  INTEGER,  
 __params                 TEXT,
 totrecaudo               TEXT,                                      
 totmensualidad           TEXT,                                          
 totdeposito              TEXT,                                       
 totpago_finsus           TEXT,                                          
 totpago_terceros         TEXT,
 otros_creditos               TEXT[],
 otros_creditos_mto_liquidar  TEXT[],
 otros_creditos_mesanterior   TEXT[],
 otros_creditos_mensualidad   TEXT[],
 otros_creditos_abcapital     TEXT[],
 otros_creditos_apcredito     TEXT[],
 otros_creditos_sdofinal      TEXT[],
 otros_creditos_capvigente    TEXT[],
 otros_creditos_capvencido    TEXT[],
 otros_creditos_intpendiente  TEXT[],
 otros_creditos_segauto       TEXT[],
 otros_creditos_segvida       TEXT[],
 otros_creditos_gps           TEXT[],
 otros_creditos_intdif        TEXT[],
 otros_creditos_adeudo        TEXT[],
 otros_creditos_nopago        TEXT[],
 otros_creditos_prod          TEXT[],
 otros_creditos_saldoliquidar  TEXT[],

 otros_creditos_proxmensualidad TEXT[],
 otros_creditos_proxvence       TEXT[],
 otros_creditos_noref           TEXT[],

 -- Datos prox mensualidad
 otros_creditos_proxabono    TEXT[],
 otros_creditos_proxinteres  TEXT[],
 otros_creditos_proxsegauto  TEXT[],
 otros_creditos_proxsegvida  TEXT[],
 otros_creditos_proxgps      TEXT[],
 otros_creditos_proxnopago   TEXT[],

 otros_creditos_fechaini     TEXT[], 
 otros_creditos_fechavence   TEXT[], 
 otros_creditos_cat          TEXT[], 
 otros_creditos_tasaio       TEXT[], 
 otros_creditos_tasaim       TEXT[], 
 otros_creditos_montoentregado TEXT[], 

 otros_creditos_detfecha      TEXT[],      
 otros_creditos_detconcepto   TEXT[],         
 otros_creditos_detreferencia   TEXT[],         
 otros_creditos_detcargo      TEXT[],      
 otros_creditos_detabono      TEXT[],      
 otros_creditos_detsaldo      TEXT[],      


 otros_creditos_prod_lc          TEXT[],
 otros_creditos_lc                TEXT[],
 otros_creditos_mesanterior_lc    TEXT[],
 otros_creditos_disposiciones_lc  TEXT[],
 otros_creditos_interes_lc  TEXT[],
 otros_creditos_apcredito_lc TEXT[],
 otros_creditos_sdofinal_lc  TEXT[],
 otros_creditos_capvigente_lc   TEXT[],
 otros_creditos_capvencido_lc   TEXT[],
 otros_creditos_intvenc_lc      TEXT[],
 otros_creditos_adeudo_lc      TEXT[],

 otros_creditos_proxmensualidad_lc TEXT[],
 otros_creditos_proxvence_lc       TEXT[],
 otros_creditos_noref_lc           TEXT[],
 otros_creditos_proxabono_lc       TEXT[],
 otros_creditos_proxinteres_lc     TEXT[], 
 otros_creditos_nopago_lc          TEXT[],

 otros_creditos_fechaini_lc        TEXT[], 
 otros_creditos_fechavence_lc      TEXT[], 
 otros_creditos_cat_lc             TEXT[], 
 otros_creditos_tasaio_lc          TEXT[], 
 otros_creditos_tasaim_lc          TEXT[], 
 otros_creditos_limite_lc          TEXT[],

otros_creditos_detfecha_lc        TEXT[],      
otros_creditos_detconcepto_lc     TEXT[],         
otros_creditos_detreferencia_lc   TEXT[],         
otros_creditos_detcargo_lc        TEXT[],      
otros_creditos_detabono_lc        TEXT[],      
otros_creditos_detsaldo_lc        TEXT[]      

);


CREATE OR REPLACE FUNCTION ofx_estado_cuenta_rutas_x_vence_v2()
 RETURNS SETOF ofx_estado_cuenta_rutas_x_vence_v2 AS $$
DECLARE

  -- Variables
  r                       ofx_estado_cuenta_rutas_x_vence_v2%ROWTYPE;
  ra                      RECORD;
  rac                     RECORD;
  rdt                     RECORD;
  rco                     RECORD;
  rsdofdet                RECORD;
  rsdofdm                 RECORD;
  rcreddet                RECORD; 
  rctas                   RECORD;
  rctassdo                RECORD;
  rctasp                  RECORD; 
  rmasdat                 RECORD; 
  rlin                    RECORD; 
  rocc                    RECORD; 
  rocdm                    RECORD; 
  rctassdode             RECORD; 
  rctassdodet            RECORD;
  rlc                    RECORD;
  rdalc                   RECORD;
  rmclc                   RECORD;
  rretsf                  RECORD;
  rdepsf                  RECORD;
  rsummov                 RECORD;
  raj                     RECORD;
  rda                     RECORD;
  rpp                      RECORD;

  ps_idsucaux             INTEGER:=0;
  ps_idproducto           INTEGER:=0;
  ps_idauxiliar           INTEGER:=0;
  ps_dfecha               DATE;
  ps_afecha               DATE;
  ps_idsucursal           INTEGER:=0;
  _nmovimientos           INTEGER;
  _limit_det              INTEGER;
  _kauxiliar              INTEGER;
  _detalle                TEXT;
  _res_mensual            TEXT:='';
  _tot_transaccion        NUMERIC:=0;
  _tot_litros             NUMERIC:=0;
  _tot_recaudo            NUMERIC:=0;
  _tot_precioxlt          NUMERIC:=0;
  _totales                TEXT;
  _recaudo                NUMERIC:=0;
  _deposito               NUMERIC:=0;
  pg_monto_fijo_segvida   NUMERIC;
  pg_monto_fijo_segunidad NUMERIC;
  pg_monto_fijo_gps       NUMERIC;
  factor_iva_io           NUMERIC;
  base_iva_io             NUMERIC;
  _seguro_vida            NUMERIC;
  _seguro_unidad          NUMERIC;
  _suguro_gps             NUMERIC;
  _mensualidad            NUMERIC:=0;
  _ctas_pago_finsus       TEXT[]:=string_to_array(ofpt('/formatos/ofx_estado_cuenta_rutas','ctas_pago_terceros','1102010111101,1102010111104,1102010111201,1102010111501,2401010211101,2401010211102,2401010211103,2401010211109,2401010211109,1401030711102'),',');
  _pago_finsus            NUMERIC:=0;
  _pago_finsus2           NUMERIC:=0;
  _pago_terceros          NUMERIC:=0;
  _dt                     INTEGER;
  _idpago                 INTEGER;
  _vence                  DATE;
  _folio_ticket           INTEGER:=-1;
  _idsucauxref            INTEGER;
  _idproductoref          INTEGER;
  _idauxiliarref          INTEGER;
  _idcuenta_terceros      TEXT:='2401010211101';
  _recaudo_periodo        NUMERIC:=0;
  _deposito_periodo       NUMERIC:=0;
  _pgo_terceros_periodo   NUMERIC:=0;
  _pgo_finsus_periodo     NUMERIC:=0;
  _saldo_periodo          NUMERIC:=0;
  --_fecha_mov              DATE;
  _finsus                 BOOLEAN; -- CLiente FINSUS
  _saldo_corte            NUMERIC:=0;
  _saldo_favor            NUMERIC:=0;
  _saldo_inicial          NUMERIC:=0;
  _dep_saldo_favor        NUMERIC:=0;
  _ret_saldo_favor        NUMERIC:=0;
  _saldo_anterior         NUMERIC:=0;
  _monto_pago             NUMERIC:=0;
  i                       INTEGER;
  _aplicacion_sdofavor    NUMERIC:=0;
  _saldo_favor_final      NUMERIC:=0;
  _deuda_inicial          NUMERIC:=0;
  _saldo_corte_ant        NUMERIC:=0;
  _recaudo_favor          NUMERIC:=0;
  _dv                     INTEGER; -- DGZZH Digito verificador
  _codigo                 TEXT;
  _referencia             TEXT;    -- Numero de referencia para acreditar depositos
  _referencia2             TEXT;    -- Numero de referencia para acreditar depositos
  _rocccodigo             INTEGER;      
  _roccdv                 TEXT;  
  _roccreferencia         TEXT;            
  _retiros_sdof NUMERIC;
  _sdoof                  NUMERIC;
  _sdoaf                  NUMERIC;
  _resumen_manual         BOOLEAN:=FALSE;
  _key                    INTEGER;
  _flag                   BOOLEAN:=FALSE;
  ii                      INTEGER:=0;
  _limit_det_recaudo      INTEGER:=0;
  _valid_emial            INTEGER;
  _nombrepfd              TEXT;
  _gen_pdfs               BOOLEAN;
  _ajuste4006oct          NUMERIC;
  _ajusterecaudooct       NUMERIC; 
  _ajustesdofavoroct      NUMERIC; 
  _r4006  RECORD;
  _pago4006    NUMERIC;
  _pagouno             DATE;
  _iva                    BOOLEAN;

  -- detalle saldo a favor
  sdofavor_det_fecha      TEXT:='';                
  sdofavor_det_concepto   TEXT:='';                   
  sdofavor_det_referencia TEXT:='';                     
  sdofavor_det_retiro     TEXT:='';                 
  sdofavor_det_deposito   TEXT:='';                   
  sdofavor_det_saldo      TEXT:='';                

  credito_det_fecha       TEXT:='';                
  credito_det_concepto    TEXT:='';                   
  credito_det_referencia  TEXT:='';                     
  credito_det_retiro      TEXT:='';                 
  credito_det_deposito    TEXT:='';                   
  credito_det_saldo       TEXT:='';    

  recaudo_fecha          TEXT:='';               
  recaudo_transaccion    TEXT:='';                     
  recaudo_contrato_gazel TEXT:='';                        
  recaudo_litros         TEXT:='';                
  recaudo_precioxlt      TEXT:='';                   
  recaudo_recaudo        TEXT:='';      
  _recaudo_nota          TEXT:='';                

  nmsdo                   INTEGER:=0;
  _spd_sdofav             NUMERIC:=0.00;
  _tasabruta              NUMERIC;
  sdo_favor_sdoini        TEXT;
  sdo_favor_dep           TEXT;        
  sdo_favor_reca          TEXT;         
  sdo_favor_ret           TEXT;        
  sdo_favor_io            TEXT;       
  sdo_favor_sdocorte      TEXT;        
  _segvida                NUMERIC:=0.00;
  _segunidad              NUMERIC:=0.00;
  _gps                    NUMERIC:=0.00;
  _gps_cero               INTEGER:=0;
  _svi_cero               INTEGER:=0;
  _sun_cero               INTEGER:=0;

  _com                    NUMERIC:=0.00;
  _comdif                    NUMERIC:=0.00;
  _comact                 NUMERIC:=0.00;
  mensualidad_periodo    NUMERIC:=0.00;
  _res_ctas              TEXT:='';               
  _res_ctas_saldos       TEXT:='';   
  _res_ctas_saldos_sum   NUMERIC:=0.00;

  _poliza_seg_auto       TEXT:='';                     
  _numeco                TEXT:='';            
  _vin                   TEXT:='';         
  _vigencia_polsegauto   DATE:=NULL;  
  _noc                   INTEGER:=0;
  _nocl                   INTEGER:=0;
  _segautooc            NUMERIC;      
  _segvidaoc            NUMERIC;      
  _gpsoc                NUMERIC;  
  _idpagopp              INTEGER;
  _ocdeuda              NUMERIC;
  _idpagoppact          INTEGER;  
  _ocmensualidad        NUMERIC;    
  _menssegvida          NUMERIC;    
  _menssegauto          NUMERIC;    
  pg_factor_iva_io  NUMERIC:=0.00; 
  _mensgps          NUMERIC; 

  _venceppsig              DATE;
  _abonoppsig             NUMERIC;   
  _ioppsig                NUMERIC; 
  _idpagoppsig            INTEGER;

  _rctasvence             TEXT;
  _rctascat               TEXT;

  _otros_creditos_detfecha   TEXT;
  _otros_creditos_detconcepto   TEXT;
  _otros_creditos_detreferencia   TEXT;
  _otros_creditos_detcargo   TEXT;
  _otros_creditos_detabono   TEXT;
  _otros_creditos_detsaldo   TEXT;

  _otros_creditos_detfecha_lc   TEXT;
  _otros_creditos_detconcepto_lc   TEXT;
  _otros_creditos_detreferencia_lc   TEXT;
  _otros_creditos_detcargo_lc   TEXT;
  _otros_creditos_detabono_lc   TEXT;
  _otros_creditos_detsaldo_lc   TEXT;

  _disposiciones            NUMERIC;
  _interes                  NUMERIC;
  _capvigente               NUMERIC;
  _abcapital                NUMERIC;

  _deudaanterior            NUMERIC;
  _credidpagoppsig          INTEGER;       
  _credvenceppsig           DATE;      
  _credabonoppsig           NUMERIC;      
  _credioppsig              NUMERIC;   
  _credivappsig             NUMERIC;   
  _proxsegvida              NUMERIC;  
  _proxsegauto                 NUMERIC;  
  _proxsegunidad            NUMERIC;      
  _proxgps                  NUMERIC;
  _proxcom                  NUMERIC;  
  _credproxsegvida         NUMERIC;         
  _credproxsegunidad       NUMERIC;           
  _credproxgps             NUMERIC;     
  _credproxcom             NUMERIC;
  _credproxcomdif             NUMERIC;
  _idpagoppactcre          INTEGER;      
  _segvidaact              NUMERIC;  
  _segunidadact            NUMERIC;    
  _gpsact                  NUMERIC;      
  _credproxmensualidad     NUMERIC;      
  _iodesc                  NUMERIC;      
  _iodincr                  NUMERIC;
   _iodifex                  NUMERIC;
   _iodifnoex             NUMERIC;
   _comdifact             NUMERIC;
   _menscom               NUMERIC;  
   _menscomdif            NUMERIC; 
   rctassdosaldo          NUMERIC;
   rctassdosaldofav       NUMERIC;
   _pnombre          TEXT;
   _iopagado         NUMERIC;
   _intdif            NUMERIC;
   _referenciad          TEXT;
   _deudamesanterior    NUMERIC;
   _credidpagoppact    INTEGER;           
   _credvenceppact     DATE;          
   _credabonoppact     NUMERIC;          
   _credioppact        NUMERIC;  
   _credivappact        NUMERIC; 
   _segvidaactm        NUMERIC;        
   _segunidadactm      NUMERIC;           
   _gpsactm            NUMERIC;    
   _comactm            NUMERIC;    
   _comdifactm         NUMERIC;              
   _saldoc             NUMERIC;  
   _montovencidoc      NUMERIC;  
   _deudamesactual    NUMERIC;       
   _comdifid          INTEGER;
   _credproxcomdesc   NUMERIC;
   _credproxcomincr   NUMERIC;
   _comisiondifca    NUMERIC;  
   _comisiondifcaab  NUMERIC; 
   _montovencidoanterior  NUMERIC;
   _saldoanterior        NUMERIC;
   _iopendant            NUMERIC;
   _abcredito           NUMERIC;
   _disposicionesm      NUMERIC:=0.00;
   _cargoslc            NUMERIC:=0.00;
   _dispacreidot        NUMERIC:=0.00;
   _bonificacion        NUMERIC:=0.00;
   _totrecaudo          NUMERIC:=0.00;     
   _totmensualidad      NUMERIC:=0.00;         
   _totdeposito         NUMERIC:=0.00;      
   _totpago_finsus      NUMERIC:=0.00;         
   _totpago_terceros    NUMERIC:=0.00;       
   _cargoajuste         NUMERIC:=0.00; 
   _tipoprestamo        INTEGER;
   _fechaultperiodoant  DATE;
   _capitalexigible    NUMERIC;     
   _capitalpagado      NUMERIC;   
   _capitalexcedente   NUMERIC;   
   _capitalexcedente_ant NUMERIC:=0.00;  
   _adeudopendiente       TEXT;  
   res     RECORD;
   _rendmiento            NUMERIC:=0.00;
   _depositopre           NUMERIC:=0.00;
   _vencetotal                 DATE;
   _seguro_vida_vencido     NUMERIC:=0.00;        
   _seguro_unidad_vencido   NUMERIC:=0.00;          
   _suguro_gps_vencido      NUMERIC:=0.00;   
   _abonos_pre_primerperiodo        NUMERIC:=0.00;   
   _interesexigible        NUMERIC;     
   _interespagado          NUMERIC;   
   _interesexcedente       NUMERIC;   
   _interesexcedente_ant   NUMERIC:=0.00;  
   _recaudoexcepcional     NUMERIC:=0.00; 
   _fechaactivacion        DATE; 
   _vence_anterior         DATE; 
   _resumendefecha         DATE; 
   _abpagadoda             NUMERIC:=0.00;                    
   _iopagadoda             NUMERIC:=0.00;                    
   _impagadoda             NUMERIC:=0.00;                    
   _ivapagadoda            NUMERIC:=0.00;   

   _abonopp                NUMERIC:=0.00;           
   _interespp              NUMERIC:=0.00;             
   _segvidapp              NUMERIC:=0.00;             
   _segunidadpp            NUMERIC:=0.00;               
   _gpspp                  NUMERIC:=0.00;         
   _compp                  NUMERIC:=0.00;       
   _iocredito              NUMERIC:=0.00;
   _ivacredito             NUMERIC:=0.00;  
   _segvidapagadoda        NUMERIC:=0.00;                 
   _segunidadpagadoda      NUMERIC:=0.00;                   
   _gpspagadoda            NUMERIC:=0.00;             
   _comdifpagadoda         NUMERIC:=0.00;                
   _comisionpagadoda       NUMERIC:=0.00;   
   _ivapend                NUMERIC:=0.00;  

   _segvidaactmd           NUMERIC:=0.00;
   _segunidadactmd         NUMERIC:=0.00;
   _gpsactmd               NUMERIC:=0.00;
   _compppagadoda          NUMERIC:=0.00;
   _paginas                INTEGER:=0;
   _ultpagina              INTEGER:=0;
   otros_creditos_pag_1    INTEGER:=0;
   otros_creditos_pag_2    INTEGER:=0;
   otros_creditos_pag_3    INTEGER:=0;
   otros_creditos_pag_4    INTEGER:=0;
   otros_creditos_pag_5    INTEGER:=0;
   otros_creditos_pag_6    INTEGER:=0;

BEGIN 
  pg_factor_iva_io := ROUND(ofpn('/socios/productos/prestamos','iva_io',0.00)/100.00,2) * 
                      ROUND(ofpn('/socios/productos/prestamos','base_iva_io',0.00)/100.00,2);
  
  ps_idsucaux      := of_ofx_get('ps_idsucaux');
  ps_idproducto    := of_ofx_get('ps_idproducto');
  ps_idauxiliar    := of_ofx_get('ps_idauxiliar');
  ps_dfecha        := of_ofx_get('ps_dfecha');
  ps_afecha        := of_ofx_get('ps_afecha');

  r.otros_creditos_prod           := '{}';           
  r.otros_creditos_prod_lc           := '{}';   
  r.otros_creditos                := '{}';          
  r.otros_creditos_mto_liquidar   := '{}';                       
  r.otros_creditos_mesanterior    := '{}';                      
  r.otros_creditos_mensualidad    := '{}';                      
  r.otros_creditos_abcapital      := '{}';                    
  r.otros_creditos_apcredito      := '{}';                    
  r.otros_creditos_sdofinal       := '{}';                   
  r.otros_creditos_capvigente     := '{}';                     
  r.otros_creditos_capvencido     := '{}';                     
  r.otros_creditos_intpendiente   := '{}';                       
  r.otros_creditos_segauto        := '{}';                  
  r.otros_creditos_segvida        := '{}';                  
  r.otros_creditos_gps            := '{}';              
  r.otros_creditos_intdif         := '{}';                 
  r.otros_creditos_adeudo         := '{}'; 
  r.otros_creditos_saldoliquidar  := '{}';        
  
  r.otros_creditos_proxmensualidad := '{}';
  r.otros_creditos_proxvence       := '{}';
  r.otros_creditos_noref           := '{}';

 -- Datos prox mensualidad
 r.otros_creditos_proxabono       := '{}';
 r.otros_creditos_proxinteres     := '{}';
 r.otros_creditos_proxsegauto     := '{}';
 r.otros_creditos_proxsegvida     := '{}';
 r.otros_creditos_proxgps         := '{}';
 r.otros_creditos_proxnopago      := '{}';
  r.otros_creditos_fechaini       := '{}';             
  r.otros_creditos_fechavence     := '{}';               
  r.otros_creditos_cat            := '{}';        
  r.otros_creditos_tasaio         := '{}';           
  r.otros_creditos_tasaim         := '{}';           
  r.otros_creditos_montoentregado := '{}';                   

  r.otros_creditos_detfecha       := '{}';       
  r.otros_creditos_detconcepto    := '{}';          
  r.otros_creditos_detconcepto    := '{}';          
  r.otros_creditos_detcargo       := '{}';       
  r.otros_creditos_detabono       := '{}';       
  r.otros_creditos_detsaldo       := '{}';    

  _otros_creditos_detfecha        :='';        
  _otros_creditos_detconcepto     :='';           
  _otros_creditos_detreferencia   :='';             
  _otros_creditos_detcargo        :='';        
  _otros_creditos_detabono        :='';        
  _otros_creditos_detsaldo        :='';             

  r.otros_creditos_mesanterior_lc  := '{}';  
  r.otros_creditos_disposiciones_lc := '{}';
  r.otros_creditos_interes_lc        := '{}';
  r.otros_creditos_apcredito_lc        := '{}';
  r.otros_creditos_sdofinal_lc   := '{}';     
  r.otros_creditos_capvigente_lc := '{}';
  r.otros_creditos_capvencido_lc := '{}';
  r.otros_creditos_intvenc_lc    := '{}';
  r.otros_creditos_adeudo_lc     := '{}';

  r.otros_creditos_proxmensualidad_lc :='{}';
  r.otros_creditos_proxvence_lc       :='{}';
  r.otros_creditos_noref_lc           :='{}';
  r.otros_creditos_proxabono_lc       :='{}';
  r.otros_creditos_proxinteres_lc     :='{}';
  r.otros_creditos_nopago_lc          :='{}';
  
  r.otros_creditos_fechaini_lc   := '{}';            
  r.otros_creditos_fechavence_lc := '{}';              
  r.otros_creditos_cat_lc        := '{}';       
  r.otros_creditos_tasaio_lc     := '{}';          
  r.otros_creditos_tasaim_lc     := '{}';          
  r.otros_creditos_limite_lc     := '{}';  

  r.otros_creditos_detfecha_lc      := '{}';
  r.otros_creditos_detconcepto_lc   := '{}';
  r.otros_creditos_detreferencia_lc := '{}';
  r.otros_creditos_detcargo_lc      := '{}';
  r.otros_creditos_detabono_lc      := '{}';
  r.otros_creditos_detsaldo_lc      := '{}';
  _otros_creditos_detfecha_lc        :='';        
  _otros_creditos_detconcepto_lc     :='';           
  _otros_creditos_detreferencia_lc   :='';             
  _otros_creditos_detcargo_lc        :='';        
  _otros_creditos_detabono_lc        :='';        
  _otros_creditos_detsaldo_lc        :='';     


  PERFORM of_param_sesion_set('vsr_vars','ps_idsucaux',ps_idsucaux::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_idproducto',ps_idproducto::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_idauxiliar',ps_idauxiliar::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_dfecha',ps_dfecha::TEXT);
  PERFORM of_param_sesion_set('vsr_vars','ps_afecha',ps_afecha::TEXT);

  factor_iva_io    := of_params_get('/socios/productos/prestamos','iva_io');
  base_iva_io      := of_params_get('/socios/productos/prestamos','base_iva_io');
  factor_iva_io    := ROUND((factor_iva_io /100.00),2);
  base_iva_io      := ROUND((base_iva_io /100.00),2);
  factor_iva_io    := factor_iva_io * base_iva_io;
  -- Obteniendo el limite de detalle para los movimientos.
  _limit_det_recaudo := of_params_get('/formatos/ofx_estado_cuenta_rutas','dt_limite');
  _gen_pdfs          := of_params_get_boolean('/formatos/ofx_estado_cuenta_rutas','gen_pdfs');
  
  SELECT INTO r * FROM ofx_forma_ec_estandar();
  DELETE FROM resumen_mensual_x_vence
        WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
  SELECT INTO res * FROM resumen_mensual_x_vence WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
  --RAISE NOTICE 'resumen %',res;
  r.__params := 'glds=gld01;gld02;gld03;gld04;gld05;';
  -- RFC de SUSTENTABLE para definir columna PAGO DE FINANCIERA SUSTENTABLE
  IF (r.suc_matriz_rfc = 'FSM121019LM6') THEN
    _finsus        := TRUE;
  ELSE
    _finsus        := FALSE;
  END IF;
  _idcuenta_terceros := of_params_get('/formatos/ofx_estado_cuenta_rutas','idcuenta_tercero');
  _detalle           := '';
  i                  := 0 ;
  --ps_idsucursal    := of_ofx_get('idsucaux');
  --PERFORM of_param_sesion_raise(NULL);
  -- Obniendo clave de kauxiliar
  SELECT INTO _kauxiliar,_referenciad,_tipoprestamo,_fechaactivacion 
              kauxiliar,referencia,tipoprestamo,fechaactivacion
    FROM deudores
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
  
  PERFORM * FROM edocta_res_mensual WHERE trim(auxiliar) = ps_idsucaux|+'-'|+ps_idproducto|+'-'|+ps_idauxiliar LIMIT 1;
  IF (FOUND) THEN -- Resumen mensual manipulado de forma manual por el usuario

    FOR ra IN SELECT *
                FROM edocta_res_mensual
               WHERE trim(auxiliar) = ps_idsucaux|+'-'|+ps_idproducto|+'-'|+ps_idauxiliar ORDER BY id LOOP
      _res_mensual     := _res_mensual |+
                          of_rellena(ra.fecha,24,' ',1)                        |+ ' ' |+ -- FECHA
                          to_char(coalesce(ra.recaudo,0),'999,999,990.00')     |+ ' ' |+ -- RECAUDOS
                          to_char(coalesce(ra.mensualidad,0),'999,999,990.00') |+ ' ' |+ -- MENSUALIDAD
                          to_char(coalesce(ra.deposito,0),'999,999,990.00')    |+ ' ' |+ -- DEPOSITOS
                          of_si(_finsus,'',to_char(coalesce(ra.pgo_tercero,0),'999,999,990.00') |+ ' ') |+ -- PGO FINSUS
                          to_char(of_si(_finsus,coalesce(ra.pgo_tercero),0),'999,999,990.00') |+ ' ' |+ -- PGO TERCEROS SIEMPRE EN CEROS PARA BEXICA
                          to_char(ra.saldo_mes,'999,999,990.00')               |+ ' ' |+ -- SALDO DEL MES
                          to_char(coalesce(ra.saldo_corte ,0),'999,999,990.00')|+ ' ' |+ -- SALDO AL CORTE
                          E'\n';
      _saldo_anterior := ra.saldo_corte;
      IF (lower(of_fecha_nombre(of_fecha_dum(ps_afecha),1)) = lower(trim(ra.fecha))) THEN
        _recaudo_periodo      := coalesce(ra.recaudo,0);
        _deposito_periodo     := coalesce(ra.deposito,0);
        _pgo_terceros_periodo := of_(_finsus,ra.pgo_tercero,0);
        _pgo_finsus_periodo   := ra.pgo_tercero;
        _monto_pago           := ra.mensualidad;
      END IF;
    END LOOP;
    _resumen_manual := TRUE;
  END IF;
  -- Obteniedo saldo a favor con producto 2001
  SELECT INTO  _idsucauxref, _idproductoref, _idauxiliarref
         idsucauxref,idproductoref,idauxiliarref
    FROM of_auxiliar_ref(ps_idsucaux,ps_idproducto,ps_idauxiliar,2001);
  
  -- La fecha de corte o inicial es al día 29/02/2016
  SELECT INTO _deuda_inicial sum(abono+interes_total+costos_asociados)
    FROM cartera
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND fecha='29/02/2016';
  
  SELECT INTO _pagouno vence 
    FROM planpago WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar)  AND idpago=1;    
  
  SELECT INTO _vencetotal max(vence)
    FROM planpago WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);

  SELECT INTO _saldo_favor,_tasabruta saldoinicial,tasa
    FROM acreedores 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) AND referencia='import';
  
  SELECT INTO _tasabruta tasa
    FROM acreedores 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) ;   
  _tasabruta := COALESCE(_tasabruta,0.00);
  --IF (NOT FOUND) THEN
  --  _saldo_favor  := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,'29/02/2016');
  --END IF;
  --_saldo_favor := COALESCE(_saldo_favor,0.00);


  --IF (_pagouno = '31/07/2021'::DATE) THEN
  --  _saldo_favor  := _saldo_favor +  COALESCE(of_auxiliar_saldo(_idsucauxref, _idproductoref, _idauxiliarref, '30/06/2021'),0.00);
  --END IF;
  _fechaultperiodoant := of_fecha_dpm(_pagouno)-1;  
  --_saldo_favor  := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,_fechaultperiodoant);
  _saldo_favor  := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,_fechaactivacion);
  _saldo_favor  := COALESCE(_saldo_favor,0.00);

  --IF ((_idsucauxref, _idproductoref, _idauxiliarref)=(1,2001,8044)) THEN
  --  _saldo_favor  := _saldo_favor +  COALESCE(of_auxiliar_saldo(_idsucauxref, _idproductoref, _idauxiliarref, '30/04/2021'),0.00);
  --END IF;


  --RAISE NOTICE 'DEUDA INICIAL %',ps_idproducto;  
  -- _saldo_corte_ant := _saldo_favor  + (_deuda_inicial*-1);
  -- _saldo_corte := _saldo_favor  + (_deuda_inicial*-1);
  _saldo_corte_ant := (coalesce(_deuda_inicial,0)*-1) + coalesce(_saldo_favor,0);

  --RAISE NOTICE 'SALDO INI: % _deuda_inicial %  _saldo_favor % fechaactivacion %',_saldo_corte_ant,_deuda_inicial,_saldo_favor,_fechaactivacion;
  --_saldo_inicial  := _saldo_favor + _saldo_corte_ant;
    --SELECT INTO _abonos_pre_primerperiodo 
    --            sum(abono)+sum(montoio)+sum(montoim)+sum(montoimp)+sum(montoca) 
    --  FROM detalle_auxiliar 
    -- WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
    --       periodo<of_periodo(_pagouno)::integer and cargo=0;
    _abonos_pre_primerperiodo := COALESCE(_abonos_pre_primerperiodo,0.00);
  
    _saldo_corte_ant := _saldo_corte_ant + _abonos_pre_primerperiodo;
  --RAISE NOTICE '_abonos_pre_primerperiodo % _saldo_favor %',_abonos_pre_primerperiodo,_saldo_favor;
  IF (NOT _resumen_manual) THEN
    _res_mensual  := of_rellena(' ',24,' ', 1)   |+ ' ' |+ -- FECHA
                     of_rellena('0.00',15,' ',2) |+ ' ' |+ -- RECAUDOS
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                     of_rellena('0.00',15,' ',2) |+ ' ' |+
                      to_char(coalesce(_saldo_corte_ant,0),'999,999,990.00')|+ E'\n';
  END IF;
  -- Obniendo Numero de contrato GAZEL
  -- DGZZH 04/08/2016 contrato_gazel guardarlo en una variable aparte
  SELECT INTO rco contrato_gazel FROM ofx_multicampos_auxiliar_masdatos_sus(_kauxiliar);
  -- Obteniedo numero de detalle de movimientos
  --SELECT INTO _nmovimientos count(*)
  --  FROM planpago
  -- WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
  --       vence BETWEEN '01/03/2016' AND ps_afecha;
  --_nmovimientos := coalesce(_nmovimientos,0);
  
  --IF (_nmovimientos > 0) THEN
    SELECT INTO pg_monto_fijo_segvida, pg_monto_fijo_segunidad, pg_monto_fijo_gps
                COALESCE(segvida,0.00), COALESCE(segunidad,0.00), COALESCE(gps,0.00)
      FROM ofx_multicampos_sustentable.auxiliar_masdatos
     WHERE kauxiliar = _kauxiliar;
    SELECT INTO _gps_cero, _svi_cero, _sun_cero COALESCE(gps_cero,0), COALESCE(svi_cero,0), COALESCE(sun_cero,0) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;

    RAISE NOTICE 'datos %,%,%     %,%,%      %, a fecha %' ,ps_idsucaux,ps_idproducto,ps_idauxiliar,_idsucauxref,_idproductoref,_idauxiliarref,_referenciad,ps_afecha;
    --FOR ra IN SELECT * FROM of_periodos_entre_fechas(of_si(_pagouno <= '31/03/2016', '31/03/2016', _pagouno::TEXT)::DATE, ps_afecha) LOOP
    FOR ra IN SELECT * FROM planpago 
                WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND vence<=of_si(ps_afecha<_pagouno,_pagouno::TEXT,ps_afecha::TEXT)::DATE LOOP
      
      _mensualidad := ra.abono + ra.io;

      _iva := of_iva_general(ps_idsucaux,ps_idproducto,ps_idauxiliar,_tipoprestamo,ra.vence);
       RAISE NOTICE 'IVA========== %',_iva;

      IF (_iva) THEN
        _mensualidad := _mensualidad + round((round(ra.io,2)*round(factor_iva_io,2)),2);
      END IF;

      -- Accesorios del plan pago.
      -- Seguro Vida
      _mensualidad := _mensualidad + COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,ra.idpago,1,1),0.00);
      -- Unidad
      _mensualidad := _mensualidad + COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,ra.idpago,2,1),0.00);
      -- GPS
      _mensualidad := _mensualidad + COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,ra.idpago,3,1),0.00);

      IF (ra.idpago=1) THEN
        _resumendefecha := _fechaactivacion + 1;
      ELSE
        SELECT INTO _resumendefecha vence 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND idpago=ra.idpago-1;
         _resumendefecha := _resumendefecha + 1;
      END IF;
     --RAISE NOTICE 'resumen de fecha %',_resumendefecha;
      FOR rda IN SELECT * 
                  FROM detalle_auxiliar 
                 WHERE ((idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) OR 
                        (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref)) AND 
                        fecha BETWEEN _resumendefecha AND ra.vence ORDER BY secuencia LOOP
        i := i + 1;
        -- Por si se pone la referencia por fuera hacemos comparación sin acentos ni signos, y en minúsculas
        IF (lower(translate(rda.referencia,'áéíóúÁÉÍÓÚäëïöüÄËÏÖÜ','aeiouAEIOUaeiouAEIOU')) ~ 'recaudo de abonos') THEN 
          _recaudo := _recaudo + rda.abono;
        END IF;

        IF (lower(translate(rda.referencia,'áéíóúÁÉÍÓÚäëïöüÄËÏÖÜ','aeiouAEIOUaeiouAEIOU')) ~ ('deposito bancario')) THEN
          _deposito := _deposito + rda.abono;
        END IF;

        IF (of_producto_subtipo(rda.idproducto)='AHO' AND lower(translate(rda.referencia,'áéíóúÁÉÍÓÚäëïöüÄËÏÖÜ','aeiouAEIOUaeiouAEIOU')) ~ ('deposito referenciado')) THEN
          _deposito := _deposito + rda.abono;
        END IF;        

        IF (of_producto_subtipo(rda.idproducto)='AHO' AND lower(rda.referencia)~'capitaliza') THEN
          _deposito := _deposito + rda.abono;
        END IF;        


        IF (lower(translate(rda.referencia,'áéíóúÁÉÍÓÚäëïöüÄËÏÖÜ','aeiouAEIOUaeiouAEIOU')) ~ 'bonificacion') THEN
          _deposito := _deposito + rda.abono;
        END IF;

        IF (rda.referencia ='' AND of_producto_subtipo(rda.idproducto)='PRE') THEN
          SELECT INTO rdepsf cargo AS abono 
            FROM detalle_auxiliar 
           WHERE folio_ticket = rda.folio_ticket  AND  (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) and cargo>0;       
          IF (NOT FOuND) THEN
            _deposito := _deposito + rda.abono + rda.montoio + rda.montoimp + rda.montoca;
          END IF;
        END IF;    

        IF (rda.referencia ='' AND of_producto_subtipo(rda.idproducto)='AHO') THEN
          _deposito := _deposito + rda.abono + rda.montoio + rda.montoimp + rda.montoca;
        END IF;             
      END LOOP;
      
      _retiros_sdof  := 0.00;
      _pago_terceros := 0.00;
      FOR rretsf IN SELECT *
                       FROM detalle_auxiliar
                      WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref,_idproductoref,_idauxiliarref) AND 
                          (fecha BETWEEN _resumendefecha AND ra.vence) AND cargo>0.00 AND
                            referencia!~'aplicación a crédito'
      LOOP
        _retiros_sdof  := _retiros_sdof + COALESCE(rretsf.cargo,0.00);
        _pago_terceros := _pago_terceros + COALESCE(rretsf.cargo,0.00);
        --RAISE NOTICE 'ra.periodo % _retiros_sdof %, _pago_terceros %',ra.periodo,_retiros_sdof,_pago_terceros;
        SELECT INTO rdepsf sum(abono+montoio+montoim+montoimp+montoca) AS abono 
          FROM detalle_auxiliar 
         WHERE folio_ticket = rretsf.folio_ticket  AND  (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
        --IF (FOUND) THEN
        --_pago_terceros := _pago_terceros + _retiros_sdof;
        --  --RAISE NOTICE 'antes ra.periodo % _pago_terceros, % abono %',ra.periodo,_pago_terceros,COALESCE(rdepsf.abono,0.00);
        _pago_terceros := _pago_terceros - COALESCE(rdepsf.abono,0.00);
        --  RAISE NOTICE 'ra.periodo % _pago_terceros %',ra.periodo,_pago_terceros;
        --END IF;
      END LOOP;


      _saldo_periodo     := (_mensualidad*-1) + (_recaudo + _deposito) - COALESCE(_pago_terceros,0.00);
      _saldo_corte       := _saldo_corte_ant + _saldo_periodo;
      _saldo_corte_ant := coalesce(_saldo_corte,0.00);
        IF (NOT _resumen_manual) THEN
          _res_mensual     := _res_mensual |+
                              of_rellena(of_fecha_nombre(ra.vence,1)::TEXT,24,' ',1) |+ ' ' |+ -- FECHA
                              to_char(coalesce(_recaudo    ,0),'999,999,990.00') |+ ' ' |+                       -- RECAUDOS
                              to_char(coalesce(_mensualidad,0),'999,999,990.00') |+ ' ' |+                       -- MENSUALIDAD
                              to_char(coalesce(_deposito   ,0),'999,999,990.00') |+ ' ' |+                       -- DEPOSITOS
                              to_char(coalesce(_disposicionesm   ,0),'999,999,990.00') |+ ' ' |+                       -- DEPOSITOS
                              of_si(_finsus,'',to_char(coalesce(_pago_finsus,0),'999,999,990.00') |+ ' ') |+     -- *PGO FINSUS
                              to_char(coalesce(_pago_terceros,0),'999,999,990.00') |+ ' ' |+                     -- *PGO TERCEROS
                              to_char(_saldo_periodo,'999,999,990.00') |+ ' ' |+ -- SALDO DEL MES
                              to_char(coalesce(_saldo_corte,0),'999,999,990.00')|+ ' '|+ -- SALDO AL CORTE
                              E'\n';
        ELSIF (of_periodo(ra.vence)::INTEGER>201606) THEN
         _res_mensual     := _res_mensual |+
                              of_rellena(of_fecha_nombre(ra.vence,1)::TEXT,24,' ',1) |+ ' ' |+ -- FECHA
                              to_char(coalesce(_recaudo    ,0),'999,999,990.00') |+ ' ' |+                       -- RECAUDOS
                              to_char(coalesce(_mensualidad,0),'999,999,990.00') |+ ' ' |+                       -- MENSUALIDAD
                              to_char(coalesce(_deposito   ,0),'999,999,990.00') |+ ' ' |+                       -- DEPOSITOS
                              of_si(_finsus,'',to_char(coalesce(_pago_finsus,0),'999,999,990.00') |+ ' ') |+     -- *PGO FINSUS
                              to_char(coalesce(_pago_terceros,0),'999,999,990.00') |+ ' ' |+                     -- *PGO TERCEROS
                              to_char(_saldo_periodo,'999,999,990.00') |+ ' ' |+ -- SALDO DEL MES
                              to_char(coalesce(_saldo_corte ,0),'999,999,990.00')|+ ' '|+ -- SALDO AL CORTE
                              E'\n';      
        END IF;

        INSERT INTO resumen_mensual_x_vence
          VALUES (ps_idsucaux,ps_idproducto,ps_idauxiliar,of_fecha_nombre(ra.vence,1),
                  coalesce(_recaudo    ,0),coalesce(_mensualidad,0),coalesce(_deposito   ,0),coalesce(_pago_finsus,0),
                  coalesce(_pago_terceros,0),coalesce(_saldo_periodo,0),coalesce(_saldo_corte ,0),COALESCE(_disposicionesm,0));
        _totrecaudo       := _totrecaudo + COALESCE(_recaudo,0.00);
        _totdeposito      := _totdeposito + COALESCE(_deposito,0.00);
        _totmensualidad   := _totmensualidad + COALESCE(_mensualidad,0.00);
        _totpago_finsus   := _totpago_finsus + COALESCE(_disposicionesm,0.00);
        _totpago_terceros := _totpago_terceros + COALESCE(_pago_terceros,0.00);
        _totrecaudo       := COALESCE(_totrecaudo,0.00);     
        _totmensualidad   := COALESCE(_totmensualidad,0.00);         
        _totdeposito      := COALESCE(_totdeposito,0.00);      
        _totpago_finsus   := COALESCE(_totpago_finsus,0.00);         
        _totpago_terceros := COALESCE(_totpago_terceros,0.00);        

       _recaudo        := 0.00;         
       _mensualidad    := 0.00;           
       _deposito       := 0.00;        
       _disposicionesm := 0.00;              
       _pago_terceros  := 0.00;                     

    END LOOP;
  --END IF;
  --FOR res IN SELECT * FROM resumen_mensual WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) LOOP
  --  RAISE NOTICE 'res2 %',res;
  --END LOOP;
  r.totrecaudo       := to_char(COALESCE(_totrecaudo,0.00),'FM999,999,990.90');
  r.totmensualidad   := to_char(COALESCE(_totmensualidad,0.00),'FM999,999,990.90');
  r.totdeposito      := to_char(COALESCE(_totdeposito,0.00),'FM999,999,990.90');
  r.totpago_finsus   := to_char(COALESCE(_totpago_finsus,0.00),'FM999,999,990.90');
  r.totpago_terceros := to_char(COALESCE(_totpago_terceros,0.00),'FM999,999,990.90');


  SELECT INTO _idpagoppactcre idpago 
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence=ra.vence;

  SELECT INTO _iodifex, _iodifnoex sum(io_desc),sum(io_incr) 
    FROM ppv.planpago_escalonado 
   WHERE kauxiliar=_kauxiliar AND idpago<=_idpagoppactcre;
  --RAISE NOTICE '_iodifex %, _iodifnoex %',_iodifex, _iodifnoex;
  -- DGZZH Días del periodo, solo considerar el ultimo mes del periodo consultado
  r.plazo       := of_solo_numeros(r.plazo)|+ ' MESES';
  r.diasperiodo := extract(day FROM of_fecha_dum(ra.vence));
  -- Monto pago
  r.montopago   := to_char(_monto_pago,'FM999,999,990.00');
  r.psaldofin   := to_char(coalesce((_saldo_corte)*-1,0),'FM999,999,990.00');
  r.psaldoini   := to_char(coalesce(_saldo_anterior,0),'FM999,999,990.00');
  _codigo       := of_rellena(_kauxiliar::TEXT,9,'0',2);
  _dv           := of_dv_gen(_codigo);
  _referencia2  := _kauxiliar::TEXT |+ _dv;
  _referencia   := _codigo |+ _dv;
  
  SELECT INTO _credidpagoppsig,_credvenceppsig,_credabonoppsig,_credioppsig 
              idpago,vence,abono,io 
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence=r.proximo_abono::DATE;

  SELECT INTO _credidpagoppact,_credvenceppact,_credabonoppact,_credioppact 
              max(idpago),max(vence),sum(abono),sum(io)
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence BETWEEN of_fecha_dpm(ra.vence) AND ra.vence;

  --RAISE NOTICE 'PLANPAGO ================== %, %, %',ps_idauxiliar,ps_idproducto,ps_idauxiliar;

  SELECT INTO _segvida COALESCE(abono,0.00) FROM of_ca_seguro_vida_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,1,ra.vence,FALSE);
  SELECT INTO _segunidad COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_seguro_unidad_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,2,ra.vence,FALSE);
  SELECT INTO _gps COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_gps_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,3,ra.vence,FALSE);
  SELECT INTO _com COALESCE(abono,0.00) FROM of_ca_entresinplacas_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,4,ra.vence,FALSE);
  SELECT INTO _comdif COALESCE(abono,0.00) FROM of_ca_interes_diferido(ps_idsucaux,ps_idproducto,ps_idauxiliar,5,ra.vence,FALSE);

/*
  SELECT INTO _segvidaact valor 
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
  SELECT INTO _segunidadact round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

  SELECT INTO _gpsact round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

  SELECT INTO _comact round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;  

  SELECT INTO _comdifact round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppactcre AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;           
*/
  -- CORREGIR Y TOMAR AUXILIARES_CA y DETALLE_AUXILIAR_CA 
  --SELECT INTO _segvidaact COALESCE(abono,0.00) FROM of_ca_seguro_vida_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,1,ps_afecha,FALSE);
  --SELECT INTO _segunidadact COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_seguro_unidad_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,2,ps_afecha,FALSE);
  --SELECT INTO _gpsact COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_gps_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,3,ps_afecha,FALSE);
  --SELECT INTO _comact COALESCE(abono,0.00) FROM of_ca_entresinplacas_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,4,ps_afecha,FALSE);
  --SELECT INTO _comdifact COALESCE(abono,0.00) FROM of_ca_interes_diferido(ps_idsucaux,ps_idproducto,ps_idauxiliar,5,ps_afecha,FALSE);
  SELECT INTO _segvidaact saldo FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=1;
  SELECT INTO _segunidadact saldo*(pg_factor_iva_io+1) FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=2;
  SELECT INTO _gpsact saldo*(pg_factor_iva_io+1) FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=3;
  SELECT INTO _comact saldo FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=4;
  SELECT INTO _comdifact saldo FROM auxiliares_ca WHERE kauxiliar=_kauxiliar AND idcosto=5;
  r.psaldofin   := to_char(round(of_numeric(r.psaldofin)-COALESCE(_iodifex,0.00)+COALESCE(_comdifact,0.00),2),'FM999,999,990.90');  
  _segvidaact   := COALESCE(_segvidaact,0.00);          
  _segunidadact := COALESCE(_segunidadact,0.00);            
  _gpsact       := COALESCE(_gpsact,0.00);      
  _comact       := COALESCE(_comact,0.00);      
  _comdifact    := COALESCE(_comdifact,0.00);         

  --SELECT INTO _credproxsegvida COALESCE(abono,0.00) FROM of_ca_seguro_vida_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,1,r.proximo_abono,FALSE);
  --SELECT INTO _credproxsegunidad COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_seguro_unidad_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,2,r.proximo_abono,FALSE);
  --SELECT INTO _credproxgps COALESCE(abono*(pg_factor_iva_io+1),0.00) FROM of_ca_gps_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,3,r.proximo_abono,FALSE);
  SELECT INTO _credproxcom COALESCE(abono,0.00) FROM of_ca_entresinplacas_sust(ps_idsucaux,ps_idproducto,ps_idauxiliar,4,r.proximo_abono,FALSE);
  SELECT INTO _credproxcomdif COALESCE(abono,0.00) FROM of_ca_interes_diferido(ps_idsucaux,ps_idproducto,ps_idauxiliar,5,r.proximo_abono,FALSE);
  SELECT INTO _credproxsegvida * FROM of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_credidpagoppsig,1,3);
  SELECT INTO _credproxsegunidad * FROM of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_credidpagoppsig,2,3);
  SELECT INTO _credproxgps * FROM of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_credidpagoppsig,3,3);

  _credproxsegvida   := COALESCE(_credproxsegvida,0.00);
  _credproxsegunidad := COALESCE(_credproxsegunidad,0.00);
  _credproxgps       := COALESCE(_credproxgps,0.00);
  _credproxcom       := COALESCE(_credproxcom,0.00);
  _credproxcomdif    := COALESCE(_credproxcomdif,0.00);

  _credproxsegvida := _credproxsegvida ;
  _credproxsegunidad := _credproxsegunidad ;
  
  --RAISE NOTICE '+++++ gps %, %',_credproxgps, _gpsact;
  _credproxgps := _credproxgps ;
  _credproxcom    := _credproxcom - _comact;
  _credproxcomdif := _credproxcomdif - _comdifact;


  IF (_credidpagoppact=1) THEN
    _dt            :=  _credvenceppact - r.fechaentrega;
    --SELECT INTO _segvidaactm segvid_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
    --IF (COALESCE(_segvidaactm,0.00)=0.00) THEN
    --  _segvidaactm   := COALESCE(trunc(((pg_monto_fijo_segvida / 30) * _dt::INTEGER),2),0.00); -- Sin iva
    --END IF;
--
--    --SELECT INTO _segunidadactm seguni_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
--    --IF (COALESCE(_segunidadactm,0.00)=0.00) THEN
--    --  _segunidadactm   := COALESCE(trunc(((pg_monto_fijo_segunidad / 30) * _dt::INTEGER),2),0.00); -- Sin iva
--    --END IF;
--
--    --SELECT INTO _gpsactm gps_1 FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
--    --IF (COALESCE(_gpsactm,0.00)=0.00) THEN
--    --  _gpsactm   := COALESCE(trunc(((pg_monto_fijo_gps / 30) * _dt::INTEGER),2),0.00); -- Sin iva
--    --END IF;     
--    --_segunidadactm := round(_segunidadactm*(pg_factor_iva_io+1),2);
    --_gpsactm       := round(_gpsactm*(pg_factor_iva_io+1),2);
  ELSE
--    SELECT INTO _segvidaactm valor 
--        FROM auxiliares_anexo 
--       WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_credidpagoppact AND 
--             kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
--          
--    SELECT INTO _segunidadactm round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
--        FROM auxiliares_anexo 
--       WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_credidpagoppact AND 
--             kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   
--
--    SELECT INTO _gpsactm round(valor::NUMERIC*(pg_factor_iva_io+1),2)
--        FROM auxiliares_anexo 
--       WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_credidpagoppact AND 
--             kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
  END IF;

  SELECT INTO _comactm round(valor::NUMERIC*(pg_factor_iva_io+1),2)
      FROM auxiliares_anexo 
     WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_credidpagoppact AND 
           kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

  --SELECT INTO _comdifactm round(valor::NUMERIC,2)
  --    FROM auxiliares_anexo 
  --   WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_credidpagoppact AND 
  --         kauxiliar=_kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;     
  -- QUITAR DIFERIDO REVISAR COMISION PORQUE DEBE ESTAR EN CERO (ID 5) _comdif
  SELECT INTO _comdifactm,_comdifid comision_id,com_id_cero FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar = _kauxiliar;
  IF (_credidpagoppact<=_comdifid) THEN
    _comdifactm := 0.00;
  END IF;
  _comdifactm := COALESCE(_comdifactm,0.00);
  IF (_iva) THEN
    _credivappact := round((round(_credioppact,2)*round(factor_iva_io,2)),2);
  END IF;
  --RAISE NOTICE '_idpagoppactcre %',_idpagoppactcre;
  
  SELECT INTO _segvidaactmd,_segunidadactmd,_gpsactmd 
              sum(COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,idpago,1,2),0.00)),
              sum(COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,idpago,2,2),0.00)),
              sum(COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,idpago,3,2),0.00)) 
    FROM planpago WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND idpago<=_idpagoppactcre;

  --_segvidaactm := COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_idpagoppactcre,1,1),0.00);
  --_segunidadactm := COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_idpagoppactcre,2,1),0.00);
  --_gpsactm := COALESCE(of_jason_ca_pago(ps_idsucaux,ps_idproducto,ps_idauxiliar,_idpagoppactcre,3,1),0.00);

  _segvidaactmd   := COALESCE(_segvidaactmd,0.00);
  _segunidadactmd := COALESCE(_segunidadactmd,0.00);
  _gpsactmd       := COALESCE(_gpsactmd,0.00);
  
  _segvidaactm := _segvidaactmd;
  _segunidadactm := _segunidadactmd;
  _gpsactm := _gpsactmd;
  --_segvidaactm   := COALESCE(_segvidaactm,0.00);
  --_segunidadactm := COALESCE(_segunidadactm,0.00);
  --_gpsactm       := COALESCE(_gpsactm,0.00);

  RAISE NOTICE 'COALESCE(_credabonoppact,0.00) %
                COALESCE(_credioppact,0.00) %  
                COALESCE(_credivappact,0.00) %
                COALESCE(_segvidaactm,0.00) %
                COALESCE(_segunidadactm,0.00) %
                COALESCE(_gpsactm,0.00) %
                COALESCE(_comactm,0.00) %
                COALESCE(_comdifactm,0.00) %',
                COALESCE(_credabonoppact,0.00), 
                COALESCE(_credioppact,0.00),
                COALESCE(_credivappact,0.00),
                COALESCE(_segvidaactm,0.00),
                COALESCE(_segunidadactm,0.00),
                COALESCE(_gpsactm,0.00),
                COALESCE(_comactm,0.00),
                COALESCE(_comdifactm,0.00);
  mensualidad_periodo := COALESCE(_credabonoppact,0.00) + COALESCE(_credioppact,0.00) +  COALESCE(_credivappact,0.00)+  COALESCE(_segvidaactmd,0.00) +  COALESCE(_segunidadactmd,0.00) +  COALESCE(_gpsactmd,0.00) + COALESCE(_comactm,0.00) + COALESCE(_comdifactm,0.00); 

  sdofavor_det_fecha      := '';           
  sdofavor_det_concepto   := '';              
  sdofavor_det_referencia := '';                
  sdofavor_det_retiro     := '';            
  sdofavor_det_deposito   := '';              
  sdofavor_det_saldo      := '';  
  
  credito_det_fecha      := '';           
  credito_det_concepto   := '';              
  credito_det_referencia := '';                
  credito_det_retiro     := '';            
  credito_det_deposito   := '';              
  credito_det_saldo      := '';          
  nmsdo                   := 0;   
  _spd_sdofav             := round(of_auxiliar_spd(_idsucauxref,_idproductoref,_idauxiliarref,of_fecha_dpm(ps_afecha),ps_afecha),2);
  --sdo_favor_sdoini        := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,of_fecha_dpm(ps_afecha));
  sdo_favor_sdoini        := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,ps_dfecha-1);
  sdo_favor_sdocorte    := of_auxiliar_saldo(_idsucauxref,_idproductoref,_idauxiliarref,ps_afecha);


  
  SELECT INTO rsdofdm COALESCE(sum(montoimp)+sum(montoio),0.00) AS int_isr
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha); 
  
  SELECT INTO sdo_favor_dep sum(abono)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         --AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha) AND referencia!~'Recaudo' AND referencia!~'Int'; 
         AND fecha BETWEEN ps_dfecha AND ps_afecha AND referencia!~'Recaudo' AND referencia!~'Int'; 

  SELECT INTO sdo_favor_reca sum(abono)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         --AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha) AND referencia~'Recaudo'; 
         AND fecha BETWEEN ps_dfecha AND ps_afecha AND referencia~'Recaudo'; 

  SELECT INTO sdo_favor_ret sum(cargo)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         --AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha) AND cargo>0;
         AND fecha BETWEEN ps_dfecha AND ps_afecha AND cargo>0;

  SELECT INTO sdo_favor_io sum(montoio)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucauxref, _idproductoref, _idauxiliarref) 
         AND fecha BETWEEN ps_dfecha AND ps_afecha; 

  sdo_favor_dep  := COALESCE(sdo_favor_dep,'0.00');   
  sdo_favor_reca := COALESCE(sdo_favor_reca,'0.00');    
  sdo_favor_ret  := COALESCE(sdo_favor_ret,'0.00');   
  sdo_favor_io   := COALESCE(sdo_favor_io,'0.00');  

  FOR rsdofdet IN SELECT fecha,concepto,retiro,deposito,saldo, idsucpol,tipopol,periodo,idpoliza,
                         of_si(referencia~'Retencion',
                               (SELECT of_si(arr[1]::TEXT~'Pago Interes',
                                       substring(arr[1]::TEXT,1,12),
                                       of_si(arr[1]::TEXT~'Capitaliza Interes',
                                             substring(arr[1]::TEXT,1,18),
                                             arr[1]::TEXT))||', '||arr[2] 
                                  FROM string_to_array(referencia,',') as arr),
                               referencia) AS referencia
                    FROM of_edoctaxaux(_idsucauxref,_idproductoref,_idauxiliarref,ps_dfecha,ps_afecha) where folio_ticket<>0 AND referencia !~'Pago Interes:' ORDER BY secuencia LOOP
    sdofavor_det_fecha := sdofavor_det_fecha |+ COALESCE(rsdofdet.fecha::TEXT,'') |+ E'\n';
    IF (rsdofdet.concepto~'Depósito en Ahorro') THEN
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(substring(rsdofdet.concepto,1,19),'') |+ E'\n';
    ELSIF (rsdofdet.concepto~'Retiro de Ahorro') THEN
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(substring(rsdofdet.concepto,1,16),'') |+ E'\n';
    ELSIF (rsdofdet.concepto~'Pago de Interés Bruto') THEN
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(substring(rsdofdet.concepto,1,16),'') |+ E'\n';
    ELSE
      sdofavor_det_concepto := sdofavor_det_concepto |+ COALESCE(rsdofdet.concepto::TEXT,'') |+ E'\n';
    END IF;

    PERFORM * FROM fs_etiquetas_noborrar
      WHERE (idsucpol,tipopol,periodo,idpoliza)=(rsdofdet.idsucpol, rsdofdet.tipopol, rsdofdet.periodo::INTEGER, rsdofdet.idpoliza);
    IF (FOUND) THEN
      sdofavor_det_referencia := sdofavor_det_referencia |+ COALESCE('Déposito recibido a través de Gasera','') |+ E'\n';
    ELSEIF ((rsdofdet.idsucpol, rsdofdet.tipopol, rsdofdet.periodo::INTEGER, rsdofdet.idpoliza)=(1,1,202110,8328) OR (rsdofdet.idsucpol, rsdofdet.tipopol, rsdofdet.periodo::INTEGER, rsdofdet.idpoliza)=(1,1,202110,8329)) THEN
          sdofavor_det_referencia := sdofavor_det_referencia |+ COALESCE('Déposito de Posibilidades Verdes','') |+ E'\n';
    ELSE
      sdofavor_det_referencia := sdofavor_det_referencia |+ COALESCE(rsdofdet.referencia,'') |+ E'\n';
    END IF;

    --sdofavor_det_referencia := sdofavor_det_referencia |+ COALESCE(rsdofdet.referencia,'') |+ E'\n';
    sdofavor_det_retiro     := sdofavor_det_retiro |+ COALESCE(to_char(rsdofdet.retiro,'FM999,999,990.90'),'') |+ E'\n';
    sdofavor_det_deposito   := sdofavor_det_deposito |+ COALESCE(to_char(rsdofdet.deposito,'FM999,999,990.90'),'') |+ E'\n';
    sdofavor_det_saldo      := sdofavor_det_saldo |+ COALESCE(to_char(rsdofdet.saldo,'FM999,999,990.90'),'') |+ E'\n';
    nmsdo := nmsdo + 1;
    IF (nmsdo >= 23) THEN
      _flag           := TRUE; -- Detalle de recaudos mas de una hoja
      --r.__params      := 'glds=gld01,gld02,gld03,gld04,gld05,gld06,gld07,gld08,gld09,gld10';-- Impresion de la hoja 3 (Detalle de recaudos)
      --RAISE NOTICE '============================================ notice 1';
      --RETURN NEXT r;   
      sdofavor_det_fecha      := '';            
      sdofavor_det_concepto   := '';               
      sdofavor_det_referencia := '';                
      sdofavor_det_retiro     := '';             
      sdofavor_det_deposito   := '';               
      sdofavor_det_saldo      := '';                  
      nmsdo := 0; 
    END IF;
  END LOOP;
  _saldo_favor_final := rsdofdet.saldo;

FOR rcreddet IN SELECT fecha,concepto,retiro,deposito,saldo,referencia
                    FROM of_edoctaxaux(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha,ps_afecha) where folio_ticket<>0 LOOP
  --RAISE NOTICE 'rcreddet %',rcreddet;                    
    credito_det_fecha := credito_det_fecha |+ COALESCE(rcreddet.fecha::TEXT,'') |+ E'\n';
    credito_det_concepto := credito_det_concepto |+ COALESCE(rcreddet.concepto::TEXT,'') |+ E'\n';
    credito_det_referencia := credito_det_referencia |+ of_si(rcreddet.referencia~'Abonos bancarios','Abonos bancarios',COALESCE(rcreddet.referencia::TEXT,'')) |+ E'\n';
    credito_det_retiro     := credito_det_retiro |+ COALESCE(to_char(rcreddet.retiro,'FM999,999,990.90'),'') |+ E'\n';
    credito_det_deposito   := credito_det_deposito |+ COALESCE(to_char(rcreddet.deposito,'FM999,999,990.90'),'') |+ E'\n';
    credito_det_saldo      := credito_det_saldo |+ COALESCE(to_char(rcreddet.saldo,'FM999,999,990.90'),'') |+ E'\n';
    nmsdo := nmsdo + 1;
    IF (nmsdo >= 21) THEN
      _flag           := TRUE; -- Detalle de recaudos mas de una hoja
      --r.__params      := 'gld01,gld02,gld03,gld04,gld05,gld06,gld07,gld08,gld09,gld10';-- Impresion de la hoja 3 (Detalle de recaudos)
      --RAISE NOTICE '============================================ notice 2';
      --RETURN NEXT r;   
      credito_det_fecha      := '';            
      credito_det_concepto   := '';               
      credito_det_referencia := '';                
      credito_det_retiro     := '';             
      credito_det_deposito   := '';               
      credito_det_saldo      := '';                  
      nmsdo := 0; 
    END IF;
  END LOOP;  

  FOR rctas IN SELECT idsucauxref,idproductoref,idauxiliarref FROM auxiliares_ref 
                 WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) GROUP BY idsucauxref,idproductoref,idauxiliarref,of_producto_subtipo(idproductoref) 
                 ORDER BY of_producto_subtipo(idproductoref),idproductoref LOOP
    SELECT INTO rctassdo idsucaux,idproducto,idauxiliar,saldo,kauxiliar FROM auxiliares WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref);
    IF (rctassdo.saldo>0.00) THEN
      SELECT INTO rctasp idproducto,nombre,tipocalculo FROM productos WHERE idproducto=rctassdo.idproducto;
      SELECT INTO rocc * FROM cartera 
        WHERE fecha=of_fecha_dum(ps_afecha) AND (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);      
      IF (of_producto_subtipo(rctassdo.idproducto)='PRE' AND rctasp.tipocalculo=99) THEN
        _noc := _noc + 1;      
        --RAISE NOTICE '_noc %', _noc;
        IF (_noc=1) THEN
          r.__params := r.__params |+ 'gld06;';
          otros_creditos_pag_1 := 6;
        ELSIF (_noc=2) THEN
          r.__params := r.__params |+ 'gld07;';
          otros_creditos_pag_2 := 7;
        ELSIF (_noc=3) THEN
          otros_creditos_pag_3 := 8;
          r.__params := r.__params |+ 'gld08;';
        END IF;        
        
        _rocccodigo       := of_rellena(rctassdo.kauxiliar::TEXT,9,'0',2);
        _roccdv           := of_dv_gen(_rocccodigo::TEXT);
        _roccreferencia   := _rocccodigo |+ _roccdv;
        r.otros_creditos_noref := r.otros_creditos_noref + COALESCE(_roccreferencia::TEXT,'');
        
        SELECT INTO rctassdode idsucaux,idproducto,idauxiliar,saldo,kauxiliar,fechaactivacion,tasaio,tasaim,montoentregado,plazo
          FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref); 

        FOR rctassdodet IN SELECT fecha,concepto,retiro,deposito,saldo,referencia
                            FROM of_edoctaxaux(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,ps_dfecha,ps_afecha) where folio_ticket<>0 LOOP
 
          _otros_creditos_detfecha := _otros_creditos_detfecha |+ rctassdodet.fecha |+ E'\n';
          _otros_creditos_detconcepto := _otros_creditos_detconcepto |+ rctassdodet.concepto |+ E'\n';  
          _otros_creditos_detreferencia := _otros_creditos_detreferencia |+ rctassdodet.concepto |+ E'\n';                            
          _otros_creditos_detcargo := _otros_creditos_detcargo |+ rctassdodet.retiro |+ E'\n';                
          _otros_creditos_detabono := _otros_creditos_detabono |+ rctassdodet.deposito |+ E'\n';                
          _otros_creditos_detsaldo := _otros_creditos_detsaldo |+ rctassdodet.saldo |+ E'\n';                             
        END LOOP;                            
          r.otros_creditos_detfecha    := r.otros_creditos_detfecha + COALESCE(_otros_creditos_detfecha::TEXT,'');      
          r.otros_creditos_detconcepto := r.otros_creditos_detconcepto + COALESCE(_otros_creditos_detconcepto::TEXT,'');         
          r.otros_creditos_detreferencia := r.otros_creditos_detreferencia + COALESCE(_otros_creditos_detreferencia::TEXT,'');         
          r.otros_creditos_detcargo    := r.otros_creditos_detcargo + COALESCE(_otros_creditos_detcargo::TEXT,'');      
          r.otros_creditos_detabono    := r.otros_creditos_detabono + COALESCE(_otros_creditos_detabono::TEXT,'');      
          r.otros_creditos_detsaldo    := r.otros_creditos_detsaldo + COALESCE(_otros_creditos_detsaldo::TEXT,'');           


        r.otros_creditos_saldoliquidar := r.otros_creditos_saldoliquidar + COALESCE((rocc.saldo + rocc.interes_total + rocc.impuesto_total + rocc.costos_asociados)::TEXT,'');
        r.otros_creditos_prod := r.otros_creditos_prod + COALESCE(rctasp.nombre::TEXT,'');
        r.otros_creditos   := r.otros_creditos + COALESCE((rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar)::TEXT,'');
        r.otros_creditos_mto_liquidar := r.otros_creditos_mto_liquidar + COALESCE((rocc.saldo+rocc.interes_total+rocc.impuesto_total+rocc.costos_asociados)::TEXT,'');
        r.otros_creditos_capvigente   := r.otros_creditos_capvigente + COALESCE((rocc.saldo - rocc.montovencido)::TEXT,'');
        r.otros_creditos_capvencido   := r.otros_creditos_capvencido + COALESCE(rocc.montovencido::TEXT,'');                           
        r.otros_creditos_intpendiente := r.otros_creditos_intpendiente + COALESCE(rocc.interes_total::TEXT,'');
        
        SELECT INTO _idpagopp idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence<=ps_afecha ORDER BY idpago DESC limit 1;

        r.otros_creditos_nopago       := r.otros_creditos_nopago + COALESCE(_idpagopp::TEXT,'1');
        SELECT INTO _segautooc abono FROM of_ca_seguro_vida_sust(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,2,ps_afecha,FALSE);
        r.otros_creditos_segauto      := r.otros_creditos_segauto + COALESCE(_segautooc::TEXT,'');
        SELECT INTO _segvidaoc abono FROM  of_ca_seguro_vida_sust(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,1,ps_afecha,FALSE);
        r.otros_creditos_segvida      := r.otros_creditos_segvida + COALESCE(_segvidaoc::TEXT,'');
        SELECT INTO _gpsoc abono FROM  of_ca_seguro_vida_sust(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar,3,ps_afecha,FALSE);
        r.otros_creditos_gps          := r.otros_creditos_gps + COALESCE(_gpsoc::TEXT,'');

        SELECT INTO rocdm sum(abono) as abcapital,sum(montoio) as abint,sum(montoimp) as abimp,sum(montoca) as abca
          FROM detalle_auxiliar 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) 
               AND fecha BETWEEN of_fecha_dpm(ps_afecha) AND of_fecha_dum(ps_afecha); 

        r.otros_creditos_abcapital    := r.otros_creditos_abcapital + COALESCE(rocdm.abca,0.00)::TEXT;
        
        SELECT INTO _ocdeuda abono+interes_total+impuesto_total+costos_asociados AS deuda -- 09/09/2021 Cambiar por saldo
          FROM cartera 
          WHERE fecha=ps_afecha AND (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);
        rctassdosaldo := _ocdeuda; 
        r.otros_creditos_mesanterior  := r.otros_creditos_mesanterior + COALESCE(_ocdeuda,0.00)::TEXT;            

        SELECT INTO _idpagoppsig,_venceppsig,_abonoppsig,_ioppsig idpago,vence,abono,io 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence>ps_afecha ORDER BY idpago LIMIT 1;
        r.otros_creditos_proxmensualidad := r.otros_creditos_proxmensualidad + '0.00';
        r.otros_creditos_proxvence       := r.otros_creditos_proxvence + COALESCE(_venceppsig::TEXT,'');
        --r.otros_creditos_noref           := r.otros_creditos_noref + ''     
        r.otros_creditos_proxabono       := r.otros_creditos_proxabono + COALESCE(_abonoppsig::TEXT,'');        
        r.otros_creditos_proxinteres     := r.otros_creditos_proxinteres + COALESCE(_ioppsig::TEXT,'');          
        r.otros_creditos_proxnopago      := r.otros_creditos_proxnopago + COALESCE(_idpagoppsig::TEXT,'');

        SELECT INTO _idpagoppact idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence=ps_afecha;
        _idpagoppact:= COALESCE(_idpagoppact,0);
        SELECT INTO _proxsegvida valor 
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact+1 AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
        SELECT INTO _proxsegauto round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppact+1 AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

        SELECT INTO _proxgps round(valor::NUMERIC*(pg_factor_iva_io+1),2)
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppact+1 AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;


        r.otros_creditos_proxsegauto     := r.otros_creditos_proxsegauto + COALESCE(_menssegauto,0.00)::TEXT;           
        r.otros_creditos_proxsegvida     := r.otros_creditos_proxsegvida + COALESCE(_proxsegvida,0.00)::TEXT;
        r.otros_creditos_proxgps         := r.otros_creditos_proxgps + COALESCE(_mensgps,0.00)::TEXT;

        r.otros_creditos_fechaini       := r.otros_creditos_fechaini + COALESCE(rctassdode.fechaactivacion::TEXT,'');
        r.otros_creditos_tasaio         := r.otros_creditos_tasaio + COALESCE(rctassdode.tasaio::TEXT,'');         
        r.otros_creditos_tasaim         := r.otros_creditos_tasaim + COALESCE(rctassdode.tasaim::TEXT,'');         
        r.otros_creditos_montoentregado := r.otros_creditos_montoentregado + COALESCE(rctassdode.montoentregado::TEXT,'');

        SELECT INTO  _rctasvence vence
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              idpago=rctassdode.plazo;

        r.otros_creditos_fechavence     := r.otros_creditos_fechavence + COALESCE(_rctasvence::TEXT,'');
        SELECT INTO _rctascat valor FROM valores_anexos WHERE (idtabla,idcolumna,idelemento)=('deudores',rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar,'CAT');
        _rctascat := round(_rctascat::numeric,2);
        r.otros_creditos_cat            := r.otros_creditos_cat + COALESCE(_rctascat,'0.00');

        SELECT INTO _idpagoppact idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence=ps_afecha;

        IF (NOT FOUND) THEN              
          r.otros_creditos_mensualidad      := r.otros_creditos_mensualidad + '0.00';
        ELSE
          SELECT INTO _ocmensualidad abono+io 
            FROM planpago 
           WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND idpago=_idpagoppact;

          SELECT INTO _menssegvida valor 
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
          SELECT INTO _menssegauto round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

          SELECT INTO _mensgps round(valor::NUMERIC*(pg_factor_iva_io+1),2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscom round(valor::NUMERIC*(pg_factor_iva_io+1),2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscomdif round(valor::NUMERIC,2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                                      

          _ocmensualidad   := COALESCE(_ocmensualidad,0.00); 
          _menssegvida     := COALESCE(_menssegvida,0.00); 
          _menssegauto     := COALESCE(_menssegauto,0.00); 
          _mensgps         := COALESCE(_mensgps,0.00); 
          _menscom         := COALESCE(_menscom,0.00);      
          _menscomdif      := COALESCE(_menscomdif,0.00);         
          r.otros_creditos_mensualidad  := r.otros_creditos_mensualidad + COALESCE((_ocmensualidad+_menssegvida+_menssegauto+_mensgps+_menscom+_menscomdif)::TEXT,'0.00');
        END IF;    

        r.otros_creditos_apcredito    := r.otros_creditos_apcredito + '0.00';
        r.otros_creditos_sdofinal     := r.otros_creditos_sdofinal + COALESCE((COALESCE(_ocdeuda,0.00) + COALESCE(_ocmensualidad,0.00) + COALESCE(_menssegvida,0.00) + COALESCE(_menssegauto,0.00) +COALESCE(_mensgps,0.00) + 
                                                                       COALESCE(_menscom,0.00) + COALESCE(_menscomdif,0.00))::TEXT,'0.00');
        r.otros_creditos_intdif       := r.otros_creditos_intdif + '0.00';
        r.otros_creditos_adeudo       := r.otros_creditos_adeudo + '0.00';
      END IF;

      IF (rctasp.tipocalculo=9970) THEN  
        _nocl := _nocl + 1;     
        
        IF (_nocl=1) THEN
          r.__params := r.__params |+ 'gld09;';
          otros_creditos_pag_4 := (5+_noc) + _nocl;
        ELSIF (_nocl=2) THEN
          otros_creditos_pag_5 := (5+_noc) + _nocl;
          r.__params := r.__params |+ 'gld10;';
        ELSIF (_nocl=3) THEN
          otros_creditos_pag_6 := (5+_noc) + _nocl;
          r.__params := r.__params |+ 'gld11;';
        END IF;        
        r.otros_creditos_prod_lc := r.otros_creditos_prod_lc + COALESCE(rctasp.nombre,'');
        SELECT INTO rctassdode idsucaux,idproducto,idauxiliar,saldo,kauxiliar,fechaactivacion,tasaio,tasaim,montoentregado,plazo
          FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref); 


        _rocccodigo       := of_rellena(rctassdo.kauxiliar::TEXT,9,'0',2);
        _roccdv           := of_dv_gen(_rocccodigo::TEXT);
        _roccreferencia   := _rocccodigo |+ _roccdv;
        r.otros_creditos_noref_lc := r.otros_creditos_noref_lc + COALESCE(_roccreferencia::TEXT,'');        
        r.otros_creditos_lc   := r.otros_creditos_lc + (rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar)::TEXT;
        SELECT INTO _ocdeuda saldo+interes_total+impuesto_total+costos_asociados AS deuda
          FROM cartera 
         WHERE fecha=ps_afecha AND (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);
        rctassdosaldo := _ocdeuda;
        r.otros_creditos_mesanterior_lc  := r.otros_creditos_mesanterior_lc + COALESCE(_ocdeuda,0.00)::TEXT;    

        SELECT INTO _disposiciones sum(cargo) 
          FROM detalle_auxiliar 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref) AND 
               periodo=of_periodo(ps_afecha)::INTEGER;

        SELECT INTO _interes sum(cargo) 
          FROM deudores_ddcc 
          INNER JOIN polizas USING (kpoliza) 
         WHERE kauxiliar = rctassdo.kauxiliar AND cargo_desc~'iodnc' AND periodo=of_periodo(ps_afecha)::INTEGER;

        r.otros_creditos_disposiciones_lc := r.otros_creditos_disposiciones_lc + COALESCE(_disposiciones::TEXT,'0.00');
        r.otros_creditos_interes_lc       := r.otros_creditos_interes_lc + COALESCE(_interes::TEXT,'0.00');
        r.otros_creditos_apcredito_lc     := r.otros_creditos_apcredito_lc + '0.00';
        

        SELECT INTO _idpagoppact idpago 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence=ps_afecha;
        _idpagoppact := COALESCE(_idpagoppact,0);
        SELECT INTO _ocmensualidad abono+io 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND idpago=_idpagoppact;

        SELECT INTO _menssegvida valor 
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_vida_sust' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;
          
        SELECT INTO _menssegauto round(valor::NUMERIC*(pg_factor_iva_io+1),2)  
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_seguro_unidad_sust' AND substring(idkey::TEXT,25,5)::INTEGER=_idpagoppact AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,25,5)) GROUP BY idkey,valor ORDER BY idkey DESC;                   

        SELECT INTO _mensgps round(valor::NUMERIC*(pg_factor_iva_io+1),2)
            FROM auxiliares_anexo 
           WHERE idkey~'of_ca_gps_sust' AND substring(idkey::TEXT,15,5)::INTEGER=_idpagoppact AND 
                 kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,15,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscom round(valor::NUMERIC*(pg_factor_iva_io+1),2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_entresinplacas_sust' AND substring(idkey::TEXT,26,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,26,5)) GROUP BY idkey,valor ORDER BY idkey DESC;

          SELECT INTO _menscomdif round(valor::NUMERIC,2)
              FROM auxiliares_anexo 
             WHERE idkey~'of_ca_interes_diferido' AND substring(idkey::TEXT,23,5)::INTEGER=_idpagoppact AND 
                   kauxiliar=rctassdo.kauxiliar AND of_is_integer(substring(idkey::TEXT,23,5)) GROUP BY idkey,valor ORDER BY idkey DESC;  

        _ocmensualidad   := COALESCE(_ocmensualidad,0.00); 
        _menssegvida     := COALESCE(_menssegvida,0.00); 
        _menssegauto     := COALESCE(_menssegauto,0.00); 
        _mensgps         := COALESCE(_mensgps,0.00); 
        _menscom         := COALESCE(_menscom,0.00);      
        _menscomdif      := COALESCE(_menscomdif,0.00);  
        r.otros_creditos_sdofinal_lc := r.otros_creditos_sdofinal_lc + (COALESCE(_ocdeuda,0.00) + COALESCE(_ocmensualidad,0.00) + COALESCE(_menssegvida,0.00) + COALESCE(_menssegauto,0.00) +COALESCE(_mensgps,0.00) +
                                                                        COALESCE(_menscom,0.00) + COALESCE(_menscomdif,0.00))::TEXT;
        r.otros_creditos_capvigente_lc  := r.otros_creditos_capvigente_lc + COALESCE((rocc.saldo - rocc.montovencido),0.00)::TEXT;
        r.otros_creditos_capvencido_lc  := r.otros_creditos_capvencido_lc + COALESCE(rocc.montovencido,0.00)::TEXT;
        r.otros_creditos_intvenc_lc     := r.otros_creditos_intvenc_lc + COALESCE(rocc.interes_total,0.00)::TEXT;
        r.otros_creditos_adeudo_lc := r.otros_creditos_adeudo_lc + (COALESCE(_ocdeuda,0.00) + COALESCE(_ocmensualidad,0.00) + COALESCE(_menssegvida,0.00) + COALESCE(_menssegauto,0.00) +COALESCE(_mensgps,0.00)+
                                                                    COALESCE(_menscom,0.00) + COALESCE(_menscomdif,0.00))::TEXT;

        SELECT INTO _idpagoppsig,_venceppsig,_abonoppsig,_ioppsig idpago,vence,abono,io 
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              vence>ps_afecha ORDER BY idpago LIMIT 1;


        r.otros_creditos_proxmensualidad_lc := r.otros_creditos_proxmensualidad_lc + '0.00';                        
        r.otros_creditos_proxvence_lc       := r.otros_creditos_proxvence_lc + COALESCE(_venceppsig::TEXT,'');
        --r.otros_creditos_noref_lc           := r.otros_creditos_noref_lc + '';              
        r.otros_creditos_proxabono_lc       := r.otros_creditos_proxabono_lc + COALESCE(_abonoppsig::TEXT,'');
        r.otros_creditos_proxinteres_lc     := r.otros_creditos_proxinteres_lc + COALESCE(_ioppsig::TEXT,'');
        r.otros_creditos_nopago_lc          := r.otros_creditos_nopago_lc + COALESCE(_idpagoppsig::TEXT,'');

        r.otros_creditos_fechaini_lc      := r.otros_creditos_fechaini_lc + COALESCE(rctassdode.fechaactivacion::TEXT,'');
        r.otros_creditos_tasaio_lc        := r.otros_creditos_tasaio_lc + COALESCE(rctassdode.tasaio::TEXT,'');         
        r.otros_creditos_tasaim_lc        := r.otros_creditos_tasaim_lc + COALESCE(rctassdode.tasaim::TEXT,'');     
        r.otros_creditos_limite_lc        := r.otros_creditos_limite_lc + COALESCE(rctassdode.montoentregado::TEXT,'');    

        SELECT INTO  _rctasvence vence
          FROM planpago 
         WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar) AND 
              idpago=rctassdode.plazo;

        r.otros_creditos_fechavence_lc     := r.otros_creditos_fechavence + COALESCE(_rctasvence::TEXT,'');
        SELECT INTO _rctascat valor FROM valores_anexos WHERE (idtabla,idcolumna,idelemento)=('deudores',rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar,'CAT');        
        --_rctascat := (ROUND(_rctascat::NUMERIC,2))::TEXT;
        r.otros_creditos_cat_lc            := r.otros_creditos_cat + COALESCE(_rctascat::TEXT,'0.00');


        FOR rlin IN SELECT * 
                      FROM (SELECT fecha,concepto,'Programa Respiro',retiro,deposito,saldo 
                              FROM of_edoctaxaux(rctas.idsucauxref,rctas.idproductoref,rctas.idauxiliarref,of_fecha_dpm(ps_afecha),of_fecha_dum(ps_afecha)) 
                             WHERE folio_ticket<>0 
                     UNION SELECT fecha,'Dev. Int Ord','Devengamiento',cargo,0.00,0.00 
                             FROM deudores_ddcc 
                             INNER JOIN polizas USING (kpoliza) 
                            WHERE kauxiliar = rctassdo.kauxiliar AND polizas.periodo=of_periodo(ps_afecha)::INTEGER AND 
                                  cargo_desc~'iodnc' AND periodo=of_periodo(fecha)::INTEGER ORDER BY 1) AS xx LOOP 
          _otros_creditos_detfecha_lc := _otros_creditos_detfecha_lc |+ rlin.fecha |+ E'\n';
          _otros_creditos_detconcepto_lc := _otros_creditos_detconcepto_lc |+ rlin.concepto |+ E'\n';  
          _otros_creditos_detreferencia_lc := _otros_creditos_detreferencia_lc |+ rlin.concepto |+ E'\n';                            
          _otros_creditos_detcargo_lc := _otros_creditos_detcargo_lc |+ rlin.retiro |+ E'\n';                
          _otros_creditos_detabono_lc := _otros_creditos_detabono_lc |+ rlin.deposito |+ E'\n';                
          _otros_creditos_detsaldo_lc := _otros_creditos_detsaldo_lc |+ rlin.saldo |+ E'\n';                        

        END LOOP;
        r.otros_creditos_detfecha_lc    := r.otros_creditos_detfecha_lc + COALESCE(_otros_creditos_detfecha_lc::TEXT,'');      
        r.otros_creditos_detconcepto_lc := r.otros_creditos_detconcepto_lc + COALESCE(_otros_creditos_detconcepto_lc::TEXT,'');         
        r.otros_creditos_detreferencia_lc := r.otros_creditos_detreferencia_lc + COALESCE(_otros_creditos_detreferencia_lc::TEXT,'');         
        r.otros_creditos_detcargo_lc    := r.otros_creditos_detcargo_lc + COALESCE(_otros_creditos_detcargo_lc::TEXT,'');      
        r.otros_creditos_detabono_lc    := r.otros_creditos_detabono_lc + COALESCE(_otros_creditos_detabono_lc::TEXT,'');      
        r.otros_creditos_detsaldo_lc    := r.otros_creditos_detsaldo_lc + COALESCE(_otros_creditos_detsaldo_lc::TEXT,'');             
      END IF;
      IF (rctasp.idproducto BETWEEN 4000 AND 4999) THEN
        SELECT INTO rctassdosaldo saldo FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(rctassdo.idsucaux,rctassdo.idproducto,rctassdo.idauxiliar);
      END IF;
      IF (rctassdo.idproducto = 2001) THEN
        rctassdosaldo := rctassdo.saldo;
        rctassdosaldofav := rctassdo.saldo;
      END IF;      
      RAISE NOTICE 'rctasp.nombre %',rctasp.nombre;
      _res_ctas          := _res_ctas |+ COALESCE(rctasp.nombre,'')|+' ('||rctassdo.idsucaux||'-'||rctassdo.idproducto||'-'||rctassdo.idauxiliar||')' |+ E'\n';
      _res_ctas_saldos   := _res_ctas_saldos |+ '$'||to_char(COALESCE(rctassdosaldo,0.00),'FM999,999,990.90') |+ E'\n';
      _res_ctas_saldos_sum := _res_ctas_saldos_sum  + COALESCE(rctassdosaldo-COALESCE(rctassdosaldofav,0.00),0.00);  
    END IF; 
  END LOOP;


  --IF (_nocl=1) THEN
  --  r.__params := r.__params |+ 'gld09;';
  --ELSIF (_nocl=2) THEN
  --  r.__params := r.__params |+ 'gld010;';
  --ELSIF (_nocl=3) THEN
  --  r.__params := r.__params |+ 'gld011;';
  --END IF;  
  
  SELECT INTO rmasdat * FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  IF (FOUND) THEN
    _poliza_seg_auto     := rmasdat.poliza_seg_auto;
    _numeco              := rmasdat.numeco;
    _vin                 := rmasdat.vin;
    _vigencia_polsegauto := rmasdat.vigencia_polsegauto;
  END IF;
  
  -- deudaanterior := sumar montoid
  SELECT INTO _deudaanterior,_pnombre,_saldoc,_montovencidoc,_deudamesactual saldo+interes_total+impuesto_total+costos_asociados AS deuda,p.nombre,saldo,montovencido,abono+interes_total+impuesto_total+costos_asociados
    FROM cartera 
    INNER JOIN productos AS p USING (idproducto) 
    WHERE fecha=of_fecha_dpm(ps_afecha)-1 AND (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
 
  --_capvigente             := round(_saldoc-_montovencidoc,2);
  SELECT INTO _capvigente sum(abono-abpagado)            
    FROM planpago 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND 
        vence>=ra.vence;
  _capvigente := COALESCE(_capvigente,0.00);


  SELECT INTO _deudamesanterior,_montovencidoanterior,_saldoanterior,_iopendant abono+interes_total+impuesto_total+costos_asociados,montovencido AS deuda,saldo,iopend
    FROM cartera 
    WHERE fecha=of_fecha_dpm(ps_afecha)-1 AND (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);

  _comisiondifca        := rmasdat.total_id;
  _comisiondifca        := COALESCE(_comisiondifca,0.00);
  _montovencidoanterior := COALESCE(_montovencidoanterior,0.00);
  _saldoanterior := COALESCE(_saldoanterior,0.00);
  _iopendant     := COALESCE(_iopendant,0.00);

  SELECT INTO _comisiondifcaab sum(daca.abono) 
    FROM detalle_auxiliar 
    INNER JOIN detalle_auxiliar_ca AS daca USING (secuencia) 
    WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND idcosto=5;
  _comisiondifcaab := COALESCE(_comisiondifcaab,0.00);
  
  SELECT INTO _pnombre nombre FROM productos WHERE idproducto=ps_idproducto;

  -- QUITAR TAMBIEN ppv
  SELECT INTO _credproxcomdesc,_credproxcomincr io_desc,io_incr 
    FROM ppv.planpago_escalonado WHERE idpago=_credidpagoppsig AND kauxiliar=_kauxiliar;

  --RAISE NOTICE '_credabonoppsig %
  --              _credioppsig %
  --              _credproxsegvida %
  --              _credproxsegunidad %
  --              _credproxgps %
  --              _credproxcom %
  --              _credproxcomdif %
  --              _credproxcomdesc %
  --              _credproxcomincr %',
  --             COALESCE(_credabonoppsig,0.00),
  --             COALESCE(_credioppsig,0.00),
  --             COALESCE(_credproxsegvida,0.00),
  --             COALESCE(_credproxsegunidad,0.00),
  --             COALESCE(_credproxgps,0.00),
  --             COALESCE(_credproxcom,0.00),
  --             COALESCE(_credproxcomdif,0.00),
  --             COALESCE(_credproxcomdesc,0.00),
  --             COALESCE(_credproxcomincr,0.00);
  RAISE NOTICE 'IVAAAAAA antes';
  IF (_iva) THEN
    RAISE NOTICE 'IVAAAAAA';
   _credivappsig := round((round(_credioppsig,2)*round(factor_iva_io,2)),2);
  END IF;
  _credproxmensualidad := COALESCE(_credabonoppsig,0.00) + COALESCE(_credioppsig,0.00) + COALESCE(_credivappsig,0.00) + COALESCE(_credproxsegvida,0.00) + COALESCE(_credproxsegunidad,0.00) + COALESCE(_credproxgps,0.00) +
                          COALESCE(_credproxcom,0.00) + COALESCE(_credproxcomdif,0.00) - COALESCE(_credproxcomdesc,0.00) + COALESCE(_credproxcomincr,0.00);

  recaudo_fecha          :='';           
  recaudo_transaccion    :='';                 
  recaudo_contrato_gazel :='';                    
  recaudo_litros         :='';            
  recaudo_precioxlt      :='';               
  recaudo_recaudo        :='';                                       
  FOR ra IN SELECT *
              FROM ofx_recaudo.detalle_auxiliar
             WHERE trim(contrato_gazel)= trim(rco.contrato_gazel) AND 
                   fecha BETWEEN of_fecha_dpm(ps_afecha) AND
                                 of_fecha_dum(ps_afecha)
             ORDER BY fecha LOOP
    recaudo_fecha          := recaudo_fecha          |+ COALESCE(ra.fecha::TEXT,'') |+ E'\n';
    recaudo_transaccion    := recaudo_transaccion    |+ COALESCE(ra.transaccion::TEXT,'') |+ E'\n';
    recaudo_contrato_gazel := recaudo_contrato_gazel |+ COALESCE(ra.contrato_gazel::TEXT,'') |+ E'\n';
    recaudo_litros         := recaudo_litros         |+ COALESCE(ra.litros::TEXT,'') |+ E'\n';
    recaudo_precioxlt      := recaudo_precioxlt      |+ COALESCE(ra.precioxlt::TEXT,'') |+ E'\n';
    recaudo_recaudo        := recaudo_recaudo        |+ COALESCE(ra.recaudo::TEXT,'') |+ E'\n';
  END LOOP;    

    recaudo_fecha          := recaudo_fecha          |+ '' |+ E'\n';
    recaudo_transaccion    := recaudo_transaccion    |+ '' |+ E'\n';
    recaudo_contrato_gazel := recaudo_contrato_gazel |+ '' |+ E'\n';
    recaudo_litros         := recaudo_litros         |+ '' |+ E'\n';
    recaudo_precioxlt      := recaudo_precioxlt      |+ '' |+ E'\n';
    recaudo_recaudo        := recaudo_recaudo        |+ '' |+ E'\n';

  FOR raj IN SELECT * FROM ofx_recaudo.detalle_auxiliar_ajustes
               WHERE trim(contrato_gazel)=trim(rco.contrato_gazel) ORDER BY fecha LOOP 
    _recaudo_nota          := '(**) Recaudo de meses anteriores.';


    recaudo_fecha          := recaudo_fecha          |+ '**'|+ COALESCE(raj.fecha::TEXT,'') |+ E'\n';
    recaudo_transaccion    := recaudo_transaccion    |+ COALESCE(raj.transaccion::TEXT,'') |+ E'\n';
    recaudo_contrato_gazel := recaudo_contrato_gazel |+ COALESCE(raj.contrato_gazel::TEXT,'') |+ E'\n';
    recaudo_litros         := recaudo_litros         |+ COALESCE(raj.litros::TEXT,'') |+ E'\n';
    recaudo_precioxlt      := recaudo_precioxlt      |+ COALESCE(raj.precioxlt::TEXT,'') |+ E'\n';
    recaudo_recaudo        := recaudo_recaudo        |+ COALESCE(raj.recaudo::TEXT,'') |+ E'\n';  
  END LOOP;


  --SELECT INTO _abpagadoda,_iopagadoda,_impagadoda,_ivapagadoda sum(abono),sum(montoio),sum(montoim),sum(montoimp)
  --  FROM detalle_auxiliar 
  -- WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND fecha<=ps_afecha;

  SELECT INTO _abpagadoda,_iopagadoda,_impagadoda,_ivapagadoda,_segvidapagadoda,_segunidadpagadoda,_gpspagadoda,_comdifpagadoda,_comisionpagadoda
              sum(abono),sum(montoio),sum(montoim),sum(montoimp),sum(segvida),sum(segunidad),sum(gps),sum(comdif),sum(comision) 
    FROM (SELECT abono,montoio,montoim,montoimp,
                 (SELECT abono FROM detalle_auxiliar_ca AS daca WHERE idcosto=1 AND daca.secuencia=da.secuencia) AS segvida,
                 (SELECT abono+impuesto FROM detalle_auxiliar_ca AS daca WHERE idcosto=2 AND daca.secuencia=da.secuencia) as segunidad,
                 (SELECT abono+impuesto FROM detalle_auxiliar_ca AS daca WHERE idcosto=3 AND daca.secuencia=da.secuencia) as gps,
                 (SELECT abono+impuesto FROM detalle_auxiliar_ca AS daca WHERE idcosto=4 AND daca.secuencia=da.secuencia) as comdif,
                 (SELECT abono+impuesto FROM detalle_auxiliar_ca AS daca WHERE idcosto=5 AND daca.secuencia=da.secuencia) as comision
    FROM detalle_auxiliar as da 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND fecha<=ps_afecha) as xx;

  -- CAQ 
  SELECT INTO _abonopp,_interespp,_segvidapp,_segunidadpp,_gpspp,_compp 
              sum(abono),((sum(io)+sum(incr))-sum(descc)),sum(segvida),sum(segunidad),sum(gps),sum(comision)
    FROM (select kauxiliar,idpago,vence,abono,abpagado,io,iopagado,
                 of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,1,1) as segvida,
                 of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,1,2) as segvida_pagado,
                 of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,2,1) as segunidad,
                 of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,2,2) as segunidad_pagado,
                 of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,3,1) as gps,
                 of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,3,2) as gps_pagado,
                 COALESCE((select io_incr from ppv.planpago_escalonado where kauxiliar=deudores.kauxiliar and idpago=planpago.idpago),0.00) as incr,
                 COALESCE((select io_desc from ppv.planpago_escalonado where kauxiliar=deudores.kauxiliar and idpago=planpago.idpago),0.00) as descc,
                 COALESCE((SELECT of_si(planpago.idpago<=com_id_cero,0,comision_id) 
                    FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                   WHERE kauxiliar=deudores.kauxiliar),0.00) as comision
            from planpago 
            inner join deudores using (idsucaux,idproducto,idauxiliar) 
           where (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) and vence<=ps_afecha) AS xx;
  

  _intdif := round(_iodifex,2);
  IF (_iva) THEN
    _ivapend := (round(_interespp - _iopagadoda,2) * factor_iva_io);
  END IF;
  RAISE NOTICE 'Deuda:  _abonopp % _abpagadoda %
               Monto vencido: %
               Interes:       %
               IVA            %
               Interes Dif    %
               segvida        %
               segunidad      %
               gps            %
               comision       %
               comision dif   %
               IO Dif No Exig %',
               _abonopp,_abpagadoda,
               round(_abonopp - _abpagadoda,2),
               round(_interespp - _iopagadoda,2),
               round(_ivapend,2),
               COALESCE(_intdif,0),
               COALESCE(_segvidapp-_segvidapagadoda,0.00),
               COALESCE(_segunidadpp-_segunidadpagadoda,0.00),
               COALESCE(_gpspp-_gpspagadoda,0.00),
               COALESCE(_compp-_compppagadoda,0.00),
               COALESCE(_comdif,0.00),
               COALESCE(_iodifnoex,0.00);
  
  r.monto_vencido_cap := to_char(COALESCE(round(_abonopp - _abpagadoda,2),of_numeric(r.monto_vencido_cap)),'FM999,999,990.90');

  _iocredito       := of_numeric(r.interes);            
  _ivacredito      := of_numeric(r.iva);
  _adeudopendiente := to_char(of_numeric(r.monto_vencido_cap)+(round(of_numeric(r.interes)+of_numeric(r.iva)-COALESCE(_intdif,0),2))+COALESCE(_segunidad,0.00)+COALESCE(_segvida,0.00)+COALESCE(_gps,0.00)+COALESCE(_com,0.00)+COALESCE(_comdif,0.00)+COALESCE(_iodifnoex,0.00),'FM999,999,990.90');
    SELECT INTO _abcredito sum(abono+montoio+montoca+montoimp)
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND periodo=of_periodo(ps_afecha)::INTEGER;


  --_adeudopendiente   := of_numeric(r.monto_vencido_cap)+round(_interespp - _iopagadoda,2)
  --_adeudopendiente := of_numeric(_adeudopendiente);
  --RAISE NOTICE '_adeudopendiente %',_adeudopendiente;
  DELETE FROM validacion_edo_cta_x_vence
    WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);

  INSERT INTO validacion_edo_cta_x_vence
    VALUES (ps_idsucaux,ps_idproducto,ps_idauxiliar,of_numeric(_adeudopendiente),round(of_numeric(sdo_favor_sdocorte),2));
  --RAISE NOTICE '========== %',to_char(of_numeric(r.monto_vencido_cap)+(round(of_numeric(r.interes)-COALESCE(_intdif,0),2))+COALESCE(_segunidad,0.00)+COALESCE(_segvida,0.00)+COALESCE(_gps,0.00)+COALESCE(_com,0.00)+COALESCE(_comdif,0.00)+COALESCE(_iodifnoex,0.00),'FM999,999,990.90');
--RAISE NOTICE '_comisiondifca % _comisiondifcaab % _saldoanterior % _iopendant %',_comisiondifca,_comisiondifcaab,_saldoanterior,_iopendant;
RAISE NOTICE '_deudaanterior      %     
              _comisiondifca      %     
              _comisiondifcaab    %       
              _comdif             %
              mensualidad_periodo %
              abonoppact          %
              abcredito           %',_deudaanterior,_comisiondifca,_comisiondifcaab,_comdif,mensualidad_periodo,_credabonoppact,_abcredito;

  _res_ctas          := _res_ctas |+ _pnombre|+' ('||ps_idsucaux||'-'||ps_idproducto||'-'||ps_idauxiliar||')' |+ E'\n';
  _res_ctas_saldos   := _res_ctas_saldos |+ '$'||to_char((COALESCE(_deudaanterior,0.00)+COALESCE(mensualidad_periodo,0.00))-(COALESCE(_credabonoppact,0.00)+COALESCE(_abcredito,0.00)),'FM999,999,990.90') |+ E'\n';
  _res_ctas_saldos_sum := _res_ctas_saldos_sum  + (COALESCE(_deudaanterior,0.00)+COALESCE(mensualidad_periodo,0.00))-(COALESCE(_credabonoppact,0.00)+COALESCE(_abcredito,0.00));       
  
  r.__params := r.__params |+ 'gld12';  
  _paginas   := COALESCE(array_length(string_to_array(substring(r.__params,6,99),';'),1),0);
  _ultpagina := COALESCE(_paginas,0);

  r.kv_data     := ARRAY['contrato_gazel'          , coalesce(rco.contrato_gazel::TEXT,''),
                         'periodo_mes'             , upper(of_enum_mes(to_char(ps_afecha,'MM')::INT)),
                         'recaudo_periodo'         , to_char(_recaudo_periodo ,'FM999,999,990.00'),
                         'pagos_finsus'            , to_char(_pgo_finsus_periodo ,'FM999,999,990.00'),
                         'deposito_periodo'        , to_char(_deposito_periodo,'FM999,999,990.00'),
                         'pagos_tercero'           , to_char(_pgo_terceros_periodo,'FM999,999,990.00'),
                         'montopago_exijible'      , to_char(of_si(COALESCE(_saldo_corte,0.00)<0,COALESCE(_saldo_corte,0.00),0.00),'FM999,999,990.00'),
                         'res_mensual'             , _res_mensual,
                         'referencia'              , _referencia,
                         'referencia2'              , _referencia2,
                         'chip'                    , _referenciad,
                         'deudaanterior'           , COALESCE(to_char(_deudaanterior,'FM999,999,990.90'),'0.00'),
                         'deta_recaudo'            , '',
                         'sdo_favor'               , _idsucauxref||'-'||_idproductoref||'-'||_idauxiliarref,
                         'sdo_favor_spd'           , to_char(COALESCE(_spd_sdofav,0.00),'FM999,999,990.90'),
                         'sdo_favor_dp'            , (ps_afecha-of_fecha_dpm(ps_afecha))::TEXT,
                         'sdo_favor_ioisr'         , rsdofdm.int_isr::TEXT,
                         'sdo_favor_tasabruta'     , _tasabruta::TEXT,
                         'sdo_favor_fec'           , sdofavor_det_fecha,
                         'sdo_favor_concepto'      , sdofavor_det_concepto,
                         'sdo_favor_referencia'    , sdofavor_det_referencia,
                         'sdo_favor_retiro'        , sdofavor_det_retiro,
                         'sdo_favor_deposito'      , sdofavor_det_deposito,
                         'sdo_favor_saldo'         , sdofavor_det_saldo,
                         'sdo_favor_sdoini'        , to_char(of_numeric(sdo_favor_sdoini),'FM999,999,990.90'),
                         'sdo_favor_dep'           , to_char(of_numeric(sdo_favor_dep),'FM999,999,990.90'),
                         'sdo_favor_reca'          , to_char(of_numeric(sdo_favor_reca),'FM999,999,990.90'),
                         'sdo_favor_ret'           , to_char(of_numeric(sdo_favor_ret),'FM999,999,990.90'),
                         'sdo_favor_io'            , to_char(of_numeric(sdo_favor_io),'FM999,999,990.90'),
                         'sdo_favor_sdocorte'      , to_char(of_numeric(sdo_favor_sdocorte),'FM999,999,990.90'),
                         'saldooanterior'          , COALESCE(to_char(_saldoanterior,'FM999,999,990.90'),'0.00'),
                         'montovencidoanterior'    , COALESCE(to_char(_montovencidoanterior,'FM999,999,990.90')),
                         'saldooanteriormenosvenc' , to_char(COALESCE(_saldoanterior,0)-COALESCE(_montovencidoanterior),'FM999,999,990.90'),
                         'iopendant'               , to_char(COALESCE(_iopendant,0.00),'FM999,999,990.90'),
                         'saldo_favor_final'       , COALESCE(to_char(_saldo_favor_final,'FM999,999,990.90'),'0.00'),
                         'proxmensualidad'         , to_char(COALESCE(_credproxmensualidad,0.00),'FM999,999,990.90'),
                         'proxcap'                 , to_char(COALESCE(_credabonoppsig,0.00),'FM999,999,990.90'),
                         'proxio'                  , to_char(COALESCE(_credioppsig,0.00),'FM999,999,990.90'),
                         'proxiva'                  , to_char(COALESCE(_credivappsig,0.00),'FM999,999,990.90'),
                         'proxidpago'              , COALESCE(_credidpagoppsig::TEXT,r.diasxplazo::TEXT),
                         'proxsegvida'             , COALESCE(to_char(_credproxsegvida,'FM999,999,990.90'),'0.00'),             
                         'proxsegunidad'           , COALESCE(to_char(_credproxsegunidad,'FM999,999,990.90'),'0.00'),              
                         'proxgps'                 , COALESCE(to_char(_credproxgps,'FM999,999,990.90'),'0.00'),        
                         'proxcom'                 , COALESCE(to_char(_credproxcom,'FM999,999,990.90'),'0.00'),         
                         'proxcomdif'              , COALESCE(to_char(_credproxcomdif,'FM999,999,990.90'),'0.00'), 
                         'abonoppact'              , COALESCE(to_char(_credabonoppact,'FM999,999,990.90'),'0.00'),
                         --'sdofinalmes'             , to_char(COALESCE(_deudaanterior+(_comisiondifca-_comisiondifcaab) - COALESCE(_comdif,0.00),0.00),'FM999,999,990.90'),
                         'sdofinalmes'             , to_char((COALESCE(_deudaanterior,0.00)+COALESCE(mensualidad_periodo,0.00))-(COALESCE(_credabonoppact,0.00)+COALESCE(_abcredito,0.00)),'FM999,999,990.90'),
                         'idpagom'                 , COALESCE(_credidpagoppact::TEXT,r.plazo),  
                         'abcapitalm'              , COALESCE(to_char(_credabonoppact,'FM999,999,990.90'),'0.00'),
                         'iom'                     , COALESCE(to_char(_credioppact,'FM999,999,990.90'),'0.00'),  
                         'ivam'                    , COALESCE(to_char(_credivappact,'FM999,999,990.90'),'0.00'), 
                         'segvidaactm'             , COALESCE(to_char(_segvidaactm,'FM999,999,990.90'),'0.00'),
                         'segunidadactm'           , COALESCE(to_char(_segunidadactm,'FM999,999,990.90'),'0.00'),
                         'gpsactm'                 , COALESCE(to_char(_gpsactm,'FM999,999,990.90'),'0.00'),
                         'comactm'                 , COALESCE(to_char(_comactm,'FM999,999,990.90'),'0.00'),
                         'comdifactm'              , COALESCE(to_char(_comdifactm,'FM999,999,990.90'),'0.00'),
                         'pandemia'                , COALESCE(to_char((_comisiondifca-_comisiondifcaab-coalesce(_comdif,0.00)),'FM999,999,990.90'),'0.00'),
                         'deudaanteriormesanterior', COALESCE(to_char(((_comisiondifca-_comisiondifcaab)+(_saldoanterior+_iopendant)),'FM999,999,990.90'),'0.00'),
                         'pandemiamensual'         , COALESCE(to_char((_comdifactm),'FM999,999,990.90'),'0.00'),
                         'credito_det_fec'         , credito_det_fecha,                   
                         'credito_det_concepto'    , credito_det_concepto,                      
                         'credito_det_referencia'  , credito_det_referencia,                        
                         'credito_det_retiro'      , credito_det_retiro,                    
                         'credito_det_deposito'    , credito_det_deposito,                      
                         'credito_det_saldo'       , credito_det_saldo,  
                         'recaudo_fec'             , recaudo_fecha,          
                         'recaudo_transaccion'     , recaudo_transaccion,                
                         'recaudo_contrato_gazel'  , recaudo_contrato_gazel,                   
                         'recaudo_litros'          , recaudo_litros,           
                         'recaudo_precioxlt'       , recaudo_precioxlt,              
                         'recaudo_recaudo'         , recaudo_recaudo,  
                         'recaudo_nota'            , _recaudo_nota,
                         'audeudopendiente'        , to_char(of_numeric(r.monto_vencido_cap)+(round(of_numeric(r.interes)+of_numeric(r.iva)-COALESCE(_intdif,0),2))+COALESCE(_segunidad,0.00)+COALESCE(_segvida,0.00)+COALESCE(_gps,0.00)+COALESCE(_com,0.00)+COALESCE(_comdif,0.00)+COALESCE(_iodifnoex,0.00),'FM999,999,990.90'),
                         'interesp'                , to_char(round(of_numeric(r.interes)-COALESCE(_intdif,0)+COALESCE(_iodifnoex,0.00),2),'FM999,999,990.90'),
                         'abcredito'               , to_char(COALESCE(_abcredito,0.00),'FM999,999,990.90'),
                         'iocredito'               , to_char(COALESCE(_iocredito,0.00),'FM999,999,990.90'),
                         'ivacredito'               , to_char(COALESCE(_ivacredito,0.00),'FM999,999,990.90'),
                         'segvida'                 , to_char(COALESCE(_segvida,0.00),'FM999,999,990.90'),
                         'segunidad'               , to_char(COALESCE(_segunidad,0.00),'FM999,999,990.90'),
                         'gps'                     , to_char(COALESCE(_gps,0.00),'FM999,999,990.90'),
                         'comision'                , to_char(COALESCE(_com,0.00),'FM999,999,990.90'),        
                         'comision_dif'             , to_char(COALESCE(_comdif,0.00),'FM999,999,990.90'),    
                         'capvigente'              , to_char(COALESCE(_capvigente,0.00),'FM999,999,990.90'),  
                         'mensualidad'             , to_char(COALESCE(mensualidad_periodo,0.00),'FM999,999,990.90'),
                         'saldo_corte'             , to_char(COALESCE(_saldo_corte,0.00),'FM999,999,990.90'),
                         'iodifnoex'               , to_char(coalesce(_intdif,0.00)-COALESCE(_iodifnoex,0.00),'FM999,999,990.90'),
                         'res_ctas'                , _res_ctas::TEXT,
                         'res_ctas_saldos'         , _res_ctas_saldos::TEXT,
                         'res_ctas_saldos_sum'     , to_char(_res_ctas_saldos_sum,'FM999,999,990.90'),
                         'poliza_seg_auto'         , COALESCE(_poliza_seg_auto,''),
                         'numeco'                  , COALESCE(_numeco,''),
                         'vin'                     , COALESCE(_vin,''),
                         'vigencia_polsegauto'     , COALESCE(_vigencia_polsegauto::TEXT,''),
                         'no_paginas'              , COALESCE(_paginas,0)::TEXT,
                         'ult_pagina'              , COALESCE(_ultpagina,0)::TEXT,
                         'otros_creditos_pag_1'    , COALESCE(otros_creditos_pag_1,0)::TEXT,
                         'otros_creditos_pag_2'    , COALESCE(otros_creditos_pag_2,0)::TEXT,
                         'otros_creditos_pag_3'    , COALESCE(otros_creditos_pag_3,0)::TEXT,
                         'otros_creditos_pag_4'    , COALESCE(otros_creditos_pag_4,0)::TEXT,
                         'otros_creditos_pag_5'    , COALESCE(otros_creditos_pag_5,0)::TEXT,
                         'otros_creditos_pag_6'    , COALESCE(otros_creditos_pag_6,0)::TEXT
                         ];
  -- DETALLE DE RECAUDOS --
  -- Validar que existan registros de recaudos
  SELECT INTO rco contrato_gazel FROM ofx_multicampos_auxiliar_masdatos_sus(_kauxiliar);
  PERFORM kauxiliar FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE contrato_gazel = rco.contrato_gazel;

  CASE WHEN of_validate_email(r.email) THEN _valid_emial := 1; ELSE _valid_emial := 0; END CASE;
--_valid_emial := 
  SELECT INTO _nmovimientos count(*)
    FROM ofx_recaudo.detalle_auxiliar
   WHERE trim(contrato_gazel) = trim(rco.contrato_gazel) AND 
         fecha BETWEEN of_fecha_dpm(ps_afecha) AND
                       of_fecha_dum(ps_afecha);


  --r.__params := 'glds=gld01;gld02;gld03;gld04;gld05;gld06;gld07;gld08;gld09;gld10;';
  
  RAISE NOTICE 'PARAMS ===================================== %',_paginas;
  IF (of_ofx_check_version('1.16.6-0')) THEN
  --RAISE NOTICE '============================================ notice 3 % ', r.__params;
    RETURN NEXT r;
  END IF;
  RETURN;
END;$$
LANGUAGE plpgsql;
