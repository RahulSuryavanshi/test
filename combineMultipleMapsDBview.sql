select 'Create View '+ SCHEMA_NAME(DTL.schema_id) +'.[Vw_'+DTL.name +']'+ ' AS '+
 'select * from Bendigo_Discovery_2.'+ SCHEMA_NAME(DTL.schema_id) +'.['+DTL.name +']'
+ ' Union All select * from map_Configinfo.' +SCHEMA_NAME(DTL.schema_id) +'.['+DTL.name +'] GO'
   from sys.tables DTL inner join map_Configinfo.sys.tables  BBL
on DTL.name=bbl.name and DTL.schema_id=BBL.schema_id and SCHEMA_NAME(DTL.schema_id) <> 'dbo'