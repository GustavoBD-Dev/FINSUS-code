
-- BUSCAR DATOS PARA CONTRATO PR
select
	d.idsucaux || '-' || d.idproducto || '-' || d.idauxiliar AS credito,
    of_nombre_asociado(aso.idsucursal, aso.idrol, aso.idasociado) AS nombre,
    of_rellena(d.kauxiliar :: TEXT, 9, '0', 2) |+ of_dv_gen(d.kauxiliar :: TEXT) |+ CIE_BBVA_00((of_rellena(d.kauxiliar :: TEXT, 9, '0', 2) |+ of_dv_gen(d.kauxiliar :: TEXT))::TEXT) AS referencia,
    aso.idsucursal || '-' || aso.idrol || '-' || aso.idasociado AS cliente,
    calles.nombre || ',' || numext || ',' || numint || ',' || colonias.nombre || ',' || estados.nombre || ',' || cp as direccion_completa,
    rfc,
    '$ ' |+ to_char(round(d.montosolicitado, 2), 'FM999,999,990.90') |+ ' (' |+ of_numero_letra(d.montosolicitado) |+ ')' AS saldo_insoluto_texto
FROM
    deudores AS d
    INNER JOIN asociados AS aso USING(idsucursal, idrol, idasociado)
    INNER JOIN directorio USING(idsucdir, iddir)
    INNER JOIN calles USING(idcalle)
    INNER JOIN colonias USING(idcolonia)
    INNER JOIN municipios USING(idmunicipio)
    INNER JOIN estados USING(idestado)
    INNER JOIN roles AS r USING(idrol)
    INNER JOIN contratos USING(idsucaux, idproducto, idauxiliar);
       WHERE (idsucaux, idproducto, idauxiliar) = (1,7200,4052);




CREATE TEMP TABLE obtener_referencias(idsucaux INTEGER, idproducto INTEGER, idauxiliar INTEGER);
\COPY obtener_referencias FROM 'CREDITOS_PRINCEPS.csv' DELIMITER ',';
\o REFERENCIAS_V3.txt
SELECT
	d.idsucaux || '-' || d.idproducto || '-' || d.idauxiliar AS credito,
    of_nombre_asociado(aso.idsucursal, aso.idrol, aso.idasociado) AS nombre,
    aso.idsucursal || '-' || aso.idrol || '-' || aso.idasociado AS cliente,
    d.kauxiliar as kauxiliar,
    of_rellena(d.kauxiliar :: TEXT, 9, '0', 2) |+ of_dv_gen(d.kauxiliar :: TEXT) |+ CIE_BBVA_00((of_rellena(d.kauxiliar :: TEXT, 9, '0', 2) |+ of_dv_gen(d.kauxiliar :: TEXT))::TEXT) AS referencia_PR,
    of_rellena(d.kauxiliar :: TEXT, 9, '0', 2) |+ of_dv_gen(d.kauxiliar :: TEXT) AS referencia_FS
FROM
    deudores AS d
    INNER JOIN asociados AS aso USING(idsucursal, idrol, idasociado)
    INNER JOIN get_ref USING(idsucaux, idproducto, idauxiliar);

\o