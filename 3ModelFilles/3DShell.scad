// OmniDeck IoT Console - Yüksek Hassasiyetli Mekanik Tasarım
// Versiyon 24.8 - ESP32 ve MPU Yerleri Kullanıcı İsteğine Göre Sabitlendi
// ESP32: 51.6mm x 28.5mm (78,12) | MPU: (70,70) | Kapı: (70)

$fn = 60;

/* [TEKNİK PARAMETRELER - KASA] */
outerWidth = 128;
outerDepth = 118;
baseHeight = 45;
wallT = 3;
floorT = 3;
tol = 0.6; // Baskı toleransı
eps = 0.1; // Manifold hatalarını önlemek için küçük ek pay

/* [BİLEŞEN ÖLÇÜLERİ VE KOORDİNATLAR] */
// HC-SR04 (Sol duvar)
hcHoleD = 16.5;
hcSpacing = 26;
hcCenterY = 70; 
hcCenterZ = 23;

// ESP32 DevKitV1 (Hassas Ölçü: 51.6 x 28.5)
// Kullanıcının istediği sabit konuma geri getirildi
espW = 28.5; 
espD = 51.6; 
espX = 78; 
espY = 12;  
espH = 35; 
espScrewD = 2.4; 

// SG90 Servo Yatağı (Sağ Üst)
// Hatch ile hizalı (X=70)
servoX = 70;
servoY = 92; 
servoW = 22.8 + tol;
servoD = 12.2 + tol;
servoArmTopZ = floorT + 32.4; 

// MPU-6050 Yatağı (Kullanıcının İstediği Sabit Konum)
mpuX = 70; 
mpuY = 70; 
mpuW = 21.0; 
mpuD = 16.2;

// DHT11 Modülü (Dikey Duvar Montajı - Sağ taraf)
dhtPCB_W = 16.5 + tol;
dhtPCB_T = 1.6 + tol;
dhtSensor_T = 7.2 + tol; 
dhtY = 72;

// Titreşim Motoru Modülü (Dikey Duvar Montajı - Sol taraf)
vibPCB_W = 16.0 + tol; 
vibPCB_T = 1.6 + tol; 
vibX = wallT;
vibY = 20;

// Kapı ve Kilit (Arka Duvar - Servo ile tam hizalı)
hatchX = 70;
hatchW = 28;
hatchH = 24;
hatchZ = 10; 
latchSlotH = 4.5;
latchSlotZ = servoArmTopZ - latchSlotH; 

/* [Modüller] */

module box_frame(w, d, h, r) {
    hull() {
        for(x=[r, w-r], y=[r, d-r]) {
            translate([x,y,0]) cylinder(h=h, r=r);
        }
    }
}

module main_shell() {
    union() {
        difference() {
            // 1. Ana Gövde
            box_frame(outerWidth, outerDepth, baseHeight, 5);
            
            // 2. İç Boşluk
            translate([wallT, wallT, floorT])
                cube([outerWidth - wallT*2, outerDepth - wallT*2, baseHeight]);

            // 3. SOL YAN: Ultrasonik Delikler
            translate([-eps, hcCenterY - hcSpacing/2, hcCenterZ]) rotate([0,90,0]) cylinder(d=hcHoleD, h=wallT + 2*eps);
            translate([-eps, hcCenterY + hcSpacing/2, hcCenterZ]) rotate([0,90,0]) cylinder(d=hcHoleD, h=wallT + 2*eps);

            // 4. ARKA: Kapı Açıklığı
            translate([hatchX, outerDepth-wallT-eps, hatchZ]) cube([hatchW, wallT + 2*eps, hatchH]);
            
            // 5. ARKA: Kilit Yuvası
            translate([hatchX + 11.8, outerDepth-wallT-eps, latchSlotZ]) 
                cube([4.4, wallT + 2*eps, latchSlotH]);

            // 6. SAĞ YAN: DHT11 için havalandırma slotları
            for(i = [0:3]) {
                translate([outerWidth-wallT-eps, dhtY + 2 + (i*4.0), 15]) cube([wallT + 2*eps, 2.0, 18]);
            }
            
            // 7. ÖN DUVAR: ESP32 USB Girişi
            translate([espX + espW/2 - 6, -eps, floorT + espH - 5])
                cube([12, wallT + 2*eps, 8]);
        }

