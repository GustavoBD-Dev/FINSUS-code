-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_pp_monto_sugerido 
-- Plan de Pago Monto Sugerido
-- 25/01/2022

-- ----------------------------------------------------------------------------
-- 25/01/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'ofx_pp_monto_sugerido.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  _id    := _version |+ '.0';
  _desc  := 'Genera plan pago con pagos sugeridos';
  _fecha := '31/01/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  CREATE TABLE ofx_pagare_monto_sugerido_masivo_datos
  --    (idsucaux      INTEGER, 
  --     idproduco     INTEGER, 
  --     idauxiliar    INTEGER, 
  --     montosugerido NUMERIC, 
  --     montopagouno  NUMERIC);    
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/01/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  --f     DATE := ofpsd('global','fecha',now()::DATE);
  rd      RECORD;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  --IF (NOT of_ofx_check_version('1.14.1')) THEN
  --  RETURN FALSE;
  --END IF;
  
  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dum(f)::TEXT);
  PERFORM of_ofx_set('bt_ini','set=click');
  PERFORM of_ofx_set('eidsucaux','set='||of_ofx_get('idsucaux'));
  PERFORM of_ofx_set('eidproducto','set='||of_ofx_get('idproducto'));
  PERFORM of_ofx_set('eidauxiliar','set='||of_ofx_get('idauxiliar'));
  PERFORM of_ofx_set('bt_ini','set=click');
  PERFORM of_ofx_set('eidsucaux','sensitive=FALSE');
  PERFORM of_ofx_set('eidproducto','sensitive=FALSE');
  PERFORM of_ofx_set('eidauxiliar','sensitive=FALSE');
  PERFORM of_ofx_set('fc_archivo_o','sensitive=FALSE');
  UPDATE params
     SET valor = 'ofx_pagare_monto_sugerido'
   WHERE (idparam,idelemento)=('/formatos/ofx_pagare_monto_sugerido','fijos'); -- Masiva

  SELECT INTO rd * 
    FROM deudores 
   WHERE (idsucaux,idproducto,idauxiliar)=
         (of_ofx_get('idsucaux')::INTEGER,of_ofx_get('idproducto')::INTEGER,of_ofx_get('idauxiliar')::INTEGER);
  IF (FOUND) THEN
    PERFORM of_ofx_set('fr_exportar','sensitive=TRUE');
    PERFORM of_ofx_set('narchivo','sensitive=FALSE');
    PERFORM of_ofx_set('narchivo','set=pp_montosugerido_'||rd.idsucaux||'-'||rd.idproducto||'-'||rd.idauxiliar||'.csv');

    IF (of_iva_general(rd.idsucaux,rd.idproducto,rd.idauxiliar,rd.tipoprestamo,of_param_sesion_get('global','fecha')::DATE)) THEN    
      PERFORM of_param_sesion_set('ofx_pp_monto_sugerido','iva','TRUE');
    ELSE
      PERFORM of_param_sesion_set('ofx_pp_monto_sugerido','iva','FALSE');
    END IF;
    
    PERFORM of_ofx_set('e_montosolicitado','sensitive=FALSE');
    PERFORM of_ofx_set('e_plazo','sensitive=FALSE');
    PERFORM of_ofx_set('e_diasxplazo','sensitive=FALSE');
    PERFORM of_ofx_set('e_tasaio','sensitive=FALSE');
    --PERFORM of_ofx_set('e_fechapa','sensitive=FALSE');
    --PERFORM of_ofx_set('chk_mismodia','sensitive=FALSE');
    --PERFORM of_ofx_set('chk_fechapa','sensitive=FALSE');

    PERFORM of_ofx_set('e_montosolicitado','set='||rd.montosolicitado);
    PERFORM of_ofx_set('e_plazo','set='||rd.plazo);
    PERFORM of_ofx_set('e_diasxplazo','set='||rd.diasxplazo);
    PERFORM of_ofx_set('e_tasaio','set='||rd.tasaio);
    --PERFORM of_ofx_set('e_fechapa','set='||rd.fechaape);
    
    --IF (rd.fechaprimerabono IS NULL) THEN
  --PERFORM of_ofx_set('chk_fechapa','sensitive=FALSE');
    --END IF;

  END IF;
  --IF () THEN
  --  PERFORM of_ofx_set('e_montosolicitado','set=click');    
  --END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/01/2022 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/01/2022 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 
  IF (p_variable = 'e_diasxplazo') THEN 
    PERFORM of_ofx_set('e_fechapa','set='||of_laborable(p_valor::INTEGER+of_param_sesion_get('global','fecha')::DATE));
  END IF;
  
  IF (p_variable = 'chk_fechapa') THEN 
    IF (p_valor::BOOLEAN) THEN
      PERFORM of_ofx_set('e_fechapa','sensitive=TRUE');
    ELSE 
      PERFORM of_ofx_set('e_fechapa','sensitive=FALSE');
    END IF;
  END IF;

  IF (p_variable = 'chk_mismodia' OR p_variable='e_montosugerido') THEN 
    PERFORM of_ofx_set('bt_generar','set=click');
  END IF;

  IF (p_variable='chk_masivo') THEN
    IF (p_valor) THEN
      PERFORM of_ofx_set('bt_guardar_archivo','sensitive=FALSE');
      PERFORM of_ofx_set('bt_aceptar','sensitive=FALSE');
      PERFORM of_ofx_set('bt_gen_pdfs','sensitive=TRUE');
      PERFORM of_ofx_set('chk_masivo','sensitive=TRUE');
      PERFORM of_ofx_set('bt_guardarpp','sensitive=FALSE');
      PERFORM of_ofx_set('fc_archivo_o','sensitive=TRUE');
      UPDATE params
         SET valor = 'ofx_pagare_monto_sugerido_masiva'
       WHERE (idparam,idelemento)=('/formatos/ofx_pagare_monto_sugerido','fijos'); -- Masiva
    ELSE
      PERFORM of_ofx_set('bt_gen_pdfs','sensitive=FALSE');
      PERFORM of_ofx_set('bt_aceptar','sensitive=TRUE');
      PERFORM of_ofx_set('chk_masivo','sensitive=TRUE');   
      PERFORM of_ofx_set('bt_guardar_archivo','sensitive=TRUE'); 
      PERFORM of_ofx_set('bt_guardarpp','sensitive=TRUE');
      PERFORM of_ofx_set('fc_archivo_o','sensitive=FALSE');
      UPDATE params
         SET valor = 'ofx_pagare_monto_sugerido'
       WHERE (idparam,idelemento)=('/formatos/ofx_pagare_monto_sugerido','fijos'); -- Masiva
    END IF;
  END IF;

  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/01/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___on_click (p_button TEXT, p_data TEXT) 
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
  fname             TEXT:= 'vsr_vars_archivo';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --IF (p_button='bt_guardar_archivo') THEN
  --  PERFORM * FROM ofx_pp_monto_sugerido_pp_exp();
  --  IF (of_ofx_get('fc_archivo_o') IS NULL) THEN
  --    PERFORM of_ofx_notice('error', 'Error: Debe seleccionar un ruta para generar el archivo.');
  --    RETURN 0;
  --  END IF;
  --  IF (of_param_sesion_get('vsr_vars','linea') IS NOT NULL) THEN
  --    IF (length(trim(of_ofx_get('narchivo')))>1 OR trim(of_ofx_get('narchivo')) IS NOT NULL) THEN
  --      PERFORM of_param_sesion_set('ofx.file','ok','TRUE');
  --      PERFORM of_param_sesion_set('ofx.file','name',of_ofx_get('fc_archivo_o')||'/'||
  --                                                    of_ofx_get('narchivo'));
  --      PERFORM of_param_sesion_set('ofx.file','content',of_param_sesion_get('vsr_vars','linea'));
  --      --PERFORM of_param_sesion_raise(NULL);
  --      --PERFORM of_ofx_set('bt_generar','set=click');
  --    ELSE
  --      PERFORM of_ofx_notice('error','Error: Nombre inválido para el archivo');
  --    END IF;
  --  ELSE
  --    PERFORM of_ofx_notice('error','Error: No hay contenido por generar');
  --  END IF;
  --  PERFORM of_param_sesion_unset('vsr_vars','linea');
  --END IF;
