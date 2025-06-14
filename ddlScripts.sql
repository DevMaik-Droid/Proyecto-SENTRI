-- ========== DOMINIOS ==========
CREATE DOMAIN D_GENERO AS CHAR(1) CHECK (VALUE IN ('M', 'F'));
CREATE DOMAIN D_TEXT50 AS VARCHAR(50);
CREATE DOMAIN D_TEXT100 AS VARCHAR(100);
CREATE DOMAIN D_TEXT20 AS VARCHAR(20);
CREATE DOMAIN D_TEXT AS VARCHAR(255);
CREATE DOMAIN D_ACTIVO_CURSO AS VARCHAR(10) CHECK (VALUE IN ('PROXIMAMENTE', 'ACTIVO','FINALIZADO', 'CANCELADO'));
CREATE DOMAIN D_DIA_SEMANA AS VARCHAR(9) CHECK (VALUE IN ('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'));
CREATE DOMAIN D_ESTADO_ASISTENCIA AS VARCHAR(15) CHECK (VALUE IN ('Presente', 'Ausente', 'Tarde', 'Justificado'));
CREATE DOMAIN D_METODO_REGISTRO AS VARCHAR(5) CHECK (VALUE IN ('QR', 'IA', 'Manual'));
CREATE DOMAIN D_ESTADO AS VARCHAR(10) CHECK (VALUE IN ('ACTIVO', 'INACTIVO','ELIMINADO'));
-- ========== ROLES ==========
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
);

INSERT INTO roles (nombre, descripcion) VALUES 
('admin', 'Administrador del sistema'),
('docente', 'Personal docente'),
('estudiante', 'Estudiantes');

-- ========== USUARIOS ==========
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre D_TEXT50 NOT NULL,
    apellido D_TEXT50 NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    cedula D_TEXT20 UNIQUE NOT NULL,
    genero D_GENERO NOT NULL,
    direccion D_TEXT100,
    telefono D_TEXT20,
    email D_TEXT100 UNIQUE NOT NULL,
    password_hash D_TEXT NOT NULL,
    foto_perfil D_TEXT,
    estado D_ESTADO DEFAULT 'ACTIVO',
    rol_id INTEGER REFERENCES roles(id),
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========== NIVELES ==========
CREATE TABLE niveles(
    id SERIAL PRIMARY KEY,
    nombre D_TEXT20 NOT NULL,
    descripcion D_TEXT
);

-- ========== ESTUDIANTES ==========
CREATE TABLE estudiantes(
    id SERIAL PRIMARY KEY,
    codigo D_TEXT20 UNIQUE NOT NULL,
    nivel_id INTEGER REFERENCES niveles(id),
    usuario_id INTEGER UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE
);

-- ========== DOCENTES ==========
CREATE TABLE docentes (
    id SERIAL PRIMARY KEY,
    profesion D_TEXT50 NOT NULL,
    especialidad D_TEXT50,
    fecha_contratacion DATE NOT NULL,
    observaciones D_TEXT,
    usuario_id INTEGER UNIQUE NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE
);

-- ========== GESTIONES ACADEMICAS ==========
CREATE TABLE gestiones_academicas (
    id SERIAL PRIMARY KEY,
    nombre D_TEXT20 NOT NULL UNIQUE,
    tipo VARCHAR(10) CHECK (tipo IN ('Anual', 'Semestral')) DEFAULT 'Anual',
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    descripcion D_TEXT
);

-- ========== AULAS ==========
CREATE TABLE aulas (
    id SERIAL PRIMARY KEY,
    nombre D_TEXT20 NOT NULL UNIQUE,
    descripcion D_TEXT,
    capacidad INTEGER CHECK (capacidad > 0),
    ubicacion D_TEXT100
);

