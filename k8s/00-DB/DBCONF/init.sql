-- =============================================================================
--  INIT SCHEMA  -  DB: lidercom (estilo de nombres de produccion)
-- =============================================================================
--  Convencion: tablas en MAYUSCULAS entre comillas (ej. "S02PERSON"), columnas
--  en minusculas (ej. nidperson), igual que la DB de produccion.
--  Requiere: extension PostGIS (por S01BOUNDARIE.ggeom).
--
--  RENOMBRES vs. el init original:
--    s03role          -> "S02ROLE"
--    s03person_role   -> "S02PERSON_ROLE"
--    s03permission    -> "S02PERMISSION"
--    s03role_permission-> "S02ROLE_PERMISSION"
--    s02venue         -> "S01VENUE"
--    s01procedure     -> "S01PROCEDURE"
--    s04disbursement_log        -> "S04DISBURSEMENT_LOG"
--    s04disbursement_log_detail -> "S04DISBURSEMENT_LOG_DETAIL"
--    s04vehicle_disbursement_log_detail -> "S04VEHICLE_DISBURSEMENT_LOG_DETAIL"
--    s04goals         -> "S04GOALS"
--
--  NOTA: los datos de S01BOUNDARIE (boundaries/geometrias GADM) se cargan
--  aparte (p.ej. ogr2ogr desde shapefile). Este script solo crea el esquema.
-- =============================================================================

SET timezone = 'America/Lima';

CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================================
--  S01BOUNDARIE  (debe existir antes que S02PERSON y S01VENUE)
-- =============================================================================
CREATE TABLE public."S01BOUNDARIE" (
	nuidgadm		INTEGER		NOT NULL,
	cgid0			VARCHAR(5),
	cname0			VARCHAR(100),
	cvarname0		VARCHAR(150),
	cgid1			VARCHAR(20),
	cname1			VARCHAR(100),
	cvarname1		TEXT,
	cnlname1		VARCHAR(150),
	ciso1			VARCHAR(20),
	chasc1			VARCHAR(20),
	ccc1			VARCHAR(20),
	ctype1			VARCHAR(50),
	cengtype1		VARCHAR(50),
	cvalidfr1		VARCHAR(20),
	cgid2			VARCHAR(20),
	cname2			VARCHAR(100),
	cvarname2		TEXT,
	cnlname2		VARCHAR(150),
	chasc2			VARCHAR(20),
	ccc2			VARCHAR(20),
	ctype2			VARCHAR(50),
	cengtype2		VARCHAR(50),
	cvalidfr2		VARCHAR(20),
	cgid3			VARCHAR(20),
	cname3			VARCHAR(100),
	cvarname3		TEXT,
	cnlname3		VARCHAR(150),
	chasc3			VARCHAR(20),
	ccc3			VARCHAR(20),
	ctype3			VARCHAR(50),
	cengtype3		VARCHAR(50),
	cvalidfr3		VARCHAR(20),
	cgid4			VARCHAR(20),
	cname4			VARCHAR(100),
	ctype4			VARCHAR(50),
	cengtype4		VARCHAR(50),
	cgid5			VARCHAR(20),
	cname5			VARCHAR(100),
	ctype5			VARCHAR(50),
	cengtype5		VARCHAR(50),
	csovereign		VARCHAR(100),
	cgovernedby		VARCHAR(100),
	cdisputedby		TEXT,
	cregion			VARCHAR(100),
	ccontinent		VARCHAR(50),
	ccountry		VARCHAR(100),
	nshapelength	DOUBLE PRECISION,
	nshapearea		DOUBLE PRECISION,
	ggeom			geometry(MultiPolygon,4326),

	CONSTRAINT "S01BOUNDARIE_pkey" PRIMARY KEY (nuidgadm)
);

CREATE INDEX idx_s01boundarie_ccountry ON public."S01BOUNDARIE" (ccountry);
CREATE INDEX idx_s01boundarie_ggeom    ON public."S01BOUNDARIE" USING gist (ggeom);

