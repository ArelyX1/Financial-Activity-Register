-- =============================================================================
--  TRIGGERS DE S02PERSON Y TABLAS RELACIONADAS  -  DB: lidercom
-- =============================================================================
--  GENERADO PARA MIGRAR LOS TRIGGERS A OTRA BASE DE DATOS
--  Usuario: arelyxl   |   Fecha: 2026-08-12
-- =============================================================================
--
--  RELACIONES DE S02PERSON:
--    S02PERSON (nidperson, uuid, PK)
--      |-- FK -> S01BOUNDARIE           (nBirthPlaceGadm     -> nuidgadm)   [SIN trigger]
--      |-- FK -> S01BOUNDARIE           (nResidencePlaceGadm -> nuidgadm)   [SIN trigger]
--      |-- FK -> S01IDENTIFICATION_TYPE (nididentificationtype)            [CON trigger]
--      |-- FK <- S02USER                (niduser -> nidperson)             [SIN trigger]
--      |-- FK <- S02PERSON_ROLE         (nidperson) ON DELETE CASCADE      [CON trigger]
--                 |-- FK -> S02ROLE     (nidrole)    ON DELETE CASCADE     [SIN trigger]
--
--  TRIGGERS EXISTENTES EN ESTE CONJUNTO DE TABLAS:
--    S02PERSON          : tr_validate_person_document_before_upsert  -> fn_validate_person_document
--    S02PERSON_ROLE     : trg_prevent_last_role_delete               -> fn_prevent_last_role_delete
--    S01IDENTIFICATION_TYPE : tr_validate_country_before_insert      -> fn_validate_country_iso
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
--  DESCRIPCIÓN: Impide que se elimine el último rol de una persona.
--  Cuenta cuántos roles tiene la persona (OLD.nidperson) en S02PERSON_ROLE;
--  si quedan 1 o menos, lanza una excepción y se cancela el DELETE.
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
--  DESCRIPCIÓN: Valida que el código de país (NEW.cCountryIso) exista en la
--  tabla S01BOUNDARIE (columna cGid0). Si no existe, lanza una excepción con
--  el código inválido y se cancela la operación INSERT/UPDATE.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_validate_country_iso()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "S01BOUNDARIE" WHERE cGid0 = NEW.cCountryIso LIMIT 1) THEN
        RAISE EXCEPTION 'El código de país % no existe en la tabla de fronteras', NEW.cCountryIso;
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
--  DESCRIPCIÓN: Valida el número de documento (NEW.cIdentificationNumber) de
--  la persona. Obtiene el patrón cRegex y el nombre del tipo de identificación
--  (S01IDENTIFICATION_TYPE) según NEW.nIdIdentificationType; si el documento
--  no cumple el patrón (expresión regular), lanza una excepción mostrando el
--  tipo y el patrón esperado, y se cancela la operación.
-- =============================================================================
CREATE OR REPLACE FUNCTION public.fn_validate_person_document()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_regex VARCHAR(100);
    v_name VARCHAR(100);
BEGIN
    SELECT cRegex, cName 
    INTO v_regex, v_name
    FROM "S01IDENTIFICATION_TYPE"
    WHERE nIdIdentificationType = NEW.nIdIdentificationType;

    IF NEW.cIdentificationNumber !~ v_regex THEN
        RAISE EXCEPTION 'The document number “%” is not valid for type %. It must conform to the pattern: %', 
            NEW.cIdentificationNumber, v_name, v_regex;
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

-- =============================================================================
--  TERCERA PARTE: VALIDACION DEL ARRAY aProcedure EN s04disbursement_log
--  Tablas de apoyo (deben existir previamente):
--    s01procedure(nidprocedure, cname, cdescription, bisactive, tcreatedat)
--    s04disbursement_log(niddisbursementlog, tdate, ntotalamount, aprocedure)
-- =============================================================================

-- =============================================================================
--  FUNCION: fn_validate_procedure_array
--  TRIGGER: tr_validate_procedure_array_before_upsert
--  TABLA  : s04disbursement_log
--  MOMENTO: BEFORE INSERT OR UPDATE
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Recorre cada elemento del array aProcedure (NEW.aprocedure) y
--  verifica que exista como PK (nidprocedure) en la tabla s01procedure.
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
    IF NEW.aProcedure IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT string_agg(coalesce(e.id::text, 'NULL'), ', ' ORDER BY e.id::text)
    INTO v_invalid
    FROM unnest(NEW.aProcedure) AS e(id)
    WHERE e.id IS NULL
       OR NOT EXISTS (SELECT 1 FROM s01procedure p WHERE p.nidprocedure = e.id);

    IF v_invalid IS NOT NULL THEN
        RAISE EXCEPTION 'El array aProcedure contiene identificadores de procedimiento invalidos: %', v_invalid;
    END IF;

    RETURN NEW;
END;
$function$;

-- Valida que cada elemento del array aProcedure exista en s01procedure
CREATE TRIGGER tr_validate_procedure_array_before_upsert BEFORE INSERT OR UPDATE ON public.s04disbursement_log FOR EACH ROW EXECUTE FUNCTION fn_validate_procedure_array();

-- =============================================================================
--  VISUALIZADOR (VIEW): vw_disbursement_log_procedures
-- -----------------------------------------------------------------------------
--  DESCRIPCION: Permite consultar los procedimientos (s01procedure) de cada
--  registro de s04disbursement_log desplegando el array aProcedure. Cada
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
FROM s04disbursement_log l
LEFT JOIN LATERAL unnest(l.aprocedure) WITH ORDINALITY AS e(id, ord) ON TRUE
LEFT JOIN s01procedure p ON p.nidprocedure = e.id
ORDER BY l.niddisbursementlog, e.ord;
