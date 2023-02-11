-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: monto_por_cuenta 
-- Monto por cuenta
-- 04/01/2023

-- ----------------------------------------------------------------------------
-- 04/01/2023 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION monto_por_cuenta___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'monto_por_cuenta.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  --_id    := _version |+ '.0';
  --_desc  := '....';
  --_fecha := '04/01/2023';
  --IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
  --  
  --END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/01/2023 
-- Inicialización
CREATE OR REPLACE FUNCTION monto_por_cuenta___ini ()
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


SELECT of_db_drop_type('ofx_layout_monto_por_cuenta','CASCADE');
CREATE TYPE ofx_layout_monto_por_cuenta AS (
  cliente   TEXT,
  nombre    TEXT,
  cuenta    TEXT,
  fecha     DATE,
  hora      TIME,
  poliza    TEXT,
  cargo     TEXT,
  abono     TEXT
);

CREATE OR REPLACE FUNCTION monto_por_cuenta(var_periodo INTEGER, var_producto_max INTEGER, var_producto_min INTEGER)
  RETURNS SETOF ofx_layout_monto_por_cuenta AS $$
DECLARE
  r   ofx_layout_monto_por_cuenta%ROWTYPE;
BEGIN
  
  FOR r IN SELECT 
          idsucursal||'-'||idrol||'-'||idasociado as cliente,
          of_nombre_asociado(idsucursal,idrol,idasociado) as nombre, 
          idsucaux||'-'||idproducto||'-'||idauxiliar as cuenta,
          fecha,
          hora,
          idsucpol||'-'||periodo||'-'||tipopol||'-'||idpoliza as poliza,
          ( select  concepto 
              from  polizas p 
             where  (p.idsucpol,p.periodo,p.tipopol,p.idpoliza)=
                    (da.idsucpol,da.periodo,da.tipopol,da.idpoliza)) as concepto,
          cargo,
          abono
    from  deudores 
          inner join detalle_auxiliar da using(idsucaux,idproducto,idauxiliar) 
    where  idproducto between var_producto_min and var_producto_max 
          and estatus > 2
          and periodo = var_periodo 
          LOOP
    RETURN NEXT R;
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/01/2023 
-- Finalización
CREATE OR REPLACE FUNCTION monto_por_cuenta___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 04/01/2023 
-- Validciones
CREATE OR REPLACE FUNCTION monto_por_cuenta___val (p_variable TEXT, p_valor TEXT)
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
-- 04/01/2023 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION monto_por_cuenta___on_click (p_button TEXT, p_data TEXT) 
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
-- 04/01/2023
-- Es llamada cuando se selecciona un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION monto_por_cuenta___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
-- 04/01/2023
-- Es llamada cuando se da un "doble-click" a un renglón de un TreeView 
--CREATE OR REPLACE FUNCTION monto_por_cuenta___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