IF (p_button='bt_guardarpp') THEN
  PERFORM * FROM ofx_pp_monto_sugerido_pp_ed();
  --IF (of_ofx_get('fc_archivo_o') IS NULL) THEN
  --  PERFORM of_ofx_notice('error', 'Error: Debe seleccionar un ruta para generar el archivo.');
  --  RETURN 0;
  --END IF;
  --IF (of_param_sesion_get('vsr_vars','linea') IS NOT NULL) THEN
  --  IF (length(trim(of_ofx_get('narchivo')))>1 OR trim(of_ofx_get('narchivo')) IS NOT NULL) THEN
  --    PERFORM of_param_sesion_set('ofx.file','ok','TRUE');
  --    PERFORM of_param_sesion_set('ofx.file','name',of_ofx_get('fc_archivo_o')||'/'||
  --                                                  of_ofx_get('narchivo'));
  --    PERFORM of_param_sesion_set('ofx.file','content',of_param_sesion_get('vsr_vars','linea'));
  --    --PERFORM of_param_sesion_raise(NULL);
  --    --PERFORM of_ofx_set('bt_generar','set=click');
  --  ELSE
  --    PERFORM of_ofx_notice('error','Error: Nombre inválido para el archivo');
  --  END IF;
  --ELSE
  --  PERFORM of_ofx_notice('error','Error: No hay contenido por generar');
  --END IF;
  --PERFORM of_param_sesion_unset('vsr_vars','linea');
END IF;  
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/01/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
--  RETURNS INTEGER AS $$
--DECLARE
--  -- Variables
--BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
--  --PERFORM of_ofx_notice('info','widget: '||p_widget||', path: '||p_path||', row_info:'||p_row_info::TEXT);
--  
--  --IF (p_widget = 'un_widget_x_tv') THEN
--  --  
--  --END IF;
--  RETURN 0;
--END;$$
--LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/01/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
--  RETURNS INTEGER AS $$
--DECLARE
--  -- Variables
--BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
--  --PERFORM of_ofx_notice('info','widget: '||p_widget||', path: '||p_path||', row_info:'||p_row_info::TEXT);
--  
--  --IF (p_widget = 'un_widget_x_tv') THEN
--  --  
--  --END IF;
--  RETURN 0;
--END;$$
--LANGUAGE plpgsql;

SELECT of_db_drop_type('ofx_pp_monto_sugerido_pp','CASCADE');
CREATE TYPE ofx_pp_monto_sugerido_pp AS (
  -- Plan de pago
  idpago            TEXT,
  vence             TEXT,
  dt                TEXT,
  abono             TEXT,
  interes           TEXT,
  iva               TEXT,
  saldo             TEXT,
  total             TEXT
);

SELECT of_db_drop_function('ofx_pp_monto_sugerido_pp',NULL,NULL);
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido_pp ()
  RETURNS SETOF ofx_pp_monto_sugerido_pp AS $$
DECLARE   
  -- Variables
  t         ofx_pp_monto_sugerido_pp%ROWTYPE;
  r         RECORD;

  p_monto          NUMERIC:=of_ofx_get('e_montosolicitado');
  p_tasa           NUMERIC:=of_ofx_get('e_tasaio');
  p_diasxtasa      INTEGER;
  p_iva            NUMERIC;
  p_idproducto     INTEGER:=of_ofx_get('idproducto');
  p_fecha          DATE:=of_param_sesion_get('global','fecha');
  p_plazo          INTEGER:=of_ofx_get('e_plazo');
  p_diasxplazo     INTEGER:=of_ofx_get('e_diasxplazo');
  p_fechapa        DATE:=of_ofx_get('e_fechapa');
  p_monto_sugerido NUMERIC:=of_ofx_get('e_montosugerido');
  _mismodia        BOOLEAN:=of_ofx_get('chk_mismodia');
  _iva             BOOLEAN:=of_param_sesion_get('ofx_pp_monto_sugerido','iva')::BOOLEAN;
  _piva            NUMERIC;
BEGIN
  IF (_iva) THEN
    _piva := ofpn('/socios/productos/prestamos','iva_io',0.00);
  ELSE
    _piva := 0.00;
  END IF;
  IF (NOT of_ofx_get('chk_fechapa')::BOOLEAN) THEN
    p_fechapa := NULL;
  END IF;

  IF (of_ofx_get('e_primerpagocap')::NUMERIC>0.00) THEN
    p_plazo := p_plazo ;
    --p_fechapa := of_laborable(of_ofx_get('e_diasxplazo')::INTEGER+of_param_sesion_get('global','fecha')::DATE);
    IF (p_fecha=of_fecha_dum(p_fecha)) THEN
      p_fechapa := of_fecha_dum((p_fecha::DATE+1));
      PERFORM of_param_sesion_set('of_vencimientos','vencimientos_nominales','TRUE');
    ELSE
      IF (_mismodia) THEN
        p_diasxplazo := p_diasxplazo * -1;
      END IF;            
      p_fechapa := p_fecha::DATE + interval '1 month';
    END IF;
    --p_fechapa := p_fecha::DATE + interval '1 month';
    t.idpago  := 1;
    t.vence   := p_fecha;
    t.dt      := 0;
    t.abono   := to_char(of_ofx_get('e_primerpagocap')::NUMERIC,'FM999,999,990.90');
    t.interes := '0.00';
    t.iva     := '0.00';
    t.saldo   := to_char(p_monto,'FM999,999,990.90');
    t.total   := to_char(of_ofx_get('e_primerpagocap')::NUMERIC,'FM999,999,990.90');
    p_monto := p_monto - of_ofx_get('e_primerpagocap')::NUMERIC;
    RETURN NEXT t;
  END IF;

  IF (p_fechapa=of_fecha_dum(p_fechapa) AND p_diasxplazo=30) THEN
    PERFORM of_param_sesion_set('of_vencimientos','vencimientos_nominales','TRUE');
  END IF;

  IF (_mismodia) THEN
    p_diasxplazo := p_diasxplazo * -1;
  END IF;  
  IF (p_fecha=of_fecha_dum(p_fecha) AND (NOT of_ofx_get('chk_fechapa')::BOOLEAN)) THEN
    --p_diasxplazo := p_diasxplazo * -1;
    p_fechapa := of_fecha_dum((p_fecha::DATE));
    PERFORM of_param_sesion_set('of_vencimientos','vencimientos_nominales','TRUE');
  END IF;
  --RAISE NOTICE 'p_monto %,p_tasa %,p_idproducto %,p_fecha %,p_plazo %,p_diasxplazo % ,p_fechapa % ,p_monto_sugerido %, IVA %',p_monto,p_tasa,p_idproducto,p_fecha,p_plazo,p_diasxplazo,p_fechapa,p_monto_sugerido,_piva;
  FOR r IN SELECT * 
             FROM of_plan_amortizacion_pf_monto_sugerido(p_monto,p_tasa,ofpi('/socios/productos/prestamos','dias por tasa',0)::INTEGER,_piva,p_idproducto,p_fecha,p_plazo,p_diasxplazo,p_fechapa,p_monto_sugerido) 
             ORDER BY idpago LOOP
    t.idpago  := of_si(of_ofx_get('e_primerpagocap')::NUMERIC>0.00,r.idpago+1,r.idpago);
    t.vence   := r.fecha;
    t.dt      := r.dt;
    t.abono   := to_char(r.abono,'FM999,999,990.90');
    t.interes := to_char(r.interes,'FM999,999,990.90');
    t.iva     := to_char(r.iva,'FM999,999,990.90');
    t.saldo   := to_char(r.saldo,'FM999,999,990.90');
    t.total   := to_char(r.total,'FM999,999,990.90');
    IF (r.abono=0.00) THEN
      PERFORM of_ofx_notice('error','Plazo máximo permitido: '||numeric_larger(r.idpago-1,0));
      --PERFORM of_ofx_notice('popup','Plazo máximo permitido: '||numeric_larger(r.idpago-1,0));
      PERFORM of_ofx_set('e_plazo','set='||numeric_larger(r.idpago-1,0));
      RETURN;
    END IF;
    RETURN NEXT t;
  END LOOP;
  --PERFORM of_param_sesion_raise(NULL);
  --PERFORM of_param_sesion_unset('ofx_pp_monto_sugerido','iva');
  IF (p_fecha=of_fecha_dum(p_fecha)) THEN
    PERFORM of_param_sesion_unset('of_vencimientos','vencimientos_nominales');
  END IF;
  RETURN;
