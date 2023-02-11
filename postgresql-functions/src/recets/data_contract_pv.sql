
-- BUSCAR DATOS PARA CONTRATO PV
select
	d.idsucaux || '-' || d.idproducto || '-' || d.idauxiliar AS numerodecredito,
    of_nombre_asociado(aso.idsucursal, aso.idrol, aso.idasociado) AS nombre,
    '69'|+of_rellena(kauxiliar::TEXT,7,'0',2)||of_dv_gen('69'|+of_rellena(kauxiliar::TEXT,7,'0',2)) AS referencia,    aso.idsucursal || '-' || aso.idrol || '-' || aso.idasociado AS cliente,
    aso.idrol,
    d.idsucaux || '-' || d.idproducto || '-' || d.idauxiliar AS credito,
    round(d.montosolicitado, 2) AS saldo_insoluto,
    to_char(round(d.montosolicitado, 2), 'FM999,999,990.90') AS saldo_insoluto_formato,
    '' AS tipo_proceso,
    'FS' AS empresa,
    calles.nombre || ',' || numext || ',' || numint || ',' || colonias.nombre || ',' || estados.nombre || ',' || cp as direccion_completa,
    telefono AS telefono_fijo,
    email,
    telefono2 AS celular,
    fechaape,
    d.plazo,
    CASE
        WHEN sexo = 0 THEN 'Masculino'
        WHEN sexo = 1 THEN 'Femenino'
    END AS sexo,
    rfc,
    ife,
    CASE
        WHEN mexicano = 0 THEN 'Mexicano'
        WHEN mexicano > 0 THEN 'Otro'
    END AS nacionalidad,
    estados.nombre AS entidadfederativa,
    (
        SELECT
            paises.nombre
        FROM
            paises
        WHERE
            paises.idpais = estados.idpais
    ) AS paisnacimiento,
    curp_rfc as curp,
    (
        SELECT
            ocup.descripcion
        FROM
            ocupaciones AS ocup
        WHERE
            ocup.idocupacion = directorio.idocupacion
    ) AS ocupacion,
    fechanacimiento,
    r.nombre AS ruta,
    DATE_PART('year', AGE(now(), fechanacimiento)) AS edad,
    of_numero_letra(d.montosolicitado) AS saldo_insoluto_texto
FROM
    deudores AS d
    INNER JOIN asociados AS aso USING(idsucursal, idrol, idasociado)
    INNER JOIN directorio USING(idsucdir, iddir)
    INNER JOIN calles USING(idcalle)
    INNER JOIN colonias USING(idcolonia)
    INNER JOIN municipios USING(idmunicipio)
    INNER JOIN estados USING(idestado)
    INNER JOIN roles AS r USING(idrol)
    WHERE (idsucaux,idproducto,idauxiliar)=(1,5200,13512);
   