-- ========== CURSOS ==========
CREATE TABLE cursos (
    id SERIAL PRIMARY KEY,
    nombre D_TEXT50 NOT NULL,
    gestion_id INTEGER REFERENCES gestiones_academicas(id),
    turno D_TEXT20,
    paralelo CHAR(1),
    activo D_ACTIVO_CURSO DEFAULT 'PROXIMAMENTE',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========== MATERIAS ==========
CREATE TABLE materias (
    id SERIAL PRIMARY KEY,
    nombre D_TEXT50 NOT NULL,
    descripcion D_TEXT,
    nivel_id INTEGER REFERENCES niveles(id)
);

-- ========== MATERIAS - CURSOS ==========
CREATE TABLE materias_cursos (
    id SERIAL PRIMARY KEY,
    curso_id INTEGER NOT NULL REFERENCES cursos(id),
    materia_id INTEGER NOT NULL REFERENCES materias(id),
    UNIQUE (curso_id, materia_id)
);

-- ========== DOCENTES - MATERIAS ==========
CREATE TABLE docentes_materias (
    id SERIAL PRIMARY KEY,
    docente_id INTEGER NOT NULL REFERENCES docentes(id) ON DELETE CASCADE,
    materia_curso_id INTEGER NOT NULL REFERENCES materias_cursos(id) ON DELETE CASCADE
);

-- ========== ESTUDIANTES - MATERIAS ==========
CREATE TABLE estudiantes_materias (
    id SERIAL PRIMARY KEY,
    estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id) ON DELETE CASCADE,
    materia_curso_id INTEGER NOT NULL REFERENCES materias_cursos(id) ON DELETE CASCADE,
    fecha_inscripcion DATE DEFAULT CURRENT_DATE,
    UNIQUE (estudiante_id, materia_curso_id)
);

-- ========== HORARIOS ==========
CREATE TABLE horarios (
    id SERIAL PRIMARY KEY,
    dia_semana D_DIA_SEMANA NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    materia_curso_id INTEGER NOT NULL REFERENCES materias_cursos(id),
    aula_id INTEGER NOT NULL REFERENCES aulas(id)
);

-- ========== ASISTENCIAS ==========
CREATE TABLE asistencias (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    metodo_registro D_METODO_REGISTRO DEFAULT 'IA',
    estado D_ESTADO_ASISTENCIA DEFAULT 'Presente',
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
    UNIQUE (usuario_id, fecha)
);

CREATE TABLE asistencias_materia (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
    materia_curso_id INTEGER NOT NULL REFERENCES materias_cursos(id),
    fecha DATE DEFAULT CURRENT_DATE,
    hora TIME DEFAULT CURRENT_TIME,
    metodo_registro D_METODO_REGISTRO DEFAULT 'QR',
    estado D_ESTADO_ASISTENCIA DEFAULT 'Presente',
    UNIQUE (usuario_id, materia_curso_id, fecha)
);

CREATE TABLE qr_asistencia (
    id SERIAL PRIMARY KEY,
    materia_curso_id INTEGER NOT NULL REFERENCES materias_cursos(id),
    codigo TEXT UNIQUE NOT NULL,           -- Token QR
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,                -- Tiempo válido del QR (ej: 10 mins)
    creado_por INTEGER REFERENCES usuarios(id), -- Docente que genera
    activo BOOLEAN DEFAULT TRUE
);

-- ========= Registro de rostros ==========
CREATE TABLE rostros (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id),
    emmbedding FLOAT8[] NOT NULL,
    image_path TEXT NOT NULL,
    UNIQUE (usuario_id)
);

-- ========== LOG DE ACCESOS =========
CREATE TABLE log_accesos (
    log_id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(usuario_id),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip VARCHAR(45),
    navegador TEXT
);

-- ========== ÍNDICES ==========
CREATE INDEX idx_usuarios_username ON usuarios(username);
CREATE INDEX idx_docente_usuario ON docentes(id);
CREATE INDEX idx_estudiante_usuario ON estudiantes(id);
CREATE INDEX idx_asistencia_usuario_fecha ON asistencias(id, fecha);
