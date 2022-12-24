select * from	Deneme

--Instead of triggers
--.....Yerine...
alter trigger t_Deneme
on Deneme
instead of insert
as
select * from Deneme
insert into deneme values('Yeni yýla girerken')


alter trigger t_Deneme
on Deneme
instead of insert
as
declare @mesaj varchar(50)
select @mesaj=Aciklama from inserted
insert  Deneme values(@mesaj)
select * from Deneme
--instead of trigger tetikleyicilerde, tetikleyici içerisinde ayrý iþlemi tekrar yazmak lazým
--Çünkü bu þekilde çalýþmasý, bizlere süreci yönetme imkani verir
insert into deneme values('Yeni yýla girerken')

--Stok örneðini negatif stok olmayacak þekilde yazýnýz
--Stokta yeterli ürün yoksa çalýþmayacak
select * from Stok
select * from StokHareket

alter trigger t_StokHareket
on StokHareket
instead of insert
as
	declare @ID int
	declare @Adet int
	declare @Htipi tinyint
	declare @Tip int=1
	declare @StokAdedi int
	--Stok yeterli mi?
	select @ID=StokID, @Adet=Adet, @Htipi=HareketTipi
	from inserted

	select @StokAdedi=StokAdedi from Stok
	where StokID=@ID

	if(@Htipi=2 ) set @Tip=-1;
	if(@StokAdedi-@Adet>=0)
	begin
	update Stok set StokAdedi = StokAdedi +(@Tip*@Adet)
	where stokID=@ID

	insert into StokHareket Values(@ID,@Htipi,@Adet,GETDATE())
	end

insert into StokHareket Values(1,1,6,GETDATE()) -- Stok+6
insert into StokHareket Values(3,2,3,GETDATE()) -- Stok-3

select * from Stok
select * from StokHareket

--DDL Triggers
--Veri tabaný seviyesinde
create trigger t_Database
on Database
for CREATE_TABLE
as
rollback

create table YeniYil(ID int identity, Aciklama varchar(60))
-- Server seviyesinde
create trigger t_Server
on all server
for CREATE_DATABASE
as
rollback

create database yeniDB

---Transactions
-- Atomik yapýlar oluþturmak için kullanýlýr.(Parçalanamaz yapýlar)

--SQL serverda istisnalarýn yakalanmasý
begin try
raiserror('HATA',16,1)
end try
begin catch
select 'HATA OLUÞTU'
end catch

------

create table Hesaplar( HesapID int identity primary key,
										    MusID int,
											Bakiye money)
create table HesapHareket( HHID int identity primary key,
										    GonderenID int references Hesaplar(HesapID),
											AlanID int references Hesaplar(HesapID),
											Miktar money,
											IslemTarihi smalldatetime)

		insert into Hesaplar values (1,10000)
		insert into Hesaplar values (2,10000)

begin try
begin transaction
	declare @GID int =2
	declare @AID int =1
	declare @Miktar money =1000
	insert into HesapHareket values(@GID,@AID,@Miktar,getdate())
	--raiserror ('HATAAA',16,1)
	UPDATE Hesaplar SET Bakiye = Bakiye - @Miktar WHERE HesapID = @GID;
	UPDATE Hesaplar SET Bakiye = Bakiye + @Miktar WHERE HesapID = @AID;
commit
end try
begin catch
	rollback
	Select 'Hataya düþtüüü'
end catch

select *from Hesaplar
select *from HesapHareket
---------------- Kümeler
create table Musteri(Ad varchar(50),
										Soyad varchar(50))
insert into Musteri values('Cevdet','Korkmaz'),('Ýlker','Þatur'),('Zafer','Mavi')

select Ad,Soyad from Personel
union 
select Ad,Soyad from Musteri

select Ad,Soyad from Personel
union all
select Ad,Soyad from Musteri

select Ad,Soyad from Personel
intersect 
select Ad,Soyad from Musteri

select Ad,Soyad from Personel
except
select Ad,Soyad from Musteri

select Ad,Soyad from Musteri
except
select Ad,Soyad from Personel

--------------Þema Kullanýmý
--SQL de varsayýlan þema dbo dur
--SQL Server tarafýnda yönetimsel olarak þema bazlý yetkilendirme verilebilinir.
create schema Banka
create table Banka.Musteri(MusID int identity primary key,
													  Ad varchar(50))
--NESTED SELECT
--1) Sütun isminin yazýlýðý yere
select UrunID,UrunAdi,renk,(select count(*)from AdvUrunler where renk=u.Renk) 
as Adet from AdvUrunler u

select renk,count(*) from AdvUrunler group by renk

--UrunID 3,316,996 olan ürünler
select * from AdvUrunler
where urunID in(3,316,996)

--2) Where den sonra
select * from AdvUrunler 
where UrunID in (select UrunID from AdvUrunler where renk='blue')

--3) From dan sonra
select * from (select UrunID, UrunAdi from AdvUrunler where UrunID<5) as Tablo 
where UrunAdi like '%head%'
-------------
select*from AdventureWorks2014.Person.Person

select BusinessEntityID,Title,FirstName,MiddleName,LastName 
into AdvPerson
from AdventureWorks2014.Person.Person

select * from AdvPerson

--                    Indexes (Indexler)
--SQL Server da indexlenmemiþ tabloya "Heap" denir.
--Clustered index(bir tabloda bir tane olur)
--Non-clustured index(birden fazla olabilir)
--SQL Serverin indexleme mekanizmasý balanced tree(b-tree)
--Bir tabloda pk olusturulunca otomatik olarak clustured index oluþturulur.
--Index uzerinden arama yapýlýnca arama hýzý çok artar
--Indexleme maliyeti(bir indexin sunucu üzerinde tutulmasý için olan maliyet,yer)

select * from AdvPerson 
where BusinessEntityID=17550