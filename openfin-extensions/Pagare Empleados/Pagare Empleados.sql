-- ----------------------------------------------------------------------------
-- DGZZH 09/06/2016
-- Inicialización plan de pagos
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ofx_forma_pp_empleados_finsus___ini ()
                   RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  _continua         BOOLEAN:= TRUE;    --> Debe contituar?.
  ps_idpago         TEXT:= of_ofx_get('tv_planpago_2');
  _cuenta_bancaria  BOOLEAN:=FALSE;
  _kauxiliar        INTEGER;
BEGIN
  
  --PERFORM of_param_sesion_raise(null);
  -- Revisando versiones
  IF (NOT of_ofx_check_version('1.14.1')) THEN
    RETURN FALSE;
  END IF;
  -- Asignar los valores en los widget's.
  PERFORM of_ofx_set('idsucaux',  'set='|| of_ofx_get_integer('idsucaux'));
  PERFORM of_ofx_set('idproducto','set='|| of_ofx_get_integer('idproducto'));
  PERFORM of_ofx_set('idauxiliar','set='|| of_ofx_get_integer('idauxiliar'));
  PERFORM of_ofx_set('bt_aceptar','focus=true');
  PERFORM of_params_get('/socios/productos/prestamos','desplegar_cat','Despliega el calculo del CAT',
                      'Permite el desplegado del calculo del CAT al estar en TRUE','BOOLEAN','TRUE'); 
  -- Avales si es necesario
  PERFORM of_params_get('/formatos/ofx_pagare','appy_avales','Aplicar o mostrar avales',
                        'Activar este parametro si desea imprimir avales','BOOLEAN','FALSE');
  -- Limite de detalle
  PERFORM of_params_get('/formatos/ofx_pagare','limite_det','Limite de detalle',
                        'Limite o tope en lineas de detalle','INTEGER','60');
  PERFORM of_params_update('/formatos/ofx_pagare','fijos','ofx_forma_pp_empleados_finsus');
  
  --SELECT INTO _kauxiliar kauxiliar
  --  FROM deudores
  -- WHERE (idsucaux,idproducto,idauxiliar)=
  --       (of_ofx_get_integer('idsucaux'),
  --        of_ofx_get_integer('idproducto'),
  --        of_ofx_get_integer('idauxiliar'));
  --
  --PERFORM valor
  --   FROM valores_anexos
  --  WHERE (idtabla,idcolumna,idelemento)=('deudores','_mc_fecha_desembolso',_kauxiliar::TEXT);
  --IF (FOUND) THEN
  --  PERFORM of_ofx_notice('info','Generando plan de pagos...');
  --  RETURN TRUE;
  --ELSE
  --  PERFORM of_ofx_notice('error','No se ha definido una fecha de activación...');
  --  RETURN FALSE;
  --END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- Genera plan de pago a partir de los datos que están en el treeview 
-- del plan de pago de aperturas
-- ---------------------------------------------------------------------

SELECT of_db_drop_type('ofx_forma_pp_empleados_finsus_psesion','CASCADE');
CREATE TYPE ofx_forma_pp_empleados_finsus_psesion AS (
  idpago    TEXT,
  vence     TEXT,
  dt        TEXT,
  abono     TEXT,
  interes   TEXT,
  iva       TEXT,
  total     TEXT,
  saldo     TEXT,
  notas     TEXT
);

CREATE OR REPLACE FUNCTION ofx_forma_pp_empleados_finsus_psesion () 
RETURNS SETOF ofx_forma_pp_empleados_finsus_psesion AS $$
DECLARE
  --Parámetros
  
  -- Variables
  t            ofx_forma_pp_empleados_finsus_psesion%ROWTYPE;
  
  ps_ppidp     TEXT[];
  ps_ppvence   TEXT[];
  ps_ppdt      TEXT[];
  ps_ppabo     TEXT[];
  ps_ppint     TEXT[];
  ps_ppiva     TEXT[];
  ps_pptot     TEXT[];
  ps_ppsaldo   TEXT[];
  ps_ppnotas   TEXT[];
  nelem        INTEGER;
  _plazo       INTEGER:=of_ofx_get('plazo');
  
