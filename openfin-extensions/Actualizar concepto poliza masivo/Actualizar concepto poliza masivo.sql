-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: actualizar_concepto_poliza_masivo 
-- Enlazar cuentas 2001
-- 22/11/2022

-- ----------------------------------------------------------------------------
-- 22/11/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'actualizar_concepto_poliza_masivo.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '22/11/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 22/11/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___ini ()
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
  --PERFORM of_ofx_notice('popup','Recuerda guardar tus archivos como TXT delimitados por tabulaciones');
  PERFORM of_ofx_set('bt_aceptar','sensitive=FALSE');
  PERFORM of_ofx_set('bt_imprimir','sensitive=FALSE');
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;

SELECT of_db_drop_type('ofx_actualizar_concepto_poliza_masivo','CASCADE');
CREATE TYPE ofx_actualizar_concepto_poliza_masivo AS (
  idsucpol  INTEGER,
  periodo   INTEGER,
  tipopol   INTEGER,
  idpoliza  INTEGER,
  concepto  TEXT,
  estatus   TEXT
);

CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo()
  RETURNS SETOF ofx_actualizar_concepto_poliza_masivo AS $$
  DECLARE
    p             ofx_actualizar_concepto_poliza_masivo%ROWTYPE;
    rlin          RECORD;
    fname         TEXT:='vsr_vars_archivo';
    _arr          TEXT[];
  BEGIN

    p.idsucpol    := 0;
    p.periodo     := 0;
    p.tipopol     := 0;
    p.idpoliza    := 0;
    p.concepto    := '';
    p.estatus     := '';

    FOR rlin IN SELECT * FROM of_archivo_txt_read(fname) AS linea LOOP
      _arr := string_to_array(replace(rlin.linea,E'\r',','),',');
      p.idsucpol    :=  _arr[1]::INTEGER;
      p.periodo     :=  _arr[2]::INTEGER;
      p.tipopol     :=  _arr[3]::INTEGER;
      p.idpoliza    :=  _arr[4]::INTEGER;
      p.concepto    :=  _arr[5]::TEXT;

      IF EXISTS (
        SELECT * FROM polizas 
        WHERE (idsucpol, periodo, tipopol, idpoliza) = 
              (p.idsucpol, p.periodo, p.tipopol, p.idpoliza)
      ) THEN
        UPDATE polizas SET concepto = p.concepto
        WHERE (idsucpol, periodo, tipopol, idpoliza) = 
              (p.idsucpol, p.periodo, p.tipopol, p.idpoliza);
              p.estatus := 'ACTUALIZADO CORRECTAMENTE';
      ELSE
        p.estatus := 'NO SE ENCONTRO REGISTRO';
      END IF;
      RETURN NEXT p;
    END LOOP;
    RETURN;
  END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION ofx_load_data_polizas_txt()
  RETURNS SETOF ofx_actualizar_concepto_poliza_masivo AS $$
  DECLARE
    r       ofx_actualizar_concepto_poliza_masivo%ROWTYPE;
    rlin    RECORD;
    _arr    TEXT[];
    fname           TEXT:= 'vsr_vars_archivo';
  BEGIN
    r.idsucpol    := 0;
    r.periodo     := 0;
    r.tipopol     := 0;
    r.idpoliza    := 0;
    r.concepto    := '';
    r.estatus     := '';
    IF (of_ofx_get('archivo') IS NULL) THEN
      PERFORM of_ofx_notice('popup','No se ha seleccionado ningún archivo.');
    ELSE
      FOR rlin IN SELECT * FROM of_archivo_txt_read(fname) AS linea LOOP
        _arr := string_to_array(TRIM(replace(rlin.linea,E'\r',',')),',');
        r.idsucpol    := _arr[1];
        r.periodo     := _arr[2];
        r.tipopol     := _arr[3];
        r.idpoliza    := _arr[4];
        r.concepto    := _arr[5]::TEXT;
        r.estatus     := '';
        --PERFORM  of_ofx_notice('info', _arr::TEXT);
        RETURN NEXT r;
      END LOOP;
      PERFORM of_ofx_set('bt_aceptar','sensitive=TRUE');
    END IF;
  RETURN;
  END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 22/11/2022 
-- Finalización
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 22/11/2022 
-- Validciones
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___val (p_variable TEXT, p_valor TEXT)
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
-- 22/11/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___on_click (p_button TEXT, p_data TEXT) 
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
-- 22/11/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 22/11/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION actualizar_concepto_poliza_masivo___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
