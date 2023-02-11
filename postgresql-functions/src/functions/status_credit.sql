
CREATE TYPE ofx_estatus_credito AS (
    credito         TEXT,
    cliente         TEXT,
    nombre          TEXT,
    vin             TEXT,
    cuota           NUMERIC,
    cta_2001        TEXT,
    sdo_cta_2001    NUMERIC,
    vencido         NUMERIC,
    mto_liquidar    NUMERIC,
    abonos          INTEGER
);

CREATE OR REPLACE FUNCTION estatus_credito(INTEGER, INTEGER, INTEGER)
    RETURNS SETOF ofx_estatus_credito AS $$
DECLARE

    st              ofx_estatus_credito%ROWTYPE;
    var_idsucaux    INTEGER := $1;
    var_idproducto  INTEGER := $2;
    var_idauxiliar  INTEGER := $3;
    mto_ideal       INTEGER := 0;
    mto_abdo        INTEGER := 0;

BEGIN

    -- NUMERO DE CREDITO
    SELECT INTO st.credito idsucaux||'-'||idproducto||'-'||idauxiliar 
      FROM deudores
     WHERE (idsucaux, idproducto, idauxiliar) = (var_idsucaux, var_idproducto, var_idauxiliar);

    -- CLIENTE
    SELECT INTO st.cliente idsucursal||'-'||idrol||'-'||idasociado 
      FROM deudores
     WHERE (idsucaux, idproducto, idauxiliar) = (var_idsucaux, var_idproducto, var_idauxiliar);
    
    -- NOMBRE
    SELECT INTO st.nombre of_nombre_asociado(d.idsucursal, d.idrol, d.idasociado)
      FROM deudores d
     WHERE (idsucaux, idproducto, idauxiliar) = (var_idsucaux, var_idproducto, var_idauxiliar);
    
    -- VIN
    SELECT INTO st.vin ms.vin
      FROM deudores d
            INNER JOIN ofx_multicampos_sustentable.auxiliar_masdatos ms USING(kauxiliar)
     WHERE (idsucaux, idproducto, idauxiliar) = (var_idsucaux, var_idproducto, var_idauxiliar);

    -- CUOTA
    SELECT INTO st.cuota  (abono + io)  
      FROM planpago
     WHERE (idsucaux,idproducto,idauxiliar) = (var_idsucaux,var_idproducto,var_idauxiliar);

    -- CUENTA 2001 y SALDO
    SELECT INTO st.cta_2001,st.sdo_cta_2001 ar.idsucauxref||'-'||ar.idproductoref||'-'||ar.idauxiliarref, of_auxiliar_saldo(ar.idsucauxref, ar.idproductoref, ar.idauxiliarref, now()::DATE) 
      FROM auxiliares_ref ar
     WHERE (idsucaux,idproducto,idauxiliar) = (var_idsucaux,var_idproducto,var_idauxiliar);

    -- VENCIDO -> MONTO IDEAL - MONTO ABONADO
    -- MONTO IDEAL
    SELECT INTO mto_ideal sum(abono + io)
      FROM planpago
     WHERE (idsucaux,idproducto,idauxiliar) = (var_idsucaux,var_idproducto,var_idauxiliar)
            AND vence <= now();
    -- MONTO ABONADO
    SELECT INTO mto_abdo sum(abono)
      FROM detalle_auxiliar
     WHERE (idsucaux,idproducto,idauxiliar) = (var_idsucaux,var_idproducto,var_idauxiliar);

    --  RAISE NOTICE '% - %', mto_ideal, mto_abdo; 
     st.vencido = mto_ideal - mto_abdo;

     st.mto_liquidar := 0;
     st.abonos := 0;

     RETURN NEXTst;

END

$$ LANGUAGE plpgsql;