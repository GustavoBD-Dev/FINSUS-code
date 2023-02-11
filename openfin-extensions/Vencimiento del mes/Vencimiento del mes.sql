
-- (c) Servicios de Informática Colegiada, S.A. de C.V.
-- Extensión de OpenFIN: ofx_sus_vece_x_mes 
-- Vencimiento del mes
-- 05/09/2016

-- ----------------------------------------------------------------------------
-- 05/09/2016 
-- Crea tablas realcionadas con esta extensión
CREATE OR REPLACE FUNCTION ofx_sus_vece_x_mes___db ()
  RETURNS INTEGER AS $$
DECLARE
  -- Variables  
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN 0;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/09/2016 
-- Inicialización
CREATE OR REPLACE FUNCTION ofx_sus_vece_x_mes___ini ()
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
  PERFORM of_ofx_set('window1','maximize=true');
  PERFORM of_ofx_set('defecha','set='||of_fecha_dpm(f)::TEXT);
  PERFORM of_ofx_set('afecha','set='||of_fecha_dum(f)::TEXT);
  PERFORM of_ofx_set('bt_act_ini','set=click');
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/09/2016 
-- Finalización
CREATE OR REPLACE FUNCTION ofx_sus_vece_x_mes___fin ()
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/09/2016 
-- Validciones
CREATE OR REPLACE FUNCTION ofx_sus_vece_x_mes___val (p_variable TEXT, p_valor TEXT)
  RETURNS BOOLEAN AS $$
DECLARE
  -- Variables
BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  --PERFORM of_param_sesion_raise(NULL); -- Mostrar los parámetros de sesión disponibles 
  --x := of_ofx_get('mi_variable');
  --y := of_ofx_get_integer('mi_integer');
  --PERFORM of_ofx_notice('error','Este es un mensaje de error');
  IF (p_variable='defecha') THEN
      IF (of_ofx_get('afecha')::DATE<=p_valor::DATE) THEN
          PERFORM of_ofx_notice('error','Error:Primer fecha no debe ser menor a la segunda');
          RETURN FALSE;
      END IF;
      --PERFORM of_ofx_set('bt_act','set=click');
  END IF;
  IF (p_variable='afecha') THEN
      IF (of_ofx_get('defecha')::DATE>=p_valor::DATE) THEN
          PERFORM of_ofx_notice('error','Error:Primer fecha no debe ser menor a la segunda');
          RETURN FALSE;
      END IF;
      PERFORM of_ofx_set('bt_act','set=click');
  END IF;

  RETURN TRUE;
END;$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- 05/09/2016 
-- Procesa el "click" de un boton que no tiene definida una función específica
CREATE OR REPLACE FUNCTION ofx_sus_vece_x_mes___on_click (p_button TEXT, p_data TEXT) 
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
-- 05/09/2016 
-- Función principal
SELECT of_db_drop_type('ofx_sus_vece_x_mes','CASCADE');
CREATE TYPE ofx_sus_vece_x_mes AS (
  socio         TEXT,
  auxiliar      TEXT,
  nombre        TEXT,
  fecha_act     TEXT,
  fecha_venc    TEXT,
  mto_dsip      TEXT,
  abono         TEXT,
  interes       TEXT,
  iva           TEXT,
  seg_danos     TEXT,
  iva_seg_danos TEXT,
  seg_vida      TEXT,
  gps           TEXT,
  iva_gps       TEXT,
  facturar      TEXT,
  num_pago      TEXT,
  comision      TEXT,
  iva_comision  TEXT,
  diferido      TEXT,
  io_diferir    TEXT,
  io_cobrar     TEXT,
  intereses_a_cobrar  TEXT,
  suma_var_total      TEXT
);

CREATE OR REPLACE FUNCTION ofx_sus_vece_x_mes(p_defecha date, p_afecha date)
 RETURNS SETOF ofx_sus_vece_x_mes
AS $$
DECLARE -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  -- Variables
  t             ofx_sus_vece_x_mes%ROWTYPE;
  r             RECORD;
  rc            RECORD;
  _seg_da       NUMERIC;
  _seg_vi       NUMERIC;
  _gps          NUMERIC;
  _comision     NUMERIC;
  _kauxiliar    NUMERIC;
  factor_iva_io NUMERIC;
  _diasgracia   INTEGER;
  _concobro     BOOLEAN:=FALSE;
  _comision_sp    NUMERIC=0.00;
  _comision_id    NUMERIC=0.00;
  _io_desc      NUMERIC=0.00;
  _io_incr      NUMERIC=0.00;
  pg_diasxtasa  INTEGER;
  _gps1         NUMERIC;
  _vida1        NUMERIC;
  _unidad1      NUMERIC;
  _id_cero      INTEGER;

  intereses_a_cobrar  INTEGER;


BEGIN -- (c) 2011 Servicios de Informática Colegiada, S.A. de C.V.
  SELECT INTO factor_iva_io COALESCE(of_params_get('/socios/productos/prestamos','iva_io')::NUMERIC,0);

  FOR r IN SELECT of_periodo(vence) AS periodo,idsucursal,idrol,idasociado,idsucaux,idproducto,idauxiliar,fechaactivacion,vence AS vence,
                  montoentregado,abono AS abono,io AS io,idpago AS idpago,tipoprestamo,
                  --CASE WHEN idpago=1 THEN round((COALESCE((SELECT segvida 
                  --                FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                  --                WHERE kauxiliar=d.kauxiliar LIMIT 1),0.001)/30) * ((vence-fechaactivacion)),2)
                  --         ELSE COALESCE((SELECT segvida 
                  --                        FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                  --                        WHERE kauxiliar=d.kauxiliar LIMIT 1),0.00) END  AS seguros_vida,
                  of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,1,1) as seguros_vida,
                  --CASE WHEN idpago=1 THEN round((COALESCE((SELECT segunidad 
                  --                FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                  --                WHERE kauxiliar=d.kauxiliar LIMIT 1),0.001)/30) * ((vence-fechaactivacion)),2)
                  --         ELSE COALESCE((SELECT segunidad 
                  --                        FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                  --                        WHERE kauxiliar=d.kauxiliar LIMIT 1),0.00) END AS seguros_unidad,
                  round(of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,2,1)/1.16,2) as seguros_unidad,
                  --CASE WHEN idpago=1 THEN round((COALESCE((SELECT gps 
                  --                FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                  --                WHERE kauxiliar=d.kauxiliar LIMIT 1),0.001)/30) * ((vence-fechaactivacion)),2)
                  --         ELSE COALESCE((SELECT gps 
                  --                        FROM ofx_multicampos_sustentable.auxiliar_masdatos 
                  --              WHERE kauxiliar=d.kauxiliar LIMIT 1),0.00) END AS gps,
                  round(of_jason_ca_pago(idsucaux,idproducto,idauxiliar,idpago,3,1)/1.16,2) as gps,kauxiliar, tasaio, plazo,controlamortiza
             FROM planpago 
             LEFT JOIN deudores AS d USING(idsucaux,idproducto,idauxiliar) 
            WHERE (vence BETWEEN p_defecha AND p_afecha)
                  AND (estatus in (3,4) ) -- AND (idsucaux,idproducto,idauxiliar)=(1,3214,74) 
            --GROUP BY idsucursal, idrol, idasociado, idsucaux, idproducto, idauxiliar, fechaactivacion, montoentregado, tipoprestamo, of_periodo(vence),kauxiliar,tasaio,plazo,controlamortiza
            ORDER BY idsucursal,idrol,idasociado,idsucaux,idproducto,idauxiliar,vence LOOP

      _comision := 0.00;
      SELECT INTO _concobro, _comision_sp, _comision_id,_id_cero COALESCE(concobro,false), COALESCE(comision_sp,0.00), COALESCE(comision_id,0.00),COALESCE(com_id_cero,0)
             FROM  ofx_multicampos_sustentable.auxiliar_masdatos 
             WHERE kauxiliar = r.kauxiliar;

      SELECT INTO _io_desc, _io_incr COALESCE(io_desc,0.00), COALESCE(io_incr,0.00) 
             FROM  ppv.planpago_escalonado
             WHERE kauxiliar = r.kauxiliar and idpago = r.idpago;
  
      IF _concobro THEN  
        SELECT INTO _diasgracia valor::INTEGER
              FROM valores_anexos 
              WHERE (idtabla,idcolumna,idelemento)=('deudores','_mc_diasgraciaio',r.kauxiliar::TEXT);
        _diasgracia := COALESCE(_diasgracia,0);  
        pg_diasxtasa := COALESCE(ofpn('/socios/productos/prestamos/' |+ r.idproducto::TEXT,'dias por tasa'),ofpn('/socios/productos/prestamos','dias por tasa'),30);
        -- Comision por idpago
        _comision := ROUND(((((r.montoentregado * (r.tasaio/100))/pg_diasxtasa) * _diasgracia) / r.plazo),2);
        IF _comision_sp > 0 THEN
          _comision := _comision_sp;
        END IF;
      END IF;
      _seg_da       :=COALESCE(r.seguros_unidad,0.00);
      _seg_vi       :=COALESCE(r.seguros_vida,0.00);
      _gps          :=COALESCE(r.gps,0.00);
      _comision     :=COALESCE(_comision,0.00);
      _comision_id  :=COALESCE(_comision_id,0.00);
      _io_desc      :=COALESCE(_io_desc,0.00);
      _io_incr      :=COALESCE(_io_incr,0.00);
      --IF r.idpago = 1 then
      --  SELECT INTO _gps1, _vida1, _unidad1 COALESCE(gps_1,0.00), COALESCE(segvid_1,0.00), COALESCE(seguni_1,0.00)
      --         FROM ofx_multicampos_sustentable.auxiliar_masdatos 
      --         WHERE kauxiliar=r.kauxiliar;
      --  IF _gps1 > 0 THEN
      --    _gps := _gps1;
      --  END IF;
      --  IF _vida1 > 0 THEN
      --    _seg_vi := _vida1;
      --  END IF;
      --  IF _unidad1 > 0 THEN
      --    _seg_da := _unidad1;
      --  END IF;
      --END IF;
      IF (r.controlamortiza = 8 and r.io = 0) THEN
        SELECT INTO r.io interes_total from of_deudor(r.idsucaux,r.idproducto,r.idauxiliar,r.vence);
        r.io := COALESCE(r.io,0.00);
      END IF;


      
      t.socio          :=r.idsucursal||'-'||r.idrol||'-'||r.idasociado;
      t.auxiliar       :=r.idsucaux||'-'||r.idproducto||'-'||r.idauxiliar;
      t.nombre         :=of_nombre_asociado(r.idsucursal,r.idrol,r.idasociado);
      t.fecha_act      :=r.fechaactivacion;
      t.fecha_venc     :=r.vence;
      t.mto_dsip       :=r.montoentregado;
      t.abono          :=r.abono;
      t.interes        :=r.io;
      IF (of_iva_general(r.idsucaux,r.idproducto,r.idauxiliar,r.tipoprestamo,r.vence)) THEN
        t.iva            :=round((r.io*(factor_iva_io/100)),2);
      ELSE
        t.iva            :='0.00';
      END IF;      
      t.Seg_danos      :=_seg_da;
      t.iva_seg_danos  :=round((_seg_da*(factor_iva_io/100)),2);
      t.seg_vida       :=_seg_vi;
      t.gps            :=_gps;
      t.iva_gps        :=round((_gps*(factor_iva_io/100)),2);
      t.comision       :=_comision;  
      t.iva_comision   :=round((_comision*(factor_iva_io/100)),2);
      t.diferido       := of_si(r.idpago>_id_cero,_comision_id,0);
      t.io_diferir     := _io_desc;
      t.io_cobrar      := _io_incr;
      t.facturar       :=round(of_numeric(t.interes)+of_numeric(t.Seg_danos)+of_numeric(t.iva_seg_danos)+
                         of_numeric(t.seg_vida)+of_numeric(t.gps)+of_numeric(t.iva_gps)+of_numeric(t.comision)+of_numeric(t.iva_comision)+ of_numeric(t.diferido) + of_numeric(t.io_cobrar) - of_numeric(t.io_diferir),2);
      t.num_Pago       :=r.idpago;   


      t.intereses_a_cobrar := t.interes::NUMERIC - t.io_diferir::NUMERIC + t.io_cobrar::NUMERIC;
      t.suma_var_total      := t.abono::NUMERIC + t.seg_danos::NUMERIC + t.iva_seg_danos::NUMERIC + t.seg_vida::NUMERIC + t.gps::NUMERIC + t.iva_gps::NUMERIC + t.comision::NUMERIC + t.iva_comision::NUMERIC + t.diferido::NUMERIC;

      --PERFORM of_ofx_notice('info', t.intereses_a_cobrar::TEXT); 
      --PERFORM of_ofx_notice('info', t.suma_var_total::TEXT); 
         
      RETURN NEXT t;  
  --END LOOP;
  END LOOP;
  RETURN;
END;$$
LANGUAGE plpgsql;

