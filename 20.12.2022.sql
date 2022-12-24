--TSQL PROGRAMLAMA
--Deðiþken tanýmlama

DECLARE @id int 
SET @id=12
SELECT @id

--Þart ifadeleri
DECLARE @id int 
SET @id=12
IF (@id>=10)
BEGIN 
		print 'sayý 10dan büyük veya eþit '
END
ELSE
BEGIN
	PRINT 'sayý 1odan küçük'
END

IF EXISTS (SELECT * FROM AdvUrunler
WHERE UrunID=1)
SELECT 'VAR'
ELSE 
SELECT 'YOK'


--Döngüler

DECLARE @sayac int=0
WHILE (@sayac<5)
BEGIN
	print @sayac
	SET @sayac=@sayac+1
END

--Case when

SELECT UrunID, UrunAdi, Renk,
	case Renk
		when 'black' THEN 'siyah'
		when 'red' THEN 'kýrmýzý'
		when 'blue' THEN 'mavi'
		END
FROM AdvUrunler


SELECT UrunID, UrunAdi, Renk, BirimFiyat,
	case --eþitlik olmadýðý için tek kullanýlýr
		when BirimFiyat<100 THEN 'çok ucuz'
		when BirimFiyat>=100 AND BirimFiyat<500 THEN 'UCUZ'
		when BirimFiyat>=500 AND BirimFiyat<1000 THEN 'NORMAL'
		when BirimFiyat>=1000 AND BirimFiyat<2000 THEN 'NORMAL'
		when BirimFiyat>=2000 THEN 'COK PAHALI'
		END
FROM AdvUrunler

--
SELECT * FROM sys.databases
SELECT * FROM sys.tables
SELECT * FROM sys.columns
WHERE object_id=117575457

--
--Stored Produceres (saklý prosedürler)
--s.pros kullanmak iþlemleri hýzlandýrýr
--daha güvenlidir
--bant geniþliði kullanýmý azaltýr, maliyeti düþürür 
--genellikle sak.pros select cümleleri ile kullanýlmaz
Select ProductID as UrunID, name as UrunAdi, color as renk, ProductNumber as UrunKodu, ListPrice as Fiyat
	into AdvUrunler
	from AdventureWorks2014.Production.Product
--saklý pros oluþturma
CREATE PROCEDURE gp_AdvUrunler
as SELECT * FROM AdvUrunler
--nasýl kullanýrýz/3 farklý yöntemi var
execute gp_AdvUrunler
exec gp_AdvUrunler
gp_AdvUrunler
--saklý prosedürlerde parametre kullanýmý 
--CREATE PROC gp_Personel_Ekle
--as INSERT INTO tbl_Personel VALUES ('Cevdet','Korkmaz',4)
--exec gp_Personel_Ekle --parametresi olmayan sp

ALTER PROC gp_UrunEkle 
							@UrunAdi nvarchar (50), 
							@renk nvarchar(15),
							@UrunKodu nvarchar(25),
							@Fiyat money 
as INSERT INTO AdvUrunler VALUES (@UrunAdi,@renk,@UrunKodu,@Fiyat)
 --1.yöntem
exec gp_UrunEkle 'Bal', 'Sarý','A-2312',15
--2.yöntem
exec gp_UrunEkle @renk='Mavi', @UrunAdi='Þapka', @UrunKodu='A-2313',@Fiyat=20

exec gp_AdvUrunler

-------
exec sp_help gp_UrunEkle
---------------------------------------------------------------
create proc gp_UrunEkleReturnID
							@UrunAdi nvarchar (50), 
							@renk nvarchar(15),
							@UrunKodu nvarchar(25),
							@Fiyat money 
as 
declare @id int
insert into AdvUrunler values(@UrunAdi,@renk,@UrunKodu,@Fiyat);
--select @id=@@identity artýk tercih edilmiyor
select @id =scope_identity()
	return @id

declare @yeniID int
exec @yeniID=gp_UrunEkleReturnID 'PC','Siyah','A1002',1523
select @yeniID

select*from AdvUrunler
-----------------------------------------------------
CREATE TABLE Fatura(		 FaturaID int PRIMARY KEY IDENTITY ,
													 FaturaNo int,
													 MusID int,
													 Tarih smalldatetime,
													 GenelTutar money)
CREATE TABLE FaturaDetay(FDID int PRIMARY KEY IDENTITY,
													 FaturaID int REFERENCES Fatura(FaturaID),
													 UrunID int,
													 Adet smallint,
													 Fiyat money,
													 --Computed Columns
													 Tutar as Adet * Fiyat)

CREATE PROC FaturaEkle @FaturaNo int, @MusID int
AS 
	INSERT INTO Fatura(FaturaNo,MusID,Tarih)  VALUES (@FaturaNo,@MusID,GETDATE())

	DECLARE @OlusanFaturaID int
	SELECT @OlusanFaturaID = SCOPE_IDENTITY();
	RETURN @OlusanFaturaID

DECLARE @yeniFaturaID int 
exec @yeniFaturaID=FaturaEkle 123,101

INSERT INTO FaturaDetay VALUES (@yeniFaturaID, 11, 3,20)
INSERT INTO FaturaDetay VALUES (@yeniFaturaID, 12, 1,80)

DECLARE @ToplamTutar money
SELECT @ToplamTutar = SUM(Tutar) FROM  FaturaDetay
Where FaturaID = @yeniFaturaID
UPDATE  Fatura SET GenelTutar = @ToplamTutar
Where FaturaID = @yeniFaturaID

SELECT * FROM Fatura
SELECT * FROM FaturaDetay