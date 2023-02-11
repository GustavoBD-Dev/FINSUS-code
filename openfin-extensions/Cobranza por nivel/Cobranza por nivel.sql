
-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_fs_cobranza 
-- Cobranza por nivel
-- 05/10/2016

-- ----------------------------------------------------------------------------
-- 05/10/2016 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_fs_cobranza___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  DROP TABLE IF EXISTS temp_cobranza_sus;
  CREATE TABLE temp_cobranza_sus
     (
      Cliente             TEXT,
      Nombre              TEXT,
      Auxiliar            TEXT,
      Fecha               TEXT,
      Pago                TEXT,
      Capital             TEXT,
      Intereses           TEXT,
      IVA_io              TEXT,
      Vencidos            TEXT,
      Comisiones          TEXT,
      Seguro_auto         TEXT,
      IVA_seg_auto        TEXT,
      Seguro_vida         TEXT,
      Localizador         TEXT,
      IVA_gps             TEXT,
      Com_spl             TEXT,
      IVA_spl             TEXT,
      diferido            TEXT,
      Monto_Cobrado       TEXT,
      Monto_Bonificado    TEXT,
      Monto_Aplicado      TEXT,
      Poliza              TEXT,
      Comision            TEXT,
      iva_comision        TEXT,
    -- Add new variable type TEXT
    Concepto_Poliza     TEXT);
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/10/2016 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_fs_cobranza___ini ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
  f     DATE;
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Revisando versiones
  IF (NOT of_ofx_check_version('1.14.1')) THEN
    RETURN FALSE;
  END IF;
  
  f := ofpsd('global','fecha',now()::DATE);
  PERFORM of_ofx_set('cb_nivel','set=0');
  PERFORM of_ofx_set('hbox14','sensitive=false');
  PERFORM of_ofx_set('bt_aceptar','sensitive=false');
  PERFORM of_ofx_set('bt_detalle','sensitive=false');
  PERFORM of_ofx_set('table4','sensitive=false');
  PERFORM of_ofx_set('dfecha','set='||of_fecha_dpm(f)::TEXT);
  PERFORM of_ofx_set('window1','maximize=true');
  PERFORM of_ofx_set('bt_detalle_ini','set=click');
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/10/2016 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_fs_cobranza___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/10/2016 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_fs_cobranza___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 
  --x := of_ofx_get('mi_variable');
  --y := of_ofx_get_integer('mi_integer');
  --PERFORM of_ofx_notice('error','Este es un mensaje de error');
  IF (p_variable='afecha') THEN
      IF (of_ofx_get('dfecha')::DATE<=p_valor::DATE) THEN
          PERFORM of_ofx_set('bt_detalle','sensitive=true,set=click');
          PERFORM of_ofx_set('hbox14','sensitive=true');
          PERFORM of_ofx_set('table4','sensitive=true');
          PERFORM of_ofx_set('bt_aceptar','sensitive=true');
      ELSE
          PERFORM of_ofx_notice('error','Error: Primer fecha no puede ser menor a la segunda');
      END IF;
  END IF;
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/10/2016 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_fs_cobranza___on_click (p_button TEXT, p_data TEXT) 
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
-- 05/10/2016 
-- Función principal
SELECT of_db_drop_type('ofx_fs_cobranza','CASCADE');
CREATE TYPE ofx_fs_cobranza AS (

    Cliente             TEXT,
    Nombre              TEXT,
    Auxiliar            TEXT,
    Fecha               TEXT,
    Pago                TEXT,
    Capital             TEXT,
    Intereses           TEXT,
    Vencidos            TEXT,
    IVA_io              TEXT,
    Comisiones          TEXT,
    Seguro_auto         TEXT,
    IVA_seg_auto        TEXT,
    Seguro_vida         TEXT,
    gps                 TEXT,
    IVA_gps             TEXT,
    spl                 TEXT,
    IVA_spl             TEXT,
    diferido            TEXT,
    Monto_Cobrado       TEXT,
    Monto_Bonificado    TEXT,
    Monto_Aplicado      TEXT,
    Poliza              TEXT,
    Comision            TEXT,
    iva_comision        TEXT,
    -- Add new variable type TEXT
    Concepto_Poliza     TEXT

);

CREATE OR REPLACE FUNCTION ofx_fs_cobranza (p_dfecha DATE,p_afecha DATE) 
  RETURNS SETOF ofx_fs_cobranza AS $$
