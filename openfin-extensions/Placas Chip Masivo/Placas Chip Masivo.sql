-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: placas_chip 
-- Placas Chip Masivo
-- 23/11/2022

-- ----------------------------------------------------------------------------
-- 23/11/2022 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION placas_chip___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'placas_chip.1';
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
CREATE OR REPLACE FUNCTION placas_chip___ini ()
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

SELECT of_db_drop_type('ofx_layout_cambio_placas_chip','CASCADE');
CREATE TYPE ofx_layout_cambio_placas_chip AS (
  idsucaux        INTEGER,
  idproducto      INTEGER,
  idauxiliar      INTEGER,
  contrato_gazel  TEXT,
  estatus          TEXT
);

CREATE OR REPLACE FUNCTION ofx_load_data_txt_placaschip ()
  RETURNS SETOF ofx_layout_cambio_placas_chip AS $$
  DECLARE
    layout    ofx_layout_cambio_placas_chip%ROWTYPE;
    rlin      RECORD;
    _arr      TEXT[];
    fname     TEXT := 'vsr_vars_archivo';
  BEGIN
    layout.idsucaux       :=  0;
    layout.idproducto     :=  0;
    layout.idauxiliar     :=  0;
    layout.contrato_gazel :=  '';
    layout.estatus        :=  '';
    IF (of_ofx_get('archivo') IS NULL) THEN
      PERFORM of_ofx_notice('popup','No se ha seleccionado ningún archivo.');
    ELSE
	    FOR rlin IN SELECT * FROM of_archivo_txt_read(fname) AS linea LOOP
	      _arr  :=  string_to_array(replace(rlin.linea,E'\r',','),',');
	      layout.idsucaux       :=  _arr[1]::INTEGER;
	      layout.idproducto     :=  _arr[2]::INTEGER;
	      layout.idauxiliar     :=  _arr[3]::INTEGER;
	      layout.contrato_gazel :=  _arr[4]::TEXT;
	      layout.estatus        :=  '';
	      RETURN NEXT layout;
	    END LOOP;
    END IF;
    PERFORM of_ofx_set('bt_aceptar','sensitive=TRUE');
    RETURN;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ofx_cambio_placas_chip ()
  RETURNS SETOF ofx_layout_cambio_placas_chip AS $$
  DECLARE 
    layout      ofx_layout_cambio_placas_chip%ROWTYPE;
    rlin        RECORD;
    _arr        TEXT[];
    fname       TEXT:='vsr_vars_archivo';
  BEGIN
    FOR rlin IN SELECT * FROM of_archivo_txt_read(fname) AS linea LOOP
      _arr  := string_to_array(TRIM(replace(rlin.linea,E'\r',',')),',');
      layout.idsucaux       :=  _arr[1]::INTEGER;
      layout.idproducto     :=  _arr[2]::INTEGER;
      layout.idauxiliar     :=  _arr[3]::INTEGER;
      layout.contrato_gazel :=  _arr[4]::TEXT;
      UPDATE ofx_multicampos_sustentable.auxiliar_masdatos
         SET contrato_gazel = layout.contrato_gazel
       WHERE kauxiliar = (SELECT kauxiliar FROM deudores WHERE
             (idsucaux,idproducto,idauxiliar)=(layout.idsucaux,layout.idproducto,layout.idauxiliar));
      UPDATE deudores
         SET referencia = (_arr[4]::TEXT)
       WHERE (idsucaux,idproducto,idauxiliar)=(layout.idsucaux,layout.idproducto,layout.idauxiliar);
      
      layout.estatus        :=  'ACTUALIZADO';
       
      RETURN NEXT layout;
    END LOOP;
    RETURN;
  END;
$$ LANGUAGE plpgsql;



-- ----------------------------------------------------------------------------
-- 23/11/2022 
-- Finalización
CREATE OR REPLACE FUNCTION placas_chip___fin ()
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
CREATE OR REPLACE FUNCTION placas_chip___val (p_variable TEXT, p_valor TEXT)
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
CREATE OR REPLACE FUNCTION placas_chip___on_click (p_button TEXT, p_data TEXT) 
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
--CREATE OR REPLACE FUNCTION placas_chip___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
--CREATE OR REPLACE FUNCTION placas_chip___row_activated (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
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
