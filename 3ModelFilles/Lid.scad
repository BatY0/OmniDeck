// OmniDeck IoT Console - Gömme Sürgülü Kapı (Sliding Door)
// Versiyon 2.3 - Tırtıklar Aşağıda (Görünür Bölgede), Servo Penceresi Yukarıda

$fn = 60;
eps = 0.1;

module final_fixed_door() {
    doorW = 36.6; 
    doorT = 2.4;  
    doorH = 57;   

    union() {
        difference() {
            // 1. ANA PANEL
            // Baskı sırasında arka (düz) yüzeyini tablaya yapıştırın.
            cube([doorW, doorT, doorH]);
            
            // 2. KİLİT PENCERESİ (Yukarı taşındı)
            // Servonun beyaz kolu fotoğrafta yukarıda görünüyor.
            // Bu pencere artık 32mm'den başlayıp 45mm'ye kadar uzanıyor.
            translate([doorW/2 - 12, -eps, 31]) 
                cube([24, doorT + 2*eps, 13]); 

            // 3. DIŞ YÜZEY SÜRTÜNME KANALLARI (Aşağı indirildi)
            // Kasanın dış deliğinden bakıldığında tam parmak ucuna gelecek yer.
            // Alt kısımdan (6mm'den) başlayarak parmak kavrama alanı oluşturur.
            for(i = [0 : 8]) {
                translate([-eps, doorT - 0.8, 6 + (i * 2.5)])
                    cube([doorW + 2*eps, 1.2, 1.2]);
            }
        }
    }
}

// --- ÇİZİM ÇAĞRILARI ---
final_fixed_door();