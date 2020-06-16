Create view Windowsserverdshbrd
as
select case when  OsAssessment =1 then 'Windows machines Ready' when OsAssessment =3 then 'Windows machines Ready after changes' else 'Not assist' end Categories
,dbo._ConvertToGB(RAM) RAM_GB,inv.* from VwInventoryDetails_inv INV
left join discovery.AzureMigration_Assessment.VMQualification AZ on
 inv.devicenumber = az.devicenumber


