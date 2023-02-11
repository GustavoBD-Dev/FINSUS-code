-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: actualizar_concepto_poliza 
-- Actualizar concepto poliza
-- 17/11/2022

-- ----------------------------------------------------------------------------
-- 17/11/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'actualizar_concepto_poliza.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '17/11/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 17/11/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___ini ()
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

CREATE OR REPLACE FUNCTION actualizar_concepto_poliza (
    e_idsucpol  INTEGER,
    e_periodo   INTEGER,
    e_tipopol   INTEGER,
    e_idpoliza  INTEGER,
    e_concepto  TEXT
)
  RETURNS VOID AS $$

  BEGIN
    IF EXISTS ( SELECT concepto FROM polizas WHERE (idsucpol, periodo, tipopol, idpoliza) = (e_idsucpol, e_periodo, e_tipopol, e_idpoliza) ) THEN
      UPDATE polizas SET concepto = e_concepto
        WHERE (idsucpol, periodo, tipopol, idpoliza) = (e_idsucpol, e_periodo, e_tipopol, e_idpoliza);
      PERFORM of_ofx_notice('popup', 'ACTUALIZADO CORRECTAMENTE');
    ELSE
      PERFORM of_ofx_notice('popup', 'NO EXISTE REGISTRO!!!');
    END IF;
    RETURN;
  END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 17/11/2022 
-- Finalización
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 17/11/2022 
-- Validciones
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___val (p_variable TEXT, p_valor TEXT)
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
-- 17/11/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___on_click (p_button TEXT, p_data TEXT) 
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
-- 17/11/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 17/11/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION actualizar_concepto_poliza___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
