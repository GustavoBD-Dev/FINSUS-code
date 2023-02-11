
-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_fecha_activacion_prestamo_sus 
-- Fecha de activación del préstamo
-- 07/06/2016

-- ----------------------------------------------------------------------------
-- 07/06/2016 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
   -- Variables  
  _id       TEXT;
  _desc     TEXT;
  _fecha    TEXT;
  _version  TEXT := 'ofx_fecha_activacion_prestamo_sus.1';
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  _Id    := _Version |+ '.0'; -- CAQ
  _Desc  := 'Creación de tablas necesarias.';
  _Fecha := '09/12/2014';
  IF (of_updatedb_ofx(_Id,_Desc,_Fecha,md5(_id|+_Desc|+_Fecha))) THEN
    PERFORM * FROM information_schema.schemata WHERE schema_name = 'ofx_multicampos_sustentable';
    IF NOT FOUND THEN
      CREATE SCHEMA ofx_multicampos_sustentable;
      
      CREATE TABLE ofx_multicampos_sustentable.auxiliar_masdatos (
        Kauxiliar       INTEGER,
        Contrato_Gazel  BIGINT,
        IdConversion    INTEGER,
        IdUnidad        INTEGER,
        LitrosConsumo   NUMERIC,
        SegVida         NUMERIC,
        SegUnidad       NUMERIC,
        GPS             NUMERIC,
        SegVid_1        NUMERIC,
        SegUni_1        NUMERIC,
        GPS_1           NUMERIC,
        IdAgencia       INTEGER);
      
      CREATE TABLE ofx_multicampos_sustentable.conversiones (
        IdConversion  INTEGER,
        IdUnidad      INTEGER,
        Descripcion   TEXT, 
        Conversion_BX NUMERIC,
        Conversion    NUMERIC,
        NoCon         INTEGER);
      
      CREATE TABLE ofx_multicampos_sustentable.unidades (
        IdUnidad    INTEGER,
        Marca       TEXT,
        Descripcion TEXT,
        Enganche    NUMERIC,
        Vehículo    NUMERIC,
        Conversion  NUMERIC,
        Bancas      NUMERIC,
        Inst_GPS    NUMERIC,
        Litros      NUMERIC,
        NoCon       INTEGER);
      
      CREATE TABLE ofx_multicampos_sustentable.agencias (
        IdAgencia  INTEGER,
        Nombre     TEXT);
    END IF;
  END IF;
  -- 0 ------------------------------------------------------------------------
  -- --------------------------------------------------------------------------
  _id    := _version |+ '.1';
  _desc  := 'Activa validación fecha de activación de préstamo';
  _fecha := '10/06/2016';
  IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
    -- Activar validacion en la entrega del préstamo  
    PERFORM * 
       FROM signals 
      WHERE fx = 'of_sv_fecha_activacion_ptmo_finsus';
    IF NOT FOUND THEN
      INSERT INTO signals VALUES ('aperturas','bt_guardar','clicked','of_sv_fecha_activacion_ptmo_finsus',
                                  TRUE,'{idsucaux,idproducto,idauxiliar}',
                                  'Valida que se capture la fecha de activación del préstamo');
    END IF;
  END IF;
  -- 1 ------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  _id    := _version |+ '.2';
  _desc  := 'Triggers';
  _fecha := '10/06/2016';
  IF (of_updatedb_ofx(_id,_desc,_fecha,md5(_id|+_desc|+_fecha))) THEN
    PERFORM proname 
       FROM pg_proc 
      WHERE proname = 't_valores_anexos_datosprestamo';
    IF NOT FOUND THEN
      CREATE TRIGGER t_valores_anexos_datosprestamo
      BEFORE UPDATE OR DELETE ON valores_anexos
         FOR EACH ROW EXECUTE PROCEDURE t_valores_anexos_datosprestamo();
    END IF;
    --
    PERFORM proname 
       FROM pg_proc 
      WHERE proname = 't_multicampos_sustentable';
    IF NOT FOUND THEN
      CREATE TRIGGER t_multicampos_sustentable
      BEFORE UPDATE OR DELETE ON ofx_multicampos_sustentable.auxiliar_masdatos
         FOR EACH ROW EXECUTE PROCEDURE t_multicampos_sustentable();
    END IF;
  END IF;


  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 07/06/2016 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  _idsucaux           INTEGER := of_ofx_get('idsucaux');
  _idproducto         INTEGER := of_ofx_get('f_idproducto');
  _idauxiliar         INTEGER := of_ofx_get('idauxiliar');
  --
  rdat                RECORD;
  runid               RECORD;
  rconv               RECORD;
  rruta               RECORD;
  rroles              RECORD;
  _lista_agencias     TEXT;
  _lista_conversiones TEXT;
  _lista_unidades     TEXT;
  _lista_rutas        TEXT;
  sp_sus              TEXT;
  sp_bex              TEXT;
  _idroles            INTEGER;
  _id_ruta            INTEGER:=0;
  _count1             INTEGER:=0;

  _dv                     INTEGER; -- DGZZH Digito verificador
  _codigo                 TEXT;
  _referencia             TEXT;    -- Numero de referencia para acreditar depositos
  _puntos                 INTEGER:=0;


BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  --IF (NOT of_ofx_check_version('1.14.1')) THEN
  --  RETURN FALSE;
  --END IF;
  ----
  PERFORM of_ofx_notice('clear',NULL);
  -- JCGE 14/06/2016  Ajustamos la extension para no batallar al visualizar
  PERFORM of_ofx_set('window1','width=100%,height=85%');
  PERFORM of_ofx_set('e_idsucaux',  'set='||of_ofx_get('idsucaux'));
  PERFORM of_ofx_set('e_idproducto','set='||of_ofx_get('f_idproducto'));
  PERFORM of_ofx_set('e_idauxiliar','set='||of_ofx_get('idauxiliar'));
  PERFORM of_ofx_set('e_cgazel','focus=TRUE');
  PERFORM * 
     FROM deudores 
    WHERE (idsucaux,idproducto,idauxiliar)=(_idsucaux,_idproducto,_idauxiliar) AND of_producto_subtipo(_idproducto) = 'PRE';
  IF NOT FOUND THEN
    PERFORM of_ofx_notice('error','Favor de entrar con un producto de tipo prestamo');
    RETURN FALSE;
  END IF;
  --
  SELECT INTO rdat *
    FROM deudores
    LEFT JOIN ofx_multicampos_sustentable.auxiliar_masdatos USING (kauxiliar)
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucaux,_idproducto,_idauxiliar);

  ----
  IF (FOUND) THEN

    _codigo       := of_rellena(rdat.kauxiliar::TEXT,9,'0',2);
    _dv           := of_dv_gen(_codigo);
    _referencia   := _codigo |+ _dv;
    PERFORM of_ofx_set('e_refepago','set='||_referencia);  
    PERFORM of_ofx_set('e_cgazel','set='||rdat.contrato_gazel);  
    PERFORM of_ofx_set('e_litros','set='||rdat.litrosconsumo);
    PERFORM of_ofx_set('e_segvida','set='||rdat.segvida);
    PERFORM of_ofx_set('e_seguni','set='||rdat.segunidad);
    PERFORM of_ofx_set('e_gps','set='||rdat.gps);  

    PERFORM of_ofx_set('e_segvid_1','set='||rdat.segvid_1);
    PERFORM of_ofx_set('e_seguni_1','set='||rdat.seguni_1);
    PERFORM of_ofx_set('e_gps_1','set='||rdat.gps_1); 

    PERFORM of_ofx_set('e_intpand','set='||rdat.comision_id);
    PERFORM of_ofx_set('e_mescero','set='||rdat.com_id_cero);
    PERFORM of_ofx_set('e_idtotal','set='||rdat.total_id); 
    PERFORM of_ofx_set('e_mescero_gps','set='||rdat.gps_cero);
    PERFORM of_ofx_set('e_mescero_sv','set='||rdat.svi_cero);
    PERFORM of_ofx_set('e_mescero_su','set='||rdat.sun_cero);

    PERFORM of_ofx_set('e_vin','set='||rdat.vin);
    PERFORM of_ofx_set('e_numeco','set='||rdat.numeco);
    PERFORM of_ofx_set('e_polizaseg','set='||rdat.poliza_seg_auto); 

    IF (rdat.concobro) then
      PERFORM of_ofx_set('_mc_con_cobro','set=1');
    ELSE
      PERFORM of_ofx_set('_mc_con_cobro','set=0');
    END IF;
    
    SELECT INTO _lista_agencias translate(array_agg(replace(nombre,',',''))::TEXT,',"{}',';') 
      FROM (SELECT * 
              FROM ofx_multicampos_sustentable.agencias 
             ORDER BY idagencia) AS a;
    SELECT INTO _lista_unidades translate(array_agg(replace(descripcion,',',''))::TEXT,',"{}',';') 
      FROM ofx_multicampos_sustentable.unidades;
    SELECT INTO _lista_conversiones translate(array_agg(replace(descripcion,',',''))::TEXT,',"{}',';') 
      FROM ofx_multicampos_sustentable.conversiones;
    SELECT INTO runid * 
      FROM ofx_multicampos_sustentable.unidades 
     WHERE IdUnidad=rdat.IdUnidad;
    SELECT INTO rconv * 
      FROM ofx_multicampos_sustentable.conversiones 
     WHERE IdConversion=rdat.IdConversion;

    SELECT INTO _lista_rutas translate(array_agg(replace(nombre,',',''))::TEXT,',"{}',';') 
      FROM (SELECT * 
              FROM roles 
             ORDER BY nombre) AS a;
    _count1 := 0;
    FOR rroles IN SELECT * 
                    FROM roles
                ORDER BY nombre LOOP
      IF (rroles.idrol = rdat.id_ruta) THEN
        _id_ruta := _count1;
      END IF;
      _count1 := _count1 + 1;
    END LOOP;    

    PERFORM of_ofx_set('_mc_rutaorigen','list='||_lista_rutas||',set='||COALESCE(_id_ruta::TEXT,'0'));      
    PERFORM of_ofx_set('cb_agencias','list='||_lista_agencias||',set='||COALESCE(rdat.IdAgencia::TEXT,'0'));  
    PERFORM of_ofx_set('cb_unidades','list='||_lista_unidades||',set='||COALESCE((runid.NoCon - 1)::TEXT,'0'));  
    PERFORM of_ofx_set('cb_conversiones','list='||_lista_conversiones||',set='||COALESCE((rconv.NoCon - 1)::TEXT,'0'));  
    --
    sp_sus := of_multicampos_get('deudores','sobreprecio_sustentable',rdat.kauxiliar::TEXT,
              (of_multicampos_get('deudores','sobreprecio_sustentable',(_idsucaux||'-'||_idproducto||'-'||_idauxiliar)::TEXT,'0.00'))::TEXT);
    sp_bex := of_multicampos_get('deudores','sobreprecio_bexica',rdat.kauxiliar::TEXT,
              (of_multicampos_get('deudores','sobreprecio_bexica',(_idsucaux||'-'||_idproducto||'-'||_idauxiliar)::TEXT,'0.00'))::TEXT);
    PERFORM of_ofx_set('_mc_sobreprecio_sustentable','set='||sp_sus);
    PERFORM of_ofx_set('_mc_sobreprecio_bexica',     'set='||sp_bex);
    PERFORM of_ofx_set('_mc_fecha_desembolso',       'set='||of_multicampos_get('deudores', 'fecha_desembolso', rdat.kauxiliar::TEXT, hoy()::TEXT));
    PERFORM of_ofx_set('_mc_fecha_con_buro',         'set='||of_multicampos_get('deudores','fecha_con_buro',rdat.kauxiliar::TEXT,hoy()::TEXT));
    PERFORM of_ofx_set('_mc_folio_buro',             'set='||of_multicampos_get('deudores','folio_buro',rdat.kauxiliar::TEXT,''));
    PERFORM of_ofx_set('_mc_fuente_fondeo',          'set='||(of_numeric0(of_multicampos_get('deudores','fuente_fondeo',rdat.kauxiliar::TEXT,''))::INTEGER-1)::TEXT);
  ELSE
    SELECT INTO _lista_agencias translate(array_agg(replace(nombre,',',''))::TEXT,',"{}',';') 
      FROM (SELECT * 
              FROM ofx_multicampos_sustentable.agencias 
             ORDER BY idagencia) AS a;
    PERFORM of_ofx_set('cb_agencias','list='||_lista_agencias);  
    --
    SELECT INTO _lista_unidades translate(array_agg(replace(descripcion,',',''))::TEXT,',"{}',';') 
      FROM ofx_multicampos_sustentable.unidades;
    PERFORM of_ofx_set('cb_unidades','list='||_lista_unidades);  
    --
    SELECT INTO _lista_conversiones translate(array_agg(replace(descripcion,',',''))::TEXT,',"{}',';') 
      FROM ofx_multicampos_sustentable.conversiones;
    PERFORM of_ofx_set('cb_conversiones','list='||_lista_conversiones);  

    SELECT INTO _lista_rutas translate(array_agg(replace(nombre,',',''))::TEXT,',"{}',';') 
      FROM (SELECT * 
              FROM roles 
             ORDER BY nombre) AS a;
    _count1 := 0;
    _id_ruta := 0;
    FOR rroles IN SELECT * 
                    FROM roles
                ORDER BY nombre LOOP
      IF (rroles.idrol = 10) THEN
        _id_ruta := _count1;
      END IF;
      _count1 := _count1 + 1;
    END LOOP;    

    PERFORM of_ofx_set('_mc_rutaorigen','list='||_lista_rutas||',set='||COALESCE(_id_ruta::TEXT,'0'));      
    PERFORM of_ofx_set('e_mescero_gps','set='||'0');
    PERFORM of_ofx_set('e_mescero_sv','set='||'0');
    PERFORM of_ofx_set('e_mescero_su','set='||'0'); 

  END IF;
  -- CAQ 01/sep/2019
  PERFORM of_ofx_set('diasgraciaio','set='||of_multicampos_get('deudores','diasgraciaio',rdat.kauxiliar::TEXT,'0')::INTEGER);

  -- JCGE 09/02/2017: Buscamos el cat, si tan solo existiera un of_valores_anexos_get
  SELECT INTO rdat valor
    FROM valores_anexos
   WHERE (idtabla,idelemento,idcolumna) = ('deudores','CAT',_idsucaux||'-'||_idproducto||'-'||_idauxiliar);
  IF FOUND THEN
    PERFORM of_ofx_set('cat','set='||to_char(rdat.valor::NUMERIC,'FM999,999,990.00'));
  ELSE
    PERFORM of_ofx_set('cat','set=');
  END IF;
  -- JCGE Evitar que se ejecute __val() despues del __ini()
  PERFORM of_param_sesion_set('ofx_fecha_activacion_prestamo_sus','desactiva__val','TRUE');

  SELECT INTO rdat *
    FROM deudores
    LEFT JOIN ofx_multicampos_sustentable.auxiliar_masdatos USING (kauxiliar)
   WHERE (idsucaux,idproducto,idauxiliar)=(_idsucaux,_idproducto,_idauxiliar);

  SELECT INTO _puntos COALESCE(valor::NUMERIC,0.00)
    FROM valores_anexos
   WHERE idcolumna='_mc_tasa_interes_TIIE' AND idelemento=rdat.kauxiliar::TEXT AND idtabla='deudores';
   PERFORM of_ofx_set('e_puntos','set='||COALESCE(_puntos,0));
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 07/06/2016 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 07/06/2016 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  rcon                RECORD;
  run                 RECORD;
  rde                 RECORD;
  rdat                RECORD;
  rconv               RECORD;
  --
  _iduni              INTEGER;
  conta               INTEGER;
  ca                  INTEGER:=0; 
  _lista_conversiones TEXT;
  _lista_unidades     TEXT;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  IF (p_variable='cb_unidades') THEN
    SELECT INTO rde * 
      FROM deudores 
     WHERE (idsucaux,idproducto,idauxiliar)=(of_ofx_get('e_idsucaux')::INTEGER,of_ofx_get('e_idproducto')::INTEGER,of_ofx_get('e_idauxiliar')::INTEGER);
    --
    SELECT INTO rdat * 
      FROM ofx_multicampos_sustentable.auxiliar_masdatos 
     WHERE kauxiliar=rde.kauxiliar;
    --
    IF (NOT FOUND) THEN
      --PERFORM of_param_sesion_raise(NULL);
      SELECT INTO _iduni idunidad 
        FROM ofx_multicampos_sustentable.unidades 
       WHERE descripcion=p_valor;
      SELECT INTO conta count(*) 
        FROM ofx_multicampos_sustentable.conversiones 
       WHERE IdUnidad=_iduni;
      ca :=0;   
      FOR rcon IN SELECT * 
                    FROM ofx_multicampos_sustentable.conversiones
                   WHERE IdUnidad=_iduni ORDER BY IdConversion LOOP
        ca     := ca + 1;
        IF (ca=1) THEN 
          _lista_conversiones := rcon.Descripcion;
        ELSE
          _lista_conversiones := _lista_conversiones ||';'||rcon.Descripcion;
        END IF;
      END LOOP;
      IF (ca=0) THEN
        PERFORM of_ofx_set('cb_conversiones','list=ERROR,set=0');
        RETURN FALSE;
      ELSE
        PERFORM of_ofx_set('cb_conversiones','list='||_lista_conversiones||',set=0');  
      END IF;   
    ELSE
      SELECT INTO rconv * 
        FROM ofx_multicampos_sustentable.conversiones 
       WHERE IdConversion=rdat.IdConversion;
      PERFORM of_ofx_set('cb_conversiones','set='||rconv.NoCon);    
    END IF;
  END IF;
  --JCGE 25/01/2017: lista de validaciones de campos, con mensaje de error y con seguimiento al otro campo
  IF (p_variable = 'e_serie') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar numero de serie valido');
      PERFORM of_ofx_set('e_serie','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_motor','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_motor') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar numero de motor valido');
      PERFORM of_ofx_set('e_motor','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_cgazel') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar el numero de contrato');
      PERFORM of_ofx_set('e_cgazel','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_litros','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_litros') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar litros validos');
      PERFORM of_ofx_set('e_litros','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_segvida','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_segvida') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar seguro de vida valido');
      PERFORM of_ofx_set('e_segvida','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_seguni','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_seguni') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar seguro de unidad valido');
      PERFORM of_ofx_set('e_seguni','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_gps','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_gps') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar cargo gps valido');
      PERFORM of_ofx_set('e_gps','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_segvid_1','focus=TRUE');
    END IF;
  END IF;

  IF (p_variable = 'e_segvid_1') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar primer mes de seguro de vida valido');
      PERFORM of_ofx_set('e_segvid_1','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_seguni_1','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_seguni_1') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar primer mes de seguro de unidad valido');
      PERFORM of_ofx_set('e_seguni_1','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('e_gps_1','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'e_gps_1') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar cargo primer mes de gps valido');
      PERFORM of_ofx_set('e_gps_1','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('_mc_sobreprecio_sustentable','focus=TRUE');
    END IF;
  END IF;


  IF (p_variable = '_mc_sobreprecio_sustentable') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar sobre cargo sustentable valido');
      PERFORM of_ofx_set('_mc_sobreprecio_sustentable','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('_mc_sobreprecio_bexica','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = '_mc_sobreprecio_bexica') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar sobre cargo bexica valido');
      PERFORM of_ofx_set('_mc_sobreprecio_bexica','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('cat','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = 'cat') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar un cat valido');
      PERFORM of_ofx_set('cat','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('_mc_fecha_desembolso','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = '_mc_fecha_desembolso') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar fecha de desembolso valida');
      PERFORM of_ofx_set('_mc_fecha_desembolso','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('_mc_folio_buro','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = '_mc_folio_buro') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar folio de buro valido');
      PERFORM of_ofx_set('_mc_folio_buro','focus=TRUE');
    ELSE
      PERFORM of_ofx_set('_mc_fecha_con_buro','focus=TRUE');
    END IF;
  END IF;
  IF (p_variable = '_mc_fecha_con_buro') THEN
    IF (trim(p_valor) = '') THEN
      PERFORM of_ofx_notice('error','Favor de colocar folio de buro valido');
      PERFORM of_ofx_set('_mc_fecha_con_buro','focus=TRUE');
    END IF;
  END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 07/06/2016 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus___on_click (p_button TEXT, p_data TEXT) 
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
  _kauxiliar          INTEGER;
  _serie              TEXT    := of_ofx_get('e_serie')::TEXT;
  _motor              TEXT    := of_ofx_get('e_motor')::TEXT;
  _idsucaux           INTEGER := of_ofx_get('idsucaux');
  _idproducto         INTEGER := of_ofx_get('idproducto');
  _idauxiliar         INTEGER := of_ofx_get('idauxiliar');
  _kauxiliar_garantia INTEGER := of_kauxiliar(_idsucaux,_idproducto,_idauxiliar);
  idgar               TEXT[]  := of_ofx_get('tv_garantia_tv_row_info');
  _concobro           BOOLEAN;
  --
  rd                  RECORD;
  rag                 RECORD;
  runi                RECORD;
  rcon                RECORD;
  rrut                RECORD;
  rmas                RECORD;
  rde                 RECORD;
  rdat                RECORD;
  ragen               RECORD;
  runid               RECORD;
  rconv               RECORD;
  rcat                RECORD;
  sp_sus              TEXT;
  sp_bex              TEXT;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  IF (p_button = 'bt_guardar') THEN
    SELECT INTO rd * 
      FROM deudores 
     WHERE (idsucaux,idproducto,idauxiliar)=
            (of_ofx_get('e_idsucaux')::INTEGER,of_ofx_get('e_idproducto')::INTEGER,of_ofx_get('e_idauxiliar')::INTEGER);
    
    IF of_ofx_get('_mc_con_cobro') = '0' THEN
      _concobro = false;
    ELSE
      _concobro = true;
    END IF;

    IF (FOUND) THEN
      SELECT INTO rmas * 
        FROM ofx_multicampos_sustentable.auxiliar_masdatos 
       WHERE kauxiliar=rd.kauxiliar;
      IF (NOT FOUND) THEN
        SELECT INTO rag * 
          FROM ofx_multicampos_sustentable.agencias 
         WHERE replace(nombre,',','')=of_ofx_get('cb_agencias');
        SELECT INTO runi * 
          FROM ofx_multicampos_sustentable.unidades 
         WHERE descripcion=of_ofx_get('cb_unidades');
        SELECT INTO rcon * 
          FROM ofx_multicampos_sustentable.conversiones 
         WHERE descripcion=of_ofx_get('cb_conversiones');

        SELECT INTO rrut * 
          FROM roles 
         WHERE nombre=of_ofx_get('_mc_rutaorigen');

        --

--        INSERT INTO ofx_multicampos_sustentable.auxiliar_masdatos 
--          VALUES (rd.kauxiliar,of_ofx_get('e_cgazel'),rcon.IdConversion,runi.IdUnidad,of_ofx_get('e_litros')::NUMERIC,of_ofx_get('e_segvida')::NUMERIC,of_ofx_get('e_seguni')::NUMERIC,of_ofx_get('e_gps')::NUMERIC,rag.IdAgencia::INTEGER,
--          of_ofx_get('e_segvid_1')::NUMERIC,of_ofx_get('e_seguni_1')::NUMERIC,of_ofx_get('e_gps_1')::NUMERIC,of_ofx_get('_mc_con_cobro')::BOOLEAN);

        INSERT INTO ofx_multicampos_sustentable.auxiliar_masdatos 
          (kauxiliar,contrato_gazel,idconversion,idunidad,litrosconsumo,segvida,segunidad,gps,idagencia,
           segvid_1,seguni_1,gps_1,concobro,vin, numeco, poliza_seg_auto,vigencia_polsegauto,comision_id,com_id_cero,total_id,gps_cero,svi_cero,sun_cero, id_ruta )

    --,id_ruta        
            VALUES    (rd.kauxiliar,of_ofx_get('e_cgazel'),rcon.IdConversion,runi.IdUnidad, of_ofx_get('e_litros')::NUMERIC, of_ofx_get('e_segvida')::NUMERIC, of_ofx_get('e_seguni')::NUMERIC, of_ofx_get('e_gps')::NUMERIC, rag.IdAgencia::INTEGER, of_ofx_get('e_segvid_1')::NUMERIC, of_ofx_get('e_seguni_1')::NUMERIC, of_ofx_get('e_gps_1')::NUMERIC, of_ofx_get('_mc_con_cobro')::BOOLEAN, of_ofx_get('e_vin'),of_ofx_get('e_numeco'), of_ofx_get('e_polizaseg'), of_ofx_get('e_vigenciapol')::DATE, of_ofx_get('e_intpand')::NUMERIC, of_ofx_get('e_mescero')::INTEGER, of_ofx_get('e_idtotal')::NUMERIC,of_ofx_get('e_mescero_gps')::INTEGER, of_ofx_get('e_mescero_sv')::INTEGER, of_ofx_get('e_mescero_su')::INTEGER, rrut.idrol );
    --,rrut.idrol
        UPDATE deudores SET referencia=of_ofx_get('e_cgazel') WHERE kauxiliar=rd.kauxiliar;
        PERFORM of_ofx_notice('info','Se han guardado los datos correctamente.');
      ELSE
        SELECT INTO rag * 
          FROM ofx_multicampos_sustentable.agencias 
         WHERE replace(nombre,',','')=of_ofx_get('cb_agencias');
        SELECT INTO runi * 
          FROM ofx_multicampos_sustentable.unidades 
         WHERE descripcion=of_ofx_get('cb_unidades');
        SELECT INTO rcon * 
          FROM ofx_multicampos_sustentable.conversiones 
         WHERE descripcion=of_ofx_get('cb_conversiones');
        SELECT INTO rrut * 
          FROM roles 
         WHERE nombre=of_ofx_get('_mc_rutaorigen');

        --
        UPDATE ofx_multicampos_sustentable.auxiliar_masdatos 
          SET kauxiliar=rd.kauxiliar,contrato_gazel=of_ofx_get('e_cgazel'),
              idconversion=rcon.IdConversion,idunidad=runi.IdUnidad,
              litrosconsumo=of_ofx_get('e_litros')::NUMERIC,
              segvida=of_ofx_get('e_segvida')::NUMERIC,segunidad=of_ofx_get('e_seguni')::NUMERIC,
              gps=of_ofx_get('e_gps')::NUMERIC,idagencia=rag.IdAgencia::INTEGER,
              segvid_1=of_ofx_get('e_segvid_1')::NUMERIC,seguni_1=of_ofx_get('e_seguni_1')::NUMERIC,
              gps_1=of_ofx_get('e_gps_1')::NUMERIC,concobro = of_boolean(of_ofx_get('_mc_con_cobro')::TEXT,FALSE), vin=of_ofx_get('e_vin'), numeco=of_ofx_get('e_numeco'), poliza_seg_auto=of_ofx_get('e_polizaseg'), vigencia_polsegauto=of_ofx_get('e_vigenciapol')::DATE, comision_id = of_ofx_get('e_intpand')::NUMERIC, com_id_cero = of_ofx_get('e_mescero')::INTEGER, total_id = of_ofx_get('e_idtotal')::NUMERIC, gps_cero = of_ofx_get('e_mescero_gps')::INTEGER, svi_cero = of_ofx_get('e_mescero_sv')::INTEGER, sun_cero = of_ofx_get('e_mescero_su')::INTEGER, id_ruta = rrut.idrol::INTEGER
        WHERE kauxiliar=rd.kauxiliar;
        --
        UPDATE deudores 
           SET referencia=of_ofx_get('e_cgazel') 
         WHERE kauxiliar=rd.kauxiliar;
        PERFORM of_ofx_notice('info','Se han guardado los cambios correctamente.');
      END IF;
      --Multicampos de sobre precio
      PERFORM of_valores_anexos_update('deudores','_mc_sobreprecio_sustentable',rd.kauxiliar::TEXT,of_ofx_get('_mc_sobreprecio_sustentable'));
      PERFORM of_valores_anexos_update('deudores','_mc_sobreprecio_bexica',rd.kauxiliar::TEXT,of_ofx_get('_mc_sobreprecio_bexica'));
      PERFORM of_valores_anexos_update('deudores','_mc_fecha_desembolso',rd.kauxiliar::TEXT,of_ofx_get('_mc_fecha_desembolso'));
      PERFORM of_valores_anexos_update('deudores','_mc_folio_buro'      ,rd.kauxiliar::TEXT,of_ofx_escape(of_ofx_get('_mc_folio_buro'))); --
      PERFORM of_valores_anexos_update('deudores','_mc_fecha_con_buro'  ,rd.kauxiliar::TEXT,of_ofx_get('_mc_fecha_con_buro'));
      PERFORM of_valores_anexos_update('deudores','_mc_fuente_fondeo'   ,rd.kauxiliar::TEXT,(of_numeric0(of_ofx_get('_mc_fuente_fondeo_idx'))::INTEGER+1)::TEXT);
      -- JCGE 09/02/2017: El cat
      PERFORM of_valores_anexos_update('deudores', rd.idsucaux||'-'||rd.idproducto||'-'||rd.idauxiliar, 'CAT', of_numeric0(of_ofx_get('cat'))::TEXT);
      -- CAQ 01/sep/2019
      PERFORM of_valores_anexos_update('deudores','_mc_diasgraciaio',rd.kauxiliar::TEXT,of_ofx_get('diasgraciaio'));

      -- Puntos para sumar al tiie.
      PERFORM of_valores_anexos_update('deudores','_mc_tasa_interes_TIIE',rd.kauxiliar::TEXT,of_ofx_get('e_puntos')::TEXT);
      
    END IF;
  END IF;
  
  --  JCGE 16/06/2016 Vaciamos en valores anexos si es vehiculo y si no estan vacios los entrys
  IF (p_button = 'bt_agregar') THEN
    IF (_serie = '' OR _motor = '') THEN
      --raise notice'--------------------%',idgar[1];
      PERFORM of_ofx_notice('error','Complete los datos');
      RETURN 0;
    ELSE
      --raise notice'--------------------%',idgar[1];
      --raise notice'--------------------%',_kauxiliar_garantia;
      PERFORM of_valores_anexos_update ('deudores','_mc_num_serie',  _kauxiliar_garantia|| '-' ||idgar[1],_serie);
      PERFORM of_valores_anexos_update ('deudores','_mc_num_motor',  _kauxiliar_garantia|| '-' ||idgar[1],_motor);
      PERFORM of_ofx_set('bt_regresar','set=click');
      PERFORM of_ofx_notice('info','Se agrego correctamente');
    END IF;
  END IF;
  
  IF (p_button = 'bt_regresar') THEN
    PERFORM of_ofx_set('e_serie','set=');
    PERFORM of_ofx_set('e_motor','set=');
    PERFORM of_ofx_set('tv_garantia','sensitive=TRUE');  --treeview
    PERFORM of_ofx_set('vehiculo1','sensitive=FALSE');
  END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- DGZZH 08/06/2016
-- Validacion de fecha de activación
/*
 BEGIN; INSERT INTO signals VALUES ('aperturas','bt_guardar','clicked','of_sv_fecha_activacion_ptmo_finsus',
                                     TRUE,'{idsucaux,idproducto,idauxiliar}',
                                     'Valida que se capture la fecha de activación del préstamo');
*/    

CREATE OR REPLACE FUNCTION of_sv_fecha_activacion_ptmo_finsus(TEXT)
                   RETURNS of_signal_validate AS $$
DECLARE
  r              of_signal_validate%ROWTYPE;
  ps_idsucaux    INTEGER;
  ps_idproducto  INTEGER;
  ps_idauxiliar  INTEGER;
  _kauxiliar     INTEGER;
BEGIN
  --PERFORM of_param_sesion_raise(NULL);
  r.es_valido  := TRUE;
  r.msg_ok     := NULL;
  r.msg_err    := NULL;
  r.reasignar  := NULL;
  -- Obteniedo auxiliar del prestamo
  ps_idsucaux    := of_param_sesion_get_numeric('signal.aperturas','idsucaux');
  ps_idproducto  := of_param_sesion_get_numeric('signal.aperturas','idproducto');
  ps_idauxiliar  := of_param_sesion_get_numeric('signal.aperturas','idauxiliar');
  ps_idsucaux    := COALESCE(ps_idsucaux,of_param_sesion_get_numeric('signal.avisos','idsucaux'));
  ps_idproducto  := COALESCE(ps_idproducto,of_param_sesion_get_numeric('signal.avisos','idproducto'));
  ps_idauxiliar  := COALESCE(ps_idauxiliar,of_param_sesion_get_numeric('signal.avisos','idauxiliar'));
  
  SELECT INTO _kauxiliar kauxiliar
    FROM deudores
   WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
  IF (FOUND) THEN
    PERFORM valor
       FROM valores_anexos
      WHERE (idtabla,idcolumna,idelemento)=('deudores','_mc_fecha_desembolso',_kauxiliar::TEXT);
    IF (NOT FOUND) THEN
      r.es_valido  := FALSE;
      -- r.msg_err    := 'Por politica, es necesario capturar mas datos laborales';
      PERFORM of_ofx_set('___ofxrun','Mas datos del prestamo');
      RETURN r;
    END IF;
  END IF;
  RETURN r;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
--  JCGE 14/06/2016 Para seleccionar la garantia que queremos agregar 
--
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus___cursor_changed (p_widget TEXT, p_path TEXT, p_row_info TEXT[])
  RETURNS INTEGER AS $$
DECLARE
  -- Variables
  rva                        RECORD;
  _idsucaux                  INTEGER := of_ofx_get('idsucaux');
  _idproducto                INTEGER := of_ofx_get('idproducto');
  _idauxiliar                INTEGER := of_ofx_get('idauxiliar');
  _kauxiliar_garantia        INTEGER := of_kauxiliar(_idsucaux,_idproducto,_idauxiliar);
  idgar                      TEXT[]  := of_ofx_get('tv_garantia_tv_row_info');
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --  JCGE  14/07/2016  Utilizamos el cursor-changed para bloquear una parte de la extension para editar
  IF (p_widget = 'tv_garantia_tv') THEN
    --PERFORM of_ofx_notice('info','widget: '||p_widget||', path: '||p_path||', row_info:'||p_row_info::TEXT);
    PERFORM of_ofx_set('tv_garantia','sensitive=FALSE');
    PERFORM of_ofx_set('vehiculo1','sensitive=TRUE');
    --  JCGE 14/07/2016  Tambien buscamos si ya lo han editado anteriormente y lo mostramos
    FOR rva IN SELECT *
                 FROM valores_anexos
                WHERE (idtabla,idelemento) = ('deudores',_kauxiliar_garantia|| '-' ||idgar[1]) LOOP
      IF (rva.idcolumna = '_mc_num_serie') THEN
        PERFORM of_ofx_set('e_serie','set='||rva.valor);
      ELSIF (rva.idcolumna = '_mc_num_motor') THEN
        PERFORM of_ofx_set('e_motor','set='||rva.valor);
      END IF;
    END LOOP;
    PERFORM of_ofx_set('e_serie','focus=TRUE');
  END IF;
  RETURN 0;
END;$$
LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 14/06/2016 
-- Función principal
SELECT of_db_drop_type('ofx_fecha_activacion_prestamo_sus_garantias_rep','CASCADE');
CREATE TYPE ofx_fecha_activacion_prestamo_sus_garantias_rep AS (
  idgarantia     INTEGER,
  referencia     TEXT,
  valor          TEXT,
  idpropietario  TEXT,
  propietario    TEXT
);

CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus_garantias_rep() 
  RETURNS SETOF ofx_fecha_activacion_prestamo_sus_garantias_rep AS $$
DECLARE -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Variables
  r           ofx_fecha_activacion_prestamo_sus_garantias_rep%ROWTYPE;
  counter     INTEGER:=0;
  rt          RECORD;
  --
  _idsucaux   INTEGER := of_ofx_get('idsucaux');
  _idproducto INTEGER := of_ofx_get('idproducto');
  _idauxiliar INTEGER := of_ofx_get('idauxiliar');
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  FOR rt IN SELECT idgarantia AS idgar, referencia AS ref, valor AS val, idsucdir||'-'||iddir AS id
              FROM garantias
             WHERE (idsucaux, idproducto, idauxiliar) = (_idsucaux, _idproducto, _idauxiliar) AND NOT vivienda
             ORDER BY idgarantia LOOP
    r.idgarantia    := rt.idgar;
    r.referencia    := rt.ref;
    r.valor         := rt.val;
    r.idpropietario := rt.id;
    SELECT INTO r.propietario nombre||' '||paterno||' '||materno
      FROM directorio
     WHERE idsucdir||'-'||iddir = rt.id;
    RETURN NEXT r;
  END LOOP;
  RETURN;
END;$$
LANGUAGE plpgsql;


--  JCGE  15/07/2016  Treeview de el historial de movimientos
SELECT of_db_drop_type('ofx_fecha_activacion_prestamo_sus_datosprestamo','CASCADE');
CREATE TYPE ofx_fecha_activacion_prestamo_sus_datosprestamo AS (
  usuario            TEXT,
  fecha              DATE,
  fechareal          DATE,
  _data1             TEXT,
  _data2             TEXT
);

-------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ofx_fecha_activacion_prestamo_sus_datosprestamo () 
  RETURNS SETOF ofx_fecha_activacion_prestamo_sus_datosprestamo AS $$
DECLARE -- (c) Servicios de Informática Colegiada, S.A. de C.V.
  -- Variables
  r            ofx_fecha_activacion_prestamo_sus_datosprestamo%ROWTYPE;
  rh           RECORD;
  _kauxiliar   INTEGER := of_kauxiliar(of_ofx_get_integer('idsucaux'),of_ofx_get_integer('f_idproducto'),of_ofx_get_integer('idauxiliar'));
  lista        INTEGER;
BEGIN
  FOR rh IN SELECT *
              FROM oflog
              LEFT JOIN oflog_tipo AS tipo USING(id)
             WHERE modulo = 'aperturas' AND (tipo.tipo = 'mc_deudores_update' OR tipo.tipo = 'mas_datos_prestamo') AND (key LIKE _kauxiliar::TEXT||'_%' OR key = _kauxiliar::TEXT) LOOP
    lista := COALESCE(replace(split_part(array_dims(rh.data),':',2),']','')::int,0);
    -- Regresamos el tipo de manera que leemos todo lo que tenga el arreglo (rh.data)
    -- y lo regresamos como si fueran campos individuales, ya que son modificados por el mismo usuario el mismo dia
    FOR i IN 1..lista LOOP
      IF (i % 2 <> 0) THEN
        r._data1  := rh.data[i];      -- nombre del campo
      ELSE 
        r.usuario            := rh.idusuario;
        r.fecha              := rh.fecha_trabajo; -- fecha del sistema
        r.fechareal          := rh.fecha_real||'  '||rh.hora_real;
        r._data2  := rh.data[i];      -- valor del campo
        RETURN NEXT r;
      END IF;
    END LOOP;
  END LOOP;
  RETURN ;
END;$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION t_multicampos_sustentable() RETURNS TRIGGER AS $$
DECLARE
  --  Variables
  _data      TEXT[]:= '{}';  -- Esta var es para guardar los cambios
  _kauxiliar INTEGER := of_kauxiliar(of_ofx_get_integer('idsucaux'),     -- Este es el kauxiliar, identificador por credito
                                     of_ofx_get_integer('f_idproducto'),
                                     of_ofx_get_integer('idauxiliar'));
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    -- Tabla: ofx_multicampos_sustentable.auxiliar_masdatos, kauxiliar es la llave primaria de esta tabla
    IF (OLD.kauxiliar = _kauxiliar) THEN
      -- campo: contrato_gazel
      -- Validamos que no se paresca al anterior y que no sea nulo
      --raise notice '----------%--%',NEW,OLD;
      IF (NEW.contrato_gazel <> OLD.contrato_gazel AND NEW.contrato_gazel IS NOT NULL) THEN
        -- Lo almacenamos en esta var para luego insertarla en oflog por medio de la FX of_log_insert_data_key
        _data := _data + 'contrato_gazel' + OLD.contrato_gazel::TEXT;
      END IF;
      -- campo: IdAgencia
      IF (NEW.IdAgencia <> OLD.IdAgencia AND NEW.IdAgencia IS NOT NULL) THEN
        _data := _data + 'IdAgencia' + OLD.IdAgencia::TEXT;
      END IF;
      IF (NEW.IdUnidad <> OLD.IdUnidad AND NEW.IdUnidad IS NOT NULL) THEN
        _data := _data + 'IdUnidad' + OLD.IdUnidad::TEXT;
      END IF;
      IF (NEW.IdConversion <> OLD.IdConversion AND NEW.IdConversion IS NOT NULL) THEN
        _data := _data + 'IdConversion' + OLD.IdConversion::TEXT;
      END IF;
      IF (NEW.litrosconsumo <> OLD.litrosconsumo AND NEW.litrosconsumo IS NOT NULL) THEN
        _data := _data + 'litrosconsumo' + OLD.litrosconsumo::TEXT;
      END IF;
      IF (NEW.segvida <> OLD.segvida AND NEW.segvida IS NOT NULL) THEN
        _data := _data + 'segvida' + OLD.segvida::TEXT;
      END IF;
      IF (NEW.segunidad <> OLD.segunidad AND NEW.segunidad IS NOT NULL) THEN
        _data := _data + 'segunidad' + OLD.segunidad::TEXT;
      END IF;
      IF (NEW.gps <> OLD.gps AND NEW.gps IS NOT NULL) THEN
        _data := _data + 'gps' + OLD.gps::TEXT;
      END IF;
      IF (NEW.idagencia <> OLD.idagencia AND NEW.idagencia IS NOT NULL) THEN
        _data := _data + 'idagencia' + OLD.idagencia::TEXT;
      END IF;
      -- Si la variable de data es vacia la rechazamos
      IF (NOT array_eq(_data,'{}')) THEN
        PERFORM of_log_insert_data_key('mc_deudores_update',now()::DATE,NULL,'-',_data,_kauxiliar::TEXT);
      END IF;
      -- Return new significa retornar el nuevo
      RETURN new;
    END IF;
    -- Este return new significa que aunque se cumpla o no se cumplan las condiciones va a insertar el nuevo
    RETURN new;
  END IF;
  
  IF (TG_OP = 'INSERT') THEN 
    RETURN new;
  END IF;
  
  IF (TG_OP = 'DELETE') THEN
    IF (OLD.kauxiliar = _kauxiliar) THEN
      IF (NEW.contrato_gazel <> OLD.contrato_gazel AND NEW.contrato_gazel IS NOT NULL) THEN
        -- Lo almacenamos en esta var para luego insertarla en oflog por medio de la FX of_log_insert_data_key
        _data := _data + 'contrato_gazel' + OLD.contrato_gazel::TEXT;
      END IF;
      -- campo: IdAgencia
      IF (NEW.IdAgencia <> OLD.IdAgencia) THEN
        _data := _data + 'IdAgencia' + OLD.IdAgencia::TEXT;
      END IF;
      IF (NEW.IdUnidad <> OLD.IdUnidad) THEN
        _data := _data + 'IdUnidad' + OLD.IdUnidad::TEXT;
      END IF;
      IF (NEW.IdConversion <> OLD.IdConversion) THEN
        _data := _data + 'IdConversion' + OLD.IdConversion::TEXT;
      END IF;
      IF (NEW.litrosconsumo <> OLD.litrosconsumo) THEN
        _data := _data + 'litrosconsumo' + OLD.litrosconsumo::TEXT;
      END IF;
      IF (NEW.segvida <> OLD.segvida) THEN
        _data := _data + 'segvida' + OLD.segvida::TEXT;
      END IF;
      IF (NEW.segunidad <> OLD.segunidad) THEN
        _data := _data + 'segunidad' + OLD.segunidad::TEXT;
      END IF;
      IF (NEW.gps <> OLD.gps) THEN
        _data := _data + 'gps' + OLD.gps::TEXT;
      END IF;
      IF (NEW.idagencia <> OLD.idagencia) THEN
        _data := _data + 'idagencia' + OLD.idagencia::TEXT;
      END IF;
      --
      IF (NOT array_eq(_data,'{}')) THEN
        PERFORM of_log_insert_data_key('mc_deudores_update',now()::DATE,NULL,'-',_data,_kauxiliar::TEXT);
      END IF;
      RETURN old;
    END IF;
    RETURN old;
  END IF;
END;$$
LANGUAGE 'plpgsql';


----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION t_valores_anexos_datosprestamo() RETURNS TRIGGER AS $$
DECLARE
  --  Variables
  _data TEXT[]:= '{}';
  _kauxiliar       INTEGER := of_kauxiliar(of_ofx_get_integer('idsucaux'),of_ofx_get_integer('f_idproducto'),of_ofx_get_integer('idauxiliar'));
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    IF (OLD.idtabla = 'deudores') THEN
      IF (NEW.valor <> OLD.valor AND NEW.valor IS NOT NULL) THEN
        _data := _data + replace(new.idcolumna,'_mc_','') + OLD.valor;
      END IF;
      IF (NOT array_eq(_data,'{}')) THEN
        PERFORM of_log_insert_data_key('mas_datos_prestamo',now()::DATE,NULL,'-',_data,_kauxiliar::TEXT);
      END IF;
      RETURN new;
    END IF;
    RETURN new;
  END IF;
  
  IF (TG_OP = 'INSERT') THEN 
    RETURN new;
  END IF;
  
  IF (TG_OP = 'DELETE') THEN
    IF (OLD.idtabla = 'deudores') THEN
      _data := _data + replace(OLD.idcolumna,'_mc_','') + OLD.valor;
      IF (NOT array_eq(_data,'{}')) THEN
        PERFORM of_log_insert_data_key('mas_datos_prestamo',now()::DATE,NULL,'-',_data,_kauxiliar::TEXT);
      END IF;
      RETURN old;
    END IF;
    RETURN old;
  END IF;
END;$$
LANGUAGE 'plpgsql';
