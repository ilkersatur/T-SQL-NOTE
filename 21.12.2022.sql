--Saklý Prosedürlerde geriye birden fazla int haricinde deðer döndürme

select * from AdvUrunler
--UrunID si gönderilen bir prosedüre, geriye ad ve fiyat bilgileri dönecek
create proc gp_AdvUrunBul @urunID int, 
													  @urunAdi varchar(50) out,
													  @fiyat money out
as
select @urunAdi=UrunAdi, @fiyat=Fiyat from AdvUrunler where UrunID=@urunID

declare @ad varchar(50)
declare @bfiyat money
exec gp_AdvUrunBul 234,@ad out,@bfiyat out
select @ad + ' ' + cast(@bfiyat as varchar(10))

--Saklý Prosedürleri Kriptolama

create proc gp_AdvUrunBul2 @urunID int, 
													  @urunAdi varchar(50) out,
													  @fiyat money out
with encryption
as
select @urunAdi=UrunAdi, @fiyat=Fiyat from AdvUrunler where UrunID=@urunID

-------------------
--VIEW kullanýmý
--Genellikle select sorgusu için kullanýlýr
--Avantajý select cümleleri ile kullanýlabilir.
-- Bant geniþliði üzerine olumlu etkisi vardýr.
--Network üzerinde SELECT cümleleri dolaþmaz.
--View ler kendi üzerinde veri tutmaz, ilgili tablolardan verileri getirir.
--Özel durum - içerisinde join olmayan View ler kullanýlarak tablolara insert iþlemi yapýlabilinir.

select * from Bolum
select * from Personel

create view vw_Personel
as
SELECT Personel.Ad, Personel.Soyad, Personel.PerID, Bolum.BolumAdi
FROM     Bolum INNER JOIN
                  Personel ON Bolum.BolumID = Personel.BolumID
--Wiev kullanýmý
select * from vw_Personel where Ad='Dursun'

--Özel durum

create view vw_Bolum
as
select * from Bolum
insert into vw_Bolum values('Mühendis')
select *from vw_Bolum

--UDF kullanýmlarý
--User Defined Functions

--Geriye Scalar(Tek) deðer döndüren fonksiyonlar
--Geriye tablo dödüren fonksiyonlar
--En büyük avantajý select cümlelerinde kullanýlabilir.

--1-Scalar Fonksiyonlar
select * from AdvUrunler

create function fn_FiyatGetir(@urunID int)
returns money
as
begin
	declare @fiyat money
	select @fiyat=Fiyat from AdvUrunler where UrunID=@urunID return @fiyat
end

select dbo.fn_FiyatGetir(989)
--scalar fonksiyonlar mutlaka þema adý ile birlikte kullanýlmalýdýr
--dbo sql server için varsayýlan þema adýdýr.

--2) tablo döndüren fonksiyonlar

create function fn_AdvUrunlerRenk(@renk varchar(20))
returns table
as
	return select * from AdvUrunler where renk=@renk
select * from fn_AdvUrunlerRenk('red')
where Fiyat<60

--Scalar fonksiyonlar sutun isimlerinin yazýldýðý yerde þema adýyla yazýlýr. 
--Tablo döndürenler ise from dan sonra þema adý olmadan da kullanýlabilir.

ALTER FUNCTION fn_Hesapla(@KDV	decimal, @Tutar money)
returns money
AS
BEGIN
declare @Sonuc money
set @Sonuc= (@Tutar)+((@KDV/100)*@Tutar)
return @Sonuc
END

select dbo.fn_Hesapla(20,1000)

create table FaturaDetayOzel(FDID int primary key identity, UrunID int, Fiyat money, Adet int)
insert into FaturaDetayOzel values(1,20,3),(13,240,35),(112,230,423),(145,26808,389)
--Sorgu içerisinde hesaplama
select UrunID, Fiyat, Adet, (Fiyat*Adet) Toplam from FaturaDetayOzel

drop table FaturaDetayOzel
-----------------

create table FaturaDetayOzel(FDID int primary key identity, 
														UrunID int, 
														Fiyat money, 
														Adet int,
														KDV int, 
														Toplam as Fiyat*Adet,
														ArtýKDV as dbo.fn_Hesapla(Fiyat,KDV))

select*from FaturaDetayOzel
insert into FaturaDetayOzel values(1,1000,2,20)

--Triggers
--DML Triggers 
	--1-After T.
	--2-Instead of T.
--DDL Triggers

create table Deneme (DID int identity (1,1)primary key,
										   Aciklama varchar(50))
insert into Deneme values('asd')

select * from Deneme

create trigger t_Deneme
on Deneme
after insert -- Bu tablo üzerinde insert, update, delete komutlarýndan biri çalýþtýðý zaman tetiklenir
as
select * from Deneme

--Triggerlara deðer aktarma
alter trigger t_Deneme
on Deneme
after insert
as
declare @mesaj varchar(20)
--Select * from deleted
select @mesaj=Aciklama from inserted
select @mesaj

insert into Deneme values('Tetikleyici')


---------------------------
create table Stok(StokID int primary key identity,
								  StokAdi varchar(50),
								  StokAdedi int)

create table StokHareket(SHID int primary key identity,
												  StokID int references Stok(StokID),
												  HareketTipi tinyint, -- 1 giriþ,2 çýkýþ
												  Adet int,
												  IslemTarihi smalldatetime default getdate())

insert into stok values('Defter',56)
insert into stok values('Kalem',42)
insert into stok values('Silgi',12)

create trigger t_StokHareket
on StokHareket
after insert
as
	declare @ID int
	declare @Adet int
	declare @Htipi tinyint
	declare @Tip int=1
	select @ID=StokID, @Adet=Adet, @Htipi=HareketTipi 
	from inserted
		if(@Htipi=2)
			set @Tip=-1;
		update Stok set StokAdedi = StokAdedi +(@Tip*@Adet)
		where stokID=@ID

insert into StokHareket Values(1,1,6,GETDATE()) -- Stok+6
insert into StokHareket Values(3,2,3,GETDATE()) -- Stok-3

select * from Stok
select * from StokHareket