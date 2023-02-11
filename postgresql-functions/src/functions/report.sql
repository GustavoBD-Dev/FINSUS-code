WITH saldos AS (
select 
ca.idsucursal |+ '-' |+ ca.idrol |+ '-' |+ ca.idasociado as cliente,
ca.idsucaux |+ '-' |+ ca.idproducto |+ '-' |+ ca.idauxiliar as credito,
ca.idproducto,
pr.nombre as producto, pr.nombrecorto as producto_corto, 
de.referencia as chip, 
am.vin,
de.montoentregado, 
(select abono + io from planpago p2 where (idpago, idsucaux, idproducto, idauxiliar) = (1,de.idsucaux, de.idproducto, de.idauxiliar)) as cuota,
ca.montovencido,
ca.saldo, 
ca.abono,
ca.fecha, ca.estatuscartera,
ca.costos_asociados, ca.impuesto, ca.impuesto_total, ca.interes_total, ca.iopend,
ca.vence, 
ca.diasmora, 
rf.idsucauxref |+ '-' |+ rf.idproductoref |+ '-' |+ rf.idauxiliarref as cuenta_2001
from cartera ca 
inner join deudores de on ca.idsucaux = de.idsucaux and ca.idproducto = de.idproducto and ca.idauxiliar = de.idauxiliar 
inner join productos pr on ca.idproducto = pr.idproducto
inner join auxiliares_ref rf on ca.idsucaux = rf.idsucaux and ca.idproducto = rf.idproducto and ca.idauxiliar = rf.idauxiliar
inner join ofx_multicampos_sustentable.auxiliar_masdatos am using(kauxiliar)
where ca.fecha IN ('2023-01-31') and rf.idproductoref = 2001 AND (ca.idsucaux,ca.idproducto, ca.idauxiliar)=(1,5300,10))
select 
cliente,credito,idproducto,producto,producto_corto,chip,vin,
montoentregado,
cuota,
cuota-abono as abono,
montovencido,
saldo,
fecha,estatuscartera,costos_asociados,impuesto,impuesto_total,interes_total,iopend,vence,diasmora,cuenta_2001 
from saldos




with a as(
select 
idsucaux,idproducto,idauxiliar,
max(fecha) as fecha_ult_abono,
idsucaux || '-' || idproducto || '-' || idauxiliar as credito,
sum(cargo) as monto_entregado,
sum(abono) as abono,
min(saldo) as saldo
from detalle_auxiliar 
where (idsucaux, idproducto, idauxiliar) = (1,5300,3737)
group by idsucaux,idproducto,idauxiliar,idsucaux || '-' || idproducto || '-' || idauxiliar),
b as (
select fecha_ult_abono,credito,monto_entregado,
(select abono + io from planpago p2 where (idpago, idsucaux, idproducto, idauxiliar) = (1,de.idsucaux, de.idproducto, de.idauxiliar)) as cuota, 
(select sum(abono + io) from planpago p2 where (idsucaux, idproducto, idauxiliar) = (de.idsucaux, de.idproducto, de.idauxiliar)and vence <='2023-01-31') as abono_ideal,
abono,saldo
from a de)
select fecha_ult_abono,credito,monto_entregado,cuota,abono_ideal,abono,(abono_ideal-abono) as saldo_vencido,saldo from b