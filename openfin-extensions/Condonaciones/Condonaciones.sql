
-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: condonaciones 
-- Condonaciones
-- 04/07/2014

-- ----------------------------------------------------------------------------
-- 04/07/2014 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION condonaciones___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables

BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.

  --Creando permiso de configuracion
  PERFORM * FROM tareas WHERE idtarea = 'ofx_condonacion_cancelar';
  IF NOT FOUND THEN
    INSERT INTO tareas (idtarea,nombre) 
    VALUES ('ofx_condonacion_cancelar','Permiso para cancelar una condonacion');
  END IF;
  
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/07/2014 
-- Inicialización
CREATE OR REPLACE FUNCTION condonaciones___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  f            DATE;
  _auxiliares  TEXT  := of_ofx_get('info_auxiliar');
  _arr         TEXT[]:= string_to_array(_auxiliares,'-');
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  IF (NOT of_ofx_check_version('1.14.1')) THEN
    RETURN FALSE;
  END IF;
  PERFORM of_params_get(
    '/socios/productos/prestamos/condonaciones','metodo_condonacion', -- LAPR Parametro para determinar si son cuentas personalizadas, de ingreso o de estimacion
    'Metodo de contabilizacion para condonacion',
    E'1:Usar condonacion por cancelacion de cuentas de ingreso\n'||
    E'2:Usar condonacion con uso de reservas de estimacion\n'||
    '>=3:Cualquier numero diferente de 1 o 2 usara las cuentas determinadas en parametros para im o io',
    'NUMERIC','1'); 
  PERFORM of_params_get_boolean(
    '/socios/productos/prestamos/condonaciones','cc_condonar_io', -- LAPR Parametro para determinar la cuenta contable personalizada desde donde se condonara el io
    'Cuenta para condonacion de io',
    'Cuenta contable que se usara para condonar el io, debe ser afectable',
    'TEXT','0');
  PERFORM of_params_get_boolean(
    '/socios/productos/prestamos/condonaciones','cc_condonar_im', -- LAPR Parametro para determinar la cuenta contable personalizada desde donde se condonara el im
    'Cuenta para condonacion de im',
    E'Cuenta contable que se usara para condonar el im\n'||
    E'Nota: Si no existe devengamiento de im en balance esta cuenta no tiene uso\n'||
    'ya que no existe un registro contable del adeudo de im, debe ser afecable',
    'TEXT','0');
  f := ofpsd('global','fecha',now()::DATE);
  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dpm(f)::TEXT);
  --LAPR:05/05/2016 Agregando valores al capcha
  PERFORM of_ofx_set('bt_act_polizas_ini','set=click');
  PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));
  --Verificando el permiso para permitir la cancelacion
  IF of_acceso(current_user::TEXT,'ofx_condonacion_cancelar',false) = 0 THEN
     PERFORM of_ofx_set('bt_canc_poliza','sensitive=false');
  END IF;
  IF (_arr IS NOT NULL) THEN
    PERFORM of_ofx_set('idsucaux',   'set=' || _arr[1]);
    PERFORM of_ofx_set('idproducto', 'set=' || _arr[2]);
    PERFORM of_ofx_set('idauxiliar', 'set=' || _arr[3]);
  END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/07/2014 
-- Finalización
CREATE OR REPLACE FUNCTION condonaciones___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/07/2014 
-- Validciones
CREATE OR REPLACE FUNCTION condonaciones___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  _user        TEXT;
  _idsucaux    INTEGER:=of_ofx_get('idsucaux')::INTEGER;
  _idproducto  INTEGER:=of_ofx_get('idproducto')::INTEGER;
  _idauxiliar  INTEGER:=of_ofx_get('idauxiliar')::INTEGER;
  _apli        BOOLEAN:=of_ofx_get('aplicar')::BOOLEAN;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 
  --x := of_ofx_get('mi_variable');
  --y := of_ofx_get_integer('mi_integer');
  --PERFORM of_ofx_notice('error','Este es un mensaje de error');
  --raise notice '----------------_apli %',_apli;
  IF (_apli) THEN
      --raise notice '-----------------%-%-%',_idsucaux,_idproducto,_idauxiliar;
      SELECT INTO _user idusuario 
        FROM temporal 
       WHERE (idsucaux,idproducto,idauxiliar)=(_idsucaux,_idproducto,_idauxiliar);
      IF FOUND THEN
          PERFORM of_ofx_notice('error','No es posible aplicar, el prestamo se encuentra en uso por el usuario '||_user);
          PERFORM of_ofx_set('aplicar','set=false');
          RETURN FALSE;
      END IF;
  END IF;
  IF (p_variable='aplicar' AND p_valor::BOOLEAN) THEN
      SELECT INTO _user idusuario 
        FROM temporal 
       WHERE (idsucaux,idproducto,idauxiliar)=(_idsucaux,_idproducto,_idauxiliar);
      IF FOUND THEN
          PERFORM of_ofx_notice('error','No es posible aplicar, el prestamo se encuentra en uso por el usuario '||_user);
          RETURN FALSE;
      END IF;
  END IF;

  --LAPR: 05/06/2016 simulando clic al boton de refresh
  IF (p_variable='afecha') THEN
      PERFORM of_ofx_set('bt_act_polizas','set=click');
  END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/07/2014 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION condonaciones___on_click (p_button TEXT, p_data TEXT) 
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
  _arr     TEXT[];
  _capcha  TEXT:=of_ofx_get('capcha');
  _capcha2 TEXT:=of_ofx_get('capcha2');
  _ok      TEXT;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  IF (p_button = 'bt_aceptar') THEN
    
  END IF;

  --LAPR: 05/06/2016 Cancelacion de la póliza
  IF (p_button = 'bt_canc_poliza') THEN
      _arr :=of_ofx_get('sw_polizas_tv_row_info');
      IF (_arr[1] IS NULL) THEN
          PERFORM of_ofx_notice('error','Error:Debe seleccionar una póliza');
          PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));
          RETURN 0;
      END IF;
      IF (_arr[6]::BOOLEAN) THEN
          PERFORM of_ofx_notice('error','Error:La poliza ya esta cancelada');
          PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));
          RETURN 0;
      END IF;
      IF (_capcha<>_capcha2) THEN
          PERFORM of_ofx_notice('error','Error:Campo verificador no coincide');
          PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));
          RETURN 0;
      END IF;
      _ok :=condonaciones___cancelacion(_arr[1]);
      IF (trim(_ok)='ok') THEN
          PERFORM of_ofx_notice('info','Poliza cancelada correctamente');
          PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));
          PERFORM of_ofx_set('bt_act_polizas','set=click');
      ELSE
          PERFORM of_ofx_notice('error','Hubo un problema en la cancelación');
          PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));
      END IF;
      RETURN 0;
  END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/07/2014 
-- Función principal
SELECT of_db_drop_type('condonaciones','CASCADE');
CREATE TYPE condonaciones AS (
  valor1        TEXT    -- Una descripción...
);

CREATE OR REPLACE FUNCTION condonaciones (INTEGER,INTEGER,INTEGER,NUMERIC, NUMERIC, BOOLEAN)
  RETURNS SETOF TEXT AS $$
DECLARE -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Parámetros
  p_idsucaux    ALIAS FOR $1;
  p_idproducto  ALIAS FOR $2;
  p_idauxiliar  ALIAS FOR $3;
  P_CoIO        ALIAS FOR $4;
  P_CoIM        ALIAS FOR $5;
  p_afectar     ALIAS FOR $6;

  -- Variables
  linea         TEXT;
  rd            RECORD;
  rd2           RECORD;
  rq            RECORD;
  rp            RECORD;
  rdesg         RECORD;
  rdesg_eco     RECORD;
  rdesg_eco_c   RECORD;
  rdesg_c       RECORD;
  rx            RECORD;
  rins          RECORD;
  rfoto         tipo_deudor%ROWTYPE;
  rdx           RECORD;
  rcc           RECORD;
  _pp           RECORD;

  _idsucaux     INTEGER;
  _idproducto   INTEGER;
  _idauxiliar   INTEGER;

  _idusuario    TEXT;
  _suctrabajo   INTEGER;
  _signum       INTEGER;
  c             TEXT;
  _dir_seq      TEXT;
  _fechaape     DATE;
  _fecha_oper   DATE;
   n            INTEGER:=0;
   
   -- Calculo de Montos Condonados --
  _io_c         NUMERIC:=0;  -- Es el IO condonado reconocido en ingresos
  _io_eco_c     NUMERIC:=0;  -- Es el IO condonado reconocido en ECO
  _imp_c        NUMERIC:=0;  -- Es el impuesto cancelado del IO reconocido en ingresos
  
  _im_c         NUMERIC:=0;  -- Es el IM condonado reconocido en ingresos
  _im_eco_c     NUMERIC:=0;  -- Es el IM condonado reconocido en ECO
  _impim_c      NUMERIC:=0;  -- Es el impuesto cancelado del IM reconocido en ingresos
  
 -- Calculo de Montos a fecha de consulta
  _capital_q    NUMERIC:=0;
  _io_q         NUMERIC:=0;  -- 
  _io_eco_q     NUMERIC:=0;  -- 
  _imp_q        NUMERIC:=0;  -- 
  
  _im_q         NUMERIC:=0;  -- 
  _im_eco_q     NUMERIC:=0;  -- 
  _impim_q      NUMERIC:=0;  -- 

  _incremento_rva NUMERIC:=0;
  _idcuenta     TEXT;
  arr_pol_quebranto TEXT[];
  arr_pol_clasifica TEXT[];

  poliza        TEXT;
  arr           TEXT[];
  sw_saldo_cero INTEGER:=0;
  rol_quebranto INTEGER:=0;
  _fecha_IVA    DATE;

  factor_iva_io            NUMERIC:=0;     
  base_iva_io              NUMERIC:=0;
  tdebe                    NUMERIC:=0;
  thaber                   NUMERIC:=0;
  --
  paso                  NUMERIC;

  contabiliza_iva_metodo  INTEGER:=1; -- Metodo para contabilizar el iva, el 1 es
                                      -- el default, y el 2 es por criterios de depac.
                                      
  -- JCH: 30/01/2012 Agregar variante de contabilización estilo BOSCO. Por defual se tenia el idproducto como variante
  variante_conta      TEXT;

  contabiliza_im_bal  BOOLEAN; -- JCH: 28/05/2013 OJO: Este parámetro es para contabilizar IM en cuentas de BALANCE
  contabiliza_im      BOOLEAN; -- JMCR: Metodo de contabilizar moratorio en cuentas de orden, caso DEPAC
  
  _paso_q             NUMERIC:=0;
  _reserva_actual     NUMERIC:=0;
  ptxt                TEXT;
  rtxt                TEXT:= '                                             ';
  _ccc_iodev          TEXT;
  _ccc_imdev          TEXT;
  _ccc_io_eprc_act    TEXT;
  _ccc_im_eprc_act    TEXT;
  _ccc_io_eprc_res    TEXT;
  _ccc_im_eprc_res    TEXT;
  _metodo_condonacion INTEGER;
  _cc_condonar_io     TEXT;
  _cc_condonar_im     TEXT;
  _maxidpago          INTEGER;
  _data               TEXT[];
  _iopend             NUMERIC;
  _impend             NUMERIC;
  _expediente         BOOLEAN;--LAPR 24/06/2016 Parametro para activar o desactivar la insercion al expediente
  _so_ab_venc         BOOLEAN;--LAPR 14/04/2019 Parametro de solo abonos vencidos para el interes en pagos fijos      

BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  contabiliza_im_bal := COALESCE(of_params_get_boolean('/socios/productos/prestamos','contabiliza_im_bal'),FALSE);
  SELECT INTO contabiliza_im of_params_get_boolean(
    '/socios/productos/prestamos','contabiliza_im', -- JCH: 28/05/2013 OJO: Este parámetro es para contabilizar IM en cuentas de orden (caso DEPAC)
    'Contabiliza Interes Moratorio',
    'Contabilizacion de los intereses moratorios dentro de la regulacion',
    'BOOLEAN','NO');  
  SELECT INTO _metodo_condonacion of_params_get(
    '/socios/productos/prestamos/condonaciones','metodo_condonacion', -- JCH: 28/05/2013 OJO: Este parámetro es para contabilizar IM en cuentas de orden (caso DEPAC)
    'Metodo de contabilizacion para condonacion',
    E'1:Usar condonacion por cancelacion de cuentas de ingreso\n'||
    E'2:Usar condonacion con uso de reservas de estimacion\n'||
    '>=3:Cualquier numero diferente de 1 o 2 usara las cuentas determinadas en parametros para im o io',
    'NUMERIC','1'); 
  SELECT INTO _cc_condonar_io of_params_get(
    '/socios/productos/prestamos/condonaciones','cc_condonar_io', -- JCH: 28/05/2013 OJO: Este parámetro es para contabilizar IM en cuentas de orden (caso DEPAC)
    'Cuenta para condonacion de io',
    'Cuenta contable que se usara para condonar el io',
    'TEXT','0');
  SELECT INTO _cc_condonar_im of_params_get(
    '/socios/productos/prestamos/condonaciones','cc_condonar_im', -- JCH: 28/05/2013 OJO: Este parámetro es para contabilizar IM en cuentas de orden (caso DEPAC)
    'Cuenta para condonacion de im',
    E'Cuenta contable que se usara para condonar el im\n'||
    E'Nota: Si no existe devengamiento de im en balance esta cuenta no tiene uso\n'||
    'ya que no existe un registro contable del adeudo de im',
    'TEXT','0');
  SELECT INTO _expediente of_params_get_boolean(
    '/socios/productos/prestamos/condonaciones','registrar_en_expediente', -- LAPR 24/06/2016 Registrar o no en expediente
    'Registrar o no en expediente',
    'Si se encuentra activo quedar registrado en expediente el movimiento de la condonacion',
    'BOOLEAN','FALSE');
  --Interes al vencimiento del abono
  _so_ab_venc :=COALESCE(of_params_get_boolean('/socios/productos/prestamos/condonaciones/'||_idproducto::TEXT,'solo_abonos_vencidos'),FALSE);
  
  --LAPR: 05/05/2016 Se valida que el auxiliar exista antes de comenzar con el proceso
  PERFORM * 
     FROM deudores 
    WHERE (idsucaux,idproducto,idauxiliar)=(p_idsucaux,p_idproducto,p_idauxiliar) AND estatus=3;
  IF (NOT FOUND) THEN
      PERFORM of_ofx_notice('error','El prestamo no existe o ya no se encuentra activo');
      RETURN;
  END IF;

  -- JCH: 28/05/2013 Contabilizar IM en cuentas de balance (caso Zongolica)
  IF (contabiliza_im AND contabiliza_im_bal) THEN -- No pueden estar en TRUE los dos
    contabiliza_im_bal := FALSE; -- Se le dara preferencia al IM en cuentas de orden por ser mas antiguo -> Que tierno !!
  END IF;

  -- SI tiene una poliza de diario en ventanilla no puede usar este modulo
  PERFORM * 
     FROM tablas 
    WHERE (idtabla, idelemento) = ('user_' || trim(current_user::varchar), 'tp3');
  IF (FOUND) THEN
    RAISE EXCEPTION 'Imposible usar este módulo con una póliza de diario pendiente en ventanilla.';
  END IF;

  SELECT INTO contabiliza_iva_metodo of_params_get(
    '/socios/productos/prestamos','contabiliza_iva_metodo',
    'Método de contabilización de IVA',
    'El método 1 es el tradicional, el método 2 utiliza cuentas de orden para contabilizar el iva devengado. ' |+
    '      y el IVA se reconoce solo hasta que se paga efectivamente,',
    'INTEGER','1');

  -- Por Seguridad, borramos el contenido del temporal
  DELETE FROM temporal WHERE (idusuario,sesion)=(current_user,pg_backend_pid()::TEXT);

  SELECT INTO _fecha_IVA of_params_get(
      '/socios/productos/prestamos','Fecha IVA completo',
      'Fecha para cobro del IVA completo',
      'Todos los prestamos entregados a partir de esta fecha se comenzara a cobar el IVA Completo ',
      'DATE','17/06/2009');

  _idusuario := current_user::TEXT;
  SELECT INTO _suctrabajo suctrabajo
    FROM usuarios
   WHERE idusuario = _idusuario;

  IF (NOT FOUND) THEN
    PERFORM of_tablero('urgente-mensaje',
                       'ERROR: No se puede determinar la sucursal de afectación del usuario «' |+ _idusuario |+ '».');
    RAISE EXCEPTION 'ERROR: No se puede determinar la sucursal de afectación del usuario «%»', _idusuario;
  END IF;

  _fecha_oper := ofpsd('global', 'fecha');

  SELECT INTO rdx *
    FROM of_deudor(p_idsucaux,p_idproducto,p_idauxiliar,_fecha_oper);

  IF (rdx.fechaultima IS NULL) THEN
    RAISE EXCEPTION 'ERROR: EL AUXILIAR NO CUENTA CON FECHA ÚLTIMA.';
  END IF;

  --RAISE NOTICE 'ESTATUS: %',rd.estatus;

  linea := ' Datos calculados a la fecha: ' |+ _fecha_oper::TEXT;
  RETURN NEXT linea;
  linea := '--------------------------------------------------------';
  RETURN NEXT linea;

  factor_iva_io := 0; --- Se deja en uno incialmente para que no produsca un cero mas abajo ...

  IF (of_iva_general(p_idsucaux,p_idproducto,p_idauxiliar,rdx.tipoprestamo,_fecha_oper)) THEN -- JCH: 25/Jul/2006 Solo a pestamos consumo
    SELECT INTO factor_iva_io of_params_get(
        '/socios/productos/prestamos','iva_io',
        'Porcentaje para calculo de IVA',
        'Porcentaje del IVA a calcular sobre los intereses ordinarios por cobrar',
        'NUMERIC','0.00');
    SELECT INTO base_iva_io of_params_get(
        '/socios/productos/prestamos','base_iva_io',
        'Base de calculo de IVA IO',
        'Base sobre el cual se calculara el IVA de los Intereses Ordinarios',
        'NUMERIC','100.00');

    base_iva_io   := ROUND((base_iva_io /100.00),2);
    factor_iva_io := ROUND((factor_iva_io /100.00),2) * base_iva_io;
  END IF;

  IF (p_afectar) THEN
    -- JCH: Antes de aplicar, clasificamos el auxiliar a la fecha
    -- El auxiliar quedara clasificado contablemente y todos sus valores
    -- quedaran actualizados.
    IF (_metodo_condonacion NOT IN (1,2)) THEN
      PERFORM * FROM cuentas WHERE idcuenta=_cc_condonar_io AND clase=4;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Error:La cuenta contable definida para condonar io no existe o no es afectable';
      END IF;
      IF (contabiliza_im OR contabiliza_im_bal) THEN
        PERFORM * FROM cuentas WHERE idcuenta=_cc_condonar_im AND clase=4;
        IF NOT FOUND THEN
          RAISE EXCEPTION 'Error:La cuenta contable definida para condonar im no existe o no es afectable';
        END IF;
      END IF;
    END IF;


    SELECT INTO arr_pol_clasifica of_deudor_clasifica(p_idsucaux, p_idproducto, p_idauxiliar, _fecha_oper, 
                                                      _suctrabajo, 3, NULL, current_user::varchar);
    SELECT INTO tdebe, thaber SUM(debe), SUM(haber)
      FROM detalle_polizas
     WHERE (idsucpol, periodo, tipopol, idpoliza)=
           (arr_pol_clasifica[1]::INTEGER, arr_pol_clasifica[2]::INTEGER,
            arr_pol_clasifica[3]::INTEGER, arr_pol_clasifica[4]::INTEGER);
    
    IF tdebe <> thaber OR tdebe <= 0 OR thaber <= 0 THEN
      DELETE FROM temporal WHERE (idusuario,sesion)=(current_user,pg_backend_pid()::TEXT);
      --RAISE EXCEPTION 'ERROR: LA PÓLIZA DE CLASIFICACIÓN TIENE ERORRES: LA CLASIFICACIÓN FUE REVERTIDO. REPORTAR ERROR A SOPORTE SINC.';
    END IF;
  END IF;
  --
  -- Actualizamos valores y calculos del créito despues de clasificarlo
  --
  SELECT INTO rd *
    FROM of_deudor(p_idsucaux,p_idproducto,p_idauxiliar,_fecha_oper);
  --
  -- JCH: 25/02/2013 Guardar una foto de la situación actual del crédito antes de afectarlo
   SELECT INTO rfoto *
     FROM of_deudor (p_idsucaux,p_idproducto,p_idauxiliar,_fecha_oper);
  PERFORM of_deudor_foto_guarda(rfoto, _fecha_oper, NULL);  

  -- Primero;
  -- Identificamos las cantidades a condonar
  _capital_q := rd.saldo;
  _io_eco_q  := (rd.IOECO  + rd.interesord_eco) +                         
                ROUND((rd.IOECO  + rd.interesord_eco) * factor_iva_io,2); 

  _io_q      := rd.interes_total + rd.impuesto_total - _io_eco_q;         -- Es el IO reconocido como devengado, condonable

  _imp_q     := rd.impuesto_total;                                        -- Es el Impuesto del IO reconocido como devengado

  _im_eco_q  := (rd.IMECO  + rd.interesmor_eco) +
                ROUND((rd.IMECO  + rd.interesmor_eco) * factor_iva_io,2); -- Es el IM reconocido como devengado, condonable

  _im_q      := rd.interesmor_total + rd.impuestoim_total - _im_eco_q;    -- Es el Impuesto del IM reconocido como devengado

  --LAPR Saliendo de aqui _im_q y _io_q incluyen iva

  SELECT INTO rdesg * -- Desglose de impuestos
    FROM of_deudor_desg_impuesto(p_idsucaux,p_idproducto,p_idauxiliar,
                                 _io_q,_im_q,0,_fecha_oper);              --- IO e IM <90dias desglosado

  SELECT INTO rdesg_eco * -- Desglose de impuestos para montos de IO en cuentas de orden
    FROM of_deudor_desg_impuesto(p_idsucaux,p_idproducto,p_idauxiliar,    --- IO e IM  ECO  desglosado
                                 _io_eco_q,_im_eco_q,0,_fecha_oper);
  _incremento_rva := _capital_q + _io_q - rdesg.IO_impuesto;
  IF (contabiliza_im_bal) THEN
    -- El moratorio forma parte de la Estimacion para el quebranto
    _incremento_rva := _incremento_rva + _im_q - rdesg.IM_impuesto;
  END IF;

  linea := ' ';
  RETURN NEXT linea;
  linea := ' Cliente                    : ' |+ rd.idsucursal::TEXT |+ '-' |+ rd.idrol::TEXT |+ '-' |+ rd.idasociado::TEXT |+ ' ' |+
                                                 of_nombre_asociado(rd.idsucursal, rd.idrol, rd.idasociado);
  RETURN NEXT linea;
  linea := ' Auxiliar                   : ' |+ rd.idsucaux::TEXT |+ '-' |+ rd.idproducto::TEXT |+ '-' |+ rd.idauxiliar::TEXT |+ ' ' |+
                                            (SELECT nombre FROM productos WHERE idproducto = rd.idproducto);
  RETURN NEXT linea;
  linea := ' Fecha Último Cálculo       : ' |+ rdx.fechaultcalculo::TEXT;
  RETURN NEXT linea;
  linea := ' ';
  RETURN NEXT linea;
  linea := ' Interés Ord. Devengado     : ' |+ to_char(_io_q-rdesg.IO_impuesto,'999,999,999.99') |+ ' * Este monto está reconocido en Ingresos';
  RETURN NEXT linea;
  linea := ' Interés Ord. ECO           : ' |+ to_char(_io_eco_q-rdesg_eco.io_impuesto,'999,999,999.99');
  RETURN NEXT linea;
  linea := '     TOTAL Int. Ordinario   : ' |+ to_char(_io_q-rdesg.IO_impuesto + _io_eco_q-rdesg_eco.io_impuesto,'999,999,999.99') ;
  RETURN NEXT linea;
  linea := ' ';
  RETURN NEXT linea;

  IF (contabiliza_im_bal) THEN
    linea := ' Interés Mor. Devengado     : ' |+ to_char(_im_q-rdesg.IM_impuesto,'999,999,999.99') |+ ' * Este monto está reconocido en Ingresos';
    RETURN NEXT linea;
    linea := ' Interés Mor. ECO           : ' |+ to_char(_im_eco_q-rdesg_eco.im_impuesto,'999,999,999.99');
    RETURN NEXT linea;
    linea := '     TOTAL Int. Moratorio   : ' |+ to_char(_im_q-rdesg.IM_impuesto + _im_eco_q-rdesg_eco.im_impuesto,'999,999,999.99') ;
    RETURN NEXT linea;
  ELSE
    linea := ' Interés Mor. ECO           : ' |+ to_char(_im_q-rdesg.IM_impuesto + _im_eco_q-rdesg_eco.im_impuesto,'999,999,999.99') |+ ' * Es el total del Interes Moraorio que no afecta Resultados';
    RETURN NEXT linea;
  END IF;  

  linea := ' Estatus                      :';
  IF (rd.estatuscartera IN (1,2)) THEN
    linea := linea |+ '      VIGENTE ';
  ELSE
    linea := linea |+ '      VENCIDO -> ' |+ of_si(rd.vence > _fecha_oper,' Vencido por días de mora.',' ') |+
                          ' Fecha vencimiento TOTAL: ' |+ rd.vence::TEXT;
  END IF;
  linea := linea |+ of_si(rd.vecesrenovado      > 0,' RENOVADO','');
  linea := linea |+ of_si(rd.vecesrestructurado > 0,' REESTRUCTURADO','');
  RETURN NEXT linea;
  linea := ' Días de Mora                 :' |+ to_char(rd.diasmora,'999,999');
  RETURN NEXT linea;

  --Si el metodo es por reservas, hay que ajustarlas
  IF (_metodo_condonacion=2) THEN 
    linea := ' Reserva Requerida            :' |+ to_char(rd.req_reservacapital+P_CoIO+of_si(contabiliza_im_bal,P_CoIM,0),'999,999,999.99');
    RETURN NEXT linea;
    _reserva_actual := rd.reservacapital + of_si(rd.estatuscartera=3,(_io_q - rdesg.IO_impuesto),0);
    IF (contabiliza_im_bal) THEN
     _reserva_actual := _reserva_actual+of_si(rd.estatuscartera=3,(_im_q - rdesg.IM_impuesto),0);
    END IF;
    linea := ' Reserva Actual               :' |+ to_char(_reserva_actual,'999,999,999.99');
    RETURN NEXT linea;

    --IF contabiliza_im_bal THEN
    --  ptxt := ' Sdo. Crédito + Int.Ord. + Int. Mor. - Int.Ord.ECO - Int.Mor.Eco';
    --ELSE
    --  ptxt := ' Sdo. Crédito + Int.Ord. - Int.Ord.ECO';
    --END IF;
    --
    --linea := ' Rva. Requerida para Quebranto:' |+ to_char(_incremento_rva,'999,999,999.99') |+ ptxt;
    --RETURN NEXT linea;
    --linea := ' Diferencia en Reserva        :' |+ to_char(_incremento_rva - _reserva_actual,'999,999,999.99')
    --                                           |+ of_si(_incremento_rva - _reserva_actual = 0,' NO SE ',' ')
    --                                           |+ of_si(_incremento_rva - _reserva_actual < 0,' HAY EXCEDENTE DE RESERVA retorno de estimación al Gasto',' REQUIERE INCREMENTO DE RESERVA');
    --RETURN NEXT linea;
    --RETURN NEXT of_si(_incremento_rva - _reserva_actual = 0,'  ',' se genera Cargo al Gasto por este monto ') ;
  END IF;

  linea := ' ';
  RETURN NEXT linea;
  linea := ' Aplicación de Condonación: ';
  RETURN NEXT linea;
  --raise notice '--------------------Val monto %,%,%,%,%',P_CoIO,_io_q,_io_eco_q,rd.impuesto_total,_io_q+_io_eco_q+rd.impuesto_total;
  --raise notice '--------------------Val monto %,%,%,%,%',P_CoIM,_im_q,_im_eco_q,rd.impuestoim_total,_im_q+_im_eco_q+rd.impuestoim_total;
  IF (P_CoIO > (_io_q - rdesg.IO_impuesto+_io_eco_q-rdesg_eco.IO_impuesto)) THEN   -- El monto de condonacion excede los montos reales
    linea := ' *** ERROR ***   El monto de condonacion excede el monto total de Interés Ordinario actual.';
    RETURN NEXT linea;
    RETURN;
  END IF;

  IF (P_CoIM > (_im_q - rdesg.IM_impuesto+_im_eco_q-rdesg_eco.IM_impuesto)) THEN   -- El monto de condonacion excede los montos reales
    linea := ' *** ERROR ***   El monto de condonacion excede el monto total de Interés Moratorio actual.';
    RETURN NEXT linea;
    RETURN;
  END IF;

  -- Primero distribuimos el monto por condonar en el IOECO, si sobra lo mandamos al IODEV 
  IF (P_CoIO > _io_eco_q-rdesg_eco.io_impuesto) THEN
     _io_eco_c := _io_eco_q-rdesg_eco.io_impuesto;
     _io_c     := P_CoIO - _io_eco_c;
  ELSE
     _io_eco_c := P_CoIO;
     _io_c     := 0;
  END IF;
  
  --_io_q := P_CoIO; -- El resto del monto por condonar se va al IODEV 
  --P_CoIO := 0;

  IF (contabiliza_im_bal) THEN
    -- Primero distribuimos el monto por condonar en el IMECO, si sobra lo mandamos al IODEV 
    IF (P_CoIM > _im_eco_q-rdesg_eco.im_impuesto) THEN
       _im_eco_c := _im_eco_q-rdesg_eco.im_impuesto;
       _im_c     := P_CoIM - _im_eco_c;
    ELSE
       _im_eco_c := P_CoIM;
       _im_c     := 0;
    END IF;
  
    --_im_q := P_CoIM; -- El resto del monto por condonar se va al IODEV 
    --P_CoIO := 0;
  ELSIF (contabiliza_im) THEN
    -- Al no reconocer IM devengado en balance, todose va al IMECO
    _im_eco_c := P_CoIM;
    --P_CoIM := 0;
  ELSE
    --No se esta devengando el IM en ningun lado, no aplica clasificacion
  END IF;



  -- linea := ' Saldo en préstamo            :' |+  to_char(_capital_q,'999,999,999.99');
  -- RETURN NEXT linea;
  linea := ' Int. Ordinario  Devengado <90 días :' |+ to_char(_io_c ,'999,999,999.99') |+ 'Afecta Resultados ';
  RETURN NEXT linea;

  linea := ' Int. Ordinario  ECO  >90 días      :' |+ to_char(_io_eco_c ,'999,999,999.99');
  RETURN NEXT linea;

  IF (contabiliza_im_bal) THEN
    linea := ' Int. Moratorio  Devengado <90 días :' |+ to_char(_im_c ,'999,999,999.99') |+ 'Afecta Resultados ';
    RETURN NEXT linea; 
    linea := ' Int. Moratorio  ECO  >90 días      :' |+ to_char(_im_eco_c ,'999,999,999.99');
    RETURN NEXT linea;
  ELSIF (contabiliza_im) THEN 
    linea := ' Int. Moratorio  ECO                :' |+ to_char(_im_eco_c ,'999,999,999.99');
    RETURN NEXT linea;
  ELSE
    linea := ' Int. Moratorio                     :' |+ to_char(P_CoIM ,'999,999,999.99');
    RETURN NEXT linea;
  END IF;
  
  SELECT INTO rdesg_c * -- Desglose de impuestos
    FROM of_deudor_desg_impuesto(p_idsucaux, p_idproducto, p_idauxiliar,
                                 _io_c+((_io_c)*factor_iva_io),
                                 _im_c+((_im_c)*factor_iva_io),0,_fecha_oper);  
  SELECT INTO rdesg_eco_c * -- Desglose de impuestos
    FROM of_deudor_desg_impuesto(p_idsucaux,p_idproducto,p_idauxiliar,
                                 _io_eco_c+((_io_eco_c)*factor_iva_io),
                                 _im_eco_c+((_im_eco_c)*factor_iva_io),0,_fecha_oper);  
  IF (contabiliza_im OR contabiliza_im_bal) THEN
     linea := ' TOTAL CONDONACION           :' |+ to_char((_io_c+_io_eco_c +_im_c+_im_eco_c),'999,999,999.99');
  ELSE
     linea := ' TOTAL CONDONACION           :' |+ to_char((_io_c+_io_eco_c +P_CoIM),'999,999,999.99');
  END IF;
                                               --to_char(_io_q+ - rdesg.IO_impuesto +
                                               --   of_si(contabiliza_im_bal,(_im_q - rdesg.IM_impuesto),0),'999,999,999.99');
  RETURN NEXT linea;
  IF contabiliza_iva_metodo = 1 THEN
    linea := ' IVA de Int. Ord. Cancelado   :' |+ to_char(rdesg_c.IO_impuesto,'999,999,999.99');
    RETURN NEXT linea;
    RETURN NEXT ' Este IVA esta registrado en cuentas de Balance por el devengamiento de interés';
    RETURN NEXT 'reconocido en resultados, pero por efecto de Condonación, será cancelado de las';
    RETURN NEXT 'cuentas en que se registró ya que no es un ingreso.';
  ELSE
    linea := ' IVA de Int. Ord. Cancelado   :' |+ to_char(rdesg_c.IO_impuesto,'999,999,999.99');
    RETURN NEXT linea;
    RETURN NEXT ' Este IVA esta registrado en cuentas de Orden por el devengamiento de interés';
    RETURN NEXT 'reconocido en resultados, pero por efecto de Condonación, será cancelado de las';
    RETURN NEXT 'cuentas en que se registró ya que no es un ingreso.';
  END IF;
  IF (contabiliza_im_bal) THEN
    IF (contabiliza_iva_metodo = 1) THEN
      linea := ' IVA de Int. Mor. Cancelado   :' |+ to_char(rdesg_c.IM_impuesto,'999,999,999.99') |+ '';
      RETURN NEXT linea;
      RETURN NEXT ' Este IVA esta registrado en cuentas de Balance por el devengamiento de interés';
      RETURN NEXT 'reconocido en resultados, pero por efecto de Condonación, será cancelado de las';
      RETURN NEXT 'cuentas en que se registró ya que no es un ingreso.';
    ELSE
      linea := ' IVA de Int. Mor. Cancelado   :' |+ to_char(rdesg_c.IM_impuesto,'999,999,999.99') |+ '';
      RETURN NEXT linea;
      RETURN NEXT ' Este IVA esta registrado en cuentas de Orden por el devengamiento de interés';
      RETURN NEXT 'reconocido en resultados, pero por efecto de Condonación, será cancelado de las';
      RETURN NEXT 'cuentas en que se registró ya que no es un ingreso.';
    END IF;
  END IF;

  linea := ' ';
  RETURN NEXT linea;

  linea := ' ';

  -- JCH: 30/01/2012 Agregar variante de contabilización estilo BOSCO
  variante_conta := of_params_get('/contabilidad','variante');
  IF (variante_conta IS NOT NULL) THEN
    IF (variante_conta = 'idsucursal') THEN  -- Por sucursal del socio
      variante_conta := rd.idsucursal::TEXT || '_' || rd.idproducto::TEXT;
    ELSIF (variante_conta = 'idsucaux') THEN -- Por sucursal del auxiliar
      variante_conta := rd.idsucaux::TEXT || '_' || rd.idproducto::TEXT;
    ELSIF (variante_conta = 'subtipoprestamo') THEN -- Por subtipo de préstamo (Regulación)
      variante_conta := COALESCE(rd.subtipoprestamo::TEXT,'0');
    ELSIF (variante_conta = 'subtipoprestamo_idproducto') THEN -- Por subtipo de préstamo y producto (Regulación)
      variante_conta := COALESCE(rd.subtipoprestamo::TEXT|| '_' || rd.idproducto::TEXT,'0');
    ELSE
      variante_conta := NULL;
    END IF;
  END IF;

  -- La logica para la afectacion de productos en cuentas de orden
  -- continua siendo la misma en esta nueva versión de quebrantos.


  -- -------------------------------------------------------------
  -- Afectacion de cuentas de IODevengado contra :
  -- 1) Cuenta pre-definida, que puede ser de gastos u otro tipo
  -- 2) Cuenta de resultados de IO.
  -- -------------------------------------------------------------
  IF (_metodo_condonacion = 1) THEN
    _ccc_iodev := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'io',variante_conta);
  ELSIF (_metodo_condonacion = 2) THEN
    _ccc_iodev := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,of_si(rd.estatuscartera=3,'reserva_int_activo','reserva_cap_activo'),variante_conta);
  ELSE
    _ccc_iodev := _cc_condonar_io;
  END IF;
  _ccc_io_eprc_act    :=of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,of_si(rd.estatuscartera=3,'reserva_int_activo','reserva_cap_activo'),variante_conta);
  _ccc_im_eprc_act    :=of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,of_si(rd.estatuscartera=3,'reserva_intmor_activo','reserva_cap_activo'),variante_conta);
  _ccc_io_eprc_res    :=of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,of_si(rd.estatuscartera=3,'reserva_int_result','reserva_cap_result'),variante_conta);
  _ccc_im_eprc_res    :=of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,of_si(rd.estatuscartera=3,'reserva_intmor_result','reserva_cap_result'),variante_conta);

  linea := ' Cuenta Contable Cargo IO Devengado  ' |+ _ccc_iodev;
  linea := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(_io_c ,'999,999,999.99');
  RETURN NEXT linea;




    -- -------------------------------------------------------------
  -- Afectacion de cuentas de IMDevengado contra :
  -- 1) Cuenta pre-definida, que puede ser de gastos u otro tipo
  -- 2) Cuenta de resultados de IM.
  -- -------------------------------------------------------------
  --_ccc_imdev := of_params_get('/socios/traspasos/macros/condonacion','CtaCont.Cargo_IMDEV');
  
  --SELECT INTO rcc * CUENTAS 
  --  WHERE idcuenta = _ccc_imdev AND clase = 4;
  IF (contabiliza_im_bal) THEN
    IF (_metodo_condonacion = 1) THEN
      _ccc_imdev := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'im',variante_conta);
    ELSIF (_metodo_condonacion = 2) THEN
      _ccc_imdev := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,of_si(rd.estatuscartera=3,'reserva_int_activo','reserva_cap_activo'),variante_conta);
    ELSE
      _ccc_imdev := _cc_condonar_im;
    END IF;
  END IF;

  linea := ' Cuenta Contable Cargo IM Devengado  ' |+ COALESCE(_ccc_imdev,'N/A');
  linea := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(_im_c,'999,999,999.99');
  RETURN NEXT linea;
  linea := '';
  RETURN NEXT linea;
  RETURN NEXT linea;

  -- (2) Cuadramos el asiento en la cuenta de orden. Para esto usaremos la cuenta
  -- de capital vencido definida en el producto

  _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,CASE WHEN rd.estatuscartera=3 THEN 'iodnc_venc' ELSE 'iodnc' END,variante_conta);
  linea     := ' Cta.  iodnc  ' |+ _idcuenta;
  linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(_io_c,'999,999,999.99');
  RETURN NEXT linea;

  -----------------------------------------------
  -- Afectacion de cuentas de orden IO ECO
  -----------------------------------------------
  -- (1) Transferir es saldo del capital al producto tipo DEUDOR DIVERSO, el cual
  -- debería estar apuntando a una cuenta de orden

  _idcuenta := _ccc_iodev;
  linea     := ' Cta. condonacion io' |+ _idcuenta::TEXT;
  linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_io_c),0),'999,999,999.99');
  RETURN NEXT linea;

  -- (2) Cuadramos el asiento en la cuenta de orden. Para esto usaremos la cuenta
  -- de capital vencido definida en el producto
  
  _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'iodnc_eco_ca',variante_conta);
  linea     := ' Cta.  Orden IO ECO deudor ' |+ _idcuenta;
  linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_io_eco_c),0) ,'999,999,999.99');
  RETURN NEXT linea;

  _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'iodnc_eco_ab',variante_conta);
  linea     := ' Cta.  Orden IO ECO acreedor ' |+ _idcuenta;
  linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_io_eco_c),0) ,'999,999,999.99');
  RETURN NEXT linea;

  -----------------------------------------------------------------------------------------------------------
  IF (contabiliza_im_bal) THEN
    -- ------------------------------------------
    -- Afectacion de cuentas de orden IM Vencido -- suena raro, pero así es, IM vencido ...!!
    -- ------------------------------------------
    
    _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,CASE WHEN rd.estatuscartera=3 THEN 'imdnc_venc' ELSE 'imdnc' END,variante_conta);
    linea   := ' Cta. IM ' |+ _idcuenta;
    linea   := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_im_c),0) ,'999,999,999.99');
    RETURN NEXT linea;
     
    _idcuenta := _ccc_imdev;
    linea   := ' Cta. condonacion IM ' |+ _idcuenta;
    linea   := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_im_c),0) ,'999,999,999.99');
    RETURN NEXT linea;
  END IF;
     
  -- (2) Cuadramos el asiento en la cuenta de orden. Para esto usaremos la cuenta
  -- de capital vencido definida en el producto
  IF (contabiliza_im) THEN
    _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'imdnc_eco',variante_conta);
    linea   := ' Cta.  Orden IM ' |+ _idcuenta;
    linea   := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(_im_eco_c,'999,999,999.99');
    RETURN NEXT linea;
    _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'im_eco',variante_conta);
    linea   := ' Cta.  Orden IM ' |+ _idcuenta;
    linea   := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(_im_eco_c,'999,999,999.99');
    RETURN NEXT linea;
  END IF;
   
  -----------------------------------------------
  -- Afectacion de cuentas de orden IM ECO
  -----------------------------------------------
  -- (1) Transferir es saldo del capital al producto tipo DEUDOR DIVERSO, el cual
  -- debería estar apuntando a una cuenta de orden
  IF (contabiliza_im_bal) THEN
    _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'iodnc_eco_ca',variante_conta);
    linea     := ' Cta. Orden IM ECO  ' |+ _idcuenta::TEXT;
    linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_im_eco_c),0),'999,999,999.99');
    RETURN NEXT linea;
    _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,'iodnc_eco_ab',variante_conta);
    linea     := ' Cta. Orden IM ECO  ' |+ _idcuenta::TEXT;
    linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((_im_eco_c),0),'999,999,999.99');
    RETURN NEXT linea;
  END IF;
  -- -----------------------------------------------------------------
  -- Cancelación de IVA, según sea método 1 o 2
  -- -----------------------------------------------------------------
  
  IF (contabiliza_iva_metodo = 1) THEN
    -- Cancelamos el IVA ya que no es un ingreso real de Ordinario
    IF (rdesg_c.IO_impuesto > 0) THEN
      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   'io_impuesto',variante_conta);
      linea     := ' Cta. IVA IO  ' |+ _idcuenta::TEXT;
      linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IO_impuesto),0),'999,999,999.99');
      RETURN NEXT linea;
      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   'iodnc_impuesto',variante_conta);
      linea     := ' Cta. Dev. IVA IO  ' |+ _idcuenta::TEXT;
      linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IO_impuesto),0),'999,999,999.99');
      RETURN NEXT linea;
    END IF;
    
    IF (contabiliza_im_bal) THEN
      IF (rdesg_c.IM_impuesto > 0) THEN
        -- Cancelamos el IVA ya que no es un ingreso real de Moratorio
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'im_impuesto',variante_conta);
        linea     := ' Cta. IVA IM  ' |+ _idcuenta::TEXT;
        linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IM_impuesto),0),'999,999,999.99');
        RETURN NEXT linea;
         
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                        'imdnc_impuesto',variante_conta);
        linea     := ' Cta. Dev. IVA IM  ' |+ _idcuenta::TEXT;
        linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IM_impuesto),0),'999,999,999.99');
        RETURN NEXT linea;
      END IF;
    END IF;
  ELSE
  
    --
    -- Metodo 2 de IVA basado en cuentas de orden.
    --
    IF (rdesg_c.IO_impuesto>0) THEN
      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   'io_impuesto_eco_acreedor',variante_conta);
      linea     := ' Cta. IVA Eco acreedor IO  ' |+ _idcuenta::TEXT;
      linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IO_impuesto),0),'999,999,999.99');
      RETURN NEXT linea;
      
      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                  'io_impuesto_eco_deudor',variante_conta);
      linea     := ' Cta. IVA Eco deudor IO  ' |+ _idcuenta::TEXT;
      linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IO_impuesto),0),'999,999,999.99');
      RETURN NEXT linea;
    END IF;
   
    IF contabiliza_im_bal THEN
      -- Cancelamos el IVA ya que no es un ingreso real de Moratorio
      IF (rdesg_c.IM_impuesto>0) THEN
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                    'im_impuesto_eco_acreedor',variante_conta);
        linea     := ' Cta. IVA Eco acreedor IM  ' |+ _idcuenta::TEXT;
        linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IM_impuesto),0),'999,999,999.99');
        RETURN NEXT linea;
         
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                  'im_impuesto_eco_deudor',variante_conta);
        linea     := ' Cta. IVA Eco deudor IM  ' |+ _idcuenta::TEXT;
        linea     := of_rellena(linea,50,' ',1) |+ ':' |+ to_char(numeric_larger((rdesg_c.IM_impuesto),0),'999,999,999.99');
        RETURN NEXT linea;
      END IF;
    END IF;
    
  END IF;
