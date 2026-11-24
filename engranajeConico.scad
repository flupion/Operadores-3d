// ==========================================
// PARÁMETROS DEL ENGRANAJE (Medidas en mm)
// ==========================================
num_dientes = 15;          // 15 dientes (como en la Figura 10.29)
diametro_exterior = 50.0;  // 5 cm de diámetro total (de punta a punta)
grosor = 4.0;              // Espesor del engranaje (4 mm)
diametro_eje = 4.0;        // Varilla metálica M4
tolerancia_eje = 0.25;     // Holgura para impresión 3D (4.25 mm reales)
angulo_presion = 20;       // Estándar (20 grados)

$fn = 80;

// ==========================================
// CÁLCULOS GEOMÉTRICOS
// ==========================================
modulo = diametro_exterior / (num_dientes + 2);
diametro_primitivo = modulo * num_dientes;

// ==========================================
// GENERACIÓN DE LA PIEZA FINAL
// ==========================================
difference() {
    engranaje_recto(
        m = modulo,
        z = num_dientes,
        h = grosor,
        pa = angulo_presion
    );
    
    // Agujero central para la varilla M4
    translate([0, 0, -1])
        cylinder(d = diametro_eje + tolerancia_eje, h = grosor + 2);
}

// ==========================================
// FUNCIONES Y MÓDULOS DE GEOMETRÍA
// ==========================================
function rad2deg(rad) = rad * 180 / PI;
function deg2rad(deg) = deg * PI / 180;
function involuta_rad(alpha_deg) = tan(alpha_deg) - deg2rad(alpha_deg);

module engranaje_recto(m, z, h, pa) {
    r_p = (m * z) / 2;          // Radio primitivo (22.06 mm)
    r_b = r_p * cos(pa);        // Radio base (20.73 mm)
    r_a = r_p + m;              // Radio exterior o de cabeza (25.00 mm)
    r_f = r_p - 1.25 * m;       // Radio de raíz o de pie (18.38 mm)
    
    linear_extrude(height = h, convexity = 10) {
        union() {
            // Disco base hasta el círculo de raíz
            circle(r = r_f + 0.05);
            
            // Repetición de los 15 dientes alrededor del centro
            for (i = [0 : z - 1]) {
                rotate([0, 0, i * (360 / z)])
                    diente_solido(r_b, r_p, r_a, r_f, z, pa);
            }
        }
    }
}

module diente_solido(r_b, r_p, r_a, r_f, z, pa) {
    pasos = 10;
    r_inicio = max(r_b, r_f);
    
    // Medio ángulo del diente en el círculo base (en grados)
    medio_ang_base = (90 / z) + rad2deg(involuta_rad(pa));
    
    // 1. Flanco inferior: sube desde la raíz (i=0) hasta la punta (i=pasos)
    // Ángulo negativo (debajo del eje X)
    flanco_inf = [
        for (i = [0 : pasos])
            let(
                r = r_inicio + (r_a - r_inicio) * (i / pasos),
                alpha = acos(min(1, r_b / r)),
                theta = -(medio_ang_base - rad2deg(involuta_rad(alpha)))
            )
            [r * cos(theta), r * sin(theta)]
    ];
    
    // 2. Flanco superior: baja desde la punta (i=pasos) hasta la raíz (i=0)
    // Ángulo positivo (encima del eje X)
    flanco_sup = [
        for (i = [pasos : -1 : 0])
            let(
                r = r_inicio + (r_a - r_inicio) * (i / pasos),
                alpha = acos(min(1, r_b / r)),
                theta = (medio_ang_base - rad2deg(involuta_rad(alpha)))
            )
            [r * cos(theta), r * sin(theta)]
    ];
    
    // Puntos de unión en la raíz (si el radio de raíz es menor que el base)
    raiz_inf = (r_f < r_b) ? [[r_f * cos(-medio_ang_base), r_f * sin(-medio_ang_base)]] : [];
    raiz_sup = (r_f < r_b) ? [[r_f * cos(medio_ang_base), r_f * sin(medio_ang_base)]] : [];
    
    // Recorrido continuo en sentido antihorario sin cruces:
    // Centro -> Raíz inferior -> Flanco inferior (sube) -> Flanco superior (baja) -> Raíz superior
    polygon(concat([[0, 0]], raiz_inf, flanco_inf, flanco_sup, raiz_sup));
}