END;$$
LANGUAGE plpgsql;

-- -----------------
-- -----------------
SELECT of_db_drop_type('ofx_pp_monto_sugerido_pp_exp','CASCADE');
CREATE TYPE ofx_pp_monto_sugerido_pp_exp AS (
  -- Plan de pago
  contenido TEXT
);

SELECT of_db_drop_function('ofx_pp_monto_sugerido_pp_exp',NULL,NULL);
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido_pp_exp()
  RETURNS SETOF ofx_pp_monto_sugerido_pp_exp AS $$
DECLARE   
  -- Variables
  t         ofx_pp_monto_sugerido_pp_exp%ROWTYPE;
  r         RECORD;
  _idpagof   INTEGER;
BEGIN
  SELECT INTO  _idpagof max(idpago::INTEGER) from ofx_pp_monto_sugerido_pp();
  _idpagof := COALESCE(_idpagof,0);
  t.contenido :=of_ofx_get('eidsucaux')||','||of_ofx_get('eidproducto')||','||of_ofx_get('eidauxiliar')||E'\n';

  DELETE FROM ofx_pp_monto_sugerido_planpago 
    WHERE (idsucaux,idproducto,idauxiliar)=(of_ofx_get('eidsucaux')::INTEGER,of_ofx_get('eidproducto')::INTEGER,of_ofx_get('eidauxiliar')::INTEGER);

  FOR r IN SELECT * 
             FROM ofx_pp_monto_sugerido_pp() ORDER BY idpago::INTEGER LOOP
      
      INSERT INTO ofx_pp_monto_sugerido_planpago 
          VALUES (of_ofx_get('eidsucaux')::INTEGER,of_ofx_get('eidproducto')::INTEGER,of_ofx_get('eidauxiliar')::INTEGER,r.idpago::INTEGER,r.vence::DATE,
                  r.dt::INTEGER,of_numeric(r.abono),of_numeric(r.interes),of_numeric(r.iva),of_numeric(r.saldo),of_numeric(r.total));

    IF (_idpagof=r.idpago::INTEGER) THEN
      t.contenido := t.contenido||r.vence||','||of_numeric(r.abono)||','||of_numeric(r.interes);
    ELSE
      t.contenido := t.contenido||r.vence||','||of_numeric(r.abono)||','||of_numeric(r.interes)||E'\n';
    END IF;
  END LOOP;
  RETURN NEXT t;
  PERFORM of_param_sesion_set('vsr_vars','linea',t.contenido);
  RETURN;
END;$$
LANGUAGE plpgsql;


-- -----------------
-- -----------------
SELECT of_db_drop_function('ofx_pp_monto_sugerido_pp_ed',NULL,NULL);
CREATE OR REPLACE FUNCTION ofx_pp_monto_sugerido_pp_ed()
  RETURNS TEXT AS $$
DECLARE   
  -- Variables
  --t         ofx_pp_monto_sugerido_pp_ed%ROWTYPE;
  r         RECORD;
  rd        RECORD;
  _idpagof   INTEGER;
BEGIN
  SELECT INTO  _idpagof max(idpago::INTEGER) from ofx_pp_monto_sugerido_pp();
  _idpagof := COALESCE(_idpagof,0);
--  t.contenido :=of_ofx_get('eidsucaux')||','||of_ofx_get('eidproducto')||','||of_ofx_get('eidauxiliar')||E'\n';
  SELECT INTO rd * 
    FROM deudores 
   WHERE (idsucaux,idproducto,idauxiliar)=(of_ofx_get('eidsucaux')::INTEGER,of_ofx_get('eidproducto')::INTEGER,of_ofx_get('eidauxiliar')::INTEGER);
  
  DELETE FROM auxiliares_anexo WHERE (kauxiliar,idkey)=(rd.kauxiliar,'__epp');
  DELETE FROM planpago_ed WHERE kauxiliar=rd.kauxiliar; 
  UPDATE deudores SET plazo=of_ofx_get('e_plazo')::INTEGER--,controlamortiza=1 
    WHERE (idsucaux,idproducto,idauxiliar)=(of_ofx_get('eidsucaux')::INTEGER,of_ofx_get('eidproducto')::INTEGER,of_ofx_get('eidauxiliar')::INTEGER);
  INSERT INTO auxiliares_anexo VALUES (rd.kauxiliar,'__epp','TRUE');

  FOR r IN SELECT * 
             FROM ofx_pp_monto_sugerido_pp() ORDER BY idpago::INTEGER LOOP
    INSERT INTO planpago_ed VALUES (rd.kauxiliar,r.vence::DATE,of_numeric(r.abono),of_numeric(r.interes),0.00);
  END LOOP;
  RETURN 'ok';
END;$$
LANGUAGE plpgsql;




