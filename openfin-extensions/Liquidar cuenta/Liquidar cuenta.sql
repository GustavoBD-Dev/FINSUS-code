-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: liquidar_cuenta 
-- Liquidar cuenta
-- 23/11/2022

-- ----------------------------------------------------------------------------
-- 23/11/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION liquidar_cuenta___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'liquidar_cuenta.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '23/11/2022';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 23/11/2022 
-- Inicialización
CREATE OR REPLACE FUNCTION liquidar_cuenta___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  --f     DATE := ofpsd('global','fecha',now()::DATE);
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  --IF (NOT of_ofx_check_version('1.14.1')) THEN
  --  RETURN FALSE;
  --END IF;
  
  PERFORM of_ofx_set('idsucaux1', 'set='||of_ofx_get('idsucaux'));
  PERFORM of_ofx_set('idproducto1', 'set='||of_ofx_get('idproducto'));
  PERFORM of_ofx_set('idauxiliar1', 'set='||of_ofx_get('idauxiliar'));

  --PERFORM of_ofx_set('de_fecha','set='||of_fecha_dpm(f)::TEXT);
  --PERFORM of_ofx_set('a_fecha','set='||of_fecha_dum(f)::TEXT);
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION liquidar_cuenta (idsucaux1 INTEGER, idproducto1 INTEGER, idauxiliar1 INTEGER)
  RETURNS VOID AS $$
  DECLARE 
    STATUS_CTA INTEGER;
    SALDO_CTA  INTEGER;
  BEGIN
    STATUS_CTA  := (SELECT estatus FROM deudores WHERE (idsucaux, idproducto, idauxiliar) = (idsucaux1, idproducto1, idauxiliar1));
    SALDO_CTA   := (SELECT saldo FROM deudores WHERE (idsucaux, idproducto, idauxiliar) = (idsucaux1, idproducto1, idauxiliar1));
    IF EXISTS (SELECT estatus FROM deudores WHERE (idsucaux, idproducto, idauxiliar) = (idsucaux1, idproducto1, idauxiliar1)) THEN
      IF (STATUS_CTA = 3 AND SALDO_CTA = 0) THEN
        UPDATE deudores SET estatus = 4
          WHERE (idsucaux, idproducto, idauxiliar) = (idsucaux1, idproducto1, idauxiliar1);
        PERFORM of_ofx_notice('popup', 'se ha liquidado a cuenta ' |+ idsucaux1::TEXT |+ '-' |+ idproducto1::TEXT |+ '-' |+ idauxiliar1::TEXT);
      ELSE
        PERFORM of_ofx_notice('popup', 'Verificar saldo y/o estatus');
      END IF;
    ELSE
        PERFORM of_ofx_notice('popup', 'No existe ' |+ idsucaux1::TEXT |+ '-' |+ idproducto1::TEXT |+ '-' |+ idauxiliar1::TEXT);
    END IF;
  END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 23/11/2022 
-- Finalización
CREATE OR REPLACE FUNCTION liquidar_cuenta___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 23/11/2022 
-- Validciones
CREATE OR REPLACE FUNCTION liquidar_cuenta___val (p_variable TEXT, p_valor TEXT)
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
-- 23/11/2022 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION liquidar_cuenta___on_click (p_button TEXT, p_data TEXT) 
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
-- 23/11/2022
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION liquidar_cuenta___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 23/11/2022
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION liquidar_cuenta___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