BEGIN
  --PERFORM of_param_sesion_raise(NULL);  
  
  t.idpago    :='';
  t.vence     :='';
  t.dt        :='';
  t.abono     :='';
  t.interes   :='';
  t.iva       :='';
  t.total     :='';
  t.saldo     :='';
  t.notas     :='';
    
  ps_ppidp     := of_ofx_get('tv_planpago_1')::TEXT[];
  ps_ppvence   := of_ofx_get('tv_planpago_2')::TEXT[];
  ps_ppabo     := of_ofx_get('tv_planpago_3')::TEXT[];
  ps_ppint     := of_ofx_get('tv_planpago_4')::TEXT[];
  ps_pptot     := of_ofx_get('tv_planpago_5')::TEXT[];
  ps_ppsaldo   := of_ofx_get('tv_planpago_6')::TEXT[];
  ps_ppdt      := of_ofx_get('tv_planpago_13')::TEXT[];
  ps_ppnotas   := of_ofx_get('tv_planpago_14')::TEXT[];
  ps_ppiva     := of_ofx_get('tv_planpago_17')::TEXT[];
  
  IF (nelem <> _plazo ) THEN
    nelem := nelem -1;
  ELSE
    nelem         := COALESCE(replace(split_part(array_dims(ps_ppvence),':',2),']','')::int,0); -- Cuantos elementos tiene el arreglo.
  END IF;

  FOR i IN 1..nelem LOOP
    t.idpago    := t.idpago  |+ ps_ppidp[i]::TEXT   |+ E'\n';
    t.vence     := t.vence   |+ ps_ppvence[i]::TEXT |+ E'\n';
    t.dt        := t.dt      |+ ps_ppdt[i]::TEXT    |+ E'\n';
    t.abono     := t.abono   |+ ps_ppabo[i]::TEXT   |+ E'\n';
    t.interes   := t.interes |+ ps_ppint[i]::TEXT   |+ E'\n';
    t.iva       := t.iva     |+ ps_ppiva[i]::TEXT   |+ E'\n';
    t.total     := t.total   |+ ps_pptot[i]::TEXT   |+ E'\n';
    t.saldo     := t.saldo   |+ ps_ppsaldo[i]::TEXT |+ E'\n';
    t.notas     := t.notas   |+ ps_ppnotas[i]::TEXT |+ E'\n';
    EXIT WHEN i = nelem-1::INTEGER; -- Salir cuando _infinito coincida con el numero de plazos.
  END LOOP;

  RETURN NEXT t;
RETURN ;
END;$$
LANGUAGE plpgsql;

-------------------------------------------------------------------------------
-- DGZZH (INICIO) 09/06/2016
-- Forma para gener el plan de pagos.
-------------------------------------------------------------------------------

SELECT of_db_drop_type('ofx_forma_pp_empleados_finsus','CASCADE');
CREATE TYPE ofx_forma_pp_empleados_finsus AS (
  -- Datos de La sucursal.
  suc_idsucursal     TEXT,
  nom_sucursal_matriz TEXT,
  nom_sucursal       TEXT,
  suc_calle          TEXT,
  suc_colonia        TEXT,
  suc_municipio      TEXT,
  suc_estado         TEXT,
  suc_rfc            TEXT,
  ------------------------
  idsucdir           INTEGER, -- Clave unica.
  iddir              INTEGER, -- Clave unica.
  idsucursal         INTEGER,
  idrol              INTEGER,
  idasociado         INTEGER,
  nombre_socio       TEXT,
  rfc                TEXT,
  idsucaux           INTEGER,
  idproducto         TEXT,
  idauxiliar         INTEGER,
  nombre_ptmo        TEXT,
  fech_apertura      DATE,  -- Fecha de apertura.
  fecha_entrega      DATE,
  fe_activacion      DATE,  -- Fecha de activacion en base a un Multicampo
  fecha_vence        TEXT,
  importeaut         TEXT,
  montoentregado     TEXT,
  plazo              TEXT,
  plazo_letras       TEXT,
  diasxplazo         TEXT,
  tasaio             TEXT,
  tasa_anual         TEXT,
  tasaim             TEXT,
  cat                TEXT,
  ptmo_referencia    TEXT, --Referencia en la resolución.
  seguro_vida        TEXT, -- Comision seguro de vida
  seguro_unidad      TEXT, -- Comision seguro de la unidad
  subtotal_seguro    TEXT, -- Suma de seguro de vida y seguro de unidad
  seguro_gps         TEXT, -- Seguro GPS
  -- DATOS DE AVALES ------
  aval_paterno       TEXT[],
  aval_materno       TEXT[],
  aval_nombre        TEXT[],
  aval_tfirma        TEXT[],
  aval_label_nom     TEXT[], --> Etiquete para el aval.
  -- DATOS DE OBLIGADOS ---
  obsol_paterno      TEXT[],
  obsol_materno      TEXT[],
  obsol_nombre       TEXT[],
  obsol_tfirma       TEXT[],
  obsol_label_nom    TEXT[], --> Etiqueta de nombre para el obligado.
  
  -- Detalle
  idserie            TEXT,
  venc               TEXT,
  dt                 TEXT,
  abono              TEXT,
  iopp               TEXT,
  iva                TEXT,
  pago               TEXT,
  saldo              TEXT,
  notas              TEXT,
  
  --Totales
  totabono           TEXT,
  totio              TEXT,
  totiva             TEXT,
  totpago            TEXT,  --Modificacion total de importe total
  msn_error          TEXT,
  ------------------------
  --     OTROS DATOS
  titulo             TEXT,  -- El título del formato.
  noconducef         TEXT,
  hoy                DATE,
  paginas            INTEGER,
  kv_multicampos     TEXT[],
  label_d_banco      TEXT,
  label_cuenta       TEXT,
  label_total        TEXT,
  kv_data            TEXT[], -- Mas datos externos.
  monto_letra        TEXT,
  direccion_asoc     TEXT,
  fe_operacion       DATE

);

