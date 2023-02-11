CREATE OR REPLACE FUNCTION public.ofx_forma_ec_estandar()
 RETURNS SETOF ofx_forma_ec_estandar
 LANGUAGE plpgsql
AS $function$
DECLARE


  -- Variables
  t               ofx_forma_ec_estandar%ROWTYPE;
  ps_idsucaux     INTEGER:=0;
  ps_idproducto   INTEGER:=0;
  ps_idauxiliar   INTEGER:=0;
  ps_idsucursal   INTEGER:=0;
  rsuc            RECORD;   --> Datos de la Sucursal.
  ra              RECORD;   --> Datos del Asociado.
  rde             RECORD;   --> Datos del Crédito.
  rto             RECORD;   --> Datos para la suma total de conceptos.
  rpa             RECORD;   --> Plan de amortización
  rdt             RECORD;
  rdt2            RECORD;   --> Mas datos en detalle auxiliar.
  rpp             RECORD;   --> Datos del Plan de pagos.
  rsm             RECORD;   --> Datos de la sucursal Matriz.
  _cubierto       NUMERIC:=0.00;
  -- Contenedores de expediente
  _auxiliar_deseado  TEXT;
  _saldofecha        TEXT;
  _scat           TEXT:='';
  _amortiza       TEXT:='';
  _cati           NUMERIC(12,2);
  _saldoini       NUMERIC:=0.00;
  _pcargos        NUMERIC:=0.00; 
  _pabonos        NUMERIC:=0.00; 
  _saldofin       NUMERIC:=0.00;
  _nmovimientos   INTEGER:=0;
  _diasxtasa      INTEGER:=0;
  nelemento      INTEGER:=0;
  i              INTEGER:=0;
  ii             INTEGER:=0; -- Contador
  --------------------------
  ps_mensual     BOOLEAN;
  ps_dfecha      DATE;
  ps_afecha        DATE;
  --------------------
  _limite        INTEGER:=13;
  _diatarde      TEXT;
  _totinteres    NUMERIC:=0.00;
  _formato_io    TEXT; -- Formato del interes ordinario.
  _formato_cat   TEXT; -- Formato del CAT.
  _proxvencimiento  DATE; -- Proximo vencimiento?
  _limit_det     INTEGER:=0;
  _det_mov           BOOLEAN:=FALSE;
  _descripcion_det   TEXT:='';
  _saldoini_cero     BOOLEAN:=FALSE; -- Parametro para determinar si mostrar saldo inicial cero
  _dt_dinamico       BOOLEAN:=of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_dinamico');

  _activa_ley_all BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_activa_leyenda_all');-- Activa todas las polizas
  _activa_ley_1   BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_activa_leyenda_ingreso');-- Activa solo tipo ingreso
  _activa_ley_2   BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_activa_leyenda_egreso'); -- Activa solo tipo egreso
  _activa_ley_3   BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_activa_leyenda_diario'); -- Activa solo tipo diario
  _ley_ingreso    TEXT   := of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_leyenda_mov_ingreso');-- Leyenda solo tipo ingreso
  _ley_egreso     TEXT   := of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_leyenda_mov_egreso'); -- Leyenda solo tipo ingreso
  _ley_diario     TEXT   := of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_leyenda_mov_diario'); -- Leyenda solo tipo ingreso
  _ley_cargo      TEXT   := of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_leyenda_mov_cargo');  -- Leyenda cuando es un cargo.
  _dt_base   BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_base');
  tolerante_prox_pago BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','tolerante_prox_pago');
  _dt_length_desc INTEGER:= of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_length_desc');  -- Longitud en la descripcion de detalle.
  _gen_detalle    BOOLEAN:= of_params_get('/formatos/ofx_estado_cuenta_deudores','gen_detalle'); -- DGZZH 24/08/2016
  _calcula_iva    BOOLEAN;
  factor_iva_io   NUMERIC;
  base_iva_io     NUMERIC;
  _pago_exijible  NUMERIC;
  
BEGIN
  -- PERFORM of_param_sesion_raise(NULL);
  
  -- Inicializando variables.
  -- Datos Generales de la Sucursal Matriz.
  t.suc_matriz_idsucursal   := 0 ; -- Clave de Sucursal.
  t.suc_matriz_nom_sucursal := ''; -- Nombre de la Sucursal.
  t.suc_matriz_calle        := ''; -- Calle Ext e Int de la Sucursal.
  t.suc_matriz_colonia      := ''; -- Colonia y CP de la Sucursal.
  t.suc_matriz_municipio    := ''; -- Municipio de la Sucursal.
  t.suc_matriz_estado       := ''; -- Estado de la Sucursal.
  t.suc_matriz_rfc          := ''; -- Telefonos de la Sucursal.
  -- Datos de la Sucursal
  t.idsucursal              := 0 ;
  t.nom_sucursal            := '';
  t.suc_calle               := '';
  t.suc_colonia             := '';
  t.suc_municipio           := '';
  t.suc_estado              := '';
  t.suc_rfc                 := '';
  --------------------------------
  t.asociado                := '';
  t.nombre                  := '';
  t.rfc                     := '';
  t.curp                    := '';
  t.calle                   := '';
  t.colonia                 := '';
  t.municipio               := '';
  t.estado                  := '';
  --------------------------------
  t.periodo                 := '';
  t.cuenta                  := '';
  t.idsucaux                := '';
  t.idproducto              := '';
  t.idauxiliar              := '';
  t.credito                 := '';
  t.tipoptmo                := '';
  t.montosolicitado         := '';
  t.montoentregado          := '';
  t.fechaentrega            := NULL;
  t.tasaio                  := '';
  t.tasaio_venta            := ''; -- Tasa de venta-- Exclusivo para capitales.
  t.tasaim                  := '';
  t.tasaim_venta            := '';
  t.tasaim_x12              := '';
  t.cat                     := '';
  t.finalidad               := '';
  t.plazo                   := '';
  t.diasxplazo              := '';
  t.vence                   := NULL;
  t.ultimomovimiento        := NULL;
  t.proximo_abono           := NULL;
  t.fe_limite_pago          := '';
  t.saldofcha               := '';
  t.gastos_cobranza         := ''; --> Gastos de cobranza (El total de los que ha pago)
  t.monto_vencido_cap       := ''; 
  --------------------------------
  t.abono                   := '';
  t.interes                 := '';
  t.moratorio               := '';
  t.comisiones              := '';
  t.iva                     := '';
  t.montopago               := '';
  t.deudatotal              := '';
  t.estatuscartera          := '';
  t.diasmoracapital         := '';
  t.diasmorainteres         := '';
  t.xcentajecubierto        := '';
  t.comision_pagado         := '';
  t.fpago_comision          := NULL;
  t.pgovencido              := '';
  t.pago_exijible           := '';
  --------------------------------
  t.dt_fhora                := '';
  t.dt_ticket               := '';
  t.dt_concepto             := '';
  t.dt_cargo                := '';  
  t.dt_abono                := '';
  t.dt_saldo                := '';
  t.dt_referencia           := '';
  -- Detalle personalizado.
  --t.dt_abono                := '';
  t.dt_capital              := '';
  t.dt_interes              := '';
  t.dt_moratorio            := '';
  t.dt_iva                  := '';
  --------------------------------
  t.psaldoini               := '';
  t.pcargos                 := '';
  t.pabonos                 := '';
  t.psaldofin               := '';
  --------------------------------
  t.tot_cargo               := '';
  t.tot_capital             := '';
  t.tot_interes             := '';
  t.tot_moratorios          := '';
  t.tot_iva                 := '';
  t.tot_pago                := '';
  --------------------------------
  t.fechreal                := NULL;
  t.fechoperacion           := NULL;
  t.fechformato             := '';
  t.dfecha                  := NULL;
  t.afecha                  := NULL;
  t.horas                   := '';
  t.titulo                  := '';
  t.pagina                  := 0 ;
  t.npaginas                := 0 ;
  
  ps_idsucaux               := of_param_sesion_get('vsr_vars','ps_idsucaux');
  ps_idproducto             := of_param_sesion_get('vsr_vars','ps_idproducto');
  ps_idauxiliar             := of_param_sesion_get('vsr_vars','ps_idauxiliar');
  t.fechreal                := current_date;
  t.fechoperacion           := of_param_sesion_get('global','fecha')::DATE;
  ps_afecha                 := of_param_sesion_get('vsr_vars','ps_afecha');
  ps_dfecha                 := of_param_sesion_get('vsr_vars','ps_dfecha');
  
  -- Filtrar solo los activos
  PERFORM * FROM deudores
           WHERE (idsucaux,idproducto,idauxiliar) = (ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
                 idproducto IN (SELECT idproducto
                                  FROM of_dep_productos('PRE')) AND
                 estatus IN (3,4);
  IF (FOUND) THEN
    factor_iva_io := of_params_get('/socios/productos/prestamos','iva_io');
    base_iva_io   := of_params_get('/socios/productos/prestamos','base_iva_io');
    factor_iva_io := ROUND((factor_iva_io /100.00),2);
    base_iva_io   := ROUND((base_iva_io /100.00),2);
    factor_iva_io := factor_iva_io * base_iva_io;
    SELECT INTO _diasxtasa valor
      FROM params
     WHERE (idparam,idelemento)= ('/socios/productos/prestamos','dias por tasa');
    -- Obteniendo el formato de los decimales definido por el cliente
    SELECT INTO _formato_io * 
      FROM of_params_get('/formatos/ofx_estado_cuenta_deudores','formato_io');
    -- Obteniendo el foramto del CAT para los decimales.
    SELECT INTO _formato_cat * 
      FROM of_params_get('/formatos/ofx_estado_cuenta_deudores','formato_cat');
    -- Obteniendo el titulo del Estado de cuenta.
    SELECT INTO t.titulo * FROM of_params_get('/formatos/ofx_estado_cuenta_deudores','titulo');
    SELECT INTO t.conducef * FROM of_params_get('/formatos/ofx_estado_cuenta_deudores','conducef');

    -- Obteniendo el limite de detalle para los movimientos.
    _limit_det           := of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_limite');
  
    -- Obteniendo parametro activa leyenda personalizado en detalle de movimientos.
    _descripcion_det     := of_params_get('/formatos/ofx_estado_cuenta_deudores','descripcion_mov'); -- Activa leyenda personalizado
    _det_mov             := of_params_get('/formatos/ofx_estado_cuenta_deudores','dt_mov'); -- Leyenda para todo tipo de movimientos
    
    -- Obteniendo parametro si inicia con saldo cero.
    _saldoini_cero       := of_params_get('/formatos/ofx_estado_cuenta_deudores','saldoini_cero');

  
    t.periodo            := of_fecha_nombre(ps_dfecha,1) |+ ' al ' |+ of_fecha_nombre(ps_afecha,1);
    t.dfecha             := ps_dfecha;
    t.afecha             := ps_afecha;
    t.diasperiodo        := ps_afecha - ps_dfecha;
    --- Obteniendo la hora con formato de 12 horas.
    IF (TO_CHAR(now(),'HH24:MI:SS ')<'12:00') THEN 
      _diatarde           := 'AM';
    ELSE 
      _diatarde           := 'PM';
    END IF;
    
    t.horas               := TO_CHAR(now(),'HH12:MI:SS ')|+_diatarde;
    
    -- Filtrando el auxiliar o cuenta deseada.
    SELECT INTO rde * FROM of_deudor(ps_idsucaux,ps_idproducto,ps_idauxiliar,t.afecha);

    -- La sucursal concetradora.
    SELECT INTO rsm idsucursal, s.nombre AS sucursal,
                  c.nombre|+ ' No.' |+ numext |+ of_si((numint IS NULL) OR (TRIM(numint)=''),'',' Int. '|+ numint) AS calle,
                  rfc, col.nombre AS colonia, col.cp, m.nombre AS municipio, e.nombre AS estado
      FROM sucursales AS s
     INNER JOIN calles AS c USING (idcalle)
     INNER JOIN colonias AS col   USING (idcolonia)
     INNER JOIN municipios AS m USING (idmunicipio)
     INNER JOIN estados  AS e USING (idestado)
     WHERE idsucursal = 99; -- Concentradora
      t.suc_matriz_idsucursal   := rsm.idsucursal ; -- Clave de Sucursal.
      t.suc_matriz_nom_sucursal := rsm.sucursal; -- Nombre de la Sucursal.
      t.suc_matriz_calle        := rsm.calle; -- Calle Ext e Int de la Sucursal.
      -- DGZZH 02/05/2016 Correccion en la etiqueta de codigo postal, debe llevar un espacio entre la letra C y la P
      t.suc_matriz_colonia      := rsm.colonia|+ ', C. P.: '|+rsm.cp; -- Colonia y CP de la Sucursal.
      t.suc_matriz_municipio    := rsm.municipio; -- Municipio de la Sucursal.
      t.suc_matriz_estado       := rsm.estado; -- Estado de la Sucursal.
      t.suc_matriz_rfc          := rsm.rfc; -- Telefonos de la Sucursal.
    
    -- Obteniendo los datos de la Sucursal
    SELECT INTO rsuc idsucursal, s.nombre AS sucursal,
                     c.nombre|+ ' No.' |+ numext |+ of_si((numint IS NULL) OR (TRIM(numint)=''),'',' Int. '|+ numint) AS calle,
                     rfc, col.nombre AS colonia, col.cp, m.nombre AS municipio, e.nombre AS estado
      FROM sucursales AS s
     INNER JOIN calles AS c USING (idcalle)
     INNER JOIN colonias AS col   USING (idcolonia)
     INNER JOIN municipios AS m USING (idmunicipio)
     INNER JOIN estados AS e USING (idestado)
     WHERE idsucursal = of_param_sesion_get('global','sucursal')::INTEGER;

      t.idsucursal              := rsuc.idsucursal;
      t.nom_sucursal            := rsuc.sucursal;
      t.suc_calle               := rsuc.calle;
      t.suc_colonia             := rsuc.colonia|+ ', C. P.: '|+rsuc.cp;
      t.suc_municipio           := rsuc.municipio;
      t.suc_estado              := rsuc.estado;
      t.suc_rfc                 := rsuc.rfc;
    
    -- Obteniendo los Datos Generales del Asociado. 
    SELECT INTO ra idsucursal|+ '-' |+idrol|+ '-' |+idasociado AS asociado, d.nombre, paterno, materno, pfisica,  d.idsucdir, d.iddir,
                   c.nombre|+ ' No. ' |+ numext |+ of_si((numint IS NULL) OR (TRIM(numint)=''),'',' Int. '|+ numint) AS calle,
                   col.nombre AS colonia, m.nombre AS municipio, rfc, curp_rfc, cp, e.nombre AS estado, d.email
      FROM asociados
     INNER JOIN directorio AS d USING (idsucdir,iddir)
     INNER JOIN calles c USING(idcalle)
     INNER JOIN colonias col USING (idcolonia)
     INNER JOIN municipios m USING (idmunicipio)
     INNER JOIN estados e USING (idestado)
     WHERE (idsucursal,idrol,idasociado)=(rde.idsucursal,rde.idrol,rde.idasociado);
   
      t.asociado                := ra.asociado;
      IF (ra.pfisica) THEN
        t.nombre                := ra.paterno|+ ' ' |+ra.materno|+ ' '|+ra.nombre;      
      ELSE
        t.nombre                := ra.nombre;
      END IF;
      t.rfc                     := ra.rfc;
      t.curp                    := ra.curp_rfc;
      t.calle                   := ra.calle;
      t.colonia                 := ra.colonia|+ ', C. P.: '|+ra.cp;
      t.municipio               := ra.municipio;
      t.estado                  := ra.estado;
      t.email                   := ra.email;
      ---------------------------
      -- Asignando valores para los datos del crédito.
      t.cuenta                  := rde.idsucaux|+ '-' |+rde.idproducto|+ '-' |+rde.idauxiliar;
      t.idsucaux                := rde.idsucaux;
      t.idproducto              := rde.idproducto;
      t.idauxiliar              := rde.idauxiliar;
      SELECT INTO t.credito substring(nombre,1,24) FROM productos WHERE idproducto  = rde.idproducto;
      t.tipoptmo                := rde.tprest_nom;
      --t.credito   := substring(t.credito,1,28);
      t.saldofcha               := TO_CHAR(rde.saldo,'FM999,999,990.00');
      t.montosolicitado         := TO_CHAR(rde.montosolicitado,'FM999,999,990.00');
      t.montoentregado          := TO_CHAR(rde.montoentregado,'FM999,999,990.00');
      t.fechaentrega            := rde.fechaactivacion;
      t.tasaio                  := of_si(rde.tasaio <= 0,'0.00',trim(TO_CHAR(rde.tasaio,'FM99.0')));
      -- Obteniendo la tasa de venta caso CAPITALES.
      --SELECT INTO _totinteres sum(interes)
      --             FROM of_plan_amortizacion(rde.idsucaux,rde.idproducto,rde.idauxiliar,rde.fechaape);
      --t.tasaio_venta            := trim(to_char((((_totinteres /
      --                                    (ROUND((rde.plazo * rde.diasxplazo)/30.00))) /
      --                                    rde.montosolicitado) * 100) * 12,'FM99.00'));
      IF (_diasxtasa > 31) THEN  -- Se refiere a que es anual
        t.tasaio_x12              := of_si(rde.tasaio <= 0,'0.00',trim(to_char(rde.tasaio,_formato_io)));
        t.tasaim_x12              := of_si(rde.tasaim <=0,'0.00',trim(to_char(rde.tasaim,_formato_io)));
      ELSE -- Se considera mensual y obtenemos el anual.
        t.tasaio_x12              := of_si(rde.tasaio <= 0,'0.00',trim(to_char(rde.tasaio*12,_formato_io)));
        t.tasaim_x12              := of_si(rde.tasaim <=0,'0.00',trim(to_char(rde.tasaim*12,_formato_io)));
      END IF;
      t.tasaim                  := ROUND(rde.tasaim,1);
      --t.tasaim_venta            := trim(to_char((((_totinteres /
      --                                    (ROUND((rde.plazo * rde.diasxplazo)/30.00))) /
      --                                    rde.montosolicitado) * 100) * 12,'FM99.00'));
    
      SELECT INTO t.finalidad idfinalidad|+ ' - ' |+substring(nombre,1,24) FROM finalidades WHERE idfinalidad = rde.idfinalidad;
      t.plazo                   := of_si(rde.plazo <=1,rde.plazo::TEXT |+ ' Abono',rde.plazo::TEXT |+ ' Abonos');
      t.diasxplazo              := rde.diasxplazo;
      IF (rde.diasxplazo = 7) THEN
        t.tipoabono := 'Semanal(es)';
      ELSIF (rde.diasxplazo = 15) THEN
        t.tipoabono := 'Quincenal(es)';
      ELSIF  (rde.diasxplazo IN (28,30,31)) THEN
        t.tipoabono := 'Mensual(es)';
      ELSIF  (rde.diasxplazo IN (360,365,366)) THEN
        t.tipoabono := 'Anual(es)';
      ELSE
        t.tipoabono := 'Dia(s)';
      END IF;
      t.vence                   := rde.vence;
      t.ultimomovimiento        := rde.fechaultcalculo;
      SELECT INTO rpp * 
        FROM planpago 
       WHERE (idsucaux,idproducto,idauxiliar)=(rde.idsucaux,rde.idproducto,rde.idauxiliar) AND vence=ps_afecha::DATE;
      IF (FOUND) THEN
        _proxvencimiento        := rpp.vence;
      ELSE 
        _proxvencimiento        := rde.proximovenc;
      END IF; 
      t.proximo_abono           := rde.proximovenc; -- 29/01/2015 Su proximo abono
      -- 29/01/2015 Tolerante en el próximo abono?
      IF (tolerante_prox_pago) THEN
        t.fe_limite_pago        := CASE WHEN _proxvencimiento <= rde.vence THEN
                                            COALESCE(_proxvencimiento::TEXT,'PAGO INMEDIATO')
                                   ELSE 'PAGO INMEDIATO'
                                  END;
      ELSE
        t.fe_limite_pago        := CASE WHEN rde.proximovenc < rde.vence THEN
                                            COALESCE(rde.proximovenc::TEXT,'PAGO INMEDIATO')
                                   ELSE 'PAGO INMEDIATO'
                                  END;
      END IF;
      
       
      -- Obteniendo el porcentaje del cat.
      SELECT INTO t.cat valor::NUMERIC(12,2)
        FROM valores_anexos
       WHERE (idtabla,idcolumna,idelemento) = ('deudores',ps_idsucaux||'-'||ps_idproducto||'-'||ps_idauxiliar,'CAT');
      
      --IF (t.cat = 0) THEN
      t.cat   := COALESCE(trim(to_char(of_numeric(t.cat),_formato_cat)),'0.00');
      /*IF (t.cat = '0.00' OR t.cat IS NULL) THEN
        -- Basado en la función of_deudor_base_apply(TEXT[]).
        FOR rpa IN SELECT *        --DGZZH Primero se obtiene el valor de _scat.
                     FROM of_plan_amortizacion(ps_idsucaux,ps_idproducto,ps_idauxiliar,current_date) LOOP
          -- La suma del abono, interes y el iva, tienen que ir separadas por comas)
         -- _amortiza  := rpa.Abono + rpa.Interes;
          _scat := _scat |+ COALESCE(to_char(rpa.Abono + rpa.Interes,'FM999999990.00')|+',','');

        END LOOP;
        _amortiza  := trim(_scat,',');
        SELECT INTO _cati *        -- DGZZH Se asignan los valores 
          FROM of_cat4(_amortiza,rde.montosolicitado,rde.plazo,rde.diasxplazo,
               rde.idsucursal,rde.idrol,rde.idasociado,
               rde.idsucaux,rde.idproducto,rde.idauxiliar, rde.costos_asociados,
               rde.tasaio,rde.fechaactivacion);

        t.cat             := TO_CHAR(COALESCE(ROUND(_cati,2),0.00),'FM999,999,999,990.00');
     END IF;*/
    
      -- Obteniendo valores calculados.
      t.abono                   := TO_CHAR(rde.abono,'FM999,999,990.00');
      t.interes                 := TO_CHAR(rde.interes_total,'FM999,999,990.00');
      t.moratorio               := TO_CHAR(rde.interesmor_total,'FM999,999,990.00');
      -- DGZZH 20/06/2016 Las comisiones vienen siendo los costos asociados
      t.comisiones              := TO_CHAR(rde.costos_asociados ,'FM999,999,990.00');
      t.iva                     := TO_CHAR(rde.impuesto_total + rde.impuestoim_total + rde.impuestoco_total,'FM999,999,990.00');
      t.montopago               := TO_CHAR(rde.abono + rde.interes_total + rde.interesmor_total + rde.costos_asociados + of_numeric(t.iva),'FM999,999,990.00');
      t.deudatotal              := TO_CHAR(rde.saldo + rde.interes_total + rde.interesmor_total + rde.costos_asociados + of_numeric(t.iva),'FM999,999,990.00');
      --t.iva                     := TO_CHAR(of_numeric(t.iva),'FM999,999,990.00');
      t.estatuscartera          := CASE WHEN rde.estatuscartera = 1 THEN 'Vigente'
                                    WHEN rde.estatuscartera = 2 THEN 'En mora'
                                         ELSE 'Cartera Vencida'
                                         END;
      t.diasmoracapital         := rde.diasmora;
      t.diasmorainteres         := rde.diasmoraio;
      t.pgovencido              := rde.plazosvencidos || ' pago(s) por $' || TO_CHAR(rde.montovencido,'FM999,999,990.00')::TEXT || ' con ' ||
                                   numeric_larger(rde.diasmora, rde.diasmoraio) || ' días de Mora.';
      t.monto_vencido_cap       := to_char(rde.montovencido,'FM999,999,990.00');
      SELECT INTO t.comision_pagado, t.fpago_comision montocomision + montoca, fecha
        FROM detalle_auxiliar
       WHERE (idsucaux,idproducto,idauxiliar) = (ps_idsucaux,ps_idproducto,ps_idauxiliar) AND cargo > 0;
       t.comision_pagado        := TO_CHAR(of_numeric(t.comision_pagado),'FM999,999,990.00');
      IF (t.comision_pagado::NUMERIC <= 0.00) THEN
        t.fpago_comision   := NULL;
      END IF;
      
      -- DGZZH 28/07/2016 Obteniendo pago exijible cuando son pagos fijos
      IF (of_controlamortiza_es_pago_fijo(rde.controlamortiza)) THEN
        _calcula_iva  := of_iva_general(ps_idsucaux,ps_idproducto,ps_idauxiliar,rde.tipoprestamo,ps_afecha);
        SELECT INTO _pago_exijible
               coalesce(sum(abono-abpagado),0) +
               coalesce(of_si(_calcula_iva,sum(io-iopagado) * (1 + factor_iva_io), sum(io-iopagado)),0)
          FROM planpago
         WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND vence <= ps_afecha;
         t.pago_exijible :=  TO_CHAR(coalesce(_pago_exijible) + coalesce(rde.interesmor_total) + coalesce(rde.impuestoim_total),'FM999,999,990.00');
      ELSE
        t.pago_exijible  := t.montopago;
      END IF;
      
      -- Obteniendo los pagos acumulados.
      SELECT INTO rto 
             sum(cargo) AS cargo ,sum(abono) AS capital, sum(montoio) AS intereses,
             sum(montoim) AS moratorios, sum(montoimp) AS iva,
             sum(abono + montoio + montoim + montoimp) AS pagototal
        FROM detalle_auxiliar
       WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar);
      t.tot_cargo           := COALESCE(TO_CHAR(rto.cargo,'FM999,999,990.00'),'0.00');
      t.tot_capital         := COALESCE(TO_CHAR(rto.capital,'FM999,999,990.00'),'0.00');
      t.tot_interes         := COALESCE(TO_CHAR(rto.intereses,'FM999,999,990.00'),'0.00');
      t.tot_moratorios      := COALESCE(TO_CHAR(rto.moratorios,'FM999,999,990.00'),'0.00');
      t.tot_iva             := COALESCE(TO_CHAR(rto.iva,'FM999,999,990.00'),'0.00');
      t.tot_pago            := COALESCE(TO_CHAR(rto.pagototal,'FM999,999,990.00'),'0.00');
      
    -- Porcentaje cubierto.
    IF (rde.montoentregado > 0) THEN 
      _cubierto := ((rde.montoentregado - rde.saldo) / rde.montoentregado) * 100.00;
    ELSE
      _cubierto := 0;
    END IF;
      t.xcentajecubierto           := TO_CHAR(_cubierto,'FM990.00')|+ '%';

    -- Obteniendo el numero de registro de detalle.
    SELECT INTO _nmovimientos count(*)
      FROM of_auxmov(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha,ps_afecha);  

    SELECT INTO  t.pcargos COALESCE(TO_CHAR(sum(retiro),'FM999,999,990.00'),'0.00')
        FROM of_auxmov(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha,ps_afecha);

    SELECT INTO  t.pabonos COALESCE(TO_CHAR(sum(deposito),'FM999,999,990.00'),'0.00')
        FROM of_auxmov(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha,ps_afecha) WHERE tipo_mv = 1;


    t.psaldofin  := TO_CHAR(rde.saldo,'FM999,999,990.00');
    _saldoini    := of_auxiliar_saldo(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha-1);
    t.psaldoini  := TO_CHAR(_saldoini,'FM999,999,990.00');
    t.pagina     := 1 ;
    
    _dt_length_desc := COALESCE(_dt_length_desc,90);
    IF (_gen_detalle) THEN -- DGZZH 24/08/2016 ¿Generar registros de detalle?
      IF (_nmovimientos > 0) THEN
        IF (_dt_base) THEN  --  *** Tipo de detalle estandar ***
        --PERFORM of_ofx_notice('info','FLAG (2) DETA 1');
          FOR rdt IN SELECT *
                       FROM of_auxmov(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha,ps_afecha)
                        ORDER BY fecha LOOP
              i  := i + 1;
              ii := ii + 1;
              IF (i = 1) THEN
                IF NOT (_saldoini_cero) THEN -- Inicia con saldo cero en la entrega del préstamo?
                  IF (rdt.concepto ~'Entrega Prest' AND rdt.retiro > 0) THEN
                    t.psaldoini     := TO_CHAR(rdt.retiro,'FM999,999,990.00');
                  END IF;
                END IF;
              END IF;
  
            -- Deterninar si en la descricion será manipulado para establecer una leyenda personalizado :(
            IF (_det_mov) THEN
              IF (_activa_ley_all) THEN
                IF (rdt.concepto ~'Entrega Prest' AND rdt.retiro > 0) THEN
                  t.dt_concepto := t.dt_concepto |+ substring(_ley_cargo |+' '|+ TO_CHAR(rdt.retiro,'FM999,999,990.00'),1,_dt_length_desc)|+ E'\n';
                ELSE
                  t.dt_concepto := t.dt_concepto |+ substring(_descripcion_det |+' '|+
                                                              rdt.idsucaux::TEXT  |+'-'|+
                                                              rdt.idproducto::TEXT|+'-'|+
                                                              rdt.idauxiliar::TEXT,1,_dt_length_desc)|+ E'\n';
                END IF;
              ELSE
                IF (rdt.tipopol = 1) THEN
                  IF (_activa_ley_1) THEN  -- Leyenda pesonalizado tipo ingreso
                    t.dt_concepto   := t.dt_concepto |+ substring(_ley_ingreso,1,_dt_length_desc) |+ E'\n';
                  ELSE
                    t.dt_concepto   := t.dt_concepto |+ substring(rdt.concepto,1,_dt_length_desc) |+ E'\n';
                  END IF;
                ELSIF (rdt.tipopol = 2) THEN
                  IF (_activa_ley_2) THEN -- Leyenda pesonalizado tipo egreso
                    t.dt_concepto   := t.dt_concepto |+ substring(_ley_egreso,1,_dt_length_desc) |+ E'\n';
                  ELSE
                    t.dt_concepto   := t.dt_concepto |+ substring(rdt.concepto,1,_dt_length_desc) |+ E'\n';
                  END IF;
                ELSIF (rdt.tipopol = 3) THEN
                  IF (_activa_ley_3) THEN -- Leyenda pesonalizado tipo diario
                    t.dt_concepto := t.dt_concepto |+ substring(_ley_diario |+' '|+
                                                      rdt.idsucaux::TEXT         |+'-'|+
                                                      rdt.idproducto::TEXT       |+'-'|+
                                                      rdt.idauxiliar::TEXT,1,_dt_length_desc) |+ E'\n';
                  ELSE
                    t.dt_concepto   := t.dt_concepto |+ substring(rdt.concepto,1,_dt_length_desc)   |+ E'\n';
                  END IF;
                END IF;
              END IF;
            ELSE
              t.dt_concepto   := t.dt_concepto |+ substring(rdt.concepto,1,_dt_length_desc)   |+ E'\n';
            END IF;
            t.dt_fhora        := t.dt_fhora  |+ rdt.fecha::TEXT   |+ E'\n';
            t.dt_ticket       := t.dt_ticket |+ COALESCE(rdt.folio_ticket,0)::TEXT  |+ E'\n';
            t.dt_cargo        := t.dt_cargo |+ TO_CHAR(rdt.retiro,'FM999,999,990.00')   |+ E'\n';
            t.dt_abono        := t.dt_abono |+ TO_CHAR(rdt.deposito,'FM999,999,990.00')   |+ E'\n';
            t.dt_saldo        := t.dt_saldo |+ TO_CHAR(rdt.saldo,'FM999,999,990.00')   |+ E'\n';
            _pcargos          := _pcargos + rdt.retiro;
            IF (rdt.tipo_mv = 1) THEN -- Tipo de movimiento, abono a capital.
              _pabonos        := _pabonos + rdt.deposito;
            END IF;
            
            -- Imprimir la hoja si ii ha llegado a  _nmovimientos.
            IF (ii = _nmovimientos) THEN
              IF (_dt_dinamico) THEN
                RETURN NEXT t;
                EXIT;
              ELSE
                RETURN NEXT t;
              END IF;
            ELSIF (i = _limit_det) THEN
              IF (_dt_dinamico) THEN
                RETURN NEXT t;
                EXIT;
              ELSE
                RETURN NEXT t;
                t.pagina          := t.pagina + 1;
                t.dt_fhora        := '';
                t.dt_ticket       := '';
                t.dt_concepto     := '';
                t.dt_cargo        := '';
                t.dt_abono        := '';
                t.dt_saldo        := '';
                i                 := 0;
              END IF;
            END IF;
          END LOOP;
        ELSE          ----- *** DETALLE PERSONALIZADO CON COLUMNAS ADICIONALES Y DISTINTAS *** ---
          -- PERFORM of_ofx_notice('info','FLAGGG (1) DETA 2');
          -- Obteniendo el numero de registro de detalle.
          SELECT INTO _nmovimientos count(*)
            FROM detalle_auxiliar
           WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
                 fecha BETWEEN ps_dfecha AND ps_afecha;
          FOR rdt2 IN SELECT fecha, folio_ticket, referencia, cargo, abono, montoio, montoim, montoimp, montocomision
                        FROM detalle_auxiliar
                       WHERE (idsucaux,idproducto,idauxiliar)=(ps_idsucaux,ps_idproducto,ps_idauxiliar) AND
                             fecha BETWEEN ps_dfecha AND ps_afecha
                       ORDER BY fecha,oid LOOP
            i  := i + 1;
            ii := ii + 1;
            IF (rdt2.cargo > 0) THEN
              t.dt_fhora       := t.dt_fhora  |+ rdt2.fecha::TEXT   |+ E'\n';
              t.dt_ticket      := t.dt_ticket |+ COALESCE(rdt2.folio_ticket,0)::TEXT  |+ E'\n';
              t.dt_concepto    := t.dt_concepto |+ _ley_cargo|+' '|+ TO_CHAR(rdt2.cargo,'FM999,999,999,990.00') |+ E'\n';
              t.dt_capital     := t.dt_capital   |+ rdt2.abono   |+ E'\n';
              t.dt_interes     := t.dt_interes   |+ rdt2.montoio |+ E'\n';
              t.dt_moratorio   := t.dt_moratorio |+ rdt2.montoim |+ E'\n';
              t.dt_iva         := t.dt_iva       |+ (rdt2.montoimp + rdt2.montocomision) |+ E'\n';
            ELSE
              t.dt_fhora       := t.dt_fhora  |+ rdt2.fecha::TEXT   |+ E'\n';
              t.dt_ticket      := t.dt_ticket |+ COALESCE(rdt2.folio_ticket,0)::TEXT  |+ E'\n';
              t.dt_concepto    := t.dt_concepto |+ _descripcion_det |+ ' '|+TO_CHAR(ROUND(rdt2.abono + rdt2.montoio + rdt2.montoim + 
                                                                                     rdt2.montoimp + rdt2.montocomision, 2), 'FM999,999,999,990.00') |+ E'\n';
              t.dt_capital     := t.dt_capital |+ of_si(rdt2.abono > 0,TO_CHAR(ROUND(rdt2.abono, 2), 'FM999,999,999,990.00'),'0.00') |+ E'\n';
              t.dt_interes     := t.dt_interes |+ of_si(rdt2.montoio > 0,TO_CHAR(ROUND(rdt2.montoio, 2), 'FM999,999,999,990.00'),'0.00') |+ E'\n';
              t.dt_moratorio   := t.dt_moratorio |+ of_si(rdt2.montoim > 0,TO_CHAR(ROUND(rdt2.montoim, 2), 'FM999,999,999,990.00'),'0.00') |+ E'\n';
              t.dt_iva         := t.dt_iva |+ of_si((rdt2.montoimp + rdt2.montocomision) > 0,TO_CHAR(ROUND(rdt2.montoimp + rdt2.montocomision, 2), 'FM999,999,999,990.00'),'0.00') |+ E'\n';
            END IF;
            
            -- Imprimir la hoja si ii ha llegado a  _nmovimientos.
            IF (ii = _nmovimientos) THEN
              IF (_dt_dinamico) THEN
                RETURN NEXT t;
                EXIT;
              ELSE
                RETURN NEXT t;
              END IF;
            ELSIF (i = _limit_det) THEN
              IF (_dt_dinamico) THEN
                RETURN NEXT t;
                EXIT;
              ELSE
                RETURN NEXT t;
                t.pagina          := t.pagina + 1;
                t.dt_fhora        := '';
                t.dt_ticket       := '';
                t.dt_concepto     := '';
                t.dt_capital      := '';
                t.dt_interes      := '';
                t.dt_moratorio    := '';
                t.dt_iva          := '';
                i                 := 0;
              END IF;
            END IF;
          END LOOP;
        END IF;
      ELSE
        _saldoini       := of_auxiliar_saldo(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha-1);
        t.psaldoini     := TO_CHAR(_saldoini,'FM999,999,990.00');
        RETURN NEXT t;
      END IF;
    ELSE
      _saldoini       := of_auxiliar_saldo(ps_idsucaux,ps_idproducto,ps_idauxiliar,ps_dfecha-1);
      t.psaldoini     := TO_CHAR(_saldoini,'FM999,999,990.00');
      RETURN NEXT t;
    END IF;
  END IF;
  RETURN;
END;$function$