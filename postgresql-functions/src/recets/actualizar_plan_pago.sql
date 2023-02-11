
create temp table importarplanes(idsucaux integer,idproducto integer,idauxiliar integer,idpago integer,vence date,abono numeric,interes numeric);

\copy importarplanes from '1-6208-15.csv' delimiter ',';  

create temp table fs_pagaresss as select idsucaux,idproducto,idauxiliar,max(idpago) as plazo from importarplanes group by 1,2,3;

select of_tmp_reclasifica_pp(idsucaux,idproducto,idauxiliar,idsucaux + idproducto + idauxiliar) from fs_pagaresss;

update planpago 
   set abono = xx.abono, io = xx.interes,vence = xx.vence  
  from importarplanes as xx 
 where (planpago.idsucaux, planpago.idproducto, planpago.idauxiliar, planpago.idpago) = (xx.idsucaux, xx.idproducto, xx.idauxiliar, xx.idpago) 
		and planpago.idproducto = 6208 
		and (planpago.idsucaux,planpago.idproducto,planpago.idauxiliar) 
			in (select idsucaux,idproducto, idauxiliar 
				  from deudores 
				 where idproducto = 6208 );

select * from planpago inner join importarplanes using(idsucaux,idproducto,idauxiliar);