SELECT of_db_drop_type('ofx_pagare_monto_sugerido','CASCADE');
CREATE TYPE ofx_pagare_monto_sugerido AS (
 suc_idsucursal      text,    
 nom_sucursal_matriz text,    
 nom_sucursal        text,    
 suc_calle           text,    
 suc_colonia         text,    
 suc_municipio       text,    
 suc_estado          text,    
 suc_rfc             text,    
 idsucdir            integer, 
 iddir               integer, 
 idsucursal          integer, 
 idrol               integer, 
 idasociado          integer, 
 nombre_socio        text,    
 rfc                 text,    
 idsucaux            integer, 
 idproducto          text,    
 idauxiliar          integer, 
 nombre_ptmo         text,    
 fech_apertura       date,    
 fecha_entrega       date,    
 fe_activacion       date,    
 fecha_vence         text,    
 importeaut          text,    
 montoentregado      text,    
 plazo               text,    
 plazo_letras        text,    
 diasxplazo          text,    
 tasaio              text,    
 tasa_anual          text,    
 tasaim              text,    
 cat                 text,    
 ptmo_referencia     text,    
 seguro_vida         text,    
 seguro_unidad       text,    
 subtotal_seguro     text,  
 subtotal_accesoriosiva     TEXT, 
 subtotal_ivaaccesorios  TEXT, 
 seguro_gps          text,    
 aval_paterno        text[],  
 aval_materno        text[],  
 aval_nombre         text[],  
 aval_tfirma         text[],  
 aval_label_nom      text[],  
 obsol_paterno       text[],  
 obsol_materno       text[],  
 obsol_nombre        text[],  
 obsol_tfirma        text[],  
 obsol_label_nom     text[],  
 idserie             text,    
 venc                text,    
 dt                  text,    
 abono               text,    
 iopp                text,    
 iva                 text,    
 pago                text,    
 saldo               text,    
 notas               text,    
 io_dpp              text,    
 io_dif              text,    
 totabono            text,    
 totio               text,    
 totiva              text,    
 totpago             text,    
 msn_error           text,    
 titulo              text,    
 noconducef          text,    
 hoy                 date,    
 paginas             integer, 
 kv_multicampos      text[],  
 label_d_banco       text,    
 label_cuenta        text,    
 label_total         text,    
 kv_data             text[],  
 monto_letra         text,    
 direccion_asoc      text,    
 fe_operacion        date,    
 comision_ape        text,
 __params            text
);
-- PAGARE
CREATE OR REPLACE FUNCTION ofx_pagare_monto_sugerido()
 RETURNS SETOF ofx_pagare_monto_sugerido
AS $$

DECLARE
  -- Variables
  t                       ofx_pagare_monto_sugerido%ROWTYPE;
  ra                      RECORD; --> Datos del asociado.
  rpp                     RECORD; --> Datos de las amortizaciones.
  rpp2                     RECORD; --> Datos de las amortizaciones.

  rsuc                    RECORD; --> Datos de la sucursal.
  rav                     RECORD; --> Registro de avales.
  rav2                    RECORD; --> Datos generales del aval. 
  rdic                    RECORD; --> Direccion de asociado
  p_idsucaux              INTEGER:= 0;
  p_idproducto            INTEGER:= 0;
  p_idauxiliar            INTEGER:= 0;
  i                       INTEGER:= 0;  -- Contador.
  _totabono               NUMERIC:= 0.00;  -- Total del abono.
  _totinteres             NUMERIC:= 0.00;  -- Total del interes
  _totiva                 NUMERIC:= 0.00;  -- Total dei IVA.
  _totimporte             NUMERIC:= 0.00;
  _infinito               INTEGER:= 0;  -- El numero de vueltas que va a ser el ciclo.
  _limite                 INTEGER:= 0; -- Para no pasarnos del borde.
  ps_ppidp                TEXT[];
  _nelem                  INTEGER:=0;
  _cuenta_bancaria        BOOLEAN;
  _diasxtasa              INTEGER:=0;
  _refaux                 TEXT;
  --_dt                    INTEGER;
  _apply_aval             BOOLEAN:=of_params_get('/formatos/ofx_pagare','appy_avales'); -- Aplica avales?
  pg_monto_fijo_segvida   NUMERIC;
  pg_monto_fijo_segunidad NUMERIC;
  pg_monto_fijo_gps       NUMERIC;

  pg_mes_uno_segvid       NUMERIC;
  pg_mes_uno_seguni       NUMERIC;
  pg_mes_uno_gps          NUMERIC;

  _tipoprestamo           INTEGER;
  _kauxiliar              INTEGER;
  _seguro_unidad          NUMERIC;
  _seguro_vida            NUMERIC;
  _suguro_gps             NUMERIC;
  _calcula_iva            BOOLEAN;
  _x_municipio            BOOLEAN;
  factor_iva_io           NUMERIC;
  base_iva_io             NUMERIC;
  p_monto                 NUMERIC;
  p_pago		  NUMERIC;
  p_plazo                 INTEGER;
  p_diasxplazo            INTEGER;
  p_interes               NUMERIC;
  p_fecha                 DATE ;
  p_fechaPA               DATE ; -- Fecha de primer abono
  _fecha_oper             DATE;
  _monto                  NUMERIC;
  _saldo    NUMERIC; 
  _erroneo  BOOLEAN;
  _gps_cero               INTEGER:=0;
  _svi_cero               INTEGER:=0;
  _sun_cero               INTEGER:=0;
  _iva_unidad             NUMERIC:=0.00;   
  _iva_gps                NUMERIC:=0.00;
  _maxidpago              INTEGER:=0;

  
BEGIN
  
  --PERFORM of_param_sesion_raise(NULL);
  -- Inicializando variables.
  t.suc_idsucursal  := '';
  t.nom_sucursal_matriz  := '';
  t.nom_sucursal    := '';
  t.suc_calle       := '';
  t.suc_colonia     := '';
  t.suc_municipio   := '';
  t.suc_estado      := '';
  t.suc_rfc         := '';
  -----------------------
  t.idsucdir        := 0; -- Clave unica.
  t.iddir           := 0; -- Clave unica.
  t.idsucursal      := 0;
  t.idrol           := 0;
  t.idasociado      := 0;
  t.fech_apertura   := NULL;
  t.fecha_entrega   := NULL;
  t.fecha_vence     := '';
  t.plazo           := '';
  t.plazo_letras    := '';
  t.diasxplazo      := '';
  t.tasaio          := '';
  t.tasaim          := '';
  t.ptmo_referencia := '';
  t.montoentregado  := '';
  t.seguro_vida     := '';
  t.seguro_unidad   := '';
  t.subtotal_seguro := '';
  t.subtotal_accesoriosiva :='';
  t.subtotal_ivaaccesorios := '';
  t.seguro_gps      := '';
  -- DATOS DE AVALES ------
  t.aval_paterno    := '{}';
  t.aval_materno    := '{}';
  t.aval_nombre     := '{}';
  t.aval_tfirma     := '{}';
  t.aval_label_nom  := '{}';
  -- Datos de obligados.
  t.obsol_paterno   := '{}';
  t.obsol_materno   := '{}';
  t.obsol_nombre    := '{}';
  t.obsol_tfirma    := '{}';
  t.obsol_label_nom := '{}';
  -- Detalle
  t.idserie         := '';
  t.venc            := '';
  t.dt              := '';
  t.abono           := '';
  t.iopp            := '';
  t.io_dpp          := '';
  t.io_dif          := '';
