-- CREATE SCHEMA ofx_traspaso_sdofavor;
/*
create table ofx_traspaso_sdofavor.detalle_archivo ( cliente  text,
 cliente   text, 
 nombre    text, 
 credito    text, 
 monto   text);
*/
 -- create table ofx_traspaso_sdofavor.no_encontrados (credito text);

-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_traspaso_sdofavor 
-- Recaudo de abonos Gazel
-- 16/04/2016

-- ----------------------------------------------------------------------------
-- 19/03/2015 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _Id       TEXT;
  _Desc     TEXT;
  _Fecha    TEXT;
  _Version  TEXT := '1.14.10'; 
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  _Id    := _Version |+ '.0'; -- CAQ
  _Desc  := 'Creación de tablas necesarias.';
  _Fecha := '01/06/2016';
  IF (of_updatedb_ofx(_Id,_Desc,_Fecha,md5(_id|+_Desc|+_Fecha))) THEN
    -- Esquema y tablas necesarias
    CREATE SCHEMA ofx_traspaso_sdofavor;
    CREATE TABLE ofx_traspaso_sdofavor.detalle_archivo (
     cliente  TEXT,
     nombre   TEXT, 
     credito TEXT, 
     monto    TEXT);
    create table ofx_traspaso_sdofavor.no_encontrados (credito text);
    CREATE TABLE ofx_traspaso_sdofavor.aplicacion(
        cliente         TEXT,
        nombre          TEXT,
        ctasdofavor     TEXT,
        credito         TEXT,
        monto           NUMERIC,
        tipo            INTEGER,
        usuario         TEXT,
        pg_backend_pid  INTEGER);
    CREATE TABLE ofx_traspaso_sdofavor.aplicacion_job(
        cliente         TEXT,
        nombre          TEXT,
        ctasdofavor     TEXT,
        credito         TEXT,
        monto           NUMERIC,
        tipo            INTEGER,
        usuario         TEXT,
        pg_backend_pid  INTEGER);
  END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 19/03/2015 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  f     DATE;
  r     RECORD;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  IF (NOT of_ofx_check_version('1.14.1')) THEN
    RETURN FALSE;
  END IF;
  
  f := ofpsd('global','fecha',now()::DATE);
  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dpm(f)::TEXT);
  DELETE FROM ofx_traspaso_sdofavor.detalle_archivo;
  DELETE FROM ofx_traspaso_sdofavor.no_encontrados;
  DELETE FROM temporal WHERE (idusuario,sesion)=(current_user,pg_backend_pid()::TEXT);  
  DELETE FROM ofx_traspaso_sdofavor.aplicacion;
  PERFORM of_ofx_set('cb_proceso','set=0');
  PERFORM of_ofx_set('bt_previo','show=FALSE');
  RETURN TRUE;
  -- validación de registros
  SELECT INTO r count(*) as cont FROM ofx_traspaso_sdofavor.aplicacion;
  IF (r.cont>0) THEN
    PERFORM of_ofx_notice('info','');  
    RETURN FALSE;
  END IF;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 19/03/2015 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 19/03/2015 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  _nombrecuenta   TEXT;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 

  IF (p_variable='chk_aplicar') THEN
    IF (p_valor::BOOLEAN) THEN
      PERFORM of_ofx_set('e_capcha','sensitive=true');
      PERFORM of_ofx_set('bt_aceptar','sensitive=true');
      PERFORM of_ofx_set('bt_cancelar','sensitive=true');
      PERFORM of_ofx_set('capcha','set='||substring(md5(random()::TEXT),1,4));   
    ELSE
      PERFORM of_ofx_set('e_capcha','sensitive=false');
      PERFORM of_ofx_set('bt_aceptar','sensitive=false');
      PERFORM of_ofx_set('bt_cancelar','sensitive=false');
    END IF;
  END IF;

  IF (p_variable='e_capcha') THEN
    IF (p_valor<>of_ofx_get('capcha') AND of_ofx_get('chk_aplicar')::BOOLEAN) THEN
      PERFORM of_ofx_notice('popup','El código de confirmación no coincide.');      
      RETURN FALSE;      
    END IF;
  END IF;

  IF (p_variable='cb_proceso') THEN
    DELETE FROM ofx_traspaso_sdofavor.aplicacion WHERE (usuario,pg_backend_pid)=(current_user::TEXT,pg_backend_pid());
    PERFORM of_ofx_set('bt_previo','set=click');
  END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 19/03/2015 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2___on_click (p_button TEXT, p_data TEXT) 
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  IF (p_button = 'bt_aceptar') THEN
    
  END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 19/03/2015 