-- =============================================================================
--  S01IDENTIFICATION_TYPE  (tiene trigger de validacion de pais)
-- =============================================================================
CREATE TABLE public."S01IDENTIFICATION_TYPE" (
	nididentificationtype	SERIAL			PRIMARY KEY,
	ccountryiso				CHAR(3)			NOT NULL	DEFAULT 'PE',
	ccode					VARCHAR(5),
	cname					VARCHAR(100)	NOT NULL,
	nminlength				INTEGER			NOT NULL	DEFAULT 1,
	nmaxlength				INTEGER,
	bisnumeric				BOOL			DEFAULT TRUE,
	cregex					VARCHAR(100),
	bisactive				BOOL			DEFAULT TRUE,
	tcreatedat				TIMESTAMP		DEFAULT NOW(),

	CONSTRAINT uq_country_code          UNIQUE (ccountryiso, ccode),
	CONSTRAINT uq_country_document_name UNIQUE (ccountryiso, cname)
);

-- =============================================================================
--  S01ACCOUNT_PROVIDER
-- =============================================================================
CREATE TABLE public."S01ACCOUNT_PROVIDER" (
	nidaccountprovider	SERIAL			PRIMARY KEY,
	cname				VARCHAR(50)		NOT NULL,
	bisactive			BOOL			DEFAULT TRUE
);

-- =============================================================================
--  S02PERSON
-- =============================================================================
CREATE TABLE public."S02PERSON" (
	nidperson				UUID			PRIMARY KEY DEFAULT gen_random_uuid(),
	cname					VARCHAR(50)		NOT NULL,
	cmiddlename				VARCHAR(50),
	cmaternalsurname		VARCHAR(50)		NOT NULL,
	cpaternalsurname		VARCHAR(50),
	nididentificationtype	INTEGER			NOT NULL	REFERENCES "S01IDENTIFICATION_TYPE"(nididentificationtype),
	cididentificationnumber	VARCHAR(20)		NOT NULL,
	tcreatedat				TIMESTAMPTZ		DEFAULT NOW(),
	tmodifiedat				TIMESTAMPTZ,
	nbirthplacegadm			INTEGER			REFERENCES "S01BOUNDARIE"(nuidgadm),
	nresidenceplacegadm		INTEGER			REFERENCES "S01BOUNDARIE"(nuidgadm),
	bisactive				BOOL			DEFAULT TRUE,

	CONSTRAINT uq_person_identification UNIQUE (nididentificationtype, cididentificationnumber)
);

-- =============================================================================
--  S02USER
-- =============================================================================
CREATE TABLE public."S02USER" (
	niduser				UUID			PRIMARY KEY DEFAULT gen_random_uuid()
									REFERENCES "S02PERSON"(nidperson),
	cusername			VARCHAR(20)		NOT NULL,
	cemail				VARCHAR(100)	NOT NULL,
	tlatestaccess		TIMESTAMPTZ,
	tcreatedat			TIMESTAMPTZ		DEFAULT NOW(),
	bisactive			BOOL			DEFAULT TRUE,
	chashedpassword		VARCHAR(256)	NOT NULL,
	csalt				VARCHAR,
	nidaccountprovider	INTEGER			REFERENCES "S01ACCOUNT_PROVIDER"(nidaccountprovider),
	cproviderid			VARCHAR(255),
	bemailverified		BOOL			DEFAULT FALSE,
	cphotourl			VARCHAR,

	CONSTRAINT uq_user_email UNIQUE (cemail)
);

-- =============================================================================
--  S02ROLE
-- =============================================================================
CREATE TABLE public."S02ROLE" (
	nidrole			SERIAL			PRIMARY KEY,
	cname			VARCHAR(50)		NOT NULL,
	cdescription	TEXT,
	ccategory		VARCHAR			CHECK (ccategory IN ('Employee', 'Client')),
	bissystemrole	BOOL			DEFAULT FALSE,
	bisactive		BOOL			DEFAULT TRUE,
	tcreatedat		TIMESTAMPTZ		DEFAULT NOW(),

	CONSTRAINT uq_role_name UNIQUE (cname)
);

