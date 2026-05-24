-- Crear tabla de registros
CREATE TABLE IF NOT EXISTS registros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    comuna VARCHAR(100) NOT NULL,
    carrera VARCHAR(100) NOT NULL,
    fecha DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_comuna (comuna),
    INDEX idx_carrera (carrera),
    INDEX idx_fecha (fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar datos de ejemplo (opcional)
INSERT INTO registros (nombre, comuna, carrera, fecha) VALUES
('Juan García López', 'Comuna 1', 'Medicina', NOW()),
('María Rodríguez López', 'Comuna 2', 'Ingeniería', NOW()),
('Carlos Martínez Pérez', 'Comuna 3', 'Abogacía', NOW()),
('Ana Sánchez Torres', 'Comuna 4', 'Licenciatura', NOW()),
('Luis González García', 'Comuna 5', 'Medicina', NOW());
