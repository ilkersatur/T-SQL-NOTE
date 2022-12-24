--Sakl� Prosed�rlerde geriye birden fazla int haricinde de�er d�nd�rme

select * from AdvUrunler
--UrunID si g�nderilen bir prosed�re, geriye ad ve fiyat bilgileri d�necek
create proc gp_AdvUrunBul @urunID int, 
													  @urunAdi varchar(50) out,
													  @fiyat money out
as
select @urunAdi=UrunAdi, @fiyat=Fiyat from AdvUrunler where UrunID=@urunID

declare @ad varchar(50)
declare @bfiyat money
exec gp_AdvUrunBul 234,@ad out,@bfiyat out
select @ad + ' ' + cast(@bfiyat as varchar(10))

--Sakl� Prosed�rleri Kriptolama

create proc gp_AdvUrunBul2 @urunID int, 
													  @urunAdi varchar(50) out,
													  @fiyat money out
with encryption
as
select @urunAdi=UrunAdi, @fiyat=Fiyat from AdvUrunler where UrunID=@urunID

-------------------
--VIEW kullan�m�
--Genellikle select sorgusu i�in kullan�l�r
--Avantaj� select c�mleleri ile kullan�labilir.
-- Bant geni�li�i �zerine olumlu etkisi vard�r.
--Network �zerinde SELECT c�mleleri dola�maz.
--View ler kendi �zerinde veri tutmaz, ilgili tablolardan verileri getirir.
--�zel durum - i�erisinde join olmayan View ler kullan�larak tablolara insert i�lemi yap�labilinir.

select * from Bolum
select * from Personel

create view vw_Personel
as
SELECT Personel.Ad, Personel.Soyad, Personel.PerID, Bolum.BolumAdi
FROM     Bolum INNER JOIN
                  Personel ON Bolum.BolumID = Personel.BolumID
--Wiev kullan�m�
select * from vw_Personel where Ad='Dursun'

--�zel durum

create view vw_Bolum
as
select * from Bolum
insert into vw_Bolum values('M�hendis')
select *from vw_Bolum

--UDF kullan�mlar�
--User Defined Functions

--Geriye Scalar(Tek) de�er d�nd�ren fonksiyonlar
--Geriye tablo d�d�ren fonksiyonlar
--En b�y�k avantaj� select c�mlelerinde kullan�labilir.

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
--scalar fonksiyonlar mutlaka �ema ad� ile birlikte kullan�lmal�d�r
--dbo sql server i�in varsay�lan �ema ad�d�r.

--2) tablo d�nd�ren fonksiyonlar

create function fn_AdvUrunlerRenk(@renk varchar(20))
returns table
as
	return select * from AdvUrunler where renk=@renk
select * from fn_AdvUrunlerRenk('red')
where Fiyat<60

--Scalar fonksiyonlar sutun isimlerinin yaz�ld��� yerde �ema ad�yla yaz�l�r. 
--Tablo d�nd�renler ise from dan sonra �ema ad� olmadan da kullan�labilir.

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
--Sorgu i�erisinde hesaplama
select UrunID, Fiyat, Adet, (Fiyat*Adet) Toplam from FaturaDetayOzel

drop table FaturaDetayOzel
-----------------

create table FaturaDetayOzel(FDID int primary key identity, 
														UrunID int, 
														Fiyat money, 
														Adet int,
														KDV int, 
														Toplam as Fiyat*Adet,
														Art�KDV as dbo.fn_Hesapla(Fiyat,KDV))

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
after insert -- Bu tablo �zerinde insert, update, delete komutlar�ndan biri �al��t��� zaman tetiklenir
as
select * from Deneme

--Triggerlara de�er aktarma
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
												  HareketTipi tinyint, -- 1 giri�,2 ��k��
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