DECLARE
   --Parámetros
 
   -- Variables
  t                      ofx_fs_cobranza%ROWTYPE;
  r                      RECORD;
  r1                     RECORD;
  r2                     RECORD;
  r3                     RECORD;
  r4                     RECORD;
  rc                     RECORD;
  --Totales de primer nivel
  --_t1Pago                NUMERIC;
  --_t1Capital             NUMERIC;
  --_t1Intereses           NUMERIC;
  --_t1Vencidos            NUMERIC;
  --_t1Comisiones          NUMERIC;
  --_t1Seguro_auto         NUMERIC;
  --_t1IVA_seg_auto        NUMERIC;
  --_t1Seguro_vida         NUMERIC;
  --_t1Localizador         NUMERIC;
  --_t1IVA_gps             NUMERIC;
  --_t1Monto_Cobrado       NUMERIC;
  --_t1Monto_Bonificado    NUMERIC;
  --_t1Monto_Aplicado      NUMERIC;
  --Totales de segundo nivel
  --_t2Pago                NUMERIC;
  --_t2Capital             NUMERIC;
  --_t2Intereses           NUMERIC;
  --_t2Vencidos            NUMERIC;
  --_t2Comisiones          NUMERIC;
  --_t2Seguro_auto         NUMERIC;
  --_t2IVA_seg_auto        NUMERIC;
  --_t2Seguro_vida         NUMERIC;
  --_t2Localizador         NUMERIC;
  --_t2IVA_gps             NUMERIC;
  --_t2Monto_Cobrado       NUMERIC;
  --_t2Monto_Bonificado    NUMERIC;
  --_t2Monto_Aplicado      NUMERIC;
  --Totales de tercer nivel
  --_t3Pago                NUMERIC;
  --_t3Capital             NUMERIC;
  --_t3Intereses           NUMERIC;
  --_t3Vencidos            NUMERIC;
  --_t3Comisiones          NUMERIC;
  --_t3Seguro_auto         NUMERIC;
  --_t3IVA_seg_auto        NUMERIC;
  --_t3Seguro_vida         NUMERIC;
  --_t3Localizador         NUMERIC;
  --_t3IVA_gps             NUMERIC;
  --_t3Monto_Cobrado       NUMERIC;
  --_t3Monto_Bonificado    NUMERIC;
  --_t3Monto_Aplicado      NUMERIC;

  --Otras
  _seg_da       NUMERIC;
  _seg_vi       NUMERIC;
  _gps          NUMERIC;
  _imp_paso     NUMERIC;
  _seg_da_imp   NUMERIC;
  _gps_imp      NUMERIC;
  _spl          NUMERIC;
  _spl_imp      NUMERIC;
  _comision     NUMERIC;
  _comision_imp NUMERIC;
  _diferido     NUMERIC;
  _kauxiliar    INTEGER;
  _idsucursal   INTEGER := COALESCE(of_ofx_get_integer('idsucursal'),0);
  _idrol        INTEGER := COALESCE(of_ofx_get_integer('idrol'),0);
  _idasociado   INTEGER := COALESCE(of_ofx_get_integer('idasociado'),0);
  _idproducto   INTEGER := COALESCE(of_ofx_get_integer('idproducto'),0);
 _idauxiliar   INTEGER := COALESCE(of_ofx_get_integer('idauxiliar'),0);
  _idsucaux   INTEGER := COALESCE(of_ofx_get_integer('idsucaux'),0);
BEGIN
  
  DROP TABLE IF EXISTS temp_cobranza_sus;
  CREATE TABLE temp_cobranza_sus
     (
      Cliente             TEXT,
      Nombre              TEXT,
      Auxiliar            TEXT,
      Fecha               TEXT,
      Pago                TEXT,
      Capital             NUMERIC,
      Intereses           NUMERIC,
      Vencidos            NUMERIC,
      IVA_io              NUMERIC,
      Comisiones          NUMERIC,
      Seguro_auto         NUMERIC,
      IVA_seg_auto        NUMERIC,
      Seguro_vida         NUMERIC,
      Localizador         NUMERIC,
      IVA_gps             NUMERIC,
      Com_spl             NUMERIC,
      IVA_spl             NUMERIC,
      diferido            NUMERIC,
      Monto_Cobrado       NUMERIC,
      Monto_Bonificado    NUMERIC,
      Monto_Aplicado      NUMERIC,
      Poliza              TEXT,
      Comision            NUMERIC,
      iva_comision        NUMERIC,
      -- Add new variable to store concept poliza
      Concepto_Poliza     TEXT
      );


  FOR r IN SELECT da.*,d.idsucursal,d.idrol,d.idasociado 
             FROM detalle_auxiliar AS da
             LEFT JOIN deudores AS d USING(idsucaux,idproducto,idauxiliar)
            WHERE idproducto IN (SELECT idproducto FROM productos WHERE of_producto_subtipo(idproducto)='PRE')
                  AND abono+montoio+montoim+montoca+montoimp_io>0 AND (_idproducto=0 OR idproducto=_idproducto)
                  AND (_idsucursal=0 OR idsucursal=_idsucursal) AND (_idrol=0 OR idrol=_idrol)
                  AND (_idasociado=0 OR idasociado=_idasociado) AND fecha BETWEEN p_dfecha AND p_afecha 
            ORDER BY idsucursal,idrol,idasociado,idsucaux,idproducto,idauxiliar,fecha LOOP

    SELECT INTO _kauxiliar kauxiliar FROM deudores WHERE (idsucaux, idproducto, idauxiliar)=(_idsucaux, _idproducto, _idauxiliar);

      _seg_da    :=0;
      _seg_vi    :=0;
      _gps       :=0;
      _spl       :=0;
      _spl_imp   :=0;
      _seg_da_imp:=0;
      _gps_imp   :=0;
      _imp_paso  :=0;
      _comision  :=0;
      _comision_imp:=0;
      _diferido  :=0;

      --LAPR 04/10/2016 Se cambia el metodo para determinar los costos asociados
      IF (r.montoca>0) THEN
          FOR rc IN SELECT * FROM of_ca_auxiliar(r.idsucaux,r.idproducto,r.idauxiliar,p_afecha,FALSE) LOOP
           
              SELECT INTO rc.abono,_imp_paso sum(abono) AS abono,sum(impuesto) 
                          FROM detalle_auxiliar_ca 
                         WHERE idcosto=rc.idcosto AND secuencia=r.secuencia;
              IF NOT FOUND THEN
                  rc.abono :=0;
              END IF;
                 
              IF (rc.idcosto=1) THEN
                  _seg_vi :=rc.abono;
              ELSIF(rc.idcosto=2) THEN
                  _seg_da      :=rc.abono;
                  _seg_da_imp  :=_imp_paso;
                  _imp_paso    :=0.00;

              ELSIF(rc.idcosto=3) THEN
                  _gps         :=rc.abono;
                  _gps_imp     :=_imp_paso;
                  _imp_paso    :=0.00;

              ELSIF(rc.idcosto=4) THEN 
                  _comision    :=rc.abono;
                  _comision_imp :=_imp_paso;
                  _imp_paso     :=0.00;
                -- SELECT INTO _comision abono
-- FROM of_ca_entresinplacas_sust(r.idsucaux,r.idproducto,r.idauxiliar,4,p_afecha,FALSE);

              ELSIF(rc.idcosto=5) THEN 
                  _diferido     :=rc.abono;
               
              ELSE
                  _spl         :=rc.abono;
                  _spl_imp     :=_imp_paso;
                  _imp_paso    :=0.00;
              END IF;


                 
          END LOOP;
      ELSE
          _seg_da    :=0;
          _seg_vi    :=0;
          _gps       :=0;
          _spl       :=0;
          _spl_imp   :=0;
          _seg_da_imp:=0;
          _gps_imp   :=0;
          _imp_paso  :=0;
          _comision  :=0;
          _comision_imp:=0;
          _diferido  :=0;
      END IF;


      _seg_da    :=COALESCE(_seg_da,0.00);
      _seg_vi    :=COALESCE(_seg_vi,0.00);
      _gps       :=COALESCE(_gps,0.00);
      _spl       :=COALESCE(_spl,0.00);
      _seg_da_imp:=COALESCE(_seg_da_imp,0.00);
      _gps_imp   :=COALESCE(_gps_imp,0.00);
      _comision  :=COALESCE(_comision,0.00);
      _comision_imp :=COALESCE(_comision_imp,0.00);
      _spl_imp   :=COALESCE(_spl_imp,0.00);
      _diferido  :=COALESCE(_diferido,0.00);
      _imp_paso  :=COALESCE(_imp_paso,0.00);

      t.Cliente             :=r.idsucursal||'-'||r.idrol||'-'||r.idasociado;
      t.Nombre              :=of_nombre_asociado(r.idsucursal,r.idrol,r.idasociado);
      t.Auxiliar            :=r.idsucaux||'-'||r.idproducto||'-'||r.idauxiliar;
      t.Fecha               :=r.fecha;
      t.Pago                :=' ';
      t.Capital             :=r.abono;
      t.Intereses           :=r.montoio;
      t.Vencidos            :=r.montoim;
      t.IVA_io              :=r.montoimp_io;
      t.Comisiones          :='0.00';
      t.Seguro_auto         :=_seg_da;
      t.IVA_seg_auto        :=_seg_da_imp;
      t.Seguro_vida         :=_seg_vi;
      t.gps                 :=_gps;
      t.IVA_gps             :=_gps_imp;
      t.Comision            := _comision;
      t.iva_comision        := _comision_imp; 
      t.diferido            := _diferido;
      t.Monto_Cobrado       :=r.abono+r.montoio+r.montoim+r.montoca;
      t.Monto_Bonificado    :='0.00';
      t.Monto_Aplicado      :=r.abono+r.montoio+r.montoim+r.montoca;
      t.Poliza              := r.idsucpol ||'-'|| r.periodo ||'-'|| r.tipopol||'-'||r.idpoliza;

      --PERFORM of_ofx_notice('info', t.Poliza::TEXT);
      -- Get and set data to variable new
      t.Concepto_Poliza := (SELECT concepto FROM polizas WHERE (idsucpol, periodo, tipopol, idpoliza) = (r.idsucpol, r.periodo, r.tipopol, r.idpoliza))::TEXT;
      --PERFORM of_ofx_notice('info',t.Concepto_Poliza);

      RETURN NEXT t;
      INSERT INTO temp_cobranza_sus VALUES(t.Cliente,t.Nombre,t.Auxiliar,t.Fecha,t.Pago,of_numeric(t.Capital),of_numeric(t.Intereses), of_numeric(t.Vencidos),of_numeric(t.IVA_io),of_numeric(t.Comisiones),of_numeric(t.Seguro_auto),                                          of_numeric(t.IVA_seg_auto),of_numeric(t.Seguro_vida),of_numeric(t.gps),                                          of_numeric(t.IVA_gps),of_numeric(t.spl),of_numeric(t.IVA_spl), of_numeric(t.diferido), of_numeric(t.Monto_Cobrado),0.00,of_numeric(t.Monto_Aplicado),t.Poliza,of_numeric(t.Comision),of_numeric(t.iva_comision), t.Concepto_Poliza);

  END LOOP;
  RETURN ;
END;$$
LANGUAGE plpgsql;


--Funcion para agrupacion de niveles del detalle
SELECT of_db_drop_type('ofx_fs_cobranza_nivel','CASCADE');
CREATE TYPE ofx_fs_cobranza_nivel AS (

    Cliente             TEXT,
    Nombre              TEXT,
    Auxiliar            TEXT,
    Fecha               TEXT,
    Pago                TEXT,
    Capital             NUMERIC,
    Intereses           NUMERIC,
    Vencidos            NUMERIC,
    IVA_io              NUMERIC,
    Comisiones          NUMERIC,
    Seguro_auto         NUMERIC,
    IVA_seg_auto        NUMERIC,
    Seguro_vida         NUMERIC,
    gps                 NUMERIC,
    IVA_gps             NUMERIC,
    spl                 NUMERIC,
    IVA_spl             NUMERIC,
    diferido            NUMERIC,
    Monto_Cobrado       NUMERIC,
    Monto_Bonificado    NUMERIC,
    Monto_Aplicado      NUMERIC,
    Poliza              TEXT,
    Comision            NUMERIC,
    iva_comision        NUMERIC,
    -- Add new variable to store concept poliza
    Concepto_Poliza     TEXT
);

CREATE OR REPLACE FUNCTION ofx_fs_cobranza_nivel (p_nivel INTEGER) 
  RETURNS SETOF ofx_fs_cobranza_nivel AS $$
DECLARE
   --Parámetros
 
   -- Variables
  t                      ofx_fs_cobranza_nivel%ROWTYPE;
  r                      RECORD;
  r1                     RECORD;
  r2                     RECORD;
  r3                     RECORD;
  r4                     RECORD;
  rc                     RECORD;
  --Totales de primer nivel
  _t1Pago                NUMERIC;
  _t1Capital             NUMERIC;
  _t1Intereses           NUMERIC;
  _t1Vencidos            NUMERIC;
  _t1IVA_io              NUMERIC;
  _t1Comisiones          NUMERIC;
  _t1Seguro_auto         NUMERIC;
  _t1IVA_seg_auto        NUMERIC;
  _t1Seguro_vida         NUMERIC;
  _t1Localizador         NUMERIC;
  _t1IVA_gps             NUMERIC;
  _t1Comision            NUMERIC;
  _t1Iva_comision        NUMERIC;
  _t1diferido            NUMERIC;
  _t1Monto_Cobrado       NUMERIC;
  _t1Monto_Bonificado    NUMERIC;
  _t1Monto_Aplicado      NUMERIC;
  --Totales de segundo nivel
  _t2Pago                NUMERIC;
  _t2Capital             NUMERIC;
  _t2Intereses           NUMERIC;
  _t2Vencidos            NUMERIC;
  _t2IVA_io              NUMERIC;
  _t2Comisiones          NUMERIC;
  _t2Seguro_auto         NUMERIC;
  _t2IVA_seg_auto        NUMERIC;
  _t2Seguro_vida         NUMERIC;
  _t2Localizador         NUMERIC;
  _t2IVA_gps             NUMERIC;
  _t2Comision            NUMERIC;
  _t2Iva_comision        NUMERIC;
  _t2diferido            NUMERIC;
  _t2Monto_Cobrado       NUMERIC;
  _t2Monto_Bonificado    NUMERIC;
  _t2Monto_Aplicado      NUMERIC;
  --Totales de tercer nivel
  _t3Pago                NUMERIC;
  _t3Capital             NUMERIC;
  _t3Intereses           NUMERIC;
  _t3Vencidos            NUMERIC;
  _t3IVA_io              NUMERIC;
  _t3Comisiones          NUMERIC;
  _t3Seguro_auto         NUMERIC;
  _t3IVA_seg_auto        NUMERIC;
  _t3Seguro_vida         NUMERIC;
  _t3Localizador         NUMERIC;
  _t3IVA_gps             NUMERIC;
  _t3Comision            NUMERIC;
  _t3Iva_comision        NUMERIC;
  _t3diferido            NUMERIC;
  _t3Monto_Cobrado       NUMERIC;
  _t3Monto_Bonificado    NUMERIC;
  _t3Monto_Aplicado      NUMERIC;

  --Otras
  _pasoptmo              TEXT;
  _pasocte               TEXT;
BEGIN

  FOR r IN SELECT *,string_to_array(Cliente,'-') AS idcliente
             FROM temp_cobranza_sus AS da 
            ORDER BY Cliente,Auxiliar,fecha LOOP
      IF (p_nivel<=2) THEN
          IF (_pasoptmo <> r.Auxiliar AND _pasoptmo IS NOT NULL) THEN

              t.Cliente             :=' ';
              t.Nombre              :=' ';
              t.Auxiliar            :=_pasoptmo;
              t.Fecha               :='Tot.';
              t.Pago                :=' ';
              t.Capital             :=_t1Capital;
              t.Intereses           :=_t1Intereses;
              t.Vencidos            :=_t1Vencidos;
              t.IVA_io              :=_t1IVA_io;
              t.Comisiones          :=_t1Comisiones;
              t.Seguro_auto         :=_t1Seguro_auto;
              t.IVA_seg_auto        :=_t1IVA_seg_auto;
              t.Seguro_vida         :=_t1Seguro_vida;
              t.gps                 :=_t1Localizador;
              t.IVA_gps             :=_t1IVA_gps;
              t.Comision            :=_t1Comision;
              t.Iva_comision        :=_t1Iva_comision;
              t.diferido            :=_t1diferido;
              t.Monto_Cobrado       :=_t1Monto_Cobrado;
              t.Monto_Bonificado    :=_t1Monto_Bonificado;
              t.Monto_Aplicado      :=_t1Monto_Aplicado;
              t.Poliza              := '';
              t.Concepto_Poliza     := '';
              RETURN NEXT t;
              t.Cliente             :=' ';
              t.Nombre              :=' ';
              t.Auxiliar            :=' ';
              t.Fecha               :=' ';
              t.Pago                :=' ';
              t.Capital             :=NULL;
              t.Intereses           :=NULL;
              t.Vencidos            :=NULL;
              t.IVA_io              :=NULL;
              t.Comisiones          :=NULL;
              t.Seguro_auto         :=NULL;
              t.IVA_seg_auto        :=NULL;
              t.Seguro_vida         :=NULL;
              t.gps                 :=NULL;
              t.IVA_gps             :=NULL;
              t.Comision            :=NULL;
              t.Iva_comision        :=NULL;
              t.diferido            :=NULL;
              t.Monto_Cobrado       :=NULL;
              t.Monto_Bonificado    :=NULL;
              t.Monto_Aplicado      :=NULL;
              t.Poliza              :='';
              t.Concepto_Poliza     := '';
              RETURN NEXT t;
              _t1Capital            :=0.00;
              _t1Intereses          :=0.00;
              _t1Vencidos           :=0.00;
              _t1IVA_io             :=0.00;
              _t1Comisiones         :=0.00;              
              _t1Seguro_auto        :=0.00;
              _t1IVA_seg_auto       :=0.00;
              _t1Seguro_vida        :=0.00;
              _t1Localizador        :=0.00;
              _t1IVA_gps            :=0.00;
              _t1Comision           :=0.00;
              _t1Iva_comision       :=0.00;
              _t1diferido           :=0.00;
              _t1Monto_Cobrado      :=0.00;
              _t1Monto_Bonificado   :=0.00;
              _t1Monto_Aplicado     :=0.00;
              _t1Capital           :=COALESCE(_t1Capital,0)+r.Capital;
              _t1Intereses         :=COALESCE(_t1Intereses,0)+r.Intereses;
              _t1Vencidos          :=COALESCE(_t1Vencidos,0)+r.Vencidos;
              _t1IVA_io            :=COALESCE(_t1IVA_io,0)+r.IVA_io;
              _t1Comisiones        :=COALESCE(_t1Comisiones,0)+r.Comisiones;
              _t1Seguro_auto       :=COALESCE(_t1Seguro_auto,0)+r.Seguro_auto;
              _t1IVA_seg_auto      :=COALESCE(_t1IVA_seg_auto,0)+r.IVA_seg_auto;
              _t1Seguro_vida       :=COALESCE(_t1Seguro_vida,0)+r.Seguro_vida;
              _t1Localizador       :=COALESCE(_t1Localizador,0)+r.Localizador;
              _t1IVA_gps           :=COALESCE(_t1IVA_gps,0)+r.IVA_gps;
              _t1Comision          :=COALESCE(_t1Comision,0)+r.Comision;
              _t1Iva_comision      :=COALESCE(_t1Iva_comision,0)+r.Iva_comision;
              _t1diferido          :=COALESCE(_t1diferido,0)+r.diferido;
              _t1Monto_Cobrado     :=COALESCE(_t1Monto_Cobrado,0)+r.Monto_Cobrado;
              _t1Monto_Bonificado  :=COALESCE(_t1Monto_Bonificado,0)+r.Monto_Bonificado;
              _t1Monto_Aplicado    :=COALESCE(_t1Monto_Aplicado,0)+r.Monto_Aplicado;
          ELSE
              _t1Capital           :=COALESCE(_t1Capital,0)+r.Capital;
              _t1Intereses         :=COALESCE(_t1Intereses,0)+r.Intereses;
              _t1Vencidos          :=COALESCE(_t1Vencidos,0)+r.Vencidos;
              _t1IVA_io            :=COALESCE(_t1IVA_io,0)+r.IVA_io;
              _t1Comisiones        :=COALESCE(_t1Comisiones,0)+r.Comisiones;
              _t1Seguro_auto       :=COALESCE(_t1Seguro_auto,0)+r.Seguro_auto;
              _t1IVA_seg_auto      :=COALESCE(_t1IVA_seg_auto,0)+r.IVA_seg_auto;
              _t1Seguro_vida       :=COALESCE(_t1Seguro_vida,0)+r.Seguro_vida;
              _t1Localizador       :=COALESCE(_t1Localizador,0)+r.Localizador;
              _t1IVA_gps           :=COALESCE(_t1IVA_gps,0)+r.IVA_gps;
              _t1Comision          :=COALESCE(_t1Comision,0)+r.Comision;
              _t1Iva_comision      :=COALESCE(_t1Iva_comision,0)+r.Iva_comision;
              _t1diferido          :=COALESCE(_t1diferido,0)+r.diferido;
              _t1Monto_Cobrado     :=COALESCE(_t1Monto_Cobrado,0)+r.Monto_Cobrado;
              _t1Monto_Bonificado  :=COALESCE(_t1Monto_Bonificado,0)+r.Monto_Bonificado;
              _t1Monto_Aplicado    :=COALESCE(_t1Monto_Aplicado,0)+r.Monto_Aplicado;
          END IF;
          _pasoptmo  :=r.Auxiliar;
      END IF;
      IF (p_nivel<=3) THEN
          IF (_pasocte <> r.Cliente AND _pasocte IS NOT NULL) THEN

              t.Cliente             :=_pasocte;
              t.Nombre              :=of_nombre_asociado(r.idcliente[1]::INTEGER,r.idcliente[2]::INTEGER,r.idcliente[3]::INTEGER);
              t.Auxiliar            :='Tot.';
              t.Fecha               :=' ';
              t.Pago                :=' ';
              t.Capital             :=_t2Capital;
              t.Intereses           :=_t2Intereses;
              t.Vencidos            :=_t2Vencidos;
              t.IVA_io              :=_t2IVA_io;
              t.Comisiones          :=_t2Comisiones;
              t.Seguro_auto         :=_t2Seguro_auto;
              t.IVA_seg_auto        :=_t2IVA_seg_auto;
              t.Seguro_vida         :=_t2Seguro_vida;
              t.gps                 :=_t2Localizador;
              t.IVA_gps             :=_t2IVA_gps;
              t.Comision            :=_t2Comision;
              t.Iva_comision        :=_t2Iva_comision;
              t.diferido            :=_t2diferido;
              t.Monto_Cobrado       :=_t2Monto_Cobrado;
              t.Monto_Bonificado    :=_t2Monto_Bonificado;
              t.Monto_Aplicado      :=_t2Monto_Aplicado;
              t.Poliza              := '';
              t.Concepto_Poliza     := '';
              RETURN NEXT t;
              t.Cliente             :=' ';
              t.Nombre              :=' ';
              t.Auxiliar            :=' ';
              t.Fecha               :=' ';
              t.Pago                :=' ';
              t.Capital             :=NULL;
              t.Intereses           :=NULL;
              t.Vencidos            :=NULL;
              t.IVA_io              :=NULL;
              t.Comisiones          :=NULL;
              t.Seguro_auto         :=NULL;
              t.IVA_seg_auto        :=NULL;
              t.Seguro_vida         :=NULL;
              t.gps                 :=NULL;
              t.IVA_gps             :=NULL;
              t.Comision            :=NULL;
              t.Iva_comision        :=NULL;
              t.diferido            :=NULL;
              t.Monto_Cobrado       :=NULL;
              t.Monto_Bonificado    :=NULL;
              t.Monto_Aplicado      :=NULL;
              t.Poliza              := '';
              t.Concepto_Poliza     := '';
              RETURN NEXT t;
              _t2Capital            :=0.00;
              _t2Intereses          :=0.00;
              _t2Vencidos           :=0.00;
              _t2IVA_io             :=0.00;
              _t2Comisiones         :=0.00;
              _t2Seguro_auto        :=0.00;
              _t2IVA_seg_auto       :=0.00;
              _t2Seguro_vida        :=0.00;
              _t2Localizador        :=0.00;
              _t2IVA_gps            :=0.00;
              _t2Comision           :=0.00;
              _t2Iva_comision       :=0.00;
              _t2diferido           :=0.00;
              _t2Monto_Cobrado      :=0.00;
              _t2Monto_Bonificado   :=0.00;
              _t2Monto_Aplicado     :=0.00;
              t.Poliza              := '';
              t.Concepto_Poliza     := '';
              _t2Capital           :=COALESCE(_t2Capital,0)+r.Capital;
              _t2Intereses         :=COALESCE(_t2Intereses,0)+r.Intereses;
              _t2Vencidos          :=COALESCE(_t2Vencidos,0)+r.Vencidos;
              _t2IVA_io            :=COALESCE(_t2IVA_io,0)+r.IVA_io;
              _t2Comisiones        :=COALESCE(_t2Comisiones,0)+r.Comisiones;
              _t2Seguro_auto       :=COALESCE(_t2Seguro_auto,0)+r.Seguro_auto;
              _t2IVA_seg_auto      :=COALESCE(_t2IVA_seg_auto,0)+r.IVA_seg_auto;
              _t2Seguro_vida       :=COALESCE(_t2Seguro_vida,0)+r.Seguro_vida;
              _t2Localizador       :=COALESCE(_t2Localizador,0)+r.Localizador;
              _t2IVA_gps           :=COALESCE(_t2IVA_gps,0)+r.IVA_gps;
              _t2Comision          :=COALESCE(_t2Comision,0)+r.Comision;
              _t2Iva_comision      :=COALESCE(_t2Iva_comision,0)+r.Iva_comision;
              _t2diferido          :=COALESCE(_t2diferido,0)+r.diferido;
              _t2Monto_Cobrado     :=COALESCE(_t2Monto_Cobrado,0)+r.Monto_Cobrado;
              _t2Monto_Bonificado  :=COALESCE(_t2Monto_Bonificado,0)+r.Monto_Bonificado;
              _t2Monto_Aplicado    :=COALESCE(_t2Monto_Aplicado,0)+r.Monto_Aplicado;
              t.Poliza              := '';
              t.Concepto_Poliza     := '';
          ELSE
              _t2Capital           :=COALESCE(_t2Capital,0)+r.Capital;
              _t2Intereses         :=COALESCE(_t2Intereses,0)+r.Intereses;
              _t2Vencidos          :=COALESCE(_t2Vencidos,0)+r.Vencidos;
              _t2IVA_io            :=COALESCE(_t2IVA_io,0)+r.IVA_io;
              _t2Comisiones        :=COALESCE(_t2Comisiones,0)+r.Comisiones;
              _t2Seguro_auto       :=COALESCE(_t2Seguro_auto,0)+r.Seguro_auto;
              _t2IVA_seg_auto      :=COALESCE(_t2IVA_seg_auto,0)+r.IVA_seg_auto;
              _t2Seguro_vida       :=COALESCE(_t2Seguro_vida,0)+r.Seguro_vida;
              _t2Localizador       :=COALESCE(_t2Localizador,0)+r.Localizador;
              _t2IVA_gps           :=COALESCE(_t2IVA_gps,0)+r.IVA_gps;
              _t2Comision          :=COALESCE(_t2Comision,0)+r.Comision;
              _t2Iva_comision      :=COALESCE(_t2Iva_comision,0)+r.Iva_comision;
              _t2diferido          :=COALESCE(_t2diferido,0)+r.diferido;
              _t2Monto_Cobrado     :=COALESCE(_t2Monto_Cobrado,0)+r.Monto_Cobrado;
              _t2Monto_Bonificado  :=COALESCE(_t2Monto_Bonificado,0)+r.Monto_Bonificado;
              _t2Monto_Aplicado    :=COALESCE(_t2Monto_Aplicado,0)+r.Monto_Aplicado;
              t.Poliza              := '';
              t.Concepto_Poliza     := '';
          END IF;
          _pasocte  :=r.Cliente;
      END IF;

      t.Cliente             :='';
      t.Nombre              :='';
      t.Auxiliar            :=r.Auxiliar;
      t.Fecha               :=r.fecha;
      t.Pago                :=' ';
      t.Capital             :=r.Capital;
      t.Intereses           :=r.Intereses;
      t.Vencidos            :=r.Vencidos;
      t.IVA_io              :=r.IVA_io;
      t.Comisiones          :=0.00;
      t.Seguro_auto         :=r.Seguro_auto;
      t.IVA_seg_auto        :=r.IVA_seg_auto;
      t.Seguro_vida         :=r.Seguro_vida;
      t.gps                 :=r.Localizador;
      t.IVA_gps             :=r.IVA_gps;
      t.Comision            :=r.Comision;
      t.Iva_comision        :=r.Iva_comision;
      t.diferido            :=r.diferido;
      t.Monto_Cobrado       :=r.Monto_Cobrado;
      t.Monto_Bonificado    :=0.00;
      t.Monto_Aplicado      :=r.Monto_Aplicado;
      t.Poliza              := r.Poliza;
      t.Concepto_Poliza     := r.Concepto_Poliza;

      IF (p_nivel=1) THEN
          RETURN NEXT t;
      END IF;
      --IF (p_nivel<=4) THEN
      _t3Capital           :=COALESCE(_t3Capital,0)+r.Capital;
      _t3Intereses         :=COALESCE(_t3Intereses,0)+r.Intereses;
      _t3Vencidos          :=COALESCE(_t3Vencidos,0)+r.Vencidos;
      _t3IVA_io            :=COALESCE(_t3IVA_io,0)+r.IVA_io;
      _t3Comisiones        :=COALESCE(_t3Comisiones,0)+r.Comisiones;
      _t3Seguro_auto       :=COALESCE(_t3Seguro_auto,0)+r.Seguro_auto;
      _t3IVA_seg_auto      :=COALESCE(_t3IVA_seg_auto,0)+r.IVA_seg_auto;
      _t3Seguro_vida       :=COALESCE(_t3Seguro_vida,0)+r.Seguro_vida;
      _t3Localizador       :=COALESCE(_t3Localizador,0)+r.Localizador;
      _t3IVA_gps           :=COALESCE(_t3IVA_gps,0)+r.IVA_gps;
      _t3Comision          :=COALESCE(_t3Comision,0)+r.Comision;
      _t3Iva_comision      :=COALESCE(_t3Iva_comision,0)+r.Iva_comision;
      _t3diferido          :=COALESCE(_t3diferido,0)+r.diferido;
      _t3Monto_Cobrado     :=COALESCE(_t3Monto_Cobrado,0)+r.Monto_Cobrado;
      _t3Monto_Bonificado  :=COALESCE(_t3Monto_Bonificado,0)+r.Monto_Bonificado;
      _t3Monto_Aplicado    :=COALESCE(_t3Monto_Aplicado,0)+r.Monto_Aplicado;
      --t.Poliza              := '';
      --END IF;
  END LOOP;
  t.Cliente             :=' ';
  t.Nombre              :=' ';
  t.Auxiliar            :=' ';
  t.Fecha               :=' ';
  t.Pago                :=' ';
  t.Capital             :=NULL;
  t.Intereses           :=NULL;
  t.IVA_io              :=NULL;
  t.Vencidos            :=NULL;
  t.Comisiones          :=NULL;
  t.Seguro_auto         :=NULL;
  t.IVA_seg_auto        :=NULL;
  t.Seguro_vida         :=NULL;
  t.gps                 :=NULL;
  t.IVA_gps             :=NULL;
  t.Comision            :=NULL;
  t.Iva_comision        :=NULL;
  t.diferido            :=NULL;
  t.Monto_Cobrado       :=NULL;
  t.Monto_Bonificado    :=NULL;
  t.Monto_Aplicado      :=NULL;
  t.Poliza              := '';
  t.Concepto_Poliza     := '';
  RETURN NEXT t;
  t.Cliente             :='Tot. Gral';
  t.Nombre              :=' ';
  t.Auxiliar            :=' ';
  t.Fecha               :=' ';
  t.Pago                :=' ';
  t.Capital             :=_t3Capital;
  t.Intereses           :=_t3Intereses;
  t.Vencidos            :=_t3Vencidos;
  t.IVA_io              :=_t3IVA_io;
  t.Comisiones          :=_t3Comisiones;
  t.Seguro_auto         :=_t3Seguro_auto;
  t.IVA_seg_auto        :=_t3IVA_seg_auto;
  t.Seguro_vida         :=_t3Seguro_vida;
  t.gps                 :=_t3Localizador;
  t.IVA_gps             :=_t3IVA_gps;
  t.Comision            :=_t3Comision;
  t.Iva_comision        :=_t3Iva_comision;
  t.diferido            :=_t3diferido;
  t.Monto_Cobrado       :=_t3Monto_Cobrado;
  t.Monto_Bonificado    :=_t3Monto_Bonificado;
  t.Monto_Aplicado      :=_t3Monto_Aplicado;
  t.Poliza              := '';
  t.Concepto_Poliza     := '';
  RETURN NEXT t;
  RETURN ;
END;$$
LANGUAGE plpgsql;

