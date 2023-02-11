-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_reporte_acreedores_pp 
-- Reporte acreedores por producto
-- 15/12/2022

-- ----------------------------------------------------------------------------
-- 15/12/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'ofx_reporte_acreedores_pp.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '15/12/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 15/12/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  --f     DATE := ofpsd('global','fecha',now()::DATE);
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  --IF (NOT of_ofx_check_version('1.14.1')) THEN
  --  RETURN FALSE;
  --END IF;
  
  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dum(f)::TEXT);
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;

SELECT of_db_drop_type('ofx_reporte_acreedores_pp','CASCADE');
CREATE TYPE ofx_reporte_acreedores_pp AS (
  -- CREDITO
  -- idsucaux  INTEGER,
  -- idproducto  INTEGER,
  -- idauxiliar  INTEGER,
  Credito     TEXT,
  -- CLIENTE
  -- idsucursal  INTEGER,
  -- idrol       INTEGER,
  -- idasociado  INTEGER,
  Cliente     TEXT,
  -- -- TASA 
  Tasa        TEXT,
  -- FECHA
  Fecha_activacion DATE,
  -- NOMBRE
  Nombre      TEXT,
  -- ESTATUS
  Estatus     TEXT
);

CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp ()
  RETURNS SETOF ofx_reporte_acreedores_pp AS $$
  DECLARE
    row_info  ofx_reporte_acreedores_pp%ROWTYPE;
    data_query  RECORD;
    DATE_INI  DATE := of_ofx_get('date_ini');
    DATE_FIN  DATE := of_ofx_get('date_fin');
    FILTER_PRODUCT  INTEGER:= of_ofx_get('filter_product');
  BEGIN 
    --PERFORM of_ofx_notice('info',DATE_INI || '-' || DATE_FIN || '-' || FILTER_PRODUCT);
    IF (DATE_FIN > now()) THEN
      PERFORM of_ofx_notice("popup", "La fecha final debe ser menor al dia de hoy");
    ELSE
      FOR data_query IN SELECT *, CASE WHEN estatus = 3 THEN 'ACTIVO' WHEN estatus = 4 THEN 'CANCELADO' END AS estatus_name FROM acreedores WHERE fechaape >= DATE_INI AND fechaape <= DATE_FIN AND idproducto = FILTER_PRODUCT LOOP
        row_info.Credito := data_query.idsucaux || '-' || data_query.idproducto || '-' || data_query.idauxiliar;
        row_info.Cliente := data_query.idsucursal || '-' || data_query.idrol || '-' || data_query.idasociado;
        row_info.tasa := to_char(data_query.tasa::NUMERIC, 'FM99.99');
        row_info.Fecha_activacion := data_query.fechaactivacion;
        row_info.Estatus  := data_query.estatus_name;
        SELECT INTO row_info.nombre paterno||' '||materno||' '||nombre FROM directorio WHERE iddir = (SELECT iddir FROM asociados WHERE (idsucursal,idrol,idasociado)=(data_query.idsucursal,data_query.idrol,data_query.idasociado));
        --PERFORM of_ofx_notice('info', row_info.nombre);
        RETURN NEXT row_info;
      END LOOP;
    END IF;
    RETURN;
  END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 15/12/2022 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 15/12/2022 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___val (p_variable TEXT, p_valor TEXT)
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
-- 15/12/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___on_click (p_button TEXT, p_data TEXT) 
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
-- 15/12/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 15/12/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION ofx_reporte_acreedores_pp___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