--------------------------------------------------------------------------------------------------------
     
  linea := ' '; RETURN NEXT linea;
  linea := ' POLIZA CONTABLE'; RETURN NEXT linea ;
  linea := '------------------------------'; RETURN NEXT linea;
       
  IF (p_afectar) THEN
    IF (arr_pol_clasifica IS NOT NULL) THEN
      UPDATE polizas
         SET concepto = 'Clasifica crédito para Condonación aux '||p_idsucaux||'-'||p_idproducto||'-'||p_idauxiliar
       WHERE (idsucpol, periodo, tipopol, idpoliza) =
             (arr_pol_clasifica[1]::INTEGER, arr_pol_clasifica[2]::INTEGER, arr_pol_clasifica[3]::INTEGER,
              arr_pol_clasifica[4]::INTEGER);
      poliza := arr_pol_clasifica[1] |+ '-' |+
                arr_pol_clasifica[2] |+ '-' |+
                arr_pol_clasifica[3] |+ '-' |+
                arr_pol_clasifica[4];
      linea := '** La póliza para Clasificar crédito para Condonación FUE APLICADA ' |+ poliza;
      RETURN NEXT linea;
      DELETE FROM temporal WHERE (idusuario,sesion)=(current_user,pg_backend_pid()::TEXT);
    ELSE
      DELETE FROM temporal WHERE (idusuario,sesion)=(current_user,pg_backend_pid()::TEXT);
      linea := '** ERROR *** La póliza para Clasificar crédito para Condonación NO FUE APLICADA ';
      RETURN NEXT linea;
    END IF;
    linea := '-----------------------------------------------------------------------------------------------------';
    RETURN NEXT linea;
    linea := '       Cuenta                    Nombre                                  Debe            Haber';
    RETURN NEXT linea;
    linea := '------------------------------------------------------------------------------------------------------';
    RETURN NEXT linea;
    FOR rp IN SELECT *
                FROM of_forma_base_poliza_detalle(arr_pol_clasifica[1]::INTEGER,arr_pol_clasifica[2]::INTEGER,
                                                  arr_pol_clasifica[3]::INTEGER,arr_pol_clasifica[4]::INTEGER)
    LOOP
      linea := of_rellena(rp.idcuenta,30,' ',1) |+
                 of_rellena(SUBSTRING(rp.nombre,1,50),50,' ',1) |+
                 of_rellena(rp.debe,20,' ',1) |+
                 of_rellena(rp.haber,20,' ',1);
      RETURN NEXT linea;
    END LOOP;
    linea := '------------------------------------------------------------------------------------------------------';
    RETURN NEXT linea;
       

    --***/
    --
    --                 AFECTACIONES PARA EL AUXILIAR
    --
    --
    -- Afectacion directa de cuenta contable de Reservas, dependiendo del
    -- estatus del crédito.
    --
    IF (rd.estatuscartera=3) THEN
      --
      -- Afectación de reservas en el caso de que el crédito está VENCIDO
      --
      -- En este caso, se asume que el 100% de la reserva en "reservacapital"
      -- pertenece al capital quebrantado, ya que la reserva de IO, y en su caso, de IM,
      -- deberan estar creadas al 100% segun criterio de <90 días. Bajo esta idea
      -- se carga a la reserva "activa" de interés el 100% del IO e IM, y se carga a la reserva
      -- "activa" de capital el 100% del monto del crédito, y este es el único monto
      -- que se evaluará para determinar si falta reserva, o en extraños casos, sobra reserva.
      -- Ya que la reserva que corresponde a IO o IM deberá estar al 100% por estar vencido el credito.

      IF (_metodo_condonacion=2) THEN
        _idcuenta := _ccc_iodev;
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                     ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - EPRC Vs IO Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
        
        IF (contabiliza_im_bal) THEN
          -- En caso de que se condone moratorio
          _idcuenta := _ccc_imdev;
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - EPRC Vs IM Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
        END IF;
      ELSIF (_metodo_condonacion=1) THEN 
        _idcuenta := _ccc_iodev;
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                     ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - Ingresos Vs IO Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                     ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - INGERSO EPRC Vs EPRC IO Venc', _ccc_io_eprc_act, NULL, _fecha_oper::DATE, NULL);
        
        IF (contabiliza_im_bal) THEN
          -- En caso de que se condone moratorio
          _idcuenta := _ccc_imdev;
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - Ingresos Vs IM Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - INGERSO EPRC Vs EPRC IM Venc', _ccc_im_eprc_act, NULL, _fecha_oper::DATE, NULL);
        END IF;
      ELSE
        _idcuenta := _ccc_iodev;
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                     ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - Fondos Vs IO Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                     ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - INGERSO EPRC Vs EPRC IO Venc', _ccc_io_eprc_act, NULL, _fecha_oper::DATE, NULL);
         
        IF (contabiliza_im_bal) THEN
          -- En caso de que se condone moratorio
          _idcuenta := _ccc_imdev;
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - Fondos Vs IM Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - INGERSO EPRC Vs EPRC IM Venc', _ccc_im_eprc_act, NULL, _fecha_oper::DATE, NULL);
        END IF;
      END IF;
       
      --
      -- Se revierte los importes de los intereses de mas de 90 días
      -- registrados en cuentas de orden.
      
      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'iodnc_eco_ca',variante_conta);
      IF (_io_eco_c<>0) THEN
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es entrada?
                                     ROUND((_io_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - IOECO Ca', _idcuenta, NULL, _fecha_oper::DATE, NULL);
       
          _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                         'iodnc_eco_ab',variante_conta);
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_io_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - IOECO Ab', _idcuenta, NULL, _fecha_oper::DATE, NULL);
      END IF;
       
      IF (contabiliza_im_bal AND _im_eco_c<>0) THEN
        
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'imdnc_eco_ca',variante_conta);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                     ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - IMECO Ca', _idcuenta, NULL, _fecha_oper::DATE, NULL);
             
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'imdnc_eco_ab',variante_conta);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                     ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - IMECO Ab', _idcuenta, NULL, _fecha_oper::DATE, NULL);
      ELSIF (contabiliza_im AND _im_eco_c <> 0) THEN
        -- Se revierte los importes de los intereses moratorios de mas de 90 días
        -- registrados en cuentas de orden.
        
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'imdnc_eco',variante_conta);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                     ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - IMECO Ca', _idcuenta, NULL, _fecha_oper::DATE, NULL);
        -- IRM 29/12/2016 Se comentariza para no generar los impuestos duplicados
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'im_eco',variante_conta);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                     ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - IMECO Ab', _idcuenta, NULL, _fecha_oper::DATE, NULL);
      END IF;
    ELSE
      --
      -- Afectación de reservas en el caso de que el crédito está VIGENTE
      --
      -- Para este caso, se tiene que considerr que lo quebrantable es el monto de Capital
      -- mas los intereses devengados menores a 90 días, se evalua si la reserva existente
      -- puede cubrir esta suma, o en su caso, que la reserva exceda esta suma, ambas cosas
      -- implican un ajuste a la reserva.

      _paso_q := P_CoIO+of_si(contabiliza_im_bal,P_CoIM,0); --((_io_q - rdesg.IO_impuesto) +
                 -- of_si(contabiliza_im_bal,(_im_q - rdesg.IM_impuesto),0));

      IF (_metodo_condonacion=2) THEN --Si el metodo es por reservas
          --LAPR se incrementará la reserva en 100% al interes por condonar.
          --debería ajustarse la estimación en el siguiente movimiento de contabilizacion en proporcion del restante
            
          _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                       'reserva_cap_result',variante_conta);
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND(_paso_q,2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación -Incremento de reserva', _idcuenta, NULL, _fecha_oper::DATE, NULL);
           
          _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                       'reserva_cap_activo',variante_conta);
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                       ROUND(_paso_q,2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - Incremento de reserva', _idcuenta, NULL, _fecha_oper::DATE, NULL);
    
    
          -- ¿ Hay mas reserva que Capital ?
          --LAPR Lo comentarizamos ya que no se liquidara el credito sera una movimiento parcial
          --     debería ajustarse la estimación en el siguiente movimiento contabilizacion
          --IF rd.reservacapital >  _paso_q THEN
          --  -- Regresamos la reserva que está de mas al gasto.
          --  -- Esto realmente es raro que suceda, pero si es posible, así
          --  -- que lo consideramos.
          --  
          --  _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
          --               'reserva_cap_result',variante_conta);
          --  SELECT INTO rins *
          --    FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
          --                               _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
          --                               ROUND((rd.reservacapital - _paso_q),2), 0.00, 0.00, 0.00, 0.00, 0.00,
          --                               FALSE, 'Condonación - Retorno Rva a Gto', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          --  _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
          --               'reserva_cap_activo',variante_conta);
          --  SELECT INTO rins *
          --    FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
          --                               _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
          --                               ROUND((rd.reservacapital - _paso_q),2), 0.00, 0.00, 0.00, 0.00, 0.00,
          --                               FALSE, 'Condonación - Retorno Rva a Gto', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          --END IF;
    
          --
          -- En este punto se presume que se tiene los montos necesarios en reservas
          -- para cubrir los importes a quebrantar, lo siguiente es hacer cargos a las
          -- cuentas contables de reservas para cubrir los abonos del préstamo.
    
          _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                       'reserva_cap_activo',variante_conta);
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                       ROUND((_paso_q),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - Pago desde reserva', _idcuenta, NULL, _fecha_oper::DATE, NULL);
      ELSIF (_metodo_condonacion = 1) THEN 
          _idcuenta := _ccc_iodev;
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                       ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - Ingresos Vs IO Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          
          IF (contabiliza_im_bal) THEN
            -- En caso de que se condone moratorio
            _idcuenta := _ccc_imdev;
            SELECT INTO rins *
              FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                         _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                         ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                         FALSE, 'Condonación - Ingresos Vs IM Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          ELSIF (contabiliza_im AND _im_eco_c <> 0) THEN 
            --LAPR Se descomentariza y se agrega condición para solo registrar si hay imeco, 
            -- en este caso el im siempre es eco, aunque esté vigente
            -- Se revierte los importes de los intereses moratorios
            -- registrados en cuentas de orden.
            
            _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                         'imdnc_eco',variante_conta);
            SELECT INTO rins *
              FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                         _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                         ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                         FALSE, 'Condonación - IMECO Ca', _idcuenta, NULL, _fecha_oper::DATE, NULL);
            -- IRM 29/12/2016 Se comentariza para no generar los impuestos duplicados
            _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                         'im_eco',variante_conta);
            SELECT INTO rins *
              FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                         _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                         ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                         FALSE, 'Condonación - IMECO Ab', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          END IF;
      ELSE
          _idcuenta := _ccc_iodev;
          SELECT INTO rins *
            FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                       _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es entrada?
                                       ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                       FALSE, 'Condonación - Fondos Vs IO Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
           
          IF (contabiliza_im_bal) THEN
            -- En caso de que se condone moratorio
            _idcuenta := _ccc_imdev;
            SELECT INTO rins *
              FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                         _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                         ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                         FALSE, 'Condonación - Fondos Vs IM Venc', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          ELSIF (contabiliza_im AND _im_eco_c <> 0) THEN 
            --LAPR Se descomentariza y se agrega condición para solo registrar si hay imeco, 
            -- en este caso el im siempre es eco, aunque esté vigente
            -- Se revierte los importes de los intereses moratorios
            -- registrados en cuentas de orden.
            
            _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                         'imdnc_eco',variante_conta);
            SELECT INTO rins *
              FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                         _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                         ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                         FALSE, 'Condonación - IMECO Ca', _idcuenta, NULL, _fecha_oper::DATE, NULL);
            -- IRM 29/12/2016 Se comentariza para no generar los impuestos duplicados
            _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                         'im_eco',variante_conta);
            SELECT INTO rins *
              FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                         _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                         ROUND((_im_eco_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                         FALSE, 'Condonación - IMECO Ab', _idcuenta, NULL, _fecha_oper::DATE, NULL);
          END IF;
      END IF;
    END IF;

    _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                 of_si(rd.estatuscartera=3,'iodnc_venc','iodnc'),variante_conta);

    SELECT INTO rins *
      FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                 _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                 ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                 FALSE, 'Condonación - IO Dev', _idcuenta, NULL, _fecha_oper::DATE, NULL);
    IF (_metodo_condonacion=1 AND rd.estatuscartera=3) THEN
      SELECT INTO rins *
        FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                   _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                   ROUND((_io_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                   FALSE, 'Condonación - INGERSO EPRC Vs EPRC IO Venc', _ccc_io_eprc_res, NULL, _fecha_oper::DATE, NULL);
    END IF;

    IF (contabiliza_im_bal) THEN
      --
      -- Afectacion directa de cuenta contable de Interés Moratorio Devengado.
      --
      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   of_si(rd.estatuscartera=3,'imdnc_venc','imdnc'),variante_conta);

      SELECT INTO rins *
        FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                   _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                   ROUND((_im_c),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                   FALSE, 'Condonación - IM Dev.', _idcuenta, NULL, _fecha_oper::DATE, NULL);
    END IF;

    -- -----------------------------------------------------------------
    -- Cancelación de IVA, según sea método 1 o 2
    -- -----------------------------------------------------------------
    IF (contabiliza_iva_metodo = 1) THEN
      -- Cancelamos el IVA ya que no es un ingreso real de Ordinario

      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   'io_impuesto',variante_conta);
      SELECT INTO rins *
        FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                   _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                   ROUND((rdesg_c.IO_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                   FALSE, 'Condonación - XIVA T1', _idcuenta, NULL, _fecha_oper::DATE, NULL);

      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   'iodnc_impuesto',variante_conta);
      SELECT INTO rins *
        FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                   _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                   ROUND((rdesg_c.IO_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                   FALSE, 'Condonación - XIVA T1', _idcuenta, NULL, _fecha_oper::DATE, NULL);

      IF (contabiliza_im_bal) THEN
        -- Cancelamos el IVA ya que no es un ingreso real de Moratorio
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                     'im_impuesto',variante_conta);
        SELECT INTO rins *
          FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                     ROUND((rdesg_c.IM_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - XIVA Mor T1', _idcuenta, NULL, _fecha_oper::DATE, NULL);

         _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                      'imdnc_impuesto',variante_conta);
         SELECT INTO rins * 
           FROM of_vent_ins_temporal(current_user::varchar,pg_backend_pid()::TEXT,
                                     _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
                                     ROUND((rdesg_c.IM_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                     FALSE, 'Condonación - XIVA Mor T1', _idcuenta, NULL, _fecha_oper::DATE, NULL);
      END IF;
    ELSE

      --
      -- Metodo 2 de IVA basado en cuentas de orden.
      --

      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                   'io_impuesto_eco_acreedor',variante_conta);
      SELECT INTO rins *
        FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                   _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
                                   ROUND((rdesg_c.IO_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                   FALSE, 'Condonación - XIVA T2', _idcuenta, NULL, _fecha_oper::DATE, NULL);

      _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                  'io_impuesto_eco_deudor',variante_conta);
      SELECT INTO rins *
        FROM of_vent_ins_temporal (current_user::varchar,pg_backend_pid()::TEXT,
                                   _suctrabajo, -1, NULL,NULL, NULL, NULL, TRUE, --es estrada?
                                   ROUND((rdesg_c.IO_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
                                   FALSE, 'Condonación - XIVA T2', _idcuenta, NULL, _fecha_oper::DATE, NULL);

      IF (contabiliza_im_bal) THEN
        -- Cancelamos el IVA ya que no es un ingreso real de Moratorio
        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                    'im_impuesto_eco_acreedor',variante_conta);
        SELECT INTO rins * 
          FROM of_vent_ins_temporal(current_user::varchar,pg_backend_pid()::TEXT,
               _suctrabajo, -1, NULL, NULL, NULL, NULL, FALSE, --es estrada?
               ROUND((rdesg_c.IM_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
               FALSE, 'Condonación - XIVA Mor T2', _idcuenta, NULL, _fecha_oper::DATE, NULL);

        _idcuenta := of_get_cuenta_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,
                  'im_impuesto_eco_deudor',variante_conta);
        SELECT INTO rins * 
          FROM of_vent_ins_temporal(current_user::varchar,pg_backend_pid()::TEXT,
               _suctrabajo, -1, NULL, NULL, NULL, NULL, TRUE, --es estrada?
               ROUND((rdesg_c.IM_impuesto),2), 0.00, 0.00, 0.00, 0.00, 0.00,
               FALSE, 'Condonación - XIVA Mor T2', _idcuenta, NULL, _fecha_oper::DATE, NULL);
      END IF;

    END IF;

    -- Aplicar la pólizas
    SELECT INTO arr_pol_quebranto
                of_temporal_apply(current_user::varchar, pg_backend_pid()::varchar, _suctrabajo, _fecha_oper, 3, FALSE, TRUE, NULL);
    -- Limpiamos tabla de tablas
    DELETE FROM tablas WHERE (idtabla,idelemento)=('user_' || trim(current_user::varchar),'tp3');

    IF (arr_pol_quebranto IS NOT NULL) THEN
      UPDATE polizas
         SET concepto = 'Condonación de crédito' ||p_idsucaux||'-'||p_idproducto||'-'||p_idauxiliar
       WHERE (idsucpol, periodo, tipopol, idpoliza) =
             (arr_pol_quebranto[1]::INTEGER, arr_pol_quebranto[2]::INTEGER, arr_pol_quebranto[3]::INTEGER,
              arr_pol_quebranto[4]::INTEGER);
      poliza := arr_pol_quebranto[1] |+ '-' |+
                arr_pol_quebranto[2] |+ '-' |+
                arr_pol_quebranto[3] |+ '-' |+
                arr_pol_quebranto[4];
      linea := '** La póliza para Condonación FUE APLICADA ' |+ poliza;
      -- raise notice '% ', linea;
      RETURN NEXT linea;
    ELSE
      linea := '** ERROR *** La póliza para Condonación NO FUE APLICADA ';
      -- raise notice '% ', linea;
      RETURN NEXT linea;
    END IF;

    SELECT INTO tdebe, thaber SUM(debe), SUM(haber)
           FROM detalle_polizas
          WHERE (idsucpol, periodo, tipopol, idpoliza)=
                (arr_pol_quebranto[1]::INTEGER, arr_pol_quebranto[2]::INTEGER, arr_pol_quebranto[3]::INTEGER,
                 arr_pol_quebranto[4]::INTEGER);
    -- raise notice '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   ......... %, %, %', tdebe, thaber, poliza;

    IF tdebe <> thaber or tdebe <= 0 or thaber <= 0 THEN
      --RAISE EXCEPTION 'ERROR: LA PÓLIZA DE CONDONACION TIENE ERORRES: LA CONDONACION FUE REVERTIDA. REPORTAR ERROR A SOPORTE SINC';
    END IF;

    linea := '-----------------------------------------------------------------------------------------------------';
    RETURN NEXT linea;
    linea := '       Cuenta                    Nombre                                  Debe            Haber';
    RETURN NEXT linea;
    linea := '------------------------------------------------------------------------------------------------------';
    RETURN NEXT linea;
    FOR rp IN SELECT *
                FROM of_forma_base_poliza_detalle(arr_pol_quebranto[1]::INTEGER,arr_pol_quebranto[2]::INTEGER,
                                                  arr_pol_quebranto[3]::INTEGER,arr_pol_quebranto[4]::INTEGER) LOOP
      linea := of_rellena(rp.idcuenta,30,' ',1) |+
                 of_rellena(SUBSTRING(rp.nombre,1,50),50,' ',1) |+
                 of_rellena(rp.debe,20,' ',1) |+
                 of_rellena(rp.haber,20,' ',1);
      RETURN NEXT linea;
    END LOOP;

    linea := ' ';
    RETURN NEXT linea;
    RETURN NEXT linea;
    -- raise notice '-------P_CoIO %<=0 AND %>0',P_CoIO,P_CoIM;
    IF (arr_pol_quebranto IS NOT NULL) THEN
      SELECT INTO _maxidpago max(idpago)
        FROM planpago
       WHERE(idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar) AND vence<_fecha_oper;
       --raise notice '------------fecha %-----------_amxid %',_fecha_oper,_maxidpago;
       --
      _maxidpago := CASE WHEN COALESCE(_maxidpago,0)=rd.plazo THEN rd.plazo 
                         ELSE COALESCE(_maxidpago,0)+of_si(_so_ab_venc,0,1) END;
       --raise notice '-----------------------_amxid %',_maxidpago;
      --
      _data:='{}';
      SELECT INTO rd2 * FROM deudores WHERE (idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar);
      --Registrando datos del io para la bitacora
      _data := _data+'io_c'+_io_c::TEXT+'ioeco_c'+_io_eco_c::TEXT+'iopend_ant'+rd2.iopend::TEXT+'ioeco_ant'+rd2.ioeco::TEXT;
      --Registrando datos del im para la bitacora
      _data := CASE WHEN (contabiliza_im_bal OR contabiliza_im) THEN _data + 'im_c'+_im_c::TEXT+'imeco_c'+_im_eco_c::TEXT
                    ELSE _data +'im_c'+P_CoIM::TEXT END;
      _data := _data + 'impend_ant' + rd2.impend::TEXT +'imeco_ant'+ rd2.imeco::TEXT;
      --Registrando detalles generales de la condonacion
      _data := _data + 'poliza' + poliza + 'fecha_oper' + _fecha_oper::TEXT + 'fecha_real' + (now()::DATE)::TEXT+
               'contabiliza_im'+COALESCE(contabiliza_im::TEXT,'false')+'contabiliza_im_bal'+COALESCE(contabiliza_im_bal::TEXT,'false')+
               'metodo_condonacion'+_metodo_condonacion::TEXT+'cc_condonar_io'+_ccc_iodev+'cc_condonar_im'+COALESCE(_ccc_imdev,'N/A')+
               'usuario'+current_user::TEXT;
      --
      --
  --  LAPR: 05/06/2016 Ajustes para evitar inconsistencias en plan de pago, en especial cambio de float4small por of_si
      PERFORM of_log_insert_data_key('condonacion',now()::DATE,NULL,'-',_data,p_idsucaux||'-'||p_idproducto||'-'||p_idauxiliar);
      UPDATE planpago
         SET iopagado = io,
             pagadoio = _fecha_oper
       WHERE (idsucaux,idproducto,idauxiliar) =
             (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago<=_maxidpago AND
             (io <> iopagado OR iopagado IS NULL);
      --
      UPDATE deudores
         SET iopend         = of_si(iopend-_io_c-_io_eco_c>0.00,iopend-_io_c-_io_eco_c,0.00),
             ioeco          = of_si(ioeco-_io_eco_c>0.00,ioeco-_io_eco_c,0.00),
             imppend        = of_si((iopend-_io_c-_io_eco_c)>0.00,(iopend-_io_c-_io_eco_c),0.00)*factor_iva_io
       WHERE (idsucaux,idproducto,idauxiliar) =
            (p_idsucaux,p_idproducto,p_idauxiliar);
      --
      --_iopend :=of_si(_iopend-_io_c-_io_eco_c>0.00,iopend-_io_c-_io_eco_c,0.00);
      --
      --LAPR: 05/06/2016 Distribuyendo iopend en el plan de pago
      SELECT INTO _iopend iopend 
        FROM deudores 
       WHERE (idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar);
      --raise notice '----------------iopend %, idmax %',_iopend,_maxidpago;
      IF (_iopend>0) THEN
          FOR _pp IN SELECT * 
                       FROM planpago 
                      WHERE (idsucaux,idproducto,idauxiliar) =(p_idsucaux,p_idproducto,p_idauxiliar)
                            AND idpago<=_maxidpago 
                      ORDER BY idpago DESC  LOOP
              --raise notice '--------------id %--iopend %, io %',_pp.idpago,_iopend,_pp.io;
              IF (_iopend-_pp.io>0) THEN
                  UPDATE planpago
                     SET iopagado = 0,
                         pagadoio = NULL
                   WHERE (idsucaux,idproducto,idauxiliar) =
                         (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago=_pp.idpago;
                  _iopend := _iopend-_pp.io;
              ELSE
                  --IF (_iopend>0) THEN
                      UPDATE planpago
                         SET iopagado = _pp.io-_iopend,
                             pagadoio = CASE WHEN (_pp.io-_iopend)=0 THEN _fecha_oper
                                             ELSE NULL END
                       WHERE (idsucaux,idproducto,idauxiliar) =
                             (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago=_pp.idpago;
                      _iopend := 0;
                  --END IF;
              END IF;
          END LOOP;
      END IF;
        --
        --
        UPDATE planpago
           SET impagado = im
         WHERE (idsucaux,idproducto,idauxiliar) =
               (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago<=_maxidpago AND
               (im <> impagado OR impagado IS NULL);
      --
      IF contabiliza_im_bal THEN -- Esto se hace para no comprmeter la actualización
                                 -- a los demas clientes que ocupan esta funcion.
        UPDATE deudores
           SET impend         = of_si(impend-_im_c-_im_eco_c>0.00,impend-_im_c-_im_eco_c,0),
               impmorpend        = of_si((impend-_im_c-_im_eco_c)>0.00,(impend-_im_c-_im_eco_c),0.00)*factor_iva_io,
               imeco          = of_si(imeco-_im_eco_c>0.00,imeco-_im_eco_c,0.00)
         WHERE (idsucaux,idproducto,idauxiliar) =
              (p_idsucaux,p_idproducto,p_idauxiliar);
      ELSIF (contabiliza_im) THEN
        UPDATE deudores
           SET impend         = of_si(impend-_im_c-_im_eco_c>0.00,impend-_im_c-_im_eco_c,0.00)
         WHERE (idsucaux,idproducto,idauxiliar) =
              (p_idsucaux,p_idproducto,p_idauxiliar);
      ELSE
        UPDATE deudores
           SET impend         = of_si(impend-P_CoIM>0.00,impend-P_CoIM,0.00)
         WHERE (idsucaux,idproducto,idauxiliar) =
              (p_idsucaux,p_idproducto,p_idauxiliar);
      END IF;
      --
      --_impend :=of_si(impend-_im_c-_im_eco_c>0.00,impend-_im_c-_im_eco_c,0);
      SELECT INTO _impend impend 
        FROM deudores 
       WHERE (idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar);
      --
      --LAPR: 05/06/2016 Distribuyendo impend en el plan de pago
      IF (_impend>0) THEN
          FOR _pp IN SELECT * 
                       FROM planpago 
                      WHERE (idsucaux,idproducto,idauxiliar) =(p_idsucaux,p_idproducto,p_idauxiliar)
                            AND idpago<=_maxidpago 
                      ORDER BY idpago DESC  LOOP
      --
              IF (_impend-_pp.im>0) THEN
                  UPDATE planpago
                     SET impagado = 0
                   WHERE (idsucaux,idproducto,idauxiliar) =
                         (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago=_pp.idpago;
                  _impend := _impend-_pp.im;
              ELSE
                  IF (_impend>0) THEN
                      UPDATE planpago
                         SET impagado = _pp.im-_impend
                       WHERE (idsucaux,idproducto,idauxiliar) =
                             (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago=_pp.idpago;
                      _impend := 0;
                  END IF;
              END IF;
          END LOOP;
      END IF;
    ELSIF (P_CoIO<=0 AND P_CoIM>0 AND NOT(contabiliza_im_bal OR contabiliza_im)) THEN
      SELECT INTO _maxidpago max(idpago)
        FROM planpago
       WHERE(idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar) AND vence<_fecha_oper;
       --raise notice '------------fecha %-----------_amxid %',_fecha_oper,_maxidpago;
       --
      _maxidpago := CASE WHEN COALESCE(_maxidpago,0)=rd.plazo THEN rd.plazo 
                         ELSE COALESCE(_maxidpago,0)+of_si(_so_ab_venc,0,1) END;
       --raise notice '-----------------------_amxid %',_maxidpago;
      --
      _data:='{}';
      SELECT INTO rd2 * FROM deudores WHERE (idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar);
      --Registrando datos del io para la bitacora
      _data := _data+'io_c'+_io_c::TEXT+'ioeco_c'+_io_eco_c::TEXT+'iopend_ant'+rd2.iopend::TEXT+'ioeco_ant'+rd2.ioeco::TEXT;
      --Registrando datos del im para la bitacora
      _data := CASE WHEN (contabiliza_im_bal OR contabiliza_im) THEN _data + 'im_c'+_im_c::TEXT+'imeco_c'+_im_eco_c::TEXT
                    ELSE _data +'im_c'+P_CoIM::TEXT END;
      _data := _data + 'impend_ant' + rd2.impend::TEXT +'imeco_ant'+ rd2.imeco::TEXT;
      --Registrando detalles generales de la condonacion
      _data := _data + 'poliza' + poliza + 'fecha_oper' + _fecha_oper::TEXT + 'fecha_real' + (now()::DATE)::TEXT+
               'contabiliza_im'+COALESCE(contabiliza_im::TEXT,'false')+'contabiliza_im_bal'+COALESCE(contabiliza_im_bal::TEXT,'false')+
               'metodo_condonacion'+_metodo_condonacion::TEXT+'cc_condonar_io'+_ccc_iodev+'cc_condonar_im'+COALESCE(_ccc_imdev,'N/A')+
               'usuario'+current_user::TEXT;
        --
        --
      UPDATE planpago
         SET impagado = im
       WHERE (idsucaux,idproducto,idauxiliar) =
             (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago<=_maxidpago AND
             (im <> impagado OR impagado IS NULL);
      --
      UPDATE deudores
         SET impend         = of_si(impend-P_CoIM>0.00,impend-P_CoIM,0.00)
       WHERE (idsucaux,idproducto,idauxiliar) =
            (p_idsucaux,p_idproducto,p_idauxiliar);
      --
      --_impend :=of_si(impend-_im_c-_im_eco_c>0.00,impend-_im_c-_im_eco_c,0);
      SELECT INTO _impend impend 
        FROM deudores 
       WHERE (idsucaux,idproducto,idauxiliar) = (p_idsucaux,p_idproducto,p_idauxiliar);
      --
      --LAPR: 05/06/2016 Distribuyendo impend en el plan de pago
      IF (_impend>0) THEN
          FOR _pp IN SELECT * 
                       FROM planpago 
                      WHERE (idsucaux,idproducto,idauxiliar) =(p_idsucaux,p_idproducto,p_idauxiliar)
                            AND idpago<=_maxidpago 
                      ORDER BY idpago DESC  LOOP
      --
              IF (_impend-_pp.im>0) THEN
                  UPDATE planpago
                     SET impagado = 0
                   WHERE (idsucaux,idproducto,idauxiliar) =
                         (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago=_pp.idpago;
                  _impend := _impend-_pp.im;
              ELSE
                  IF (_impend>0) THEN
                      UPDATE planpago
                         SET impagado = _pp.im-_impend
                       WHERE (idsucaux,idproducto,idauxiliar) =
                             (p_idsucaux,p_idproducto,p_idauxiliar) AND idpago=_pp.idpago;
                      _impend := 0;
                  END IF;
              END IF;
          END LOOP;
      END IF;
    END IF;
    --
    -- LAPR 24/06/2016 Afectacion del estado de cuenta del auxiliar.
    -- Tipo de movimiento=3 Condonacion
    IF (_expediente AND arr_pol_quebranto IS NOT NULL) THEN
      INSERT INTO detalle_auxiliar 
         (idsucaux,idproducto,idauxiliar, 
          idsucpol,periodo,tipopol,idpoliza,fecha,hora,
          cargo,abono,saldo,montoio,montoim,referencia,folio_ticket,tipomov)
       VALUES
         (rd.idsucaux,rd.idproducto,rd.idauxiliar,
          arr_pol_quebranto[1]::INTEGER,arr_pol_quebranto[2]::INTEGER,
          arr_pol_quebranto[3]::INTEGER,arr_pol_quebranto[4]::INTEGER,
          _fecha_oper, now()::time,
          0, 0, 0, (COALESCE(_io_c,0)+COALESCE(_io_eco_c,0)),
          (COALESCE(_im_c,0)+COALESCE(_im_eco_c,0)),'Condonación',-- IRM 29/12/2016 Se quita "of_si()" para siempre mostrar el detalle de los intereses moratorios.
          (SELECT folio_ticket 
             FROM detalle_cuentas 
            WHERE (idsucpol,periodo,tipopol,idpoliza)=
                  (arr_pol_quebranto[1]::INTEGER,arr_pol_quebranto[2]::INTEGER,
                   arr_pol_quebranto[3]::INTEGER,arr_pol_quebranto[4]::INTEGER) 
            LIMIT 1), 3);
    END IF;
    SELECT INTO rx *
           FROM deudores
          WHERE (idsucaux,idproducto,idauxiliar)=(p_idsucaux,p_idproducto,p_idauxiliar);
    PERFORM of_ofx_notice('info','La condonación fue realizada con exito');
  ELSE
    linea := '** La póliza NO FUE APLICADA ';
    RETURN NEXT linea;
  END IF;
    
  DELETE FROM temporal WHERE (idusuario,sesion)=(current_user,pg_backend_pid()::TEXT);
   
  RETURN;
END;$$
LANGUAGE plpgsql;

-- -------------------------------------------------------------------------------
--  LAPR 05/05/2016 
--  Funcion para realizar la cancelacion de una condonacion en base a un log
----------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION condonaciones___cancelacion (p_poliza TEXT) 
  RETURNS TEXT AS $$
DECLARE
   --Parámetros
   -- Variables
 r               RECORD;
 rd              RECORD;
 rdc             RECORD;
 _pp             RECORD;
 _arr_pol        TEXT[]:=string_to_array(p_poliza,'-');
 _log_tipo       INTEGER;
 _cred           TEXT[];
 _kpoliza        INTEGER;
 _maxidpago      INTEGER;
 _ultimomov      DATE;
BEGIN
  SELECT INTO _log_tipo id FROM oflog_tipo WHERE tipo='condonacion' LIMIT 1;

  --Nos aseguramos que la poliza sea una condonacion
  SELECT INTO r * FROM oflog WHERE id=_log_tipo AND trim(of_data_get(data,'poliza'))=trim(p_poliza);
  IF NOT FOUND THEN
      PERFORM of_ofx_notice('error','Error: La poliza no pertenece a una condonacion');
      RETURN 'error';
  END IF;

  --Revisamos que el prestamo exista
  _cred :=string_to_array(trim(r.key),'-');
   
  SELECT INTO rd * 
    FROM deudores 
   WHERE (idsucaux,idproducto,idauxiliar)=(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER);

  IF NOT FOUND THEN
      PERFORM of_ofx_notice('error','Error: El prestamo no existe');
      RETURN 'error';
  END IF;

  --Revisamos que sea el ultimo movimiento del crédito;
  SELECT INTO _ultimomov max(fecha) 
    FROM detalle_auxiliar 
   WHERE (idsucaux,idproducto,idauxiliar)=(rd.idsucaux,rd.idproducto,rd.idauxiliar);
  IF (_ultimomov>trim(of_data_get(r.data,'fecha_oper'))::DATE) THEN
          --OR rd.fechaultcalculo>trim(of_data_get(r.data,'fecha_oper'))::DATE) THEN
      PERFORM of_ofx_notice('error','Error: No es el ultimo movimiento del prestamo');
      RETURN 'error';
  END IF;

  --Determinar si fue el ultimo movimiento del prestamo en el día
  SELECT INTO _kpoliza kpoliza 
    FROM polizas 
   WHERE (idsucpol,periodo,tipopol,idpoliza)=(_arr_pol[1]::INTEGER,_arr_pol[2]::INTEGER,_arr_pol[3]::INTEGER,_arr_pol[4]::INTEGER);

  PERFORM * 
     FROM detalle_auxiliar AS da
     LEFT JOIN polizas AS p USING(idsucpol,periodo,tipopol,idpoliza)
    WHERE (idsucaux,idproducto,idauxiliar)=(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER)
          AND (idsucpol,periodo,tipopol,idpoliza)<>(_arr_pol[1]::INTEGER,_arr_pol[2]::INTEGER,_arr_pol[3]::INTEGER,_arr_pol[4]::INTEGER)
          AND da.fecha=trim(of_data_get(r.data,'fecha_oper'))::DATE AND (kpoliza>_kpoliza OR da.hora>r.hora_real);
  IF FOUND THEN
      PERFORM of_ofx_notice('error','Error: No es el ultimo movimiento del prestamo');
      RETURN 'error';
  END IF;

  FOR rdc IN SELECT * 
               FROM detalle_cuentas
              WHERE (idsucpol,periodo,tipopol,idpoliza)=(_arr_pol[1]::INTEGER,_arr_pol[2]::INTEGER,_arr_pol[3]::INTEGER,_arr_pol[4]::INTEGER)
                    AND referencia !~ '^cancela_mov' LOOP

      PERFORM of_canmov_cont (rdc.idcuenta,
                              p_poliza,
                              rdc.secuencia);
  END LOOP;

  --Recuperando valores antes de la condonación.
  UPDATE deudores SET iopend=iopend+of_numeric(trim(of_data_get(r.data,'io_c')))+of_numeric(trim(of_data_get(r.data,'ioeco_c'))),
                      ioeco =ioeco+of_numeric(trim(of_data_get(r.data,'ioeco_c'))),
                      impend =impend+of_numeric(trim(of_data_get(r.data,'im_c')))+of_numeric(trim(of_data_get(r.data,'imeco_c'))),
                      imeco =imeco+of_numeric(trim(of_data_get(r.data,'imeco_c'))),
                      estatus = 3
   WHERE (idsucaux,idproducto,idauxiliar)=(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER);
   
  SELECT INTO rd * 
    FROM deudores 
   WHERE (idsucaux,idproducto,idauxiliar)=(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER);

  --Recuperando el plan de pago
    SELECT INTO _maxidpago max(idpago)
      FROM planpago
     WHERE (idsucaux,idproducto,idauxiliar)=(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) 
           AND vence<trim(of_data_get(r.data,'fecha_oper'))::DATE;
     --raise notice '------------fecha %-----------_amxid %',_fecha_oper,_maxidpago;

    _maxidpago := CASE WHEN COALESCE(_maxidpago,0)=rd.plazo THEN rd.plazo 
                       ELSE COALESCE(_maxidpago,0)+1 END;

    UPDATE planpago
       SET iopagado = io,
           pagadoio = trim(of_data_get(r.data,'fecha_oper'))::DATE
     WHERE (idsucaux,idproducto,idauxiliar) =
           (_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) AND idpago<=_maxidpago AND
           (io <> iopagado OR iopagado IS NULL);

    IF (rd.iopend>0) THEN
        FOR _pp IN SELECT * 
                     FROM planpago 
                    WHERE (idsucaux,idproducto,idauxiliar) =(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) 
                          AND idpago<=_maxidpago  AND (pagadoio IS NULL OR pagadoio>=trim(of_data_get(r.data,'fecha_oper'))::DATE)
                    ORDER BY idpago DESC  LOOP
            --raise notice '--------------id %--iopend %, io %',_pp.idpago,_iopend,_pp.io;
            IF (rd.iopend-_pp.io>0) THEN
                UPDATE planpago
                   SET iopagado = 0,
                       pagadoio = NULL
                 WHERE (idsucaux,idproducto,idauxiliar) =
                       (_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER)  AND idpago=_pp.idpago;
                rd.iopend := rd.iopend-_pp.io;
            ELSE
                --IF (_iopend>0) THEN
                    UPDATE planpago
                       SET iopagado = _pp.io-rd.iopend,
                           pagadoio = CASE WHEN (_pp.io-rd.iopend)=0 THEN trim(of_data_get(r.data,'fecha_oper'))::DATE
                                           ELSE NULL END
                     WHERE (idsucaux,idproducto,idauxiliar) =
                           (_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) 
                           AND idpago=_pp.idpago;
                    rd.iopend := 0;
                --END IF;
            END IF;
        END LOOP;
    END IF;


    UPDATE planpago
       SET impagado = im
     WHERE (idsucaux,idproducto,idauxiliar) =
           (_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) AND idpago<=_maxidpago AND
           (im <> impagado OR impagado IS NULL);


    IF (rd.impend>0) THEN
        FOR _pp IN SELECT * 
                     FROM planpago 
                    WHERE (idsucaux,idproducto,idauxiliar) =(_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) 
                          AND idpago<=_maxidpago
                    ORDER BY idpago DESC  LOOP

            IF (rd.impend-_pp.im>0) THEN
                UPDATE planpago
                   SET impagado = 0
                 WHERE (idsucaux,idproducto,idauxiliar) =
                       (_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER)  AND idpago=_pp.idpago;
                rd.impend := rd.impend-_pp.im;
            ELSE
                IF (rd.impend>0) THEN
                    UPDATE planpago
                       SET impagado = _pp.im-rd.impend
                     WHERE (idsucaux,idproducto,idauxiliar) = (_cred[1]::INTEGER,_cred[2]::INTEGER,_cred[3]::INTEGER) 
                           AND idpago=_pp.idpago;
                    rd.impend := 0;
                END IF;
            END IF;
        END LOOP;
    END IF;

    --LAPR 27/06/2016 Borrando el registro del expediente
      PERFORM * 
         FROM detalle_auxiliar 
        WHERE (idsucpol,periodo,tipopol,idpoliza)=(_arr_pol[1]::INTEGER,_arr_pol[2]::INTEGER,_arr_pol[3]::INTEGER,_arr_pol[4]::INTEGER);
      IF FOUND THEN
          DELETE FROM detalle_auxiliar 
           WHERE (idsucpol,periodo,tipopol,idpoliza)=(_arr_pol[1]::INTEGER,_arr_pol[2]::INTEGER,_arr_pol[3]::INTEGER,_arr_pol[4]::INTEGER);
      END IF;
  
  RETURN 'ok';
END;$$
LANGUAGE plpgsql;


-- ------------------------------------------------------------------------------------------
-- LAPR 05/05/2016
-- Funcion para mostrar un detalle de las condoncaciones posibles a cancelar
-- ------------------------------------------------------------------------------------------
SELECT of_db_drop_type('ofx_polizas_condoncacion','CASCADE');
CREATE TYPE ofx_polizas_condoncacion AS (
    poliza         TEXT,
    auxiliar       TEXT,
    condonacion_io TEXT,
    condonacion_im TEXT,
    fecha_real     TEXT,
    cancelado      BOOLEAN
);

CREATE OR REPLACE FUNCTION ofx_polizas_condoncacion (p_defecha DATE,p_afecha DATE) 
  RETURNS SETOF ofx_polizas_condoncacion AS $$
DECLARE
   --Parámetros
   -- Variables
 t               ofx_polizas_condoncacion%ROWTYPE;
 r               RECORD;
 _filtro         BOOLEAN:=COALESCE(of_ofx_get('filtro'),'false')::BOOLEAN;
 _auxiliar       TEXT:=of_ofx_get('idsucaux')||'-'||of_ofx_get('idproducto')||'-'||of_ofx_get('idauxiliar');
 --_afecha         DATE:=of_ofx_get('afecha')::DATE;
 --_defecha        DATE:=of_ofx_get('defecha')::DATE;
BEGIN
  FOR r IN SELECT *,(SELECT referencia LIKE '%cancela_mov%' 
                       FROM detalle_cuentas 
                      WHERE (idsucpol,periodo,tipopol,idpoliza)=(
                            (string_to_array(poliza,'-'))[1]::INTEGER,
                            (string_to_array(poliza,'-'))[2]::INTEGER,
                            (string_to_array(poliza,'-'))[3]::INTEGER,
                            (string_to_array(poliza,'-'))[4]::INTEGER) LIMIT 1) AS cancelado 
            FROM (SELECT of_data_get(data,'poliza') AS poliza,key,
                        --LAPR 27/06/2016 Se suma el interes eco condonado ya que solo se mostraba el de balance
                         of_numeric(of_data_get(data,'io_c'))+of_numeric(of_data_get(data,'ioeco_c')) AS condonacion_io,
                         of_numeric(of_data_get(data,'im_c'))+of_numeric(of_data_get(data,'imeco_c')) AS condonacion_im,
                         fecha AS fecha_real
                    FROM oflog 
                   WHERE id=(SELECT id FROM oflog_tipo WHERE tipo='condonacion' AND trim(of_data_get(data,'poliza'))<>'(null)') --LAPR 05/05/2016 Evitando errores por polizas en blanco
                         AND (fecha BETWEEN p_defecha AND p_afecha)
                         AND ( (NOT _filtro) OR (_filtro AND key=_auxiliar) )) AS x 
           ORDER BY fecha_real::DATE,poliza LOOP

      t.poliza         :=r.poliza;
      t.auxiliar       :=r.key;
      t.condonacion_io :=r.condonacion_io;
      t.condonacion_im :=r.condonacion_im;
      t.fecha_real     :=r.fecha_real;
      t.cancelado      :=r.cancelado;
      RETURN NEXT t;
  END LOOP;
  RETURN ;
END;$$
LANGUAGE plpgsql;

-- --------------------------------------------------------------------------------
-- JCG ??/??/2016
-- Reporte de condonaciones
-- --------------------------------------------------------------------------------

SELECT of_db_drop_type('ofx_reporte_condonaciones','CASCADE');
CREATE TYPE ofx_reporte_condonaciones AS (
  key                 TEXT,
  poliza              TEXT,
  iopend_ant          TEXT,
  io_c                TEXT,
  im_c                TEXT,
  io_eco_c            TEXT,
  im_eco_c            TEXT,
  impend_ant          TEXT,
  contabiliza_im      TEXT,
  idusuario           TEXT,
  metodo_condonacion  TEXT,
  fecha_oper          TEXT
);
  
CREATE OR REPLACE FUNCTION ofx_reporte_condonaciones(p_defecha DATE,p_afecha DATE)
  RETURNS SETOF ofx_reporte_condonaciones AS $$
DECLARE
  r             RECORD;
  k             ofx_reporte_condonaciones%ROWTYPE;
  _filtro         BOOLEAN:=COALESCE(of_ofx_get('filtro'),'false')::BOOLEAN;
 _auxiliar       TEXT:=of_ofx_get('idsucaux')||'-'||of_ofx_get('idproducto')||'-'||of_ofx_get('idauxiliar');
BEGIN
  FOR r IN SELECT *,(SELECT referencia
                       FROM detalle_cuentas
                      WHERE (idsucpol,periodo,tipopol,idpoliza)=(
                            (string_to_array(poliza,'-'))[1]::INTEGER,
                            (string_to_array(poliza,'-'))[2]::INTEGER,
                            (string_to_array(poliza,'-'))[3]::INTEGER,
                            (string_to_array(poliza,'-'))[4]::INTEGER) LIMIT 1) AS cancelado 
            FROM (SELECT of_data_get(data,'contabiliza_im')     AS contabiliza_im,
                         of_data_get(data,'io_c')               AS condonacion_io,
                         of_data_get(data,'fecha_oper')         AS fecha_oper,
                         of_data_get(data,'iopend_ant')         AS iopend_ant,
                         of_data_get(data,'impend_ant')         AS impend_ant,
                         of_data_get(data,'metodo_condonacion') AS metodo_condonacion,
                         of_data_get(data,'poliza')             AS poliza,
                         of_data_get(data,'im_c')               AS im_c,
                         of_data_get(data,'io_c')               AS io_c,
                        --LAPR 27/06/2016 Se suma el interes eco condonado ya que solo se mostraba el de balance
                         of_data_get(data,'imeco_c')           AS im_eco_c,
                         of_data_get(data,'ioeco_c')           AS io_eco_c,
                         idusuario,fecha_real,key                    
                    FROM oflog 
                   WHERE id=(SELECT id FROM oflog_tipo WHERE tipo='condonacion')
                         AND (fecha BETWEEN p_defecha AND p_afecha) AND trim(of_data_get(data,'poliza'))<>'(null)' --LAPR 05/05/2016 Evitando errores por polizas en blanco
                         AND ( (NOT _filtro) OR (_filtro AND key=_auxiliar) )) AS x 
           ORDER BY fecha_real::DATE,poliza LOOP
      k.metodo_condonacion := CASE
                                WHEN r.metodo_condonacion = '1' THEN 'Cancelacion de ingreso'
                                WHEN r.metodo_condonacion = '2' THEN 'Uso de reservas'
                                WHEN r.metodo_condonacion = '3' THEN 'Personalizado'
                              END;
      k.contabiliza_im     := CASE 
                                WHEN NOT r.contabiliza_im::BOOLEAN THEN 'No'
                                WHEN r.contabiliza_im::BOOLEAN     THEN 'Si'
                              END;
      --LAPR 27/06/2016 Se suma el interes eco condonado ya que solo se mostraba el de balance
      k.io_c               :=of_numeric(r.io_c)+of_numeric(r.io_eco_c);
      k.fecha_oper         :=r.fecha_oper;
      k.iopend_ant         :=r.iopend_ant;
      k.impend_ant         :=r.impend_ant; 
      k.idusuario          :=r.idusuario;
      k.poliza             :=r.poliza;
      k.im_c               :=of_numeric(r.im_c)+of_numeric(r.im_eco_c);
      k.key                :=r.key;
      RETURN NEXT k;
  END LOOP;
END;$$
LANGUAGE plpgsql;
