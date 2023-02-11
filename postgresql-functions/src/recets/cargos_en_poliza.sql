--Cargos en poliza de cuentas (filtro: 4000)
select  idsucursal||'-'||idrol||'-'||idasociado as cliente,
 		of_nombre_asociado(idsucursal,idrol,idasociado) as nombre, 
 		idsucaux||'-'||idproducto||'-'||idauxiliar as cuenta,
 		fecha,
 		hora,
 		idsucpol||'-'||periodo||'-'||tipopol||'-'||idpoliza as poliza,
 		(select	concepto 
 		   from polizas p 
 		  where (p.idsucpol,p.periodo,p.tipopol,p.idpoliza)=(da.idsucpol,da.periodo,da.tipopol,da.idpoliza)) as concepto,
 		cargo,
 		abono 
  from 	deudores 
 		inner join detalle_auxiliar da using(idsucaux,idproducto,idauxiliar) 
 where  idproducto 
		between 4000 and 4999 
		and estatus in (3,4) 
		and periodo = 202210;
	