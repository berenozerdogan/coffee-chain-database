1. Giriş

Bu çalışmada, bir kahve zinciri işletmesine ait kurumsal verilerin yönetimini sağlamak amacıyla ilişkisel bir veritabanı sistemi tasarlanmış ve gerçekleştirilmiştir. Geliştirilen sistem; mağazalar, çalışanlar, müşteriler, ürünler, stok yönetimi ve satış işlemlerini bütünleşik bir yapı içerisinde ele almakta olup, gerçek hayattaki ticari süreçleri yansıtacak şekilde modellenmiştir.

Tasarım sürecinde Genişletilmiş Varlık-İlişki (EER) modeli kullanılmış, ardından bu model SQL tabanlı ilişkisel veritabanına dönüştürülmüştür. Tüm veritabanı işlemleri yalnızca SQL dili kullanılarak gerçekleştirilmiştir.

2. EER Diyagramı

Sistem tasarımının ilk aşamasında EER diyagramı oluşturulmuştur. Diyagramda yer alan temel varlıklar; Countries, Cities, Districts, Stores, Employees, Customers, Products, Categories, Seasons, Sales ve Payments olarak belirlenmiştir.

Mağazalar ile ürünler arasındaki stok ilişkisi, Inventories adlı zayıf varlık aracılığıyla modellenmiş ve bu tabloda bileşik birincil anahtar kullanılmıştır. Satış işlemleri ise Sales ve SaleDetails varlıkları ile temsil edilmiş, her satışın bir veya daha fazla ürünü içerebilmesi sağlanmıştır.

3. İlişkisel Veritabanı Tasarımı

EER diyagramı temel alınarak veritabanı tabloları SQL dili kullanılarak oluşturulmuştur. Tüm tablolar birincil anahtar (PRIMARY KEY), yabancı anahtar (FOREIGN KEY) ve bütünlük kısıtları ile desteklenmiştir.

Coğrafi yapı; Countries, Cities ve Districts tabloları aracılığıyla hiyerarşik olarak modellenmiştir. Her mağaza belirli bir ilçeye bağlıdır ve her mağazada birden fazla çalışan görev yapabilmektedir.

Ürün yapısı Categories ve Seasons tabloları ile zenginleştirilmiş, ürünlerin kategori ve mevsimsel özellikleri ayrı varlıklar üzerinden tanımlanmıştır. Satış ve ödeme işlemleri ayrı tablolar halinde ele alınarak veri tekrarının önüne geçilmiştir.

4. Veri Bütünlüğü ve Kısıtlar

Veri bütünlüğünü sağlamak amacıyla CHECK, UNIQUE ve FOREIGN KEY kısıtları kullanılmıştır. Örneğin; ürün fiyatlarının ve çalışan maaşlarının sıfırdan büyük olması, stok miktarlarının negatif olmaması gibi iş kuralları sistem seviyesinde kontrol altına alınmıştır.

Ayrıca satış sonrası stok miktarını otomatik olarak güncelleyen bir tetikleyici (trigger) tanımlanmıştır. Bu tetikleyici sayesinde her satış işlemi sonrasında ilgili mağazanın stok bilgileri tutarlı bir şekilde güncellenmektedir.

5. Veri Üretimi ve Test

Sistemin test edilebilmesi amacıyla büyük ölçekli örnek veriler oluşturulmuştur. Veritabanına 20.000 müşteri, 50.000 satış kaydı ve yüzlerce ürün otomatik olarak eklenmiştir.

Bu veri kümesi sayesinde sistemin performansı ve sorgu doğruluğu test edilmiş, karmaşık ilişkisel sorguların başarılı bir şekilde çalıştığı gözlemlenmiştir.



6. Örnek SQL Sorguları

Projede sistemin işlevselliğini göstermek amacıyla çeşitli örnek SQL sorguları geliştirilmiştir. Bunlara örnek olarak:

Kış ayında çay tercih eden 20 yaş üstü erkek müşterilerin listelenmesi

Şehirlere göre toplam satış tutarlarının hesaplanması

En çok satılan ürünlerin belirlenmesi

Mağaza bazında çalışan sayılarının listelenmesi

Sezonlara göre satış adetlerinin analizi

Ortalama sepet tutarının hesaplanması

Stok seviyesi kritik düzeyin altına düşen ürünlerin tespiti

verilebilir.






