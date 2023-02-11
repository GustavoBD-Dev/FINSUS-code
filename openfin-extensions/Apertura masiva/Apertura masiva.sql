-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: apertura_masiva 
-- Apertura masiva
-- 14/12/2022

-- ----------------------------------------------------------------------------
-- 14/12/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION apertura_masiva___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'apertura_masiva.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '14/12/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 14/12/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION apertura_masiva___ini ()
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

SELECT of_db_drop_type('apertura_masiva','CASCADE');
CREATE TYPE apertura_masiva AS(
  idsucaux integer,
  idproducto integer,
  idsucursal integer,
  idrol integer,
  idasociado integer,
  fechaape date,
	fechaactivacion date,
  fechasdoini date,
  fechaultima date,
  ejapertura text,
  tasaio numeric,
  tasaiodesc numeric,
  tasaim numeric,
  plazo smallint,
	diasxplazo smallint,
  montosolicitado numeric,
  fechaprimerabono date
);

CREATE OR REPLACE FUNCTION ofx_load_data_txt_apertura()
  RETURNS SETOF apertura_masiva AS $$
  DECLARE
    row_info  apertura_masiva%ROWTYPE;
    rlin      RECORD;
    fname     TEXT:='vsr_vars_archivo';
    _arr      TEXT[];
  BEGIN
    IF (of_ofx_get('archivo') IS NULL ) THEN
      PERFORM of_ofx_notice('popup','No se ha seleccionado ningún archivo.');
    ELSE
      FOR rlin IN SELECT * FROM of_archivo_txt_read(fname) AS linea LOOP
        _arr  :=  string_to_array(TRIM(replace(rlin.linea,E'\r',',')),',');
        row_info.idsucaux         :=  _arr[1]::INTEGER;
        row_info.idproducto       :=  _arr[2]::INTEGER;
        row_info.idauxiliar       :=  _arr[3]::INTEGER;
        row_info.idrol            :=  _arr[4]::INTEGER;  
        row_info.idasociado       :=  _arr[5]::INTEGER;
        row_info.fechaape         :=  _arr[6]::DATE;
        row_info.fechaactivacion  :=  _arr[7]::DATE;
        row_info.fechasdoini      :=  _arr[8]::DATE;
        row_info.fechaultima      :=  _arr[9]::DATE;
        row_info.ejapertura       :=  _arr[10]::TEXT;
        row_info.tasaio           :=  _arr[11]::NUMERIC;
        row_info.tasaiodesc       :=  _arr[12]::NUMERIC;
        row_info.tasaim           :=  _arr[13]::NUMERIC;
        row_info.plazo            :=  _arr[14]::SMALLINT;
        row_info.diasxplazo       :=  _arr[15]::SMALLINT;
        row_info.montosolicitado  :=  _arr[16]::NUMERIC;
        -- Remove line break from last column
        row_info.fechaprimerabono  :=  replace(_arr[17],E'\n','')::DATE;
        RETURN NEXT row_info;
      END LOOP;
      PERFORM of_ofx_set('bt_aceptar','sensitive=TRUE');
    END IF;
    RETURN;
  END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 14/12/2022 
-- Finalización
CREATE OR REPLACE FUNCTION apertura_masiva___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 14/12/2022 
-- Validciones
CREATE OR REPLACE FUNCTION apertura_masiva___val (p_variable TEXT, p_valor TEXT)
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
-- 14/12/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION apertura_masiva___on_click (p_button TEXT, p_data TEXT) 
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
-- 14/12/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION apertura_masiva___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 14/12/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION apertura_masiva___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