-- =============================================================================
--  S02PERSON_ROLE  (tiene trigger que evita eliminar el ultimo rol)
-- =============================================================================
CREATE TABLE public."S02PERSON_ROLE" (
	nidrole			INTEGER			NOT NULL	REFERENCES "S02ROLE"(nidrole) ON DELETE CASCADE,
	nidperson		UUID			NOT NULL	REFERENCES "S02PERSON"(nidperson) ON DELETE CASCADE,
	tcreatedat		TIMESTAMPTZ		DEFAULT NOW(),

	CONSTRAINT "S02PERSON_ROLE_pkey" PRIMARY KEY (nidrole, nidperson)
);

-- =============================================================================
--  S02PERMISSION
-- =============================================================================
CREATE TABLE public."S02PERMISSION" (
	nidpermission	SERIAL			PRIMARY KEY,
	ccode			VARCHAR(50)		NOT NULL,
	cname			VARCHAR(100)	NOT NULL,
	cdescription	TEXT,
	cmodule			VARCHAR(50),
	bisactive		BOOL			DEFAULT TRUE,
	tcreatedat		TIMESTAMPTZ		DEFAULT NOW(),

	CONSTRAINT uq_permission_code UNIQUE (ccode)
);

-- =============================================================================
--  S02ROLE_PERMISSION
-- =============================================================================
CREATE TABLE public."S02ROLE_PERMISSION" (
	nidrole			INTEGER			NOT NULL	REFERENCES "S02ROLE"(nidrole) ON DELETE CASCADE,
	nidpermission	INTEGER			NOT NULL	REFERENCES "S02PERMISSION"(nidpermission) ON DELETE CASCADE,
	tcreatedat		TIMESTAMPTZ		DEFAULT NOW(),

	CONSTRAINT "S02ROLE_PERMISSION_pkey" PRIMARY KEY (nidrole, nidpermission)
);

-- =============================================================================
--  S01VENUE_TYPE
-- =============================================================================
CREATE TABLE public."S01VENUE_TYPE" (
	nidvenuetype	SERIAL			PRIMARY KEY,
	cname			VARCHAR(100)	NOT NULL,
	cdescription	TEXT,
	bisactive		BOOL			DEFAULT TRUE
);

-- =============================================================================
--  S01VENUE
-- =============================================================================
CREATE TABLE public."S01VENUE" (
	nidvenue			SERIAL			PRIMARY KEY,
	nidvenuetype		INTEGER			NOT NULL	REFERENCES "S01VENUE_TYPE"(nidvenuetype),
	cname				VARCHAR(100)	NOT NULL,
	cdescription		TEXT,
	clogourl			VARCHAR(500),
	nuidgadm			INTEGER			NOT NULL	REFERENCES "S01BOUNDARIE"(nuidgadm),
	clocationdetail		VARCHAR(300)	NOT NULL,
	nlatitude			NUMERIC(10,8),
	nlongitude			NUMERIC(11,8),
	bisactive			BOOL			DEFAULT TRUE
);

-- =============================================================================
--  S01PROCEDURE  (referenciada por S04DISBURSEMENT_LOG.aprocedure via trigger)
-- =============================================================================
CREATE TABLE public."S01PROCEDURE" (
	nidprocedure	SERIAL			PRIMARY KEY,
	cname			VARCHAR(100)	NOT NULL,
	cdescription	TEXT,
	bisactive		BOOL			DEFAULT TRUE,
	tcreatedat		TIMESTAMPTZ		DEFAULT NOW()
);

-- =============================================================================
--  S04DISBURSEMENT_LOG  (tiene trigger de validacion del array aProcedure)
-- =============================================================================
CREATE TABLE public."S04DISBURSEMENT_LOG" (
	niddisbursementlog	UUID		PRIMARY KEY DEFAULT gen_random_uuid(),
	tdate				DATE		NOT NULL	DEFAULT CURRENT_DATE,
	ntotalamount		NUMERIC(12,2)	NOT NULL,
	aprocedure			INT[]
);