p_pago := 0;
  t.iva             := '';
  t.pago            := '';
  t.saldo           := '';
  t.notas           := '';
  -- Totales
  t.totabono        := '';
  t.totio           := '';
  t.totiva          := '';
  t.totpago         := '';
  t.msn_error       := '';
  t.hoy             := NULL;
  t.noconducef      := '';
  t.kv_multicampos  := '{}';
  t.label_total     := '';
  t.titulo          := '';
  t.__params        := '';
  ps_ppidp          := of_ofx_get('tv_planpago_2')::TEXT[];
  _nelem            := COALESCE(replace(split_part(array_dims(ps_ppidp),':',2),']','')::int,0);
  _nelem            := _nelem - 1;
  t.idsucursal      := of_ofx_get('idsucursal');
  t.idrol           := of_ofx_get('idrol');
  t.idasociado      := of_ofx_get('idasociado');
  t.nombre_socio    := of_ofx_get('nom_asoc');
  t.idsucaux        := of_ofx_get('idsucaux');
  t.idproducto      := of_ofx_get('idproducto');
  t.idauxiliar      := of_ofx_get('idauxiliar');
  _refaux           := COALESCE(t.idsucaux::TEXT,'')|+'-'|+
                       COALESCE(t.idproducto::TEXT,'')|+'-'|+
                       COALESCE(t.idauxiliar::TEXT,'');
  t.nombre_ptmo     := of_ofx_get('nom_prod');
  t.ptmo_referencia := of_ofx_get('referencia_cred');
  t.fecha_entrega   := COALESCE(of_ofx_get('fechaactivacion')::TEXT,of_param_sesion_get('global','fecha')::TEXT)::DATE;
  t.fech_apertura   := of_si(trim(of_ofx_get('fechaape')) = '',of_param_sesion_get('global','fecha')::TEXT,of_ofx_get('fechaape'))::DATE;
  t.importeaut      := of_ofx_get('montosolicitado');
  t.plazo           := of_ofx_get('Plazo');
  t.plazo_letras    := of_numero_letra(of_numeric(t.plazo),FALSE);
  t.diasxplazo      := of_ofx_get('diasxplazo');
  t.tasaio          := of_ofx_get('tasaio');
  t.tasa_anual      := (COALESCE(of_ofx_get('tasaio')::NUMERIC,0) * 12)::TEXT;
  t.tasaim          := of_ofx_get('tasaim');
  t.cat             := of_ofx_get('e_cat');
  t.hoy             := current_date;
  t.paginas         := 1;
  t.kv_multicampos  := of_multicampos_suc_array(99); --Multicampos de la sucursal matriz
  t.titulo          := of_params_get('/formatos/ofx_pagare','titulo');
  t.monto_letra     := '';
  t.direccion_asoc  := '';
  t.fe_operacion    := of_param_sesion_get('global','fecha');
  p_idproducto      := of_ofx_get('idproducto');
  p_monto           := of_ofx_get('montosolicitado');
  p_plazo           := of_ofx_get('Plazo');
  p_diasxplazo      := of_ofx_get('diasxplazo');
  p_interes         := of_ofx_get('tasaio');
  p_fechaPA         := of_si(trim(of_ofx_get('fechaprimerabono')) = '',t.fech_apertura::TEXT,of_ofx_get('fechaprimerabono'))::DATE;
  p_fecha           := of_param_sesion_get('global','fecha');
