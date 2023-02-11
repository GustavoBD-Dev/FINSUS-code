CREATE OR REPLACE FUNCTION public.of_edoctaxaux(integer, integer, integer, date, date)
 RETURNS SETOF tipo_edocta
 LANGUAGE plpgsql
AS $function$
DECLARE

  -- Parametros Variables
  p_idsucaux        ALIAS FOR $1;
  p_idproducto      ALIAS FOR $2;
  p_idauxiliar      ALIAS FOR $3;
  p_fecha1          ALIAS FOR $4;
  p_fecha2          ALIAS FOR $5;
  
  -- Variables Locales
  redo            tipo_edocta%ROWTYPE;
  rm              tipo_edocta%ROWTYPE;
  r               RECORD;
  auxiliar        TEXT;
  tot_dep         NUMERIC;
  tot_ret         NUMERIC;
  _saldo          NUMERIC;
  _ssaldo         NUMERIC;
  _tipo_producto  NUMERIC;
  _fechaactivacion DATE;
  sw_sirve        INTEGER;
  sw_dia          INTEGER;
  _txt            TEXT;
  _fechaini       DATE;
  t_dispon        NUMERIC;
  t_abono         NUMERIC;
  t_deposito      NUMERIC;
  t_retiro        NUMERIC;
  t_into          NUMERIC;
  t_intm          NUMERIC;
  t_isr           NUMERIC;
  t_iva           NUMERIC;
  sdo_ini         NUMERIC;
  --
  ret             RECORD;