SELECT of_db_drop_type('ofx_traspaso_sdofavor_previo_v2','CASCADE');
CREATE TYPE ofx_traspaso_sdofavor_previo_v2 AS (
  tipo            TEXT,
  cliente         TEXT,
  nombre          TEXT,
  ctasdofavor     TEXT,
  credito         TEXT,
  sdofavor        TEXT,
  pg_backend_pid  TEXT
);

CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_previo_v2 () 
  RETURNS SETOF ofx_traspaso_sdofavor_previo_v2 AS $$
DECLARE -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Variables
  r       ofx_traspaso_sdofavor_previo_v2%ROWTYPE;
  rc      RECORD;
  rauxr   RECORD;
  rlin    RECORD;
  rdet    RECORD;
  rd      RECORD;
  rofd    RECORD;
  rdist   RECORD;
  rins    RECORD;
  rva     RECORD;
  rtemp   RECORD;
  rne     RECORD;
  rjob    RECORD;
  _arr    TEXT[];
  fname   TEXT := 'vsr_vars_archivo'; -- OJO: el nombre del archivo es: 'vsr_vars_' || $variable
  _ref    TEXT; -- Referencia que contiene el código de barras (auxiliar)
  _idsucaux     INTEGER;
  _idproducto   INTEGER;
  _idauxiliar   INTEGER;
  _monto        NUMERIC;
  _deudatot     NUMERIC:=0.00;
  _abreal       NUMERIC:=0.00;
  _sobrante     NUMERIC:=0.00;
  _totsobrante  NUMERIC:=0.00;
  _idusuario    TEXT;
  _fecha_oper   DATE;
  _suctrabajo   INTEGER;
  tabono        NUMERIC:=0.00;
  _pol          TEXT[];
  _idcuenta     TEXT;
  _idcuentasob  TEXT;   
  _linea        TEXT:='';
  _data         TEXT[];
  _cont         INTEGER;
  _contap       INTEGER;
  tdebe         NUMERIC:=0;
  thaber        NUMERIC:=0;
  _exigible     NUMERIC:=0;

BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 
  -- Detalle
  PERFORM of_ofx_notice('info','Se está generando la información, este proceso puede tardar unos minutos.');  
  _cont := 0;
  _fecha_oper := of_param_sesion_get_date('global','fecha');
  FOR rc IN SELECT c.idsucursal,c.idrol,c.idasociado,
                   c.idsucaux,c.idproducto,c.idauxiliar,c.saldo AS sdofav,
                   d.idsucaux AS idsucauxpre,d.idproducto AS idproductopre,d.idauxiliar AS idauxiliarpre,d.saldo AS sdocred
              FROM acreedores AS c 
              INNER JOIN auxiliares_ref AS ax 
                ON (ax.idsucauxref,ax.idproductoref,ax.idauxiliarref)=(c.idsucaux,c.idproducto,c.idauxiliar) 
              INNER JOIN deudores AS d 
                ON (d.idsucaux,d.idproducto,d.idauxiliar)=(ax.idsucaux,ax.idproducto,ax.idauxiliar) 
             WHERE c.idproducto=2001 AND c.saldo>0.00 AND d.estatus=3 AND d.idproducto=5200  
             GROUP BY 1,2,3,4,5,6,7,8,9,10,11 
             ORDER BY c.idsucursal,c.idrol,c.idasociado,sdofav LOOP

            --SELECT * 
            --  FROM acreedores
            -- WHERE idproducto=2001 AND saldo>0.00 ORDER BY idsucursal,idrol,idasociado LOOP
            -- --WHERE (idsucaux,idproducto,idauxiliar)=(1,2001,7607) LIMIT 10 LOOP
    --SELECT INTO rauxr * 
    --  FROM auxiliares_ref 
    -- WHERE (idsucauxref,idproductoref,idauxiliarref)=(rc.idsucaux,rc.idproducto,rc.idauxiliar);
    
    --IF (FOUND) THEN
      --SELECT INTO rofd * FROM of_deudor(rc.idsucauxpre,rc.idproductopre,rc.idauxiliarpre,_fecha_oper);
      --
      --_exigible := rofd.abono + rofd.interes_total + rofd.impuesto_total + rofd.interesmor_total +
      --           rofd.impuestoim_total + rofd.costos_asociados;
      --IF (_exigible>0.00) THEN
        _cont := _cont + 1;
        r.tipo           := of_si(of_ofx_get('cb_proceso_idx')::INTEGER=0,'Abonos bancarios','Recaudo');
        r.cliente        := rc.idsucursal||'-'||rc.idrol||'-'||rc.idasociado;
        r.nombre         := of_nombre_asociado(rc.idsucursal,rc.idrol,rc.idasociado);
        r.ctasdofavor    := rc.idsucaux||'-'||rc.idproducto||'-'||rc.idauxiliar; 
        r.credito        := rc.idsucauxpre||'-'||rc.idproductopre||'-'||rc.idauxiliarpre ;
        r.sdofavor       := rc.sdofav;--round(of_si(rc.saldo>=_exigible,_exigible,rc.saldo),2);
        --r.tipo           := of_ofx_get('cb_proceso_idx');
        r.pg_backend_pid := pg_backend_pid()::TEXT;
        --r.usuario        := current_user;
        INSERT INTO ofx_traspaso_sdofavor.aplicacion 
          VALUES (rc.idsucursal||'-'||rc.idrol||'-'||rc.idasociado,
                  of_nombre_asociado(rc.idsucursal,rc.idrol,rc.idasociado),
                  rc.idsucaux||'-'||rc.idproducto||'-'||rc.idauxiliar,
                  rc.idsucauxpre||'-'||rc.idproductopre||'-'||rc.idauxiliarpre,
                  rc.sdofav,--round(of_si(rc.saldo>=_exigible,_exigible,rc.saldo),2),
                  of_ofx_get('cb_proceso_idx')::INTEGER,
                  current_user,
                  pg_backend_pid()::INTEGER);

        SELECT INTO rjob * FROM ofx_traspaso_sdofavor.aplicacion_job 
          WHERE ctasdofavor=r.ctasdofavor;
        IF (NOT FOUND) THEN
          RETURN NEXT r;
        ELSE 
          PERFORM of_ofx_notice('info','La cuenta '||r.ctasdofavor||'del cliente '||rc.idsucursal||'-'||rc.idrol||'-'||rc.idasociado||
                                ' está en cola de proceso para ser aplicado. No se agregará a este nuevo proceso.');  
        END IF;
      --END IF;
    --END IF;
  END LOOP;             
  RETURN;
END;$$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2_genera_proc () 
  RETURNS TEXT AS $$
DECLARE -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Variables
  r    RECORD;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  FOR r IN SELECT * FROM ofx_traspaso_sdofavor.aplicacion LOOP
    INSERT INTO ofx_traspaso_sdofavor.aplicacion_job 
      VALUES (r.cliente,
              r.nombre,
              r.ctasdofavor,
              r.credito,
              r.monto,--round(of_si(rc.saldo>=_exigible,_exigible,rc.saldo),2),
              r.tipo,
              current_user,
              pg_backend_pid()::INTEGER);
  END LOOP;
  PERFORM ofxq_new_process('traspaso_sdosfav_prestamo'||'_'||of_folio('traspaso_sdosfav_prestamo',TRUE)::TEXT,'ofx_traspaso_sdofavor_v2_queue',NULL);
  PERFORM of_ofx_notice('popup','Se ha generado el proceso en la cola de trabajos.');  
  DELETE FROM ofx_traspaso_sdofavor.aplicacion;
  PERFORM of_ofx_set('bt_cancelar','set=click');
  --PERFORM 
RETURN 'ok';
END;$$
LANGUAGE plpgsql;


-- Procesos para OFqueue
CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2_queue___ofxq_ini(p_id BIGINT)
  RETURNS TEXT[] AS $$
DECLARE
  _uuid        TEXT[] := '{}';
  rdet         RECORD;
  rc           RECORD;
  rauxr        RECORD;
  rofd         RECORD;
  _exigible    NUMERIC;
 -- Parámetros 
  _fecha_oper  DATE;
  _idusuario   TEXT;
  _idsucursal  INTEGER;
BEGIN
  --FOR i IN 1..50 LOOP
  --  _uuid := _uuid || ofxq_queue_job(p_id, json_build_object('mensaje', 'hola que haces, pruebas ofxq jobs'));
  --END LOOP;
  _fecha_oper := of_param_sesion_get_date('global','fecha');
  _idusuario  := current_user;  
  SELECT INTO _idsucursal suctrabajo FROM usuarios
     WHERE idusuario = _idusuario AND estatus = 1; --activo

  --FOR rc IN SELECT * 
  --            FROM acreedores
  --           WHERE idproducto=2001 AND saldo>0.00 ORDER BY idsucursal,idrol,idasociado LOOP
  --           --WHERE (idsucaux,idproducto,idauxiliar)=(1,2001,7607) LOOP
  --  SELECT INTO rauxr * 
  --    FROM auxiliares_ref 
  --   WHERE (idsucauxref,idproductoref,idauxiliarref)=(rc.idsucaux,rc.idproducto,rc.idauxiliar);
  --  
  --  IF (FOUND) THEN
  --    SELECT INTO rofd * FROM of_deudor(rauxr.idsucaux,rauxr.idproducto,rauxr.idauxiliar);
  --    
  --    _exigible := rofd.abono + rofd.interes_total + rofd.impuesto_total + rofd.interesmor_total +
  --               rofd.impuestoim_total + rofd.costos_asociados;
  --    
  --    IF (_exigible>0.00) THEN
  --      _uuid := _uuid || ofxq_queue_job(p_id, json_build_object('_fecha_oper', date(_fecha_oper), '_idusuario',_idusuario,
  --              '_idsucursal',_idsucursal,'pg_backend_pid',pg_backend_pid()::TEXT,
  --              'cta_sdo_fav',rc.idsucaux||'-'||rc.idproducto||'-'||rc.idauxiliar,
  --              'cta_credito',rofd.idsucaux||'-'||rofd.idproducto||'-'||rofd.idauxiliar));          
  --    END IF;
  --  END IF;
  --END LOOP; 
  FOR rc IN SELECT * FROM ofx_traspaso_sdofavor.aplicacion_job LOOP
    _uuid := _uuid || ofxq_queue_job(p_id, json_build_object('_fecha_oper', date(_fecha_oper), '_idusuario',_idusuario,
                      '_idsucursal',_idsucursal,'pg_backend_pid',pg_backend_pid()::TEXT,
                      'cta_sdo_fav',rc.ctasdofavor,'cta_credito',rc.credito,
                      'tipo',of_si(rc.tipo=0,'Abonos bancarios','Recaudo')));  
    DELETE FROM ofx_traspaso_sdofavor.aplicacion_job 
      WHERE ctasdofavor=rc.ctasdofavor;
  END LOOP;
  RETURN _uuid;
END;$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ofx_traspaso_sdofavor_v2_queue___ofxq_job(p_jdata JSONB)
  RETURNS JSON AS $$
DECLARE
  rdet               RECORD;
  rd                 RECORD;
  rp                 RECORD;
  rins               RECORD;
  rdaim              RECORD;
  rpol               RECORD;
  rsum               RECORD;
  rv                 RECORD;
  rcu                RECORD;
  rofd               RECORD;
  rauxaf             RECORD;
  rsa                RECORD;
  rmd                RECORD;
  rpp                RECORD;
  rpp2               RECORD;
  rtemp              RECORD;

  _kpoliza           INTEGER;
  _pol               TEXT[]; 
  _fecha_oper        DATE;
  _idusuario         TEXT;
  _idsucursal        INTEGER;
  pg_backend_pid     INTEGER;
  _monto_archivo     NUMERIC;
  _idcuenta          TEXT;
  _referencia        TEXT;
  _uuid              JSONB;
  _abonot            NUMERIC;
  _cargot            NUMERIC;
  _fiva              BOOLEAN;
  _io_desc           NUMERIC;  
  _exigible          NUMERIC; 
  _idproducto_sf     INTEGER := 2001;
  _abono_ca          NUMERIC;
  _ca_pend           NUMERIC;
  _ca_x_pago         NUMERIC;
  _iopend            NUMERIC; 
  _io_x_pago         NUMERIC; 
  _abono_ca_x_pago   NUMERIC;
  _abono_io_x_pago   NUMERIC;
  _abono_cap_x_pago  NUMERIC;
  _ca_pagado         NUMERIC;
  _restante          NUMERIC;
  _dict              TEXT[];
  _abono_im_pago     NUMERIC;
  _factor_iva        NUMERIC:=of_params_get('/socios/productos/prestamos','iva_io');
  _dt                INTEGER; 
  _iopagado          NUMERIC; 
  _mensaje           TEXT;
  _productos         TEXT:='';
  cta_sdo_fav        TEXT;          
  cta_credito        TEXT;
  _tipoproc          TEXT;  
  _aux               INTEGER[];   
  rprel              RECORD;    
  c      TEXT;   
  _fname   TEXT;
BEGIN
  --PERFORM of_ofx_notice('info', (p_jdata->>'mensaje')::TEXT);
  --PERFORM of_ofx_notice('warning', (p_jdata->>'mensaje')::TEXT);
  --PERFORM of_ofx_notice('info', (p_jdata->>'info')::TEXT);
  --PERFORM of_ofx_notice('error', (p_jdata->>COALESCE('error','')::TEXT));
  _uuid          := '{}';
  _fecha_oper    := (p_jdata->>'_fecha_oper');
  _idusuario     := (p_jdata->>'_idusuario');
  _idsucursal    := (p_jdata->>'_idsucursal');
  pg_backend_pid := (p_jdata->>'pg_backend_pid');
  cta_sdo_fav    := (p_jdata->>'cta_sdo_fav');     
  cta_credito    := (p_jdata->>'cta_credito'); 
  _tipoproc      := (p_jdata->>'tipo');     
  PERFORM of_param_sesion_set('global','fecha',_fecha_oper::TEXT);
  _factor_iva := ROUND((_factor_iva /100.00),2); 
  -- APLICACIÓN AL CREDITO.
  rv := of_ventanilla_ini(_idusuario, 
                          NULL, -- Sucursal de trabajo del usuario
                          3,    -- Tipo de póliza
                          NULL, -- Fecha del sistema
                          NULL, -- La póliza no es acumulativa
                          _tipoproc||' (aplicación al credito)');
  IF (NOT rv.ok) THEN
    PERFORM of_ofx_notice('error', 'error aqui');
    PERFORM of_ventanilla_fin(rv);
    _uuid := json_build_object('error','Se generó un error.');    
    RETURN _uuid;
  END IF;
  _abono_ca          :=0.00;
  _ca_pend           :=0.00;
  _ca_x_pago         :=0.00;
  _iopend            :=0.00;
  _io_x_pago         :=0.00;
  _abono_ca_x_pago   :=0.00;
  _abono_io_x_pago   :=0.00;
  _abono_cap_x_pago  :=0.00;
  _ca_pagado         :=0.00;
  _restante          :=0.00;
  _dict := NULL;
  --_monto_archivo := _monto_archivo;
  
  _aux := string_to_array(cta_credito,'-');    
  SELECT INTO rd * FROM deudores
    --WHERE idsucaux||'-'||idproducto||'-'||idauxiliar=cta_credito;
    WHERE (idsucaux,idproducto,idauxiliar)=(_aux[1],_aux[2],_aux[3]);
  -- CAQ 21/02/2017 -- El recaudo siempre se abonará primero al saldo a favor.
  IF (FOUND) THEN -- Se encuentra en deudores...
    _fiva :=of_iva_general(rd.idsucaux,rd.idproducto,rd.idauxiliar,NULL,_fecha_oper);
    SELECT INTO rofd abono,interes_total,impuesto_total,interesmor_total,impuestoim_total,numeric_larger(0.00,costos_asociados) AS costos_asociados,
           kauxiliar,fechaactivacion,fechaultcalculo 
      FROM of_deudor(rd.idsucaux,rd.idproducto,rd.idauxiliar,_fecha_oper);
    --Determinamos el exigible de interes menos los descuentos por diferimiento
    PERFORM kauxiliar FROM ppv.deudores_escalonados WHERE kauxiliar=rofd.kauxiliar;
    IF FOUND THEN
      SELECT INTO rofd.interes_total,_io_desc r_io,r_iopr 
        FROM of_dist_abono_escalonado_sus(rd.idsucaux,rd.idproducto,rd.idauxiliar,_fecha_oper);
      IF (_fiva) THEN
        rofd.impuesto_total:=round(rofd.interes_total*_factor_iva,2);
      END IF;
    ELSE
      _io_desc :=0.00;
    END IF;
    _exigible := rofd.abono + rofd.interes_total + rofd.impuesto_total + rofd.interesmor_total +
                 rofd.impuestoim_total + rofd.costos_asociados;
    _restante := _exigible;
    SELECT INTO rmd * FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=rofd.kauxiliar;
    -- SOLO CON EXIGIBLE.
    IF (_exigible>0) THEN -- Exigible mayor a cero.
      SELECT INTO rauxaf idsucauxref,idproductoref,idauxiliarref  -- El auxiliar de saldo a favor.
        FROM of_auxiliar_ref(rd.idsucaux,rd.idproducto,rd.idauxiliar,_idproducto_sf);
      -- Checamos el saldo del auxiliar de saldo a favor. En caso de que sea mayor o igual 
      -- al exigible hacemos el cargo de lo equivalente al exigible y lo depositamos sin hacer 
      -- manualmente distribuición de nada. Directo al préstamo. 
      SELECT INTO rsa * from of_auxiliar_saldo(rauxaf.idsucauxref,rauxaf.idproductoref,rauxaf.idauxiliarref,_fecha_oper) AS saldo;
      IF (rsa.saldo>0.00) THEN
        IF (rsa.saldo>=_exigible) THEN
          INSERT INTO temporal (idusuario,sesion,idsucaux,idproducto,idauxiliar, 
                      idsucursal,idrol,idasociado,esentrada,capital, 
                      intord,icxa,intmor,impuesto,comision,esajuste, 
                      referencia,idcuenta,multiplex)
              VALUES (_idusuario,pg_backend_pid,rauxaf.idsucauxref,rauxaf.idproductoref,rauxaf.idauxiliarref, 
                      rd.idsucursal, rd.idrol, rd.idasociado,FALSE,_exigible, 
                       0,   0,     0,       0,       0,FALSE, 
                      _tipoproc||' (aplicación a crédito)',    NULL,     NULL);  
          
          --SELECT INTO rins *
          --  FROM of_ventanilla_ins_abono_manual(rv, rd.idsucaux, rd.idproducto, rd.idauxiliar, 
          --                                      rofd.abono,rofd.interes_total+rofd.impuesto_total,rofd.interesmor_total+rofd.impuestoim_total,rofd.costos_asociados,
          --                                     'Abonos bancarios (aplicación a crédito)', NULL);

          -- No sé porqué no funcionó of_ventanilla_ins_abono_manual, full manual.
          INSERT INTO temporal (idusuario,sesion,idsucaux,idproducto,idauxiliar, 
                      idsucursal,idrol,idasociado,esentrada,capital, 
                      intord,icxa,intmor,impuesto,comision,esajuste,costos_asociados, 
                      referencia,idcuenta,multiplex)
              VALUES (_idusuario,pg_backend_pid,rd.idsucaux, rd.idproducto, rd.idauxiliar, 
                      rd.idsucursal, rd.idrol, rd.idasociado,TRUE,rofd.abono, 
                       rofd.interes_total+rofd.impuesto_total,0,rofd.interesmor_total+rofd.impuestoim_total,0,0,FALSE,rofd.costos_asociados, 
                      _tipoproc||' (aplicación a crédito)',    NULL,     NULL);

          SELECT INTO _abonot COALESCE(sum(capital)+sum(intord)+sum(intmor)+sum(costos_asociados),0.00) AS abono 
            FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT) AND esentrada=TRUE; 
          
          SELECT INTO _cargot COALESCE(sum(capital),0.00) AS cargo 
            FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT) AND esentrada=FALSE; 
          IF (_abonot<>_cargot) THEN
            _uuid :=  json_build_object('error','No se ha aplicado el abono al crédito por error de cuadre');            
            DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
            RETURN _uuid;  
          ELSE
            -- Aplicar la póliza
            SELECT INTO _pol of_temporal_apply(_idusuario::TEXT,pg_backend_pid::TEXT,
                                             _idsucursal,
                                             date(_fecha_oper),3,FALSE,FALSE,NULL);
                        
            IF (_pol IS NULL) THEN
              _uuid :=  json_build_object('error','Hubo un error al generar la póliza de aplicación al crédito');            
              DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
            ELSE
              SELECT INTO _kpoliza kpoliza 
                FROM polizas 
               WHERE (idsucpol,periodo,tipopol,idpoliza)=(_pol[1]::INTEGER,_pol[2]::INTEGER,_pol[3]::INTEGER,_pol[4]::INTEGER);
              UPDATE polizas SET concepto='Traspaso de saldo a favor ('||_tipoproc||') '||_fecha_oper||' pol: D-'||_pol[4]::INTEGER
               WHERE (idsucpol,periodo,tipopol,idpoliza)=(_pol[1]::INTEGER,_pol[2]::INTEGER,_pol[3]::INTEGER,_pol[4]::INTEGER);               
              DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
              _uuid :=  json_build_object('Ok','El movimiento de abono a crédito se aplicó correctamente',
                                          'poliza',_pol[1]::INTEGER||'-'||_pol[2]::INTEGER||'-'||_pol[3]::INTEGER||'-'||_pol[4]::INTEGER,
                                          'cliente',rd.idsucursal||'-'||rd.idrol||'-'||rd.idasociado,'cta_credito',cta_credito,
                                          'monto',_abonot,'_referencia',rd.referencia);

              --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('mensaje','Se ha generado la póliza: '||_pol[1]||'-'||_pol[2]||'-'||_pol[3]||'-'||_pol[4])::jsonb);
            END IF;   
          END IF; 
        ELSE  -- MENOR AL EXIGIBLE
          _restante := rsa.saldo;
          --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('resultado','Menor al exigible.','saldo fav',_restante)::jsonb);
          --RAISE NOTICE '---------------------------------------------11---%',_restante;
          INSERT INTO temporal (idusuario,sesion,idsucaux,idproducto,idauxiliar, 
                      idsucursal,idrol,idasociado,esentrada,capital, 
                      intord,icxa,intmor,impuesto,comision,esajuste, 
                      referencia,idcuenta,multiplex)
              VALUES (_idusuario,pg_backend_pid,rauxaf.idsucauxref,rauxaf.idproductoref,rauxaf.idauxiliarref, 
                      rd.idsucursal, rd.idrol, rd.idasociado,FALSE,rsa.saldo, 
                       0,   0,     0,       0,       0,FALSE, 
                      _tipoproc||' (aplicación a crédito)',    NULL,     NULL); 
          --SELECT INTO rtemp * FROM temporal ;
          --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('rtemp1',rtemp)::jsonb);
          --RETURN _uuid;          
          -- Nueva funcón de Prelación
          SELECT INTO rprel * FROM of_deudor_base_dist_pago_fs(rd.idsucaux, rd.idproducto, rd.idauxiliar, rsa.saldo); 
          --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('previo: ',_idusuario||','||pg_backend_pid||','||rd.idsucaux||','||rd.idproducto||','||rd.idauxiliar||','||
          --                   rd.idsucursal||','||rd.idrol||','||rd.idasociado||','||rprel.capital||','||
          --                   rprel.io||','||rprel.im||','||rprel.comision||','||_tipoproc)::jsonb);
          --RETURN _uuid;
          INSERT INTO temporal (idusuario,sesion,idsucaux,idproducto,idauxiliar, 
                      idsucursal,idrol,idasociado,esentrada,capital, 
                      intord,icxa,intmor,impuesto,comision,esajuste,costos_asociados, 
                      referencia,idcuenta,multiplex)
              VALUES (_idusuario::TEXT,pg_backend_pid::TEXT,rd.idsucaux, rd.idproducto, rd.idauxiliar, 
                      rd.idsucursal, rd.idrol, rd.idasociado,TRUE,rprel.capital, 
                       rprel.io,0,rprel.im,0,0,FALSE,rprel.comision, 
                      _tipoproc||' (aplicación a crédito)',    NULL,     NULL);                
          --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('previo despues: ',_idusuario||','||pg_backend_pid||','||rd.idsucaux||','||rd.idproducto||','||rd.idauxiliar||','||
          --                   rd.idsucursal||','||rd.idrol||','||rd.idasociado||','||rprel.capital||','||
          --                   rprel.io||','||rprel.im||','||rprel.comision||','||_tipoproc)::jsonb);
          --RETURN _uuid;                                    
          --SELECT INTO rtemp * FROM temporal where idproducto=3972;
          --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('rtemp',rtemp)::jsonb);
          --RETURN _uuid;
          IF (rprel.capital>rofd.abono) THEN
            --PERFORM of_notice(NULL,'error','Error: Problema al aplicar la poliza, credito '||rd.idsucaux||'-'||rd.idproducto||'-'||rd.idauxiliar);
            --RAISE EXCEPTION 'Error: Problema al aplicar la poliza';  
            --_uuid := jsonb_set(_uuid,ARRAY['Resultado'],json_build_object('Error','Hubo un problema de prelación. Póliza de abono a crédito no aplicada.')::jsonb);
            RETURN json_build_object('Error','Hubo un problema de prelación. Póliza de abono a crédito no aplicada.');            
            DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
          END IF;
              
          -- Revisar cuadre.
          SELECT INTO _abonot COALESCE(round(sum(capital)+sum(intord)+sum(intmor)+sum(costos_asociados),2),0.00) AS abono 
            FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT) AND esentrada=TRUE; 
          
          SELECT INTO _cargot COALESCE(round(sum(capital),2),0.00) AS cargo 
            FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT) AND esentrada=FALSE; 
          --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('cuadre',_abonot||' : '||_cargot)::jsonb);
          --RETURN _uuid;
          IF (_abonot<>_cargot) THEN
            RETURN json_build_object('error','No se ha aplicado el abono al crédito por error de cuadre..abono '||_abonot||' cargo '||_cargot);            
            DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
            RETURN _uuid;  
          ELSE
            --_uuid := json_build_object('msj','cuadra..abono '||_abonot||' cargo '||_cargot);            
            --RETURN _uuid;  
            -- Aplicar la póliza
            --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('datos antes poliza',_idusuario||'-'||pg_backend_pid||'-'||_idsucursal||'-'||_fecha_oper)::jsonb);
            --RETURN _uuid;
            --_fname := '/tmp/temporal2.csv';
            --c := 'COPY (SELECT * FROM temporal) TO ' || quote_literal(_fname);
            --EXECUTE c;
            --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('datos poliza',_abonot||' : '||_cargot)::jsonb);
            --RETURN _uuid;
            SELECT INTO _pol of_temporal_apply(_idusuario::TEXT,pg_backend_pid::TEXT,_idsucursal::INTEGER,date(_fecha_oper),3,FALSE,FALSE,NULL);
            --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('datos poliza','LLEGO AQUI')::jsonb);
            --RETURN _uuid;
            --_uuid := _uuid || json_build_object('error','POL'||_pol);            
            IF (_pol IS NULL) THEN
              RETURN json_build_object('error','Hubo un error al generar la póliza de aplicación al crédito cuando es menor al exigible');
              DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
            ELSE
              SELECT INTO _kpoliza kpoliza 
                FROM polizas 
               WHERE (idsucpol,periodo,tipopol,idpoliza)=(_pol[1]::INTEGER,_pol[2]::INTEGER,_pol[3]::INTEGER,_pol[4]::INTEGER);
              UPDATE polizas SET concepto='Traspaso de saldo a favor ('||_tipoproc||') '||_fecha_oper||' pol: D-'||_pol[4]::INTEGER
               WHERE (idsucpol,periodo,tipopol,idpoliza)=(_pol[1]::INTEGER,_pol[2]::INTEGER,_pol[3]::INTEGER,_pol[4]::INTEGER);               
              DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
              --PERFORM of_notice(NULL,'info','Se ha generado la póliza: '||_pol[1]||'-'||_pol[2]||'-'||_pol[3]||'-'||_pol[4]);
              --_mensaje := '"Se ha generado la póliza: "'||_pol[1]||'-'||_pol[2]||'-'||_pol[3]||'-'||_pol[4];
              DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
              RETURN json_build_object('Ok','El movimiento de abono a crédito se aplicó correctamente',
                                          'poliza',_pol[1]::INTEGER||'-'||_pol[2]::INTEGER||'-'||_pol[3]::INTEGER||'-'||_pol[4]::INTEGER,
                                          'cliente',rd.idsucursal||'-'||rd.idrol||'-'||rd.idasociado,'cta_credito',cta_credito,
                                          'monto',_abonot,'_referencia',rd.referencia);
              --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('mensaje','Se ha generado la póliza: '||_pol[1]||'-'||_pol[2]||'-'||_pol[3]||'-'||_pol[4])::jsonb);
            END IF;   
          END IF;
        END IF;  
      ELSE -- SDFO A FAVOR SIN SALDO
        DELETE FROM temporal WHERE (idusuario,sesion)=(_idusuario::TEXT,pg_backend_pid::TEXT);
        --_uuid := jsonb_set(_uuid, ARRAY['Alerta'],'"El auxiliar de saldo a favor no tenía saldo para aplicar el abono al crédito"'::JSONB, TRUE);
        _uuid :=  json_build_object('error','El auxiliar de saldo a favor no tenía saldo para aplicar el abono al crédito.');        
        RETURN _uuid;
      END IF;
    ELSE 
      _uuid :=  json_build_object('error','El crédito no cuenta con exigible a la fecha, el depósito quedó en saldo a favor.');
    END IF; -- Exigible mayor a cero   
  ELSE -- Ya no lo encuentra 
    --_uuid := jsonb_set(_uuid,ARRAY['resultado'],json_build_object('Alerta','El abono al crédito no se llevó a cabo debido a que no se encontró la referencia o ya no está activo')::jsonb);
    _uuid :=  json_build_object('error','Ya no se encontró el crédito activo.');
  END IF; -- Se encuentra en deudores.
  --_uuid := jsonb_set(_uuid, ARRAY['2do Ok'], '"mensaje de prueba"'::JSONB, TRUE);
    PERFORM of_param_sesion_unset('global','fecha');
 RETURN _uuid;          
END;$$
LANGUAGE plpgsql;  
