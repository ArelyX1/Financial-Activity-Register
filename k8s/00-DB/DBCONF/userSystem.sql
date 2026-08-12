CREATE TABLE "S01IDENTIFICATION_TYPE" (
    nIdIdentificationType SERIAL PRIMARY KEY,
    
    cCountryIso CHAR(3) DEFAULT 'PER' NOT NULL, 
    
    cCode VARCHAR(5),  
    
    cName VARCHAR(100) NOT NULL,
    nMinLength INTEGER NOT NULL DEFAULT 1,
    nMaxLength INTEGER NOT NULL,
    bIsNumeric BOOLEAN DEFAULT TRUE,
    cRegex VARCHAR(100), -- Patrón de validación
    
    bIsActive BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT uq_country_code UNIQUE(cCountryIso, cCode),
    CONSTRAINT uq_country_document_name UNIQUE(cCountryIso, cName)
);