-- =============================================================================
--  S04DISBURSEMENT_LOG_DETAIL
-- =============================================================================
CREATE TABLE public."S04DISBURSEMENT_LOG_DETAIL" (
	niddisbursementlogdetail	UUID			PRIMARY KEY DEFAULT gen_random_uuid(),
	namount						NUMERIC(12,2)	NOT NULL,
	nidperson					UUID			REFERENCES "S02PERSON"(nidperson),
	nmora						NUMERIC(12,2),
	bisvehicle					BOOL			NOT NULL,
	tdate						TIMESTAMPTZ		DEFAULT NOW()
);

-- =============================================================================
--  S04VEHICLE_DISBURSEMENT_LOG_DETAIL
-- =============================================================================
CREATE TABLE public."S04VEHICLE_DISBURSEMENT_LOG_DETAIL" (
	niddisbursementlogdetail	UUID		PRIMARY KEY REFERENCES "S04DISBURSEMENT_LOG_DETAIL"(niddisbursementlogdetail),
	nidvenue					INTEGER		NOT NULL REFERENCES "S01VENUE"(nidvenue),
	bismorningshift				BOOL		NOT NULL,
	bislateshift				BOOL		NOT NULL,

	CONSTRAINT chk_vehicle_one_shift CHECK (bismorningshift OR bislateshift)
);

-- =============================================================================
--  S04GOALS
-- =============================================================================
CREATE TABLE public."S04GOALS" (
	nidgoals		UUID			PRIMARY KEY DEFAULT gen_random_uuid(),
	cname			VARCHAR(50)		NOT NULL,
	tlimitdate		TIMESTAMPTZ		NOT NULL,
	namount			NUMERIC(12,2)	NOT NULL,
	ctype			VARCHAR			CHECK (ctype IN ('Money', 'Client')),
	nidperson		UUID			REFERENCES "S02PERSON"(nidperson),
	bisfulfilled	BOOL			DEFAULT FALSE,
	bisactive		BOOL			DEFAULT TRUE,
	tcreatedat		TIMESTAMPTZ		DEFAULT NOW()
);

-- =============================================================================
--  TRIGGERS DE S02PERSON Y TABLAS RELACIONADAS  -  DB: lidercom
-- =============================================================================
--  GENERADO PARA MIGRAR LOS TRIGGERS A OTRA BASE DE DATOS
--  Usuario: arelyxl   |   Fecha: 2026-08-12
-- =============================================================================
--
--  RELACIONES DE S02PERSON:
--    "S02PERSON" (nidperson, uuid, PK)
--      |-- FK -> "S01BOUNDARIE"            (nbirthplacegadm     -> nuidgadm)   [SIN trigger]
--      |-- FK -> "S01BOUNDARIE"            (nresidenceplacegadm -> nuidgadm)   [SIN trigger]
--      |-- FK -> "S01IDENTIFICATION_TYPE"  (nididentificationtype)            [CON trigger]
--      |-- FK <- "S02USER"                 (niduser -> nidperson)             [SIN trigger]
--      |-- FK <- "S02PERSON_ROLE"          (nidperson) ON DELETE CASCADE      [CON trigger]
--                 |-- FK -> "S02ROLE"      (nidrole)    ON DELETE CASCADE     [SIN trigger]
--
--  TRIGGERS EXISTENTES EN ESTE CONJUNTO DE TABLAS:
--    "S02PERSON"      : tr_validate_person_document_before_upsert  -> fn_validate_person_document
--    "S02PERSON_ROLE" : trg_prevent_last_role_delete               -> fn_prevent_last_role_delete
--    "S01IDENTIFICATION_TYPE" : tr_validate_country_before_insert  -> fn_validate_country_iso
--    "S04DISBURSEMENT_LOG"    : tr_validate_procedure_array_before_upsert -> fn_validate_procedure_array
--
--  NOTA: Los triggers usan las funciones que se definen abajo (orden:
--  primero FUNCIONES, luego TRIGGERS).
-- =============================================================================

