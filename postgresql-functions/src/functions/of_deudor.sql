CREATE OR REPLACE FUNCTION public.of_deudor(integer, integer, integer, date, date, boolean)
 RETURNS tipo_deudor
 LANGUAGE plpgsql
AS $function$
DECLARE
  -- Parámetros
  p_idsucaux   ALIAS FOR $1;
  p_idproducto ALIAS FOR $2;
  p_idauxiliar ALIAS FOR $3;
  p_afecha     ALIAS FOR $5; --si es null NO CALCULAR NADA
  p_afectar    ALIAS FOR $6;

  -- Variables
  td        tipo_deudor%ROWTYPE;
  fx        VARCHAR; -- Nombre de la función a llamar
  n         INTEGER;
  _defecha  DATE;
  q         TEXT; -- Query a ejecutar
  param_a   TEXT[];
  param_t   TEXT;
  sw_nc     integer;
  --
  ps_gen_caratula   BOOLEAN;
  _dato             TEXT;
  c                 TEXT;
  rvalor            RECORD;
  _idprefijo        TEXT;
  --
  rca               RECORD;
  _ca               TEXT; -- Texto sobre costos asociados calculados
  total_ca          NUMERIC := 0.00;
  _ca_fes           BOOLEAN := FALSE;
BEGIN

  _ca_fes        := ofpb('/socios/costos_asociados','ca_fes',FALSE);

  ps_gen_caratula := of_param_sesion_get_boolean('expediente','gen_caratula');
  sw_nc := 0;
  -- Datos básícos del auxiliar ------------------------------------------------
  SELECT INTO td * FROM of_tipo_deudor($1,$2,$3,NULL);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'of_tipo_deudor: Auxiliar no existe (%-%-%)',
                      p_idsucaux,p_idproducto,p_idauxiliar;
  END IF;

  -- No requiere de cálculo ----------------------------------------------------
  IF (p_afecha IS NULL) THEN -- Normalmente es un cargo (no es un abono)
    RETURN td;
  END IF;
  -- Si la fecha inicial es NULA entonces usar una de las siguientes (no NULL)
  _defecha := COALESCE($4,td.FechaUltCalculo,td.FechaActivacion,td.FechaApe);

  -- JCH: 29/03/2011 Primero calcular los costos asociados. Esto no permitirá tener una relación de
  -- los costos (en variable tipo TEXT) que se puede concatenar en el proceso del tipo de cálculo que
  -- le corresponda para ponerlo como caratula o en expediente.
  IF (NOT _ca_fes) THEN
    total_ca := 0.00;
    _ca      := NULL;
    FOR rca IN SELECT * FROM of_ca_auxiliar(p_idsucaux,p_idproducto,p_idauxiliar,p_afecha,p_afectar) LOOP
      total_ca := total_ca + rca.cargo + rca.abono - rca.descuento;
      _ca := COALESCE(_ca,'') |+ '                ' |+
             TO_CHAR(rca.cargo + rca.abono,'FM999,999,990.00') ||
             of_si(rca.descuento<>0.00,' - ' ||
             to_char(rca.descuento,'FM999,999,990.00'),'') || ': ' ||
             COALESCE(rca.nombre,'') || E'\n';
    END LOOP;
    IF (_ca IS NOT NULL) THEN
      PERFORM of_param_sesion_set('ca','detalle',_ca);
    END IF;
  END IF;


  -- ---------------------------------------------------------------------------
  -- Determinar el proceso de Tipo de Cálculo de Interés -----------------------
  -- ---------------------------------------------------------------------------
  IF (td.tipocalculo<>0)  THEN
    SELECT INTO fx datos[1]
      FROM tablas
     WHERE idtabla   = '_tci_deudor' AND
           idelemento= td.tipocalculo::text;
    IF (fx IS NULL) THEN -- No existe ==> No calcular nada
      RAISE EXCEPTION 'of_deudor(): No existe tipo de cálculo: %',td.tipocalculo;
    ELSE
      -- ¿Existe la función?
      SELECT INTO n count(*) FROM pg_proc WHERE proname=(fx|+'_ci')::name;
      IF (n IS NULL OR n=0) THEN -- No existe esa función ==> No calcular nada
        RAISE EXCEPTION '1 of_deudor(): No existe función: %_ci(), tipocalculo=%, producto=%',fx,td.tipocalculo,td.idproducto;
      ELSE
        param_a := ARRAY[of_si(p_afectar,'TRUE','FALSE')];
        param_t := param_a;
        IF (_defecha IS NULL) THEN
          q := 'SELECT * FROM ' |+ fx |+ '_ci' |+
                '(' |+ p_idsucaux::text   |+ ','
                      |+ p_idproducto::text |+ ','
                      |+ p_idauxiliar::text |+ ','
                      |+ 'NULL,'
                      |+ quote_literal(p_afecha::text) |+ ','
                      |+ quote_literal(param_t) |+ ')';
        ELSE
          q := 'SELECT * FROM ' |+ fx |+ '_ci' |+
                '(' |+ p_idsucaux::text   |+ ','
                      |+ p_idproducto::text |+ ','
                      |+ p_idauxiliar::text |+ ','
                      |+ quote_literal(_defecha::text)  |+ ','
                      |+ quote_literal(p_afecha::text) |+ ','
                      |+ quote_literal(param_t) |+ ')';
        END IF;
        -- RAISE NOTICE 'of_deudor(): Ejecutando función: %',q;
        -- Esto porque Execute no acepta "SELECT INTO"
        FOR td IN EXECUTE q LOOP
        END LOOP;
        sw_nc := 1;
      END IF;
    END IF;
  END IF;
  
  -- Terminar con datos de costos asociados
  PERFORM of_param_sesion_unset('ca','detalle');
  IF (NOT _ca_fes) THEN
    td.costos_asociados := total_ca;
  END IF;

  IF sw_nc = 0 AND ps_gen_caratula = TRUE THEN
  --/////// SIN TIPO DE CALCULO
  --/////// GENERA CARATULA DE EXPEDIENTE POR DEFAULT
  td.caratula_exp :=
    'Saldo Actual: ' |+ to_char(td.saldo,'999,999,999.99') |+
    '           Interes a la fecha: ' |+
    to_char(td.interesord,'999,999,999.99') |+ E'\n' |+
    'Fecha apertura: '  |+ td.fechaape::TEXT |+ E' \n' |+
    'Ultimo movimiento: ' |+ td.fechaultima::TEXT |+ E' \n' |+
    'Ultimo cálculo: ' |+ td.fechaultcalculo::TEXT |+ E' \n';
  END IF;

  RETURN td;
END;$function$