        // 8. KAPAK VİDA SÜTUNLARI (M3)
        for(x = [8, outerWidth-8], y = [8, outerDepth-8]) {
            translate([x, y, floorT])
            difference() {
                cylinder(h = baseHeight - floorT, d = 8);
                translate([0,0,-eps]) cylinder(h = baseHeight + 2*eps, d = 3.0); 
            }
        }

        // 9. SÜRGÜ RAYLARI (TAM "U" FORMU - BİRBİRİNE BAKAN SLOTLAR)
        railDepth = 7;
        channelGap = 2.8; 
        railH = hatchZ + hatchH + 10;
        
        // Kapı kenarları X=68 ve X=100 koordinatlarına denk gelir.
        
        // Sol Ray (Kanal sağa bakar)
        translate([68 - 5, outerDepth - wallT - railDepth, floorT]) {
            difference() {
                cube([5, railDepth, railH]);
                translate([5 - 3, 2, -eps]) 
                    cube([4, channelGap, railH + 2*eps]);
            }
        }
        
        // Sağ Ray (Kanal sola bakar)
        translate([100, outerDepth - wallT - railDepth, floorT]) {
            difference() {
                cube([5, railDepth, railH]);
                translate([-1, 2, -eps]) 
                    cube([4, channelGap, railH + 2*eps]);
            }
        }
        
        // 10. ESP32 SÜTUNLARI (Vidalama Delikli - 51.6x28.5)
        for(ix = [0, espW], iy = [0, espD]) {
            translate([espX + ix, espY + iy, floorT])
            difference() {
                cylinder(d=8, h=espH);
                translate([0,0,espH-15]) cylinder(d=espScrewD, h=16); 
            }
        }
        
        // 11. SERVO YATAĞI (Kablo Çıkışı Tam Merkezde)
        translate([servoX, servoY, floorT])
            difference() {
                cube([servoW + 4, servoD + 4, 6]); 
                translate([2, 2, -eps]) cube([servoW, servoD, 10]); 
                translate([-eps, (servoD + 4)/2 - 4, 1.5]) cube([10, 8, 10]);
            }

        // 12. MPU-6050 YATAĞI (Restored to 70,70)
        translate([mpuX, mpuY, floorT])
            difference() {
                cube([mpuW + 4, mpuD + 4, 6]); 
                translate([2, 2, 1.5]) cube([mpuW, mpuD, 10]); 
                for(mx = [4, mpuW]) {
                    translate([mx, 2, 0]) cylinder(d=4, h=6);
                }
            }
        for(mx = [4, mpuW]) {
             translate([mpuX+mx, mpuY+2, floorT-eps]) 
                cylinder(d=2.4, h=10);
        }

        // 13. DHT11 DİKEY YUVA
        translate([outerWidth - wallT - dhtSensor_T - dhtPCB_T - 2, dhtY, floorT]) {
            difference() {
                union() {
                    cube([dhtPCB_T + 4, 2, 20]); 
                    translate([0, dhtPCB_W + 2, 0]) cube([dhtPCB_T + 4, 2, 20]); 
                    cube([dhtPCB_T + 4, dhtPCB_W + 4, 2]); 
                }
                translate([2, 2, -eps]) cube([dhtPCB_T, dhtPCB_W, 25]);
                translate([dhtPCB_T+2, dhtPCB_W/2+2, 10]) rotate([0,90,0]) cylinder(d=2.4, h=10);
            }
        }

        // 14. TİTREŞİM MOTORU DİKEY YUVA
        translate([vibX, vibY, floorT]) {
            difference() {
                union() {
                    cube([6, 2, 15]); 
                    translate([0, vibPCB_W+2, 0]) cube([6, 2, 15]); 
                    cube([2, vibPCB_W+4, 2]);
                }
                translate([2, 2, -eps]) cube([vibPCB_T, vibPCB_W, 20]);
            }
        }
            
        // Breadboard Görsel Rehberi
        %translate([10, 15, floorT]) color("pink", 0.3) cube([54, 82, 9]);
    }
}

// Render
main_shell();

// Aksesuar: Kapı ve Kilit Kolu
translate([outerWidth + 20, 0, 0]) {
    union() {
        difference() {
            cube([32, 30, 2]); 
            for(i=[0:5]) translate([10, 5 + i*3, 1.5]) cube([12, 1.5, 1]);
        }
        translate([16 - 2.1, 30, 0]) cube([4.2, 3.5, 2]);
    }
    translate([45, 0, 0])
    difference() {
        cube([4.4, 18, 2.2]);
        translate([1.2, 2.5, -eps]) cube([2, 7.5, 5]);
    }
}