-- =============================================================================
--  FUNCION: fn_prevent_last_role_delete
--  TRIGGER: trg_prevent_last_role_delete
--  TABLA  : S02PERSON_ROLE
--  MOMENTO: BEFORE DELETE
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Impide que se elimine el ultimo rol de una persona.
--  Cuenta cuantos roles tiene la persona (OLD.nidperson) en S02PERSON_ROLE;
--  si quedan 1 o menos, lanza una excepcion y se cancela el DELETE.
--  Garantiza que toda persona mantenga siempre al menos un rol.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_prevent_last_role_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 AS $function$
DECLARE
    role_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_count
    FROM "S02PERSON_ROLE"
    WHERE nidperson = OLD.nidperson;

    IF role_count <= 1 THEN
        RAISE EXCEPTION 'No se puede eliminar el ultimo rol de una persona. Cada persona debe tener al menos un rol.';
    END IF;

    RETURN OLD;
END;
$function$;

-- =============================================================================
--  FUNCION: fn_validate_country_iso
--  TRIGGER: tr_validate_country_before_insert
--  TABLA  : S01IDENTIFICATION_TYPE
--  MOMENTO: BEFORE INSERT OR UPDATE
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Valida que el codigo de pais (NEW.ccountryiso) exista en la
--  tabla S01BOUNDARIE (columna cgid0). Si no existe, lanza una excepcion con
--  el codigo invalido y se cancela la operacion INSERT/UPDATE.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_validate_country_iso()
 RETURNS trigger
 LANGUAGE plpgsql
 AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "S01BOUNDARIE" WHERE cgid0 = NEW.ccountryiso LIMIT 1) THEN
        RAISE EXCEPTION 'El codigo de pais % no existe en la tabla de fronteras', NEW.ccountryiso;
    END IF;
    RETURN NEW;
END;
$function$;

-- =============================================================================
--  FUNCION: fn_validate_person_document
--  TRIGGER: tr_validate_person_document_before_upsert
--  TABLA  : S02PERSON
--  MOMENTO: BEFORE INSERT OR UPDATE
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Valida el numero de documento (NEW.cididentificationnumber) de
--  la persona. Obtiene el patron cregex y el nombre del tipo de identificacion
--  (S01IDENTIFICATION_TYPE) segun NEW.nididentificationtype; si el documento
--  no cumple el patron (expresion regular), lanza una excepcion mostrando el
--  tipo y el patron esperado, y se cancela la operacion.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_validate_person_document()
 RETURNS trigger
 LANGUAGE plpgsql
 AS $function$
DECLARE
    v_regex VARCHAR(100);
    v_name VARCHAR(100);
BEGIN
    SELECT cregex, cname
    INTO v_regex, v_name
    FROM "S01IDENTIFICATION_TYPE"
    WHERE nididentificationtype = NEW.nididentificationtype;

    IF NEW.cididentificationnumber !~ v_regex THEN
        RAISE EXCEPTION 'El numero de documento % no es valido para el tipo %. Debe cumplir el patron: %',
            NEW.cididentificationnumber, v_name, v_regex;
    END IF;

    RETURN NEW;
END;
$function$;

-- =============================================================================
--  FUNCION: fn_validate_procedure_array
--  TRIGGER: tr_validate_procedure_array_before_upsert
--  TABLA  : S04DISBURSEMENT_LOG
--  MOMENTO: BEFORE INSERT OR UPDATE
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Recorre cada elemento del array aProcedure (NEW.aprocedure) y
--  verifica que exista como PK (nidprocedure) en la tabla S01PROCEDURE.
--  Si alguno no existe (o hay un NULL), lanza una excepcion listando los ids
--  invalidos y se cancela el INSERT/UPDATE, impidiendo agregar el array.
--  Si el array es NULL, se permite (no se valida).
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_validate_procedure_array()
 RETURNS trigger
 LANGUAGE plpgsql
 AS $function$
DECLARE
    v_invalid TEXT;
BEGIN
    IF NEW.aprocedure IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT string_agg(coalesce(e.id::text, 'NULL'), ', ' ORDER BY e.id::text)
    INTO v_invalid
    FROM unnest(NEW.aprocedure) AS e(id)
    WHERE e.id IS NULL
       OR NOT EXISTS (SELECT 1 FROM "S01PROCEDURE" p WHERE p.nidprocedure = e.id);

    IF v_invalid IS NOT NULL THEN
        RAISE EXCEPTION 'El array aProcedure contiene identificadores de procedimiento invalidos: %', v_invalid;
    END IF;

    RETURN NEW;
END;
$function$;

-- =============================================================================
--  CREACION DE TRIGGERS
-- =============================================================================

-- Valida el codigo de pais antes de insertar/actualizar un tipo de identificacion
CREATE TRIGGER tr_validate_country_before_insert BEFORE INSERT OR UPDATE ON public."S01IDENTIFICATION_TYPE" FOR EACH ROW EXECUTE FUNCTION fn_validate_country_iso();

-- Valida el numero de documento de una persona antes de insertar/actualizar
CREATE TRIGGER tr_validate_person_document_before_upsert BEFORE INSERT OR UPDATE ON public."S02PERSON" FOR EACH ROW EXECUTE FUNCTION fn_validate_person_document();

-- Evita eliminar el ultimo rol de una persona
CREATE TRIGGER trg_prevent_last_role_delete BEFORE DELETE ON public."S02PERSON_ROLE" FOR EACH ROW EXECUTE FUNCTION fn_prevent_last_role_delete();

-- Valida que cada elemento del array aProcedure exista en S01PROCEDURE
CREATE TRIGGER tr_validate_procedure_array_before_upsert BEFORE INSERT OR UPDATE ON public."S04DISBURSEMENT_LOG" FOR EACH ROW EXECUTE FUNCTION fn_validate_procedure_array();

-- =============================================================================
--  VISUALIZADOR (VIEW): vw_disbursement_log_procedures
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Permite consultar los procedimientos (S01PROCEDURE) de cada
--  registro de S04DISBURSEMENT_LOG desplegando el array aProcedure. Cada
--  elemento del array se une con su nidprocedure correspondiente y se muestra
--  una fila por log + procedimiento (LEFT JOIN: los logs sin procedimientos o
--  con ids invalidos tambien aparecen con columnas de procedimiento en NULL).
-- =============================================================================
CREATE OR REPLACE VIEW public.vw_disbursement_log_procedures AS
SELECT
    l.niddisbursementlog,
    l.tdate,
    l.ntotalamount,
    l.aprocedure,
    e.id                       AS nidprocedure_array,
    p.nidprocedure             AS nidprocedure,
    p.cname                    AS cname,
    p.cdescription             AS cdescription,
    p.bisactive                AS bisactive
FROM "S04DISBURSEMENT_LOG" l
LEFT JOIN LATERAL unnest(l.aprocedure) WITH ORDINALITY AS e(id, ord) ON TRUE
LEFT JOIN "S01PROCEDURE" p ON p.nidprocedure = e.id
ORDER BY l.niddisbursementlog, e.ord;

-- =============================================================================
--  SEED BASICO (opcional): tipos de identificacion y roles minimos
--  NOTA: S01BOUNDARIE se carga aparte (shapefile GADM). El trigger
--  tr_validate_country_before_insert exige que ccountryiso exista en
--  S01BOUNDARIE.cgid0 antes de insertar un tipo de identificacion.
-- =============================================================================
-- INSERT INTO "S01IDENTIFICATION_TYPE"(ccountryiso, ccode, cname, cregex)
-- VALUES ('PER', 'DNI', 'Documento Nacional de Identidad', '^\d{8}$');
--
-- INSERT INTO "S02ROLE"(cname, ccategory) VALUES ('Employee', 'Employee'), ('Client', 'Client');
