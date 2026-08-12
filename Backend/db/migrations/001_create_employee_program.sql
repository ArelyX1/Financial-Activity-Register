CREATE TABLE IF NOT EXISTS "S02EMPLOYEE_PROGRAM" (
    nidemployee UUID NOT NULL REFERENCES "S02EMPLOYEE"(nidemployee),
    nidprogram UUID NOT NULL REFERENCES "S01PROGRAM"(nidprogram),
    bisactive BOOLEAN DEFAULT TRUE,
    tcreatedat TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (nidemployee, nidprogram)
);