CREATE OR REPLACE FUNCTION ofx_forma_pp_empleados_finsus()
                  RETURNS SETOF  ofx_forma_pp_empleados_finsus AS $$

DECLARE
  -- Variables
  t                       ofx_forma_pp_empleados_finsus%ROWTYPE;
  ra                      RECORD; --> Datos del asociado.
  rpp                     RECORD; --> Datos de las amortizaciones.
  rsuc                    RECORD; --> Datos de la sucursal.
  rav                     RECORD; --> Registro de avales.
  rav2                    RECORD; --> Datos generales del aval. 
  rdic                    RECORD; --> Direccion de asociado
  p_idsucaux              INTEGER:= 0;
  p_idproducto            INTEGER:= 0;
  p_idauxiliar            INTEGER:= 0;
  i                       INTEGER:= 0;  -- Contador.
  _totabono               NUMERIC:= 0.00;  -- Total del abono.
  _totinteres             NUMERIC:= 0.00;  -- Total del interes
  _totiva                 NUMERIC:= 0.00;  -- Total dei IVA.
  _totimporte             NUMERIC:= 0.00;
  _infinito               INTEGER:= 0;  -- El numero de vueltas que va a ser el ciclo.
  _limite                 INTEGER:= 0; -- Para no pasarnos del borde.
  ps_ppidp                TEXT[];
  _nelem                  INTEGER:=0;
  _cuenta_bancaria        BOOLEAN;
  _diasxtasa              INTEGER:=0;
  _refaux                 TEXT;
  _apply_aval             BOOLEAN:=of_params_get('/formatos/ofx_pagare','appy_avales'); -- Aplica avales?
  pg_monto_fijo_segvida   NUMERIC;
  pg_monto_fijo_segunidad NUMERIC;
  pg_monto_fijo_gps       NUMERIC;
  _tipoprestamo           INTEGER;
  _kauxiliar              INTEGER;
  _seguro_unidad          NUMERIC;
  _suguro_gps             NUMERIC;
  _calcula_iva            BOOLEAN;
  _x_municipio            BOOLEAN;
  factor_iva_io           NUMERIC;
  base_iva_io             NUMERIC;
  p_monto                 NUMERIC;
  p_plazo                 INTEGER;
  p_diasxplazo            INTEGER;
  p_interes               NUMERIC;
  p_fecha                 DATE ;
  p_fechaPA               DATE ; -- Fecha de primer abono
  _fecha_oper             DATE;
  _estatus                INTEGER;
  _saldo                    NUMERIC:=0.00;
  _var              ofx_forma_pp_empleados_finsus_psesion%ROWTYPE;