--  _fecha_oper       := of_param_sesion_get('global','fecha');

  -- Datos del asociado.
  SELECT INTO ra idsucdir,iddir
    FROM asociados
   WHERE (idsucursal,idrol,idasociado)=(t.idsucursal,t.idrol,t.idasociado);

  -- Revisar los dias por tasa si se maneja mensual o anual.
  SELECT INTO _diasxtasa valor
    FROM params
   WHERE (idparam,idelemento)= ('/socios/productos/prestamos','dias por tasa');
  -- Mostrar los datos bancarios si es necerio.
  SELECT INTO _cuenta_bancaria *
    FROM of_params_get('/formatos/ofx_pagare','cuenta_bancaria');
  
  -- Limite de detalle.
  SELECT INTO _limite *
    FROM of_params_get('/formatos/ofx_pagare','limite_det');
  
    -- Obteniendo los datos de la Sucursal
  SELECT INTO rsuc idsucursal, s.nombre AS sucursal,
                   c.nombre|+ ' # ' |+ numext |+
                   of_si((numint IS NULL) OR (TRIM(numint)=''),'',' Int. '|+ numint) AS calle,
                   rfc, col.nombre AS colonia, col.cp, m.nombre AS municipio, e.nombre AS estado
    FROM sucursales AS s
   INNER JOIN calles AS c USING (idcalle)
   INNER JOIN colonias AS col   USING (idcolonia)
   INNER JOIN municipios AS m USING (idmunicipio)
   INNER JOIN estados AS e USING (idestado)
   WHERE idsucursal = of_param_sesion_get('global','sucursal')::INTEGER;
    
    t.suc_idsucursal          := rsuc.idsucursal;
    t.nom_sucursal            := rsuc.sucursal;
    t.suc_calle               := rsuc.calle;
    t.suc_colonia             := rsuc.colonia;
    t.suc_municipio           := initcap(rsuc.municipio);
    t.suc_estado              := initcap(rsuc.estado);
    t.suc_rfc                 := rsuc.rfc;
    
  SELECT INTO rdic cal.nombre    AS calle, 
                     d.numext    AS numext,
                     d.numint    AS numint,
                     col.nombre  AS colonia,
                     m.nombre    AS municipio,
                     e.nombre    AS estado,
                     col.cp      AS cp
    FROM asociados       AS a
    LEFT JOIN directorio AS d   USING (idsucdir,iddir)
    LEFT JOIN calles     AS cal USING (idcalle)
    LEFT JOIN colonias   AS col USING (idcolonia)
    LEFT JOIN municipios AS m   USING (idmunicipio)
    LEFT JOIN estados    AS e   USING (idestado)
   WHERE (idsucursal,idrol,idasociado)=(t.idsucursal,t.idrol,t.idasociado);
  
  t.direccion_asoc :=  'Calle '||     rdic.calle
                      || ', #' ||     rdic.numext
                      ||CASE WHEN trim(rdic.numint) IN (NULL,'0','') THEN '' ELSE ' #'||rdic.numint END
                      || ', Col ' ||  rdic.colonia
                      || ', ' ||      rdic.municipio
                      || ', ' ||      rdic.estado
                      || ', C.P. ' || rdic.cp;
    
  SELECT INTO t.montoentregado, _kauxiliar, _tipoprestamo, p_fechaPA  montoentregado, kauxiliar, tipoprestamo, fechaprimerabono
    FROM deudores
   WHERE (idsucaux,idproducto,idauxiliar)=(t.idsucaux::INTEGER,t.idproducto::INTEGER,t.idauxiliar::INTEGER);
  _kauxiliar   := COALESCE(_kauxiliar,0);
  SELECT INTO p_fecha valor
    FROM valores_anexos
   WHERE (idtabla,idcolumna,idelemento)=('deudores','_mc_fecha_desembolso',_kauxiliar::TEXT);
   --RAISE NOTICE 'FECHA DESEMBOLSO %',p_fecha;
  p_fecha          := COALESCE(p_fecha,t.fe_operacion);
  --RAISE NOTICE 'FECHA DESEMBOLSO 2 %',p_fecha;
  _monto := t.montoentregado;
  t.fe_activacion  := p_fecha;
  t.monto_letra    := of_numero_letra(of_numeric(of_si(of_numeric(t.montoentregado) > 0,t.montoentregado,t.importeaut)));
  t.montoentregado := of_si(of_numeric(t.montoentregado) > 0,t.montoentregado,t.importeaut)::MONEY::TEXT;
  t.importeaut     := t.importeaut::MONEY::TEXT;
  _calcula_iva     := of_iva_general(t.idsucaux::INTEGER,t.idproducto::INTEGER,t.idauxiliar::INTEGER,_tipoprestamo,t.fe_operacion);
  factor_iva_io    := of_params_get('/socios/productos/prestamos','iva_io');
  base_iva_io      := of_params_get('/socios/productos/prestamos','base_iva_io');
  factor_iva_io    := ROUND((factor_iva_io /100.00),2);
  base_iva_io      := ROUND((base_iva_io /100.00),2);
  factor_iva_io    := round(factor_iva_io * base_iva_io,2);
  
  -- En dado caso el producto esté registrado ante conducef
  SELECT INTO t.noconducef *
    FROM of_params_get('/socios/productos/prestamos/'||t.idproducto,'conducef','Número de conducef',
                       'Número de registro ante conducef par este producto','TEXT','');
  
  --Datos del asociado.
  SELECT INTO t.rfc rfc
    FROM asociados
    LEFT JOIN directorio USING (idsucdir,iddir)
   WHERE (idsucursal,idrol,idasociado)=(t.idsucursal,t.idrol,t.idasociado);
  
  -- En dado caso el CAT se null. Buscamos!...
  IF (trim(t.cat) = '') THEN
    SELECT INTO t.cat valor::NUMERIC(12,2)
      FROM valores_anexos
     WHERE (idtabla,idcolumna,idelemento) = ('deudores',t.idsucaux::TEXT|+'-'|+t.idproducto::TEXT|+'-'|+t.idauxiliar::TEXT,'CAT');
  END IF;
  
  -- DGZZH 19/11/2014 Obteniendo los avales y obligados.
  ---IF (_apply_aval) THEN
    FOR rav IN SELECT * 
                 FROM referencias 
                WHERE (idsucdir,iddir)=(ra.idsucdir,ra.iddir) AND 
                      referencia  = _refaux AND 
                      (tiporef = 10 OR obligadosol)
                ORDER BY oid LOOP
      SELECT INTO rav2 paterno,materno,nombre
        FROM directorio
       WHERE (idsucdir,iddir)=(rav.idsucdirref,rav.iddirref);
      RAISE NOTICE '===============================';
      i  := i + 1; 

      IF (rav.obligadosol) THEN -- Obligados
        t.obsol_paterno   := t.obsol_paterno + COALESCE(rav2.paterno,'');
        t.obsol_materno   := t.obsol_materno + COALESCE(rav2.materno,'');
        t.obsol_nombre    := t.obsol_nombre  + COALESCE(rav2.nombre,'');
        t.obsol_tfirma    := t.obsol_tfirma  + ('___________________________________________'||E'\n'||
                                                'OBLIGADO SOLIDARIO');
      ELSE                      -- Avales
        t.aval_paterno    := t.aval_paterno + COALESCE(rav2.paterno,'');
        t.aval_materno    := t.aval_materno + COALESCE(rav2.materno,'');
        t.aval_nombre     := t.aval_nombre  + COALESCE(rav2.nombre,'');
        t.aval_tfirma     := t.aval_tfirma  + ('____________________________________________'||E'\n'||
                                               'AVAL');
      END IF;
    END LOOP;
  --END IF;
  SELECT INTO pg_monto_fijo_segvida   COALESCE(segvida  ,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  SELECT INTO pg_monto_fijo_segunidad COALESCE(segunidad,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  SELECT INTO pg_monto_fijo_gps       COALESCE(gps      ,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;

  SELECT INTO pg_mes_uno_segvid COALESCE(segvid_1,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  SELECT INTO pg_mes_uno_seguni COALESCE(seguni_1,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  SELECT INTO pg_mes_uno_gps COALESCE(gps_1,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;

  SELECT INTO _gps_cero, _svi_cero, _sun_cero COALESCE(gps_cero,0), COALESCE(svi_cero,0), COALESCE(sun_cero,0) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;

  i := 0;
  --RETURN NEXT t;
--  PERFORM of_param_sesion_raise(NULL);
  SELECT INTO _maxidpago max(idpago::INTEGER) FROM ofx_pp_monto_sugerido_pp();
  FOR rpp IN SELECT * FROM ofx_pp_monto_sugerido_pp() LOOP
    i  := i + 1;
    _erroneo := FALSE;
    --  RAISE NOTICE 'DIAS transcurridos %',rpp.dt;
    IF (i = 1) THEN -- En el primer pago el monto es proporcional a los días transcurridos.
        IF pg_mes_uno_segvid = 0 THEN
          _seguro_vida   := COALESCE(round(((pg_monto_fijo_segvida / 30) * rpp.dt::INTEGER),2),0.00); -- Sin iva
        ELSE
          _seguro_vida   := COALESCE(round(pg_mes_uno_segvid,2),0.00); 
        END IF;
        IF (i <= _svi_cero) THEN
          _seguro_vida    := 0;

        END IF; 

        IF pg_mes_uno_seguni = 0 THEN
          _seguro_unidad  := COALESCE(round(((pg_monto_fijo_segunidad / 30) * rpp.dt::INTEGER),2),0.00);
        ELSE
          _seguro_unidad  := COALESCE(round(pg_mes_uno_seguni,2),0.00);
        END IF;
        IF (i <= _sun_cero) THEN
          _seguro_unidad  := 0;
        END IF;
       IF pg_mes_uno_gps = 0 THEN
         _suguro_gps     := COALESCE(round(((pg_monto_fijo_gps / 30) * rpp.dt::INTEGER),2),0.00);
         --_suguro_gps     := COALESCE(trunc(((pg_monto_fijo_gps / 30) * (rpp.dt::INTEGER + _dgracia)),2),0.00);
         --RAISE NOTICE 'rpp.dt % _dgracia % _suguro_gps %', rpp.dt, _dgracia, _suguro_gps;
       ELSE
         _suguro_gps     := COALESCE(round(pg_mes_uno_gps,2),0.00);  
       END IF;
       IF (i <= _gps_cero) THEN
           _suguro_gps     := 0;
       END IF;
    --_comision := round(_comision,2);        
    ELSE -- No es el pago 1 no es proporcional
      IF (i <= _gps_cero) THEN
        _suguro_gps     := 0;
      ELSE        
      _suguro_gps     := COALESCE(round(pg_monto_fijo_gps,2),0.00);
      END IF;
      IF (i <= _svi_cero) THEN
        _seguro_vida    := 0;
      ELSE        
        _seguro_vida    := COALESCE(round(pg_monto_fijo_segvida,2),0.00);
      END IF;
      IF (i <= _sun_cero) THEN
        _seguro_unidad  := 0;
      ELSE        
        _seguro_unidad  := COALESCE(round(pg_monto_fijo_segunidad,2),0.00);
      END IF;
    END IF; -- Pago 1 o no.
    --_seguro_unidad    :=  of_si(TRUE,_seguro_unidad * (factor_iva_io) + _seguro_unidad, _seguro_unidad);
    --_suguro_gps       :=  of_si(TRUE,_suguro_gps * (factor_iva_io) + _suguro_gps, _suguro_gps);
    _iva_unidad         := round(_seguro_unidad * (factor_iva_io),2);        
    _iva_gps            := round(_suguro_gps * (factor_iva_io),2);     
    _infinito         := _infinito + 1;


/**
  idpago            TEXT,
  vence             TEXT,
  dt                TEXT,
  abono             TEXT,
  interes           TEXT,
  iva               TEXT,
  saldo             TEXT,
  total             TEXT
  **/    
    RAISE NOTICE 'rpp.iva %',rpp.iva;
    t.idserie         := t.idserie |+ i::TEXT |+ E'\n';
    t.venc            := t.venc   |+ rpp.vence::TEXT |+ E'\n';
    t.dt              := t.dt    |+ rpp.dt::TEXT    |+ E'\n';
    t.abono           := t.abono |+ to_char(of_numeric(rpp.abono),'FM999,999,990.00') |+ E'\n';
    t.iopp            := t.iopp  |+ to_char(of_numeric(rpp.interes),'FM999,999,990.00')  |+ E'\n';
    t.iva             := t.iva   |+ to_char(of_numeric(rpp.iva),'FM999,999,990.00')   |+ E'\n';
    t.saldo           := t.saldo |+ to_char(of_numeric(rpp.saldo),'FM999,999,990.00') |+ E'\n';
    t.subtotal_seguro := t.subtotal_seguro |+ to_char(_seguro_vida + _seguro_unidad,'FM999,999,990.00') |+ E'\n';
    t.seguro_gps      := t.seguro_gps      |+ to_char(_suguro_gps,'FM999,999,990.00') |+ E'\n';
    t.subtotal_accesoriosiva := t.subtotal_accesoriosiva |+ to_char(_suguro_gps + _seguro_unidad,'FM999,999,990.00') |+ E'\n';
    t.subtotal_ivaaccesorios := t.subtotal_ivaaccesorios |+ to_char(_iva_unidad + _iva_gps,'FM999,999,990.00') |+ E'\n';
    t.seguro_vida     := t.seguro_vida |+ to_char(_seguro_vida,'FM999,999,990.00') |+ E'\n';
    t.comision_ape    := t.comision_ape    |+ to_char(0.00,'FM999,999,990.00') |+ E'\n';
    p_pago = p_pago + round(of_numeric(rpp.total) + round(_seguro_vida,2) + round(_seguro_unidad,2) + round(_suguro_gps,2) + round(_iva_unidad,2) + round(_iva_gps,2), 2);

    t.pago            := t.pago  |+ to_char(round(of_numeric(rpp.total) + round(_seguro_vida,2) + round(_seguro_unidad,2) + round(_suguro_gps,2) + round(_iva_unidad,2) + round(_iva_gps,2),2),'FM999,999,990.00')   |+ E'\n';
    t.notas           := t.notas |+ substring('',0,30) |+ E'\n';
    t.montoentregado := p_pago;
t.monto_letra    := of_numero_letra(of_numeric(of_si(of_numeric(t.montoentregado) > 0,t.montoentregado,t.importeaut)));
  t.montoentregado := of_si(of_numeric(t.montoentregado) > 0,t.montoentregado,t.importeaut)::MONEY::TEXT;
          
    -- Sumando las filas de cada columna para obtener el total.
    -- Guardar primero en una variable para no mostrar el resultado.
    _totabono      := _totabono   + COALESCE(of_numeric(rpp.abono),0.00);
    _totinteres    := _totinteres + COALESCE(of_numeric(rpp.interes),0.00);
    _totiva        := _totiva     + COALESCE(of_numeric(rpp.iva),0.00);
    _totimporte    := _totimporte + COALESCE(of_numeric(rpp.total),0.00);
    --_tcomision_ape := _tcomision_ape + COALESCE ()
    IF (i = t.plazo::INTEGER) THEN
      t.label_total  := 'TOTALES';
      t.totabono     := _totabono::TEXT::MONEY::TEXT;  --Mostrar el resultado de totales.
      t.totio        := _totinteres::TEXT::MONEY::TEXT;
      t.totiva       := _totiva::TEXT::MONEY::TEXT;
      t.totpago      := _totimporte::TEXT::MONEY::TEXT;
      --t.comision_ape := _comision_ape::TEXT::MONEY::TEXT;
    END IF;
        
    IF (_infinito = _maxidpago) THEN -- Mostrar el resultado si se ha llenado la hoja
      RETURN NEXT t;
      t.idserie         := '';
      t.venc            := '';
      t.dt              := '';
      t.abono           := '';
      t.iopp            := '';
      t.iva             := '';
      t.pago            := '';
      t.saldo           := '';
      t.notas           := '';
      t.totabono        := '';
      t.totio           := '';
      t.totiva          := '';
      t.totpago         := '';
      t.subtotal_seguro := '';
      t.seguro_vida     := '';
      t.subtotal_accesoriosiva := '';
      t.subtotal_ivaaccesorios := '';
      t.seguro_gps      := '';
      t.paginas    := t.paginas + 1; -- Numero de páginas
      --_limite      := _limite + 45;  -- Le sumamos otros 40 para no salirnos del borde.
      _infinito    := 0;
    ELSIF (i = _maxidpago) THEN
      RETURN NEXT t;
    END IF;
  END LOOP;
  RETURN;
END;$$
LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------------
-- Imprime el formato de forma masiva.
/*
create table ofx_pagare_monto_sugerido_masivo_datos
(idsucaux      INTEGER, 
 idproduco     INTEGER, 
 idauxiliar    INTEGER, 
 montosugerido NUMERIC, 
 montopagouno  NUMERIC);
*/
-- ------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ofx_pagare_monto_sugerido_masiva()
 RETURNS SETOF ofx_pagare_monto_sugerido
AS $$
DECLARE
  -- Variables
  t                 ofx_pagare_monto_sugerido%ROWTYPE;
  r                 RECORD;
  rd                RECORD;
  rpp               RECORD;
  c                 TEXT;
  _gen_pdfs         BOOLEAN;
  _nombrepfd        TEXT:='';
  cp      TEXT;
  n                  INTEGER:=0;
  _iva               BOOLEAN;
BEGIN
  --PERFORM of_ofx_set('bt_gen_pdfs',  'sensitive=false');
  c                 := of_params_get('/formatos/ofx_pagare_monto_sugerido','fx_principal');
  _gen_pdfs         := of_params_get_boolean('/formatos/ofx_pagare_monto_sugerido','gen_pdfs');

  FOR r IN SELECT * FROM ofx_pagare_monto_sugerido_masivo_datos  LOOP
    SELECT INTO rd * FROM deudores WHERE (idsucaux,idproducto,idauxiliar)=(r.idsucaux,r.idproducto,r.idauxiliar);
    _iva := of_iva_general(rd.idsucaux::INTEGER,rd.idproducto::INTEGER,rd.idauxiliar::INTEGER,rd.tipoprestamo,of_param_sesion_get('global','fecha')::DATE);
    --PERFORM of_param_sesion_set('global','fecha',of_param_sesion_get('global','fecha')::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idsucursal',rd.idsucursal::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idrol',rd.idrol::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idasociado',rd.idasociado::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','nom_asoc',of_nombre_asociado(rd.idsucursal,rd.idrol,rd.idasociado)::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idsucaux',rd.idsucaux::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idproducto',rd.idproducto::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idauxiliar',rd.idauxiliar::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','nom_prod','-'::TEXT);
    --PERFORM of_param_sesion_setet('vsr_vars','referencia_cred','set=');
    PERFORM of_param_sesion_set('vsr_vars','montosolicitado',rd.montosolicitado::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','Plazo',rd.plazo::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','diasxplazo',rd.diasxplazo::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','tasaio',round(rd.tasaio,2)::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','tasaim',round(rd.tasaim,2)::TEXT); 
    PERFORM of_param_sesion_set('vsr_vars','fechaprimerabono',rd.fechaprimerabono::TEXT);
    --e_fechapa
    --
    PERFORM of_param_sesion_set('vsr_vars','e_montosolicitado',rd.montosolicitado::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','e_tasaio',round(rd.tasaio,2)::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','idproducto',rd.idproducto::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','e_plazo',rd.plazo::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','e_diasxplazo',rd.diasxplazo::TEXT);
    
    IF (r.montosugerido>0.00) THEN
      PERFORM of_param_sesion_set('vsr_vars','e_fechapa',rd.fechaprimerabono::TEXT);
      PERFORM of_param_sesion_set('vsr_vars','fechaprimerabono',rd.fechaprimerabono::TEXT);
    ELSE
      PERFORM of_param_sesion_set('vsr_vars','e_fechapa',rd.fechaprimerabono::TEXT);
      PERFORM of_param_sesion_set('vsr_vars','fechaprimerabono',rd.fechaprimerabono::TEXT);
    END IF;  

    PERFORM of_param_sesion_set('vsr_vars','e_montosugerido',r.montosugerido::TEXT);
    IF (of_param_sesion_get('global','fecha')::DATE=of_fecha_dum(of_param_sesion_get('global','fecha')::DATE)::DATE) THEN
      PERFORM of_param_sesion_set('vsr_vars','chk_mismodia','FALSE');
    ELSE 
      PERFORM of_param_sesion_set('vsr_vars','chk_mismodia','TRUE');
    END IF;
    PERFORM of_param_sesion_set('vsr_vars','e_primerpagocap',r.montopagouno::TEXT);
    PERFORM of_param_sesion_set('vsr_vars','e_primerpagocap',r.montopagouno::TEXT);
    PERFORM of_param_sesion_set('ofx_pp_monto_sugerido','iva',_iva::TEXT);

    FOR t IN EXECUTE 'SELECT * FROM '||c||'()' LOOP -- Vaciar toda la info en el TYPE.
      IF (_gen_pdfs) THEN
_nombrepfd := of_ofx_get('nom_asoc')::TEXT |+ '_' |+t.idsucaux::TEXT |+ '-'|+ t.idproducto::TEXT |+ '-'|+ t.idauxiliar::TEXT |+'_'|+ of_ofx_get('e_montosugerido')::TEXT|+'_pagare';


  
        --_nombrepfd := 'pagare_monto_sugerido_'|+t.idsucaux::TEXT |+ '-'|+ t.idproducto::TEXT |+ '-'|+ t.idauxiliar::TEXT;
        t.__params := t.__params || format('fname=%s',_nombrepfd);
      END IF;

      PERFORM of_param_sesion_set('vsr_vars','eidsucaux',t.idsucaux::TEXT);
      PERFORM of_param_sesion_set('vsr_vars','eidproducto',t.idproducto::TEXT);
      PERFORM of_param_sesion_set('vsr_vars','eidauxiliar',t.idauxiliar::TEXT);
      cp := 'CREATE TEMP TABLE ofx_pagare_monto_sugerido_masivo_pp (columna TEXT, columnab TEXT, columnac TEXT)';
      EXECUTE cp;
      INSERT INTO ofx_pagare_monto_sugerido_masivo_pp VALUES (t.idsucaux,t.idproducto,t.idauxiliar);
      DELETE FROM ofx_pp_monto_sugerido_planpago 
        WHERE (idsucaux,idproducto,idauxiliar)=(t.idsucaux::INTEGER,t.idproducto::INTEGER,t.idauxiliar::INTEGER);
      
      n :=0;
      DELETE FROM auxiliares_anexo WHERE (kauxiliar,idkey)=(rd.kauxiliar,'__epp');
      DELETE FROM planpago_ed WHERE kauxiliar=rd.kauxiliar; 
      INSERT INTO auxiliares_anexo VALUES (rd.kauxiliar,'__epp','TRUE');      
      FOR rpp IN SELECT * FROM ofx_pp_monto_sugerido_pp() ORDER BY idpago::INTEGER LOOP
        n:=n+1;
        IF (n>=1) THEN
          INSERT INTO ofx_pp_monto_sugerido_planpago 
            VALUES (t.idsucaux::INTEGER,t.idproducto::INTEGER,t.idauxiliar::INTEGER,rpp.idpago::INTEGER,rpp.vence::DATE,rpp.dt::INTEGER,of_numeric(rpp.abono),
                    of_numeric(rpp.interes),of_numeric(rpp.iva),of_numeric(rpp.saldo),of_numeric(rpp.total));

          INSERT INTO planpago_ed VALUES (rd.kauxiliar,rpp.vence::DATE,of_numeric(rpp.abono),of_numeric(rpp.interes),0.00);          
        END IF;
        INSERT INTO ofx_pagare_monto_sugerido_masivo_pp VALUES (rpp.vence,of_numeric(rpp.abono),of_numeric(rpp.interes));
      END LOOP;
      cp := 'COPY (SELECT columna||'||quote_literal(',')||'||columnab||'||quote_literal(',')||'||columnac FROM ofx_pagare_monto_sugerido_masivo_pp) TO '||quote_literal('/tmp/'||_nombrepfd||'.csv');
      RAISE NOTICE 'cp %',cp;
      EXECUTE cp;
      cp := 'DROP TABLE ofx_pagare_monto_sugerido_masivo_pp';
      EXECUTE cp;
 
      RETURN NEXT t;
    END LOOP;
    -- Borra el auxiliar por cada ciclo.
    --PERFORM of_param_sesion_unset('vsr_vars','ps_idsucaux');
    PERFORM of_param_sesion_unset('vsr_vars','idsucursal');
    PERFORM of_param_sesion_unset('vsr_vars','idrol');
    PERFORM of_param_sesion_unset('vsr_vars','idasociado');
    PERFORM of_param_sesion_unset('vsr_vars','nom_asoc');
    PERFORM of_param_sesion_unset('vsr_vars','idsucaux');
    PERFORM of_param_sesion_unset('vsr_vars','idproducto');
    PERFORM of_param_sesion_unset('vsr_vars','idauxiliar');
    PERFORM of_param_sesion_unset('vsr_vars','nom_prod');
    PERFORM of_param_sesion_unset('vsr_vars','montosolicitado');
    PERFORM of_param_sesion_unset('vsr_vars','Plazo');
    PERFORM of_param_sesion_unset('vsr_vars','diasxplazo');
    PERFORM of_param_sesion_unset('vsr_vars','tasaio');
    PERFORM of_param_sesion_unset('vsr_vars','tasaim');
    PERFORM of_param_sesion_unset('vsr_vars','fechaprimerabono');
    PERFORM of_param_sesion_unset('vsr_vars','e_montosolicitado');
    PERFORM of_param_sesion_unset('vsr_vars','e_tasaio');
    PERFORM of_param_sesion_unset('vsr_vars','idproducto');
    PERFORM of_param_sesion_unset('vsr_vars','e_plazo');
    PERFORM of_param_sesion_unset('vsr_vars','e_diasxplazo');
    PERFORM of_param_sesion_unset('vsr_vars','e_fechapa');
    PERFORM of_param_sesion_unset('vsr_vars','e_montosugerido');
    PERFORM of_param_sesion_unset('vsr_vars','chk_mismodia');
    PERFORM of_param_sesion_unset('vsr_vars','e_primerpagocap');
    PERFORM of_param_sesion_unset('vsr_vars','eidsucaux');
    PERFORM of_param_sesion_unset('vsr_vars','eidproducto');
    PERFORM of_param_sesion_unset('vsr_vars','eidauxiliar'); 
    PERFORM of_param_sesion_unset('ofx_pp_monto_sugerido','iva');   
  END LOOP; 
RETURN ;
END;$$
LANGUAGE plpgsql;
