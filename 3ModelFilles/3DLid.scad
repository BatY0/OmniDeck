// OmniDeck IoT Console - Yüksek Hassasiyetli Mekanik Tasarım
// Versiyon 24.9.12 - Dış PCB çerçevesi 30.0'a geri alındı, İç köşeler maksimumda.

$fn = 60;

/*[TEKNİK PARAMETRELER - KASA] */
outerWidth = 128;
outerDepth = 118;
baseHeight = 60; 
wallT = 3;
floorT = 3;
tol = 0.6; 
eps = 0.1; 

/*[KULLANICI REFERANS KAPAK (LID) PARAMETRELERİ] */
lidThickness = 3;
lipClearance = 0.35;
lidHoleDiameter = 3.2;

// --- OLED EKRAN (SSD1306) HASSAS GÜNCELLEMELERİ ---
oledWindowWidth = 24.0;   
oledWindowHeight = 13.5;  
oledWindowOffsetY = -1.5; 

oledDepthPcb = 1.0;       
oledDepthClearance = 2.4; 

oledCenterX = 36;
oledCenterY = 42;

encoderHoleDiameter = 7.2;
encoderCenterX = 92;
encoderCenterY = 42;

ldrHoleDiameter = 6.2;
ldrCenterX = 108;
ldrCenterY = 84;

/*[BİLEŞEN ÖLÇÜLERİ VE KOORDİNATLAR] */
hcHoleD = 16.5;
hcSpacing = 26;
hcCenterY = 70; 
hcCenterZ = 23; 

espW = 28.5; 
espD = 51.6; 
espX = 78; 
espY = 12;  
espH = 30;  
espScrewD = 2.4; 

servoX = 70;
servoY = 92; 
servoW = 22.8 + tol;
servoD = 12.2 + tol;
servoArmTopZ = floorT + 32.4; 

mpuX = 70; 
mpuY = 70; 
mpuW = 21.0; 
mpuD = 16.2;

dhtY = 72;

vibX = wallT;
vibY = 15; 

hatchX = 70;
hatchW = 28;
hatchH = 24;
hatchZ = 10; 
latchSlotH = 4.5;
latchSlotZ = servoArmTopZ - latchSlotH; 


/*[YARDIMCI MODÜLLER] */
module box_frame(w, d, h, r) {
    hull() {
        for(x=[r, w-r], y=[r, d-r]) {
            translate([x,y,0]) cylinder(h=h, r=r);
        }
    }
}

/*[1. ANA GÖVDE (SHELL)] */
module main_shell() {
    bridgeZ = hatchZ + hatchH; 
    slotTopZ = latchSlotZ + latchSlotH; 
    railDepth = 7;
    channelGap = 2.8; 
    railH = 45; 
    espOffX = 2.4; 
    dht_W = 16.6; 
    pcb_W = dht_W + 0.6; 
    pcb_T = 2.0; 
    v_W = 23.8; 
    vp_W = v_W + 0.6; 
    vp_T = 2.0; 

    union() {
        difference() {
            box_frame(outerWidth, outerDepth, baseHeight, 5);
            
            translate([wallT, wallT, floorT])
                cube([outerWidth - wallT*2, outerDepth - wallT*2, baseHeight]);

            translate([-eps, hcCenterY - hcSpacing/2, hcCenterZ]) rotate([0,90,0]) cylinder(d=hcHoleD, h=wallT + 2*eps);
            translate([-eps, hcCenterY + hcSpacing/2, hcCenterZ]) rotate([0,90,0]) cylinder(d=hcHoleD, h=wallT + 2*eps);

            translate([hatchX, outerDepth-wallT-eps, hatchZ]) cube([hatchW, wallT + 2*eps, hatchH]);
            
            if (slotTopZ > bridgeZ) {
                translate([hatchX + 11.8, outerDepth-wallT-eps, bridgeZ + 0.2]) 
                    cube([4.4, wallT + 2*eps, slotTopZ - (bridgeZ + 0.2)]);
            }

            for(i =[0:3]) {
                translate([outerWidth-wallT-eps, dhtY + 2 + (i*4.0), 15]) cube([wallT + 2*eps, 2.0, 18]);
            }
            
            translate([espX + espW/2 - 6, -eps, floorT + espH - 2])
                cube([12, wallT + 2*eps, 8]);
        }

        for(x =[8, outerWidth-8], y =[8, outerDepth-8]) {
            translate([x, y, floorT])
            difference() {
                cylinder(h = baseHeight - floorT - lidThickness, d = 8);
                translate([0,0,-eps]) cylinder(h = baseHeight, d = 3.0); 
            }
        }

        translate([68 - 5, outerDepth - wallT - railDepth, floorT]) {
            difference() {
                cube([5, railDepth, railH]);
                translate([5 - 3, 2, -eps]) cube([4, channelGap, railH + 2*eps]);
            }
        }
        
        translate([100, outerDepth - wallT - railDepth, floorT]) {
            difference() {
                cube([5, railDepth, railH]);
                translate([-1, 2, -eps]) cube([4, channelGap, railH + 2*eps]);
            }
        }
        