BEGIN
  
  --PERFORM of_param_sesion_raise(NULL);
  -- Inicializando variables.
  t.suc_idsucursal  := '';
  t.nom_sucursal_matriz  := '';
  t.nom_sucursal    := '';
  t.suc_calle       := '';
  t.suc_colonia     := '';
  t.suc_municipio   := '';
  t.suc_estado      := '';
  t.suc_rfc         := '';
  -----------------------
  t.idsucdir        := 0; -- Clave unica.
  t.iddir           := 0; -- Clave unica.
  t.idsucursal      := 0;
  t.idrol           := 0;
  t.idasociado      := 0;
  t.fech_apertura   := NULL;
  t.fecha_entrega   := NULL;
  t.fecha_vence     := '';
  t.plazo           := '';
  t.plazo_letras    := '';
  t.diasxplazo      := '';
  t.tasaio          := '';
  t.tasaim          := '';
  t.ptmo_referencia := '';
  t.montoentregado  := '';
  t.seguro_vida     := '';
  t.seguro_unidad   := '';
  t.subtotal_seguro := '';
  t.seguro_gps      := '';
  -- DATOS DE AVALES ------
  t.aval_paterno    := '{}';
  t.aval_materno    := '{}';
  t.aval_nombre     := '{}';
  t.aval_tfirma     := '{}';
  t.aval_label_nom  := '{}';
  -- Datos de obligados.
  t.obsol_paterno   := '{}';
  t.obsol_materno   := '{}';
  t.obsol_nombre    := '{}';
  t.obsol_tfirma    := '{}';
  t.obsol_label_nom := '{}';
  -- Detalle
  t.idserie         := '';
  t.venc            := '';
  t.dt              := '';
  t.abono           := '';
  t.iopp            := '';
  t.iva             := '';
  t.pago            := '';
  t.saldo           := '';
  t.notas           := '';
  -- Totales
  t.totabono        := '';
  t.totio           := '';
  t.totiva          := '';
  t.totpago         := '';
  t.msn_error       := '';
  t.hoy             := NULL;
  t.noconducef      := '';
  t.kv_multicampos  := '{}';
  t.label_total     := '';
  t.titulo          := '';
  ps_ppidp          := of_ofx_get('tv_planpago_2')::TEXT[];
  _nelem            := COALESCE(replace(split_part(array_dims(ps_ppidp),':',2),']','')::int,0);
  _nelem            := _nelem - 1;
  t.idsucursal      := of_ofx_get('idsucursal');
  t.idrol           := of_ofx_get('idrol');
  t.idasociado      := of_ofx_get('idasociado');
  t.nombre_socio    := of_ofx_get('nom_asoc');
  t.idsucaux        := of_ofx_get('idsucaux');
  t.idproducto      := of_ofx_get('idproducto');
  t.idauxiliar      := of_ofx_get('idauxiliar');
  _refaux           := COALESCE(t.idsucaux::TEXT,'')|+'-'|+
                       COALESCE(t.idproducto::TEXT,'')|+'-'|+
                       COALESCE(t.idauxiliar::TEXT,'');
  t.nombre_ptmo     := of_ofx_get('nom_prod');
  t.ptmo_referencia := of_ofx_get('referencia_cred');
  t.fecha_entrega   := COALESCE(of_ofx_get('fechaactivacion')::TEXT,of_param_sesion_get('global','fecha')::TEXT)::DATE;
  t.fech_apertura   := of_si(trim(of_ofx_get('fechaape')) = '',of_param_sesion_get('global','fecha')::TEXT,of_ofx_get('fechaape'))::DATE;
  t.importeaut      := of_ofx_get('montosolicitado');
  t.plazo           := of_ofx_get('Plazo');
  t.plazo_letras    := of_numero_letra(of_numeric(t.plazo),FALSE);
  t.diasxplazo      := of_ofx_get('diasxplazo');
  t.tasaio          := of_ofx_get('tasaio');
  t.tasa_anual      := (COALESCE(of_ofx_get('tasaio')::NUMERIC,0) * 12)::TEXT;
  t.tasaim          := of_ofx_get('tasaim');
  t.cat             := of_ofx_get('e_cat');
  t.hoy             := current_date;
  t.paginas         := 1;
  t.kv_multicampos  := of_multicampos_suc_array(99); --Multicampos de la sucursal matriz
  t.titulo          := of_params_get('/formatos/ofx_pagare','titulo');
  t.monto_letra     := '';
  t.direccion_asoc  := '';
  t.fe_operacion    := of_param_sesion_get('global','fecha');
  p_idproducto      := of_ofx_get('idproducto');
  p_monto           := of_ofx_get('montosolicitado');
  p_plazo           := of_ofx_get('Plazo');
  p_diasxplazo      := of_ofx_get('diasxplazo');
  p_interes         := of_ofx_get('tasaio');
  p_fechaPA         := of_si(trim(of_ofx_get('fechaprimerabono')) = '',t.fech_apertura::TEXT,of_ofx_get('fechaprimerabono'))::DATE;
  p_fecha           := NULL;
  _fecha_oper       := of_param_sesion_get('global','fecha');
  -- Datos del asociado.
  SELECT INTO ra idsucdir,iddir
    FROM asociados
   WHERE (idsucursal,idrol,idasociado)=(t.idsucursal,t.idrol,t.idasociado);

  -- Revisar los dias por tasa si se maneja mensual o anual.
  SELECT INTO _diasxtasa valor
    FROM params
   WHERE (idparam,idelemento)= ('/socios/productos/prestamos','dias por tasa');
  -- Mostrar los datos bancarios si es necerio.
  SELECT INTO _cuenta_bancaria *
    FROM of_params_get('/formatos/ofx_pagare','cuenta_bancaria');
  
  -- Limite de detalle.
  SELECT INTO _limite *
    FROM of_params_get('/formatos/ofx_pagare','limite_det');
  
    -- Obteniendo los datos de la Sucursal
  SELECT INTO rsuc idsucursal, s.nombre AS sucursal,
                   c.nombre|+ ' # ' |+ numext |+
                   of_si((numint IS NULL) OR (TRIM(numint)=''),'',' Int. '|+ numint) AS calle,
                   rfc, col.nombre AS colonia, col.cp, m.nombre AS municipio, e.nombre AS estado
    FROM sucursales AS s
   INNER JOIN calles AS c USING (idcalle)
   INNER JOIN colonias AS col   USING (idcolonia)
   INNER JOIN municipios AS m USING (idmunicipio)
   INNER JOIN estados AS e USING (idestado)
   WHERE idsucursal = of_param_sesion_get('global','sucursal')::INTEGER;
    
    t.suc_idsucursal          := rsuc.idsucursal;
    t.nom_sucursal            := rsuc.sucursal;
    t.suc_calle               := rsuc.calle;
    t.suc_colonia             := rsuc.colonia;
    t.suc_municipio           := initcap(rsuc.municipio);
    t.suc_estado              := initcap(rsuc.estado);
    t.suc_rfc                 := rsuc.rfc;
    
  SELECT INTO rdic cal.nombre    AS calle, 
                     d.numext    AS numext,
                     d.numint    AS numint,
                     col.nombre  AS colonia,
                     m.nombre    AS municipio,
                     e.nombre    AS estado,
                     col.cp      AS cp
    FROM asociados       AS a
    LEFT JOIN directorio AS d   USING (idsucdir,iddir)
    LEFT JOIN calles     AS cal USING (idcalle)
    LEFT JOIN colonias   AS col USING (idcolonia)
    LEFT JOIN municipios AS m   USING (idmunicipio)
    LEFT JOIN estados    AS e   USING (idestado)
   WHERE (idsucursal,idrol,idasociado)=(t.idsucursal,t.idrol,t.idasociado);
  
  t.direccion_asoc :=  'Calle '||     rdic.calle
                      || ', #' ||     rdic.numext
                      ||CASE WHEN trim(rdic.numint) IN (NULL,'0','') THEN '' ELSE ' #'||rdic.numint END
                      || ', Col ' ||  rdic.colonia
                      || ', ' ||      rdic.municipio
                      || ', ' ||      rdic.estado
                      || ', C.P. ' || rdic.cp;
    
  SELECT INTO t.montoentregado, _kauxiliar, _tipoprestamo,_estatus  montoentregado, kauxiliar, tipoprestamo,estatus
    FROM deudores
   WHERE (idsucaux,idproducto,idauxiliar)=(t.idsucaux::INTEGER,t.idproducto::INTEGER,t.idauxiliar::INTEGER);
  _saldo := of_numeric(t.montoentregado);
  _kauxiliar   := COALESCE(_kauxiliar,0);
  SELECT INTO p_fecha valor
    FROM valores_anexos
   WHERE (idtabla,idcolumna,idelemento)=('deudores','_mc_fecha_desembolso',_kauxiliar::TEXT);
   RAISE NOTICE 'FECHA DESEMBOLSO %',p_fecha;
  p_fecha          := COALESCE(p_fecha,t.fe_operacion);
  RAISE NOTICE 'FECHA DESEMBOLSO 2 %',p_fecha;
  t.fe_activacion  := p_fecha;
  t.monto_letra    := of_numero_letra(of_numeric(of_si(of_numeric(t.montoentregado) > 0,t.montoentregado,t.importeaut)));
  t.montoentregado := of_si(of_numeric(t.montoentregado) > 0,t.montoentregado,t.importeaut)::MONEY::TEXT;
  t.importeaut     := t.importeaut::MONEY::TEXT;
  _calcula_iva     := of_iva_general(t.idsucaux::INTEGER,t.idproducto::INTEGER,t.idauxiliar::INTEGER,_tipoprestamo,t.fe_operacion);
  factor_iva_io    := of_params_get('/socios/productos/prestamos','iva_io');
  base_iva_io      := of_params_get('/socios/productos/prestamos','base_iva_io');
  factor_iva_io    := ROUND((factor_iva_io /100.00),2);
  base_iva_io      := ROUND((base_iva_io /100.00),2);
  factor_iva_io    := factor_iva_io * base_iva_io;
  
  -- En dado caso el producto esté registrado ante conducef
  SELECT INTO t.noconducef *
    FROM of_params_get('/socios/productos/prestamos/'||t.idproducto,'conducef','Número de conducef',
                       'Número de registro ante conducef par este producto','TEXT','');
  
  --Datos del asociado.
  SELECT INTO t.rfc rfc
    FROM asociados
    LEFT JOIN directorio USING (idsucdir,iddir)
   WHERE (idsucursal,idrol,idasociado)=(t.idsucursal,t.idrol,t.idasociado);
  
  -- En dado caso el CAT se null. Buscamos!...
  IF (trim(t.cat) = '') THEN
    SELECT INTO t.cat valor::NUMERIC(12,2)
      FROM valores_anexos
     WHERE (idtabla,idcolumna,idelemento) = ('deudores',t.idsucaux::TEXT|+'-'|+t.idproducto::TEXT|+'-'|+t.idauxiliar::TEXT,'CAT');
  END IF;
  
  -- DGZZH 19/11/2014 Obteniendo los avales y obligados.
  IF (_apply_aval) THEN
    FOR rav IN SELECT * 
                 FROM referencias 
                WHERE (idsucdir,iddir)=(ra.idsucdir,ra.iddir) AND 
                      referencia  = _refaux AND 
                      (tiporef = 10 OR obligadosol)
                ORDER BY oid LOOP
      SELECT INTO rav2 paterno,materno,nombre
        FROM directorio
       WHERE (idsucdir,iddir)=(rav.idsucdirref,rav.iddirref);

      i  := i + 1;

      IF (rav.obligadosol) THEN -- Obligados
        t.obsol_paterno   := t.obsol_paterno + COALESCE(rav2.paterno,'');
        t.obsol_materno   := t.obsol_materno + COALESCE(rav2.materno,'');
        t.obsol_nombre    := t.obsol_nombre  + COALESCE(rav2.nombre,'');
        t.obsol_tfirma    := t.obsol_tfirma  + ('___________________________________________'||E'\n'||
                                                'OBLIGADO SOLIDARIO');
      ELSE                      -- Avales
        t.aval_paterno    := t.aval_paterno + COALESCE(rav2.paterno,'');
        t.aval_materno    := t.aval_materno + COALESCE(rav2.materno,'');
        t.aval_nombre     := t.aval_nombre  + COALESCE(rav2.nombre,'');
        t.aval_tfirma     := t.aval_tfirma  + ('____________________________________________'||E'\n'||
                                               'AVAL');
      END IF;
    END LOOP;
  END IF;
  SELECT INTO pg_monto_fijo_segvida   COALESCE(segvida  ,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  SELECT INTO pg_monto_fijo_segunidad COALESCE(segunidad,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  SELECT INTO pg_monto_fijo_gps       COALESCE(gps      ,0.00) FROM ofx_multicampos_sustentable.auxiliar_masdatos WHERE kauxiliar=_kauxiliar;
  i := 0;
  
  -- Levantar parámetros de sesión
  IF (of_ofx_get('rb_abono_capital')='TRUE') THEN
    PERFORM of_param_sesion_set('pp_psesion','ab_periodico_cap','TRUE');
  ELSE 
    PERFORM of_param_sesion_set('pp_psesion','ab_periodico_cap','FALSE');
  END IF;

  -- Ints sobre...
  IF (of_ofx_get('rb_int_sobre')='TRUE') THEN
    PERFORM of_param_sesion_set('pp_psesion','int_ssinsoluto','TRUE');
  ELSE 
    PERFORM of_param_sesion_set('pp_psesion','int_ssinsoluto','FALSE');
  END IF;
  
  PERFORM of_param_sesion_set('pp_psesion','fechapa',COALESCE(p_fecha,_fecha_oper)::TEXT);
  PERFORM of_param_sesion_set('pp_psesion','fecha',_fecha_oper::TEXT);
  PERFORM of_param_sesion_set('pp_psesion','pagosfijos',of_ofx_get('cb_pagosfijos'));
  PERFORM of_param_sesion_set('pp_psesion','diasxplazo',p_diasxplazo::TEXT);
  PERFORM of_param_sesion_set('pp_psesion','tasaim',of_ofx_get('tasaim'));
  PERFORM of_param_sesion_set('pp_psesion','tipoprestamo',of_ofx_get('cb_tipoprestamo_idx')::TEXT); 
  PERFORM of_param_sesion_set('pp_sesion','0',p_plazo||'~^~'||p_monto||'~^~'); 
PERFORM of_param_sesion_raise(NULL);

  -- Detalle de amortizaciones.
  --IF (of_ofx_get('tv_planpago_2') <> '{}') THEN
  IF (_estatus=3) THEN
    FOR rpp IN SELECT * 
                 FROM planpago
                WHERE (idsucaux,idproducto,idauxiliar)=
                      (of_ofx_get('idsucaux')::INTEGER,of_ofx_get('idproducto')::INTEGER,of_ofx_get('idauxiliar')::INTEGER) 
                      ORDER BY idpago LOOP
    IF (rpp.idpago>=2) THEN
      _saldo := _saldo - rpp.abono;
    END IF;
    --FOR rpp IN SELECT *
    --             FROM of_plan_amortizacion(p_idproducto,p_monto,p_plazo,p_diasxplazo,p_interes,COALESCE(p_fecha,current_date),p_fechaPA) LOOP

      EXIT WHEN _infinito = t.plazo::INTEGER; -- Salir cuando _infinito coincida con el numero de plazos.
      i  := i + 1;
      --RAISE NOTICE 'DIAS transcurridos %',rpp.dt;
      IF (i = 1) THEN -- En el primer pago el monto es proporcional a los días transcurridos.
        t.seguro_vida   := COALESCE(trunc(((pg_monto_fijo_segvida / 30) * (rpp.vence - p_fecha::DATE)::INTEGER),2),0.00); -- Sin iva
        _seguro_unidad  := COALESCE(trunc(((pg_monto_fijo_segunidad / 30) * (rpp.vence - p_fecha::DATE)::INTEGER),2),0.00);
        _suguro_gps     := COALESCE(trunc(((pg_monto_fijo_gps / 30) * (rpp.vence - p_fecha::DATE)::INTEGER),2),0.00);
      ELSE
        t.seguro_vida   := COALESCE(trunc(pg_monto_fijo_segvida,2),0.00);
        _seguro_unidad  := COALESCE(trunc(pg_monto_fijo_segunidad,2),0.00);
        _suguro_gps     := COALESCE(trunc(pg_monto_fijo_gps,2),0.00);
      END IF;
      _seguro_unidad    :=  of_si(TRUE,_seguro_unidad * (factor_iva_io) + _seguro_unidad, _seguro_unidad);
      _suguro_gps       :=  of_si(TRUE,_suguro_gps * (factor_iva_io) + _suguro_gps, _suguro_gps);
      _infinito         := _infinito + 1;
      t.idserie         := t.idserie |+ i::TEXT |+ E'\n';
      t.venc            := t.venc   |+ rpp.vence::TEXT |+ E'\n';
      t.dt              := t.dt    |+ (rpp.vence - p_fecha::DATE)::INTEGER    |+ E'\n';
      t.abono           := t.abono |+ to_char(rpp.abono,'FM999,999,990.00') |+ E'\n';
      t.iopp            := t.iopp  |+ to_char(rpp.io,'FM999,999,990.00')  |+ E'\n';
      IF (_calcula_iva) THEN
        t.iva             := t.iva   |+ to_char(rpp.io*factor_iva_io,'FM999,999,990.00')   |+ E'\n';
      ELSE
        t.iva             := t.iva   |+ to_char(0.00,'FM999,999,990.00')   |+ E'\n';
      END IF;
      t.saldo           := t.saldo |+ to_char(_saldo,'FM999,999,990.00') |+ E'\n';
      t.subtotal_seguro := t.subtotal_seguro |+ to_char(of_numeric(t.seguro_vida) + _seguro_unidad,'FM999,999,990.00') |+ E'\n';
      t.seguro_gps      := t.seguro_gps      |+ to_char(_suguro_gps,'FM999,999,990.00') |+ E'\n';
      t.pago            := t.pago  |+ to_char(rpp.abono+rpp.io + of_si(_calcula_iva,rpp.io*factor_iva_io,0.00)::NUMERIC + of_numeric(t.seguro_vida) + _seguro_unidad + _suguro_gps,'FM999,999,990.00')   |+ E'\n';
      t.notas           := t.notas |+ substring('',0,30) |+ E'\n';
      
      -- Sumando las filas de cada columna para obtener el total.
      -- Guardar primero en una variable para no mostrar el resultado.
      _totabono      := _totabono   + COALESCE(rpp.abono,0);
      _totinteres    := _totinteres + COALESCE(rpp.io,0);
      _totiva        := _totiva     + 0.00;--COALESCE(rpp.iva,0);
      _totimporte    := _totimporte + rpp.abono+rpp.io + of_numeric(t.seguro_vida) + _seguro_unidad + _suguro_gps;--COALESCE(rpp.total,0);
      IF (i = t.plazo::INTEGER) THEN
        t.label_total  := 'TOTALES';
        t.totabono     := _totabono::TEXT::MONEY::TEXT;  --Mostrar el resultado de totales.
        t.totio        := _totinteres::TEXT::MONEY::TEXT;
        t.totiva       := _totiva::TEXT::MONEY::TEXT;
        t.totpago      := _totimporte::TEXT::MONEY::TEXT;
      END IF;
        
      IF (_infinito = _limite) THEN -- Mostrar el resultado si se ha llenado la hoja
      RAISE NOTICE 'AQUI';
        RETURN NEXT t;
        t.idserie    := '';
        t.venc       := '';
        t.dt         := '';
        t.abono      := '';
        t.iopp       := '';
        t.iva        := '';
        t.pago       := '';
        t.saldo      := '';
        t.notas      := '';
        t.totabono   := '';
        t.totio      := '';
        t.totiva     := '';
        t.totpago    := '';
        t.paginas    := t.paginas + 1; -- Numero de páginas
        --_limite      := _limite + 45;  -- Le sumamos otros 40 para no salirnos del borde.
        _infinito    := 0;
      ELSIF (i = t.plazo::INTEGER) THEN
      RAISE NOTICE 'AQUI 2';
        RETURN NEXT t;
      END IF;
    END LOOP;
  ELSE
    
    
    FOR rpp IN SELECT * FROM 
                --of_plan_amortizacion_psesion(p_idproducto::INTEGER,p_diasxplazo::INTEGER,of_ofx_get('tasaio')::NUMERIC,p_fecha,of_fecha_dum(p_fecha)) LOOP
      
      
      of_plan_amortizacion_psesion(p_idproducto::INTEGER,p_diasxplazo::INTEGER,of_ofx_get('tasaio')::NUMERIC,p_fecha,p_fechaPA) LOOP

      --PERFORM of_ofx_notice('info', '-' || ps_ppidp[i]::TEXT || ' : ' || i || 't.VENCE: ' || t.venc::TEXT);

    --FOR rpp IN SELECT *
    --             FROM of_plan_amortizacion(p_idproducto,p_monto,p_plazo,p_diasxplazo,p_interes,COALESCE(p_fecha,current_date),p_fechaPA) LOOP

      EXIT WHEN _infinito = t.plazo::INTEGER; -- Salir cuando _infinito coincida con el numero de plazos.
      i  := i + 1;
      RAISE NOTICE 'DIAS transcurridos %',rpp.dt;
      IF (i = 1) THEN -- En el primer pago el monto es proporcional a los días transcurridos.
        t.seguro_vida   := COALESCE(trunc(((pg_monto_fijo_segvida / 30) * rpp.dt::INTEGER),2),0.00); -- Sin iva
        _seguro_unidad  := COALESCE(trunc(((pg_monto_fijo_segunidad / 30) * rpp.dt::INTEGER),2),0.00);
        _suguro_gps     := COALESCE(trunc(((pg_monto_fijo_gps / 30) * rpp.dt::INTEGER),2),0.00);
      ELSE
        t.seguro_vida   := COALESCE(trunc(pg_monto_fijo_segvida,2),0.00);
        _seguro_unidad  := COALESCE(trunc(pg_monto_fijo_segunidad,2),0.00);
        _suguro_gps     := COALESCE(trunc(pg_monto_fijo_gps,2),0.00);
      END IF;
      _seguro_unidad    :=  of_si(TRUE,_seguro_unidad * (factor_iva_io) + _seguro_unidad, _seguro_unidad);
      _suguro_gps       :=  of_si(TRUE,_suguro_gps * (factor_iva_io) + _suguro_gps, _suguro_gps);
      _infinito         := _infinito + 1;
      t.idserie         := t.idserie |+ i::TEXT |+ E'\n';
      t.venc            := t.venc   |+ rpp.fecha::TEXT |+ E'\n';
      --PERFORM of_ofx_notice('info', i::TEXT || ' - ' || ps_ppidp[i]::TEXT || ' : ' || t.venc::TEXT);
      SELECT INTO t.venc vence FROM ofx_forma_pp_empleados_finsus_psesion(); 


      t.dt              := t.dt    |+ rpp.dt::TEXT    |+ E'\n';
      t.abono           := t.abono |+ to_char(rpp.abono,'FM999,999,990.00') |+ E'\n';
      t.iopp            := t.iopp  |+ to_char(rpp.interes,'FM999,999,990.00')  |+ E'\n';
      t.iva             := t.iva   |+ to_char(rpp.iva,'FM999,999,990.00')   |+ E'\n';
      t.saldo           := t.saldo |+ to_char(rpp.saldo,'FM999,999,990.00') |+ E'\n';
      t.subtotal_seguro := t.subtotal_seguro |+ to_char(of_numeric(t.seguro_vida) + _seguro_unidad,'FM999,999,990.00') |+ E'\n';
      t.seguro_gps      := t.seguro_gps      |+ to_char(_suguro_gps,'FM999,999,990.00') |+ E'\n';
      t.pago            := t.pago  |+ to_char(rpp.abono+rpp.interes+rpp.iva+of_numeric(t.seguro_vida)+_seguro_unidad+_suguro_gps,'FM999,999,990.00')   |+ E'\n';
      t.notas           := t.notas |+ substring(rpp.notas,0,30) |+ E'\n';
      
      -- Sumando las filas de cada columna para obtener el total.
      -- Guardar primero en una variable para no mostrar el resultado.
      _totabono      := _totabono   + COALESCE(rpp.abono,0);
      _totinteres    := _totinteres + COALESCE(rpp.interes,0);
      _totiva        := _totiva     + COALESCE(rpp.iva,0);
      _totimporte    := _totimporte + COALESCE(rpp.total,0);
      IF (i = t.plazo::INTEGER) THEN
        t.label_total  := 'TOTALES';
        t.totabono     := _totabono::TEXT::MONEY::TEXT;  --Mostrar el resultado de totales.
        t.totio        := _totinteres::TEXT::MONEY::TEXT;
        t.totiva       := _totiva::TEXT::MONEY::TEXT;
        t.totpago      := _totimporte::TEXT::MONEY::TEXT;
      END IF;
        
      IF (_infinito = _limite) THEN -- Mostrar el resultado si se ha llenado la hoja
      RAISE NOTICE 'AQUI';
        RETURN NEXT t;
        t.idserie    := '';
        t.venc       := '';
        t.dt         := '';
        t.abono      := '';
        t.iopp       := '';
        t.iva        := '';
        t.pago       := '';
        t.saldo      := '';
        t.notas      := '';
        t.totabono   := '';
        t.totio      := '';
        t.totiva     := '';
        t.totpago    := '';
        t.paginas    := t.paginas + 1; -- Numero de páginas
        --_limite      := _limite + 45;  -- Le sumamos otros 40 para no salirnos del borde.
        _infinito    := 0;
      ELSIF (i = t.plazo::INTEGER) THEN
      RAISE NOTICE 'AQUI 2';
        RETURN NEXT t;
      END IF;
    END LOOP;
  END IF;
  --ELSE
  --  PERFORM of_notice(NULL,'error','Es necesario calcular el Plan de Pagos');
  --  RETURN NEXT t;
  --  RETURN;
  --END IF;
  RETURN;
END;$$
LANGUAGE plpgsql;
