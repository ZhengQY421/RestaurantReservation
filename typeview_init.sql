create or replace view accountTypes (uid, isCustomer, isOwner) as
select
uid,
coalesce((select true from Customers C where C.uid = U.uid), false),
coalesce((select true from Owners O where O.uid = U.uid), false)
from Users U
;