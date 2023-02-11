
-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_reporte_cartera_exigible 
-- Cartera Exigible
-- 20/12/2021

-- ----------------------------------------------------------------------------
-- 20/12/2021 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'ofx_reporte_cartera_exigible.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '20/12/2021';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 20/12/2021 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  f     DATE;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  IF (NOT of_ofx_check_version('1.14.1')) THEN
    RETURN FALSE;
  END IF;
  PERFORM of_ofx_set('bt_ini','set=click');
  PERFORM of_ofx_set('window1','height=70%,width=90%');
  PERFORM of_ofx_notice('clear',NULL);
  f := ofpsd('global','fecha',now()::DATE);
  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dum(f)::TEXT);
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 20/12/2021 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 20/12/2021 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  IF (p_variable = 'fechacorte') THEN
    PERFORM of_ofx_notice('clear',NULL);
    PERFORM of_ofx_notice('warning','Se esta generando el calculo');
    PERFORM of_ofx_set('bt_actualizar','set=click');
  END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 20/12/2021 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___on_click (p_button TEXT, p_data TEXT) 
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  IF (p_button = 'bt_actualizar') THEN
    
  END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 20/12/2021
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 20/12/2021
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION ofx_reporte_cartera_exigible___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