        for(ix =[espOffX, espW - espOffX]) {
            translate([espX + ix, espY + 3.8 - 3.5, floorT])
            difference() {
                cylinder(d=7.5, h=espH);
                translate([0,0,espH-15]) cylinder(d=espScrewD, h=16); 
            }
            
            translate([espX + ix, espY + espD - 3.8, floorT])
            difference() {
                cylinder(d=7.5, h=espH);
                translate([0,0,espH-15]) cylinder(d=espScrewD, h=16); 
                translate([-5, -11.8, espH - 12]) cube([10, 10, 13]);
            }
        }
        
        translate([servoX, servoY, floorT])
            difference() {
                cube([servoW + 4, servoD + 4, 16]); 
                translate([2, 2, -eps]) cube([servoW, servoD, 20]); 
                translate([-eps, (servoD + 4)/2 - 4, -eps]) cube([10, 8, 20]);
            }

        translate([mpuX, mpuY, floorT])
            difference() {
                cube([mpuW + 4, mpuD + 4, 8]); 
                translate([2, 2, 3.5]) cube([mpuW, mpuD, 10]); 
                translate([2, mpuD - 1.5, 1.5]) cube([mpuW, 4, 10]);
                for(mx =[5, 20]) { translate([mx, 4.5, 0]) cylinder(d=2.4, h=10); }
            }

        translate([outerWidth - wallT - 10, dhtY, floorT]) {
            difference() {
                cube([pcb_T + 4, pcb_W + 4, 27]);
                translate([2, 2, 13]) cube([pcb_T, pcb_W, 15]);
                translate([-eps, 3.5, -eps]) cube([10, pcb_W - 3, 30]);
            }
        }

        translate([vibX, vibY, floorT]) {
            difference() {
                cube([vp_T + 4, vp_W + 4, 28]);
                translate([2, 2, 8]) cube([vp_T, vp_W, 25]);
                translate([-eps, 3.5, -eps]) cube([10, vp_W - 3, 30]);
            }
        }
    }
}

/*[2. KAPAK (LID) MODÜLÜ] */
/*[2. KAPAK (LID) MODÜLÜ] */
/*[2. KAPAK (LID) MODÜLÜ] */
/*[2. KAPAK (LID) MODÜLÜ] */
module shell_lid() {
    lidW = outerWidth - 2*wallT - lipClearance*2;
    lidD = outerDepth - 2*wallT - lipClearance*2;
    lidR = 5 - wallT; 
    oledPitch = 23.5; 
    railDepth = 7;
    doorSlotX = 62; 
    doorSlotW = 44; 
    doorSlotY = outerDepth - wallT - railDepth - 1; 
    doorSlotD = railDepth + 2;
    oledPcbPocket = 30.0; 

    difference() {
        translate([wallT + lipClearance, wallT + lipClearance, 0])
            box_frame(lidW, lidD, lidThickness, lidR);
        
        for(x=[8, outerWidth-8], y=[8, outerDepth-8]) {
            translate([x, y, -eps]) 
                cylinder(h=lidThickness + 2*eps, d=lidHoleDiameter);
        }
        
        // OLED Penceresi
        translate([oledCenterX - oledWindowWidth/2, oledCenterY - oledWindowHeight/2 + oledWindowOffsetY, -eps])
            cube([oledWindowWidth, oledWindowHeight, lidThickness + 2*eps]);
            
        // OLED Sığ Raf (PCB Dış Çerçevesi 30.0)
        translate([oledCenterX - oledPcbPocket/2, oledCenterY - oledPcbPocket/2, lidThickness - oledDepthPcb])
            cube([oledPcbPocket, oledPcbPocket, oledDepthPcb + eps]);
            
        // --- KUSURSUZ İÇ KANALLAR (VİDA KALKANLARI SİLİNDİ) ---
        // Slicer hatasını önlemek ve maksimum boşluk için kanallar 21.5mm'ye çıkarıldı.
        // Bu genişlik vida delikleriyle temiz bir şekilde kesişir.
        translate([0, 0, lidThickness - oledDepthClearance]) {
            union() {
                // Dikey Kanal (Lehimler ve Bant için) - Genişlik 21.5
                translate([oledCenterX - 21.5/2, oledCenterY - 30/2, 0])
                    cube([21.5, 30, oledDepthClearance + eps]);
                // Yatay Kanal (Cam esnemesi için) - Yükseklik 21.5
                translate([oledCenterX - 30/2, oledCenterY - 21.5/2, 0])
                    cube([30, 21.5, oledDepthClearance + eps]);
            }
        }
            
        // OLED Vidaları (2.4mm Delikler)
        for(hx = [-1, 1], hy =[-1, 1]) {
            translate([oledCenterX + (hx * oledPitch/2), oledCenterY + (hy * oledPitch/2), -eps])
            cylinder(h=lidThickness + 2*eps, d=2.4); 
        }
            
        // Rotary Encoder Deliği
        translate([encoderCenterX, encoderCenterY, -eps])
            cylinder(h=lidThickness + 2*eps, d=encoderHoleDiameter);
            
        // LDR Sensörü Deliği
        translate([ldrCenterX, ldrCenterY, -eps])
            cylinder(h=lidThickness + 2*eps, d=ldrHoleDiameter);
            
        // Kapı Boşluğu (Sürgü Çıkışı)
        translate([doorSlotX, doorSlotY, -eps])
            cube([doorSlotW, doorSlotD, lidThickness + 2*eps]);
    }
}

// --- ÇİZİM ÇAĞRILARI ---
// Hangi parçayı dışa aktarmak istiyorsan onun başındaki '//' işaretini kaldır
//main_shell();
shell_lid();