-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: reporte_detalle_poliza 
-- Reporte Detalle Poliza
-- 25/11/2022

-- ----------------------------------------------------------------------------
-- 25/11/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION reporte_detalle_poliza___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'reporte_detalle_poliza.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '25/11/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/11/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION reporte_detalle_poliza___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  --f     DATE := ofpsd('global','fecha',now()::DATE);
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  --IF (NOT of_ofx_check_version('1.14.1')) THEN
  --  RETURN FALSE;
  --END IF;
  PERFORM of_ofx_set('bt_aceptar','sensitive=FALSE');
  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dum(f)::TEXT);
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;

SELECT of_db_drop_type('ofx_layout_rep_poliza','CASCADE');
CREATE TYPE ofx_layout_rep_poliza AS (
  idsucaux    INTEGER,
  idproducto  INTEGER,
  idauxiliar  INTEGER,
  idsucpol    INTEGER,
  periodo     INTEGER,
  tipopol     INTEGER,
  idpoliza    INTEGER,
  fecha       TEXT,
  hora        TEXT,
  cargo       TEXT,
  abono       TEXT,
  saldo       TEXT,
  referencia  TEXT,
  folio_ticket  INTEGER,
  secuencia     INTEGER
  );

CREATE OR REPLACE FUNCTION ofx_get_data_report_poliza (inputdate DATE)
 RETURNS SETOF ofx_layout_rep_poliza AS $$
  DECLARE
    row_info    ofx_layout_rep_poliza%ROWTYPE;
  BEGIN
    FOR row_info IN SELECT idsucaux,idproducto,idauxiliar,idsucpol,
      periodo,tipopol,idpoliza,fecha,hora,cargo,abono,saldo,referencia,
      folio_ticket,secuencia FROM detalle_auxiliar da
      WHERE fecha = inputdate ORDER BY fecha, hora LOOP
      --PERFORM of_ofx_notice('info',row_info::TEXT);
        row_info.cargo := to_char(row_info.cargo::NUMERIC,'FM999,999,990.90');
        row_info.abono := to_char(row_info.abono::NUMERIC,'FM999,999,990.90');
        row_info.saldo := to_char(row_info.saldo::NUMERIC,'FM999,999,990.90');
        row_info.hora := to_char(row_info.hora::TIME,'HH24:MI');
      RETURN NEXT row_info;
    END LOOP;
    PERFORM of_ofx_set('bt_aceptar','sensitive=TRUE');
    RETURN;
    
  END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/11/2022 
-- Finalización
CREATE OR REPLACE FUNCTION reporte_detalle_poliza___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/11/2022 
-- Validciones
CREATE OR REPLACE FUNCTION reporte_detalle_poliza___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 
  --IF (p_variable = 'mi_variable') THEN 
  --  x := of_ofx_get('mi_variable');
  --  y := of_ofx_get_integer('mi_integer');
  --  PERFORM of_ofx_notice('error','Este es un mensaje de error');
  --  RETURN FALSE;
  --END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 25/11/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION reporte_detalle_poliza___on_click (p_button TEXT, p_data TEXT) 
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
-- 25/11/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION reporte_detalle_poliza___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 25/11/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION reporte_detalle_poliza___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