BEGIN
  tot_dep := 0;
  tot_ret := 0;
  _ssaldo := 0;
  
  SELECT INTO _fechaactivacion fechaactivacion FROM
    auxiliares WHERE idsucaux   = p_idsucaux AND 
                    idproducto = p_idproducto AND 
                    idauxiliar = p_idauxiliar;
  sw_dia := 1;
  IF _fechaactivacion >= (p_fecha1) THEN
    SELECT INTO sdo_ini,_fechaini saldoinicial,fechaactivacion FROM
    auxiliares WHERE idsucaux   = p_idsucaux AND 
                    idproducto = p_idproducto AND 
                    idauxiliar = p_idauxiliar;
    _txt := ' (Arranque) ';
    
  ELSE
    SELECT INTO sdo_ini of_auxiliar_saldo(p_idsucaux,p_idproducto, 
      p_idauxiliar,(p_fecha1 - sw_dia));
    _fechaini := p_fecha1;
     _txt := ' ';
  END IF;
  SELECT INTO _tipo_producto tipo FROM productos WHERE
    idproducto = p_idproducto;
  t_dispon :=0; t_abono := 0; t_intm := 0; t_into := 0;
  t_iva := 0; t_isr := 0;
  t_deposito :=0; t_retiro := 0;
  redo.orden         := 1;
  redo.tipo_producto := _tipo_producto;
  redo.idsucaux      := p_idsucaux;
  redo.idproducto    := p_idproducto;
  redo.idauxiliar    := p_idauxiliar;
  redo.idusuario     := ' ';
  redo.mv_ax         := 0;
  redo.tipo_mv       := 0;
  redo.folio_ticket  := 0;
  redo.folio         := ' ';
  redo.tipopol       := 0;
  redo.idpoliza      := 0;
  redo.idsucpol      := 0;
  redo.periodo       := ' ';
  redo.fecha         := _fechaini;
  redo.concepto      := 'Saldo Inicial ' || _txt;
  redo.deposito      := 0;
  redo.retiro        := 0;
  redo.saldo         := sdo_ini;
  redo.notas         := ' ';
  redo.auxiliar      := ' ';
  redo.referencia    := ' ';
  --RETURN NEXT redo;
  FOR rm  IN SELECT *  
       FROM of_auxmov(p_idsucaux,p_idproducto,p_idauxiliar,
       p_fecha1,p_fecha2) ORDER BY fecha LOOP
       
    --IF rm.mv_ax = 1 THEN -- Solo movtos que afectan el saldo
      --IF _tipo_producto = 2 THEN
      --  _ssaldo := _ssaldo - rm.deposito + rm.retiro;
      --ELSE
        _ssaldo := _ssaldo + rm.deposito - rm.retiro;
      --END IF;
    --END IF;
    redo.secuencia     := rm.secuencia;
    redo.orden         := rm.orden;
    redo.tipo_producto := rm.tipo_producto;
    redo.idsucaux      := rm.idsucaux;
    redo.idproducto    := rm.idproducto;
    redo.idauxiliar    := rm.idauxiliar;
    redo.idusuario     := rm.idusuario;
    redo.tipo_mv       := rm.tipo_mv;
    redo.folio_ticket  := rm.folio_ticket;
    redo.mv_ax         := rm.mv_ax;
    redo.folio         := rm.folio;
    redo.tipopol       := rm.tipopol;
    redo.idpoliza      := rm.idpoliza;
    redo.idsucpol      := rm.idsucpol;
    redo.periodo       := rm.periodo;
    redo.fecha         := rm.fecha;
    redo.concepto      := rm.concepto;
    redo.deposito      := rm.deposito;
    redo.retiro        := rm.retiro;
    --redo.saldo         := _ssaldo;
    redo.saldo         := rm.saldo;
    redo.notas         := rm.notas;
    redo.auxiliar      := rm.auxiliar;
    redo.hora          := rm.hora;
    redo.referencia    := rm.referencia;
    
    RETURN NEXT redo;
    --
    -- Resumen        @JMCR 22/Abr/05
    -- 
    IF rm.tipo_producto = 1 THEN 
    -- Acreedor
      IF rm.tipo_mv = 1 THEN
         t_deposito := t_deposito + rm.deposito;
         t_retiro   := t_retiro   + rm.retiro;
      END IF;
      IF rm.tipo_mv = 2 THEN
         t_into := t_into + rm.retiro;
      END IF;
      IF rm.tipo_mv = 4 THEN
         t_isr := t_isr + rm.deposito;
      END IF;
    ELSE
    -- Deudor
      IF rm.tipo_mv = 1 THEN
         t_dispon := t_dispon + rm.retiro;
         t_abono  := t_abono  + rm.deposito;
      END IF;
      IF rm.tipo_mv = 2 THEN
         t_into := t_into + rm.deposito;
      END IF;
      IF rm.tipo_mv = 3 THEN
         t_intm := t_intm + rm.deposito;
      END IF;
      IF rm.tipo_mv = 4 THEN
         t_iva := t_iva + rm.deposito;
      END IF;
    END IF;
  END LOOP;
  
  -- JCH: 13/ene/2009: Agregar los movimientos en tránsito pendientes y los rechazados
  FOR ret IN SELECT et.*,p.idusuario,p.hora
               FROM en_transito AS et
               LEFT JOIN polizas AS p USING (idsucpol,periodo,tipopol,idpoliza)
              WHERE ((et.idsucaux,et.idproducto,et.idauxiliar)=(p_idsucaux,p_idproducto,p_idauxiliar)) AND 
                    (NOT aplicado OR (aplicado AND notas <> 'Aplicado')) LOOP
    redo.orden         := 1;
    redo.tipo_producto := 1;
    redo.concepto := 'Abono con cheque salvo buen cobro';
    IF (ret.aplicado) THEN
      redo.referencia := 'RECHAZADO: ' || COALESCE(ret.notas,'???');
    ELSE
      redo.referencia := 'En transito';
    END IF;
    redo.idsucaux      := ret.idsucaux;
    redo.idproducto    := ret.idproducto;
    redo.idauxiliar    := ret.idauxiliar;
    redo.idusuario     := ret.idusuario;
    redo.tipo_mv       := 1;
    redo.folio_ticket  := NULL;
    redo.mv_ax         := 1; -- Afecta al saldo
    redo.folio         := ret.tipopol::text || '-' ||  
                          ret.idpoliza::text;
    redo.tipopol       := ret.tipopol;
    redo.idpoliza      := ret.idpoliza;
    redo.idsucpol      := ret.idsucpol;
    redo.periodo       := ret.periodo;
    redo.fecha         := ret.fecha;
    redo.deposito      := ret.capital;
    redo.retiro        := 0.00;
    --redo.saldo         := 0;
    redo.saldo         := 0.00;
    redo.auxiliar      := ' ';
    redo.notas         := '';
    redo.hora          := ret.hora;
    RETURN NEXT redo;
  END LOOP;
  redo.referencia := '';
    
  SELECT INTO _ssaldo of_auxiliar_saldo(p_idsucaux,p_idproducto, 
        p_idauxiliar,p_fecha2);
  redo.orden         := 1;
  redo.tipo_producto := _tipo_producto;
  redo.idsucaux      := p_idsucaux;
  redo.idproducto    := p_idproducto;
  redo.idauxiliar    := p_idauxiliar;
  redo.idusuario     := ' ';
  redo.tipo_mv       := 0;
  redo.folio_ticket  := 0;
  redo.mv_ax         := 0;
  redo.folio         := ' ';
  redo.tipopol       := 0;
  redo.idpoliza      := 0;
  redo.idsucpol      := 0;
  redo.periodo       := ' ';
  redo.fecha         := p_fecha2;
  redo.concepto      := 'Saldo Final ';
  redo.deposito      := 0;
  redo.retiro        := 0;
  redo.saldo         := _ssaldo;
  redo.notas         := ' ';
  redo.auxiliar      := ' ';
  redo.referencia    := ' ';
  --RETURN NEXT redo;
  --
  -- Genera las lineas del resumen
  --
  redo.orden         := 3;
  redo.concepto      := 'Saldo Inicial...................... ';
  redo.deposito      := 0;
  redo.retiro        := 0;
  redo.saldo         := sdo_ini;
  RETURN NEXT redo;
  
  IF _tipo_producto = 1 THEN
    -- Acreedor 
    redo.orden         := 3;
    redo.concepto      := 'Total Depósitos.................... ';
    redo.saldo         := t_deposito;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total Retiros...................... ';
    redo.saldo         := t_retiro;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total Retiro de Interés Neto....... ';
    redo.saldo         := t_into;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total ISR.......................... ';
    redo.saldo         := t_isr;
    RETURN NEXT redo;
  ELSE
    -- Deudor
    redo.orden         := 3;
    redo.concepto      := 'Total Disposiciones................ ';
    redo.saldo         := t_dispon;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total Abonos....................... ';
    redo.saldo         := t_abono;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total Interés Ordinario Neto....... ';
    redo.saldo         := t_into;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total Interés Moratorio Neto....... ';
    redo.saldo         := t_intm;
    RETURN NEXT redo;
    redo.orden         := 3;
    redo.concepto      := 'Total IVA.......................... ';
    redo.saldo         := t_iva;
    RETURN NEXT redo;
  END IF;
  redo.orden         := 3;
  redo.concepto      := 'Saldo Final........................ ';
  redo.saldo         := _ssaldo;
  RETURN NEXT redo;
  --
  -- Fin de resumen
  --
  SELECT INTO redo * FROM  
         of_auxdet(p_idsucaux,p_idproducto,p_idauxiliar, 
                   p_fecha1,p_fecha2);
  RETURN NEXT redo;
  RETURN;
END;$function$