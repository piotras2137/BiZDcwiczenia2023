-- FUNKCJE 1
CREATE OR REPLACE FUNCTION get_job_title(job_id_param IN VARCHAR2)
    RETURN VARCHAR2
IS
    v_job_title jobs.job_title%TYPE;
BEGIN
    SELECT job_title
    INTO v_job_title
    FROM jobs
    WHERE job_id = job_id_param;

    RETURN v_job_title;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Praca o podanym ID nie istnieje');
END;
-- TEST
DECLARE
  v_job_title VARCHAR2(100);
BEGIN
  v_job_title := get_job_title('AD_PRES');
  DBMS_OUTPUT.PUT_LINE('Nazwa pracy: ' || v_job_title);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
END;


-- FUNKCJE 2
CREATE OR REPLACE FUNCTION calculate_annual_income(employee_id_param IN NUMBER)
RETURN NUMBER
IS
  v_salary NUMBER;
  v_commission_pct NUMBER;
  v_annual_income NUMBER;
BEGIN
  SELECT salary, commission_pct
  INTO v_salary, v_commission_pct
  FROM employees
  WHERE employee_id = employee_id_param;

  v_annual_income := v_salary * 12;

  IF v_commission_pct IS NOT NULL THEN
    v_annual_income := v_annual_income + (v_salary * v_commission_pct);
  END IF;

  RETURN v_annual_income;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Pracownik o podanym ID nie istnieje');
END;
-- TEST
DECLARE
  v_annual_income NUMBER;
BEGIN
  v_annual_income := calculate_annual_income(101);
  DBMS_OUTPUT.PUT_LINE('Roczne zarobki pracownika: ' || v_annual_income);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
END;


-- FUNKCJE 3
CREATE OR REPLACE FUNCTION get_area_code(phone_number_param IN VARCHAR2)
RETURN VARCHAR2
IS
  v_area_code VARCHAR2(10);
BEGIN
  SELECT REGEXP_SUBSTR(phone_number_param, '^\+?\d{1,4}') 
  INTO v_area_code
  FROM dual;

  RETURN v_area_code;
END;
-- TEST
DECLARE
  v_area_code VARCHAR2(10);
BEGIN
  v_area_code := get_area_code('+48-522-456-790');
  DBMS_OUTPUT.PUT_LINE('Numer kierunkowy: ' || v_area_code);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
END;


-- FUNKCJE 4
CREATE OR REPLACE FUNCTION capitalize_first_last(str IN VARCHAR2) RETURN VARCHAR2
IS
  v_result VARCHAR2(4000);
BEGIN
  IF str IS NULL THEN
    RETURN NULL;
  END IF;
  
  v_result := LOWER(str);

  IF LENGTH(v_result) >= 2 THEN
    v_result := INITCAP(SUBSTR(v_result, 1, 1)) || SUBSTR(v_result, 2, LENGTH(v_result) - 2) || INITCAP(SUBSTR(v_result, -1));
  ELSE
    v_result := INITCAP(v_result);
  END IF;

  RETURN v_result;
END;
-- TEST
DECLARE
  v_input VARCHAR2(100);
  v_output VARCHAR2(100);
BEGIN
  v_input := 'aLa Ma KoTa';
  v_output := capitalize_first_last(v_input);
  DBMS_OUTPUT.PUT_LINE('Wynik: ' || v_output);
END;


-- FUNKCJE 5
CREATE OR REPLACE FUNCTION pesel_to_birthdate(pesel_param IN VARCHAR2) 
RETURN VARCHAR2
IS
  v_birthdate VARCHAR2(11);
  v_year NUMBER;
  v_month NUMBER;
  v_day NUMBER;
BEGIN
  IF LENGTH(pesel_param) <> 11 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Nieprawidłowa długość numeru PESEL');
  END IF;

  v_year := TO_NUMBER(SUBSTR(pesel_param, 1, 2));
  v_month := TO_NUMBER(SUBSTR(pesel_param, 3, 2));
  v_day := TO_NUMBER(SUBSTR(pesel_param, 5, 2));

  IF v_month < 20 THEN
    v_year := v_year + 1900;
  ELSE
    v_year := v_year + 2000;
  END IF;
  
  v_birthdate := TRIM(TO_CHAR(v_year, '0000')) || '-' || TRIM(TO_CHAR(v_month, '00')) || '-' || TRIM(TO_CHAR(v_day, '00'));

  RETURN v_birthdate;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20002, 'Błąd: ' || SQLERRM);
END;
-- TEST
DECLARE
  v_pesel VARCHAR2(11);
  v_birthdate VARCHAR2(10);
BEGIN
  v_pesel := '99052421433';
  v_birthdate := pesel_to_birthdate(v_pesel);
  DBMS_OUTPUT.PUT_LINE('Data urodzenia: ' || v_birthdate);
END;


-- FUNKCJE 6
CREATE OR REPLACE FUNCTION get_employee_department_count(country_name_param IN VARCHAR2)
RETURN VARCHAR2
IS
  v_employee_count NUMBER;
  v_department_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_department_count
  FROM countries c
  JOIN locations l ON c.country_id = l.country_id
  JOIN departments d ON d.location_id = l.location_id 
  WHERE UPPER(country_name) = UPPER(country_name_param);

  IF v_department_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Kraj nie istnieje w bazie danych');
  END IF;

  SELECT COUNT(*) INTO v_employee_count
  FROM employees e
  JOIN departments d ON e.department_id = d.department_id
  JOIN locations l ON d.location_id = l.location_id
  JOIN countries c ON l.country_id = c.country_id
  WHERE UPPER(c.country_name) = UPPER(country_name_param);

  RETURN 'Liczba pracowników: ' || TO_CHAR(v_employee_count) || ', Liczba departamentów: ' || TO_CHAR(v_department_count);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Brak danych');
END;
-- TEST
DECLARE
  v_result VARCHAR2(100);
BEGIN
  v_result := get_employee_department_count('United States of America');
  DBMS_OUTPUT.PUT_LINE('Wynik: ' || v_result);
END;


-- WYZWALACZE 1
DROP TABLE archiwum_departamentow;
-- TABELA POMOCNICZA
CREATE TABLE archiwum_departamentow (
    id NUMBER,
    nazwa VARCHAR2(100),
    data_zamkniecia DATE,
    ostatni_manager VARCHAR2(100)
);
-- WYZWALACZ
CREATE OR REPLACE TRIGGER archiwum_departamentow_trigger
AFTER DELETE ON departments
FOR EACH ROW
DECLARE
    v_manager_first_name employees.first_name%TYPE;
    v_manager_last_name employees.last_name%TYPE;
BEGIN
    SELECT first_name, last_name
    INTO v_manager_first_name, v_manager_last_name
    FROM employees
    WHERE employee_id = :OLD.manager_id;

    INSERT INTO archiwum_departamentow (id, nazwa, data_zamkniecia, ostatni_manager)
    VALUES (:OLD.department_id, :OLD.department_name, SYSDATE, v_manager_first_name || ' ' || v_manager_last_name);
END;


-- WYZWALACZE 2
DROP TABLE zlodziej;
-- TABELA POMOCNICZA
CREATE TABLE zlodziej (
    id NUMBER,
    "USER" VARCHAR2(100),
    czas_zmiany TIMESTAMP
);
-- SEKWENCJA DO INDEKSOWANIA
DECLARE
    v_sequence_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_sequence_exists FROM user_sequences WHERE sequence_name = 'ZLODZIEJ_SEQ';
    
    IF v_sequence_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE zlodziej_seq';
    END IF;
END;
-- WYZWALACZ
CREATE OR REPLACE TRIGGER employees_salary_check_trigger
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
    IF :NEW.salary < 2000 OR :NEW.salary > 26000 THEN
        INSERT INTO zlodziej (id, "USER", czas_zmiany)
        VALUES (zlodziej_seq.NEXTVAL, USER, SYSTIMESTAMP);

        RAISE_APPLICATION_ERROR(-20001, 'Wynagrodzenie musi być w zakresie  2000 - 26000');
    END IF;
END;




-- WYZWALACZE 3
-- SEKWENCJA
CREATE SEQUENCE employees_seq
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE;
-- WYZWALACZ
CREATE OR REPLACE TRIGGER employees_auto_increment_trigger
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF :NEW.employee_id IS NULL THEN
        SELECT employees_seq.NEXTVAL INTO :NEW.employee_id FROM DUAL;
    END IF;
END;


-- WYZWALACZE 4
CREATE OR REPLACE TRIGGER job_grades_restrict_trigger
BEFORE INSERT OR UPDATE OR DELETE ON JOB_GRADES
BEGIN
    RAISE_APPLICATION_ERROR(-20001, 'Operacje INSERT, UPDATE i DELETE na tabeli JOB_GRADES są zabronione.');
END;


-- WYZWALACZE 5
CREATE OR REPLACE TRIGGER jobs_restrict_salaries_trigger
BEFORE UPDATE ON jobs
FOR EACH ROW
BEGIN
    IF :NEW.max_salary IS NOT NULL AND :OLD.max_salary IS NOT NULL THEN
        :NEW.max_salary := :OLD.max_salary;
    END IF;

    IF :NEW.min_salary IS NOT NULL AND :OLD.min_salary IS NOT NULL THEN
        :NEW.min_salary := :OLD.min_salary;
    END IF;
END;


-- PACZKI 1
-- DEFINICJA PACZKI
CREATE OR REPLACE PACKAGE MY_PACKAGE AS
    FUNCTION get_job_title(job_id_param IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION calculate_annual_income(employee_id_param IN NUMBER) RETURN NUMBER;
    FUNCTION get_area_code(phone_number_param IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION capitalize_first_last(str IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION pesel_to_birthdate(pesel_param IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION get_employee_department_count(country_name_param IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE job_grades_restrict;
    SEQUENCE jobs_restrict_salaries_seq START WITH 1 INCREMENT BY 1;
    PROCEDURE reset_jobs_sequence;
    PROCEDURE archiwum_departamentow_trigger;
    SEQUENCE zlodziej_seq START WITH 1 INCREMENT BY 1;
    PROCEDURE employees_salary_check_trigger;
    SEQUENCE employees_seq START WITH 1 INCREMENT BY 1;
    PROCEDURE employees_auto_increment_trigger;
    PROCEDURE job_grades_restrict_trigger;
    TRIGGER jobs_restrict_salaries_trigger
        BEFORE UPDATE ON jobs
        FOR EACH ROW;
END MY_PACKAGE;

-- UZUPEŁNIENIE ZAWARTOŚCI PACZKI
CREATE OR REPLACE PACKAGE BODY MY_PACKAGE AS
    FUNCTION get_job_title(job_id_param IN VARCHAR2) RETURN VARCHAR2 IS
        v_job_title jobs.job_title%TYPE;
    BEGIN
        SELECT job_title INTO v_job_title FROM jobs WHERE job_id = job_id_param;
        RETURN v_job_title;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Praca o podanym ID nie istnieje');
    END get_job_title;
    
    FUNCTION calculate_annual_income(employee_id_param IN NUMBER) RETURN NUMBER IS
        v_salary NUMBER;
        v_commission_pct NUMBER;
        v_annual_income NUMBER;
    BEGIN
        SELECT salary, commission_pct INTO v_salary, v_commission_pct
        FROM employees WHERE employee_id = employee_id_param;

        v_annual_income := v_salary * 12;

        IF v_commission_pct IS NOT NULL THEN
            v_annual_income := v_annual_income + (v_salary * v_commission_pct);
        END IF;

        RETURN v_annual_income;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Pracownik o podanym ID nie istnieje');
    END calculate_annual_income;
    
    FUNCTION get_area_code(phone_number_param IN VARCHAR2) RETURN VARCHAR2 IS
        v_area_code VARCHAR2(10);
    BEGIN
        SELECT REGEXP_SUBSTR(phone_number_param, '^\+?\d{1,4}') INTO v_area_code FROM dual;
        RETURN v_area_code;
    END get_area_code;
    
    FUNCTION capitalize_first_last(str IN VARCHAR2) RETURN VARCHAR2 IS
        v_result VARCHAR2(4000);
    BEGIN
        IF str IS NULL THEN
            RETURN NULL;
        END IF;
      
        v_result := LOWER(str);

        IF LENGTH(v_result) >= 2 THEN
            v_result := INITCAP(SUBSTR(v_result, 1, 1)) || SUBSTR(v_result, 2, LENGTH(v_result) - 2) || INITCAP(SUBSTR(v_result, -1));
        ELSE
            v_result := INITCAP(v_result);
        END IF;

        RETURN v_result;
    END capitalize_first_last;
    
    FUNCTION pesel_to_birthdate(pesel_param IN VARCHAR2) RETURN VARCHAR2 IS
        v_birthdate VARCHAR2(11);
        v_year NUMBER;
        v_month NUMBER;
        v_day NUMBER;
    BEGIN
        IF LENGTH(pesel_param) <> 11 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Nieprawidłowa długość numeru PESEL');
        END IF;

        v_year := TO_NUMBER(SUBSTR(pesel_param, 1, 2));
        v_month := TO_NUMBER(SUBSTR(pesel_param, 3, 2));
        v_day := TO_NUMBER(SUBSTR(pesel_param, 5, 2));

        IF v_month < 20 THEN
            v_year := v_year + 1900;
        ELSE
            v_year := v_year + 2000;
        END IF;
      
        v_birthdate := TRIM(TO_CHAR(v_year, '0000')) || '-' || TRIM(TO_CHAR(v_month, '00')) || '-' || TRIM(TO_CHAR(v_day, '00'));
        RETURN v_birthdate;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Błąd: ' || SQLERRM);
    END pesel_to_birthdate;
    
    FUNCTION get_employee_department_count(country_name_param IN VARCHAR2) RETURN VARCHAR2 IS
        v_employee_count NUMBER;
        v_department_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_department_count
        FROM countries c
        JOIN locations l ON c.country_id = l.country_id
        JOIN departments d ON d.location_id = l.location_id 
        WHERE UPPER(country_name) = UPPER(country_name_param);

        IF v_department_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Kraj nie istnieje w bazie danych');
        END IF;

        SELECT COUNT(*) INTO v_employee_count
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN locations l ON d.location_id = l.location_id
        JOIN countries c ON l.country_id = c.country_id
        WHERE UPPER(c.country_name) = UPPER(country_name_param);

        RETURN 'Liczba pracowników: ' || TO_CHAR(v_employee_count) || ', Liczba departamentów: ' || TO_CHAR(v_department_count);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Brak danych');
    END get_employee_department_count;
    
    PROCEDURE job_grades_restrict AS
    BEGIN
        RAISE_APPLICATION_ERROR(-20001, 'Operacje INSERT, UPDATE i DELETE na tabeli JOB_GRADES są zabronione.');
    END job_grades_restrict;
    
    TRIGGER jobs_restrict_salaries_trigger
        BEFORE UPDATE ON jobs
        FOR EACH ROW
    BEGIN
        IF :NEW.max_salary IS NOT NULL AND :OLD.max_salary IS NOT NULL THEN
            :NEW.max_salary := :OLD.max_salary;
        END IF;

        IF :NEW.min_salary IS NOT NULL AND :OLD.min_salary IS NOT NULL THEN
            :NEW.min_salary := :OLD.min_salary;
        END IF;
    END jobs_restrict_salaries_trigger;
    
    SEQUENCE jobs_restrict_salaries_seq;
    
    PROCEDURE reset_jobs_sequence AS
    BEGIN
        SELECT jobs_restrict_salaries_seq.NEXTVAL INTO NULL FROM DUAL;
    END reset_jobs_sequence;
    
    PROCEDURE archiwum_departamentow_trigger AS
        v_manager_first_name employees.first_name%TYPE;
        v_manager_last_name employees.last_name%TYPE;
    BEGIN
        SELECT first_name, last_name
        INTO v_manager_first_name, v_manager_last_name
        FROM employees
        WHERE employee_id = :OLD.manager_id;

        INSERT INTO archiwum_departamentow (id, nazwa, data_zamkniecia, ostatni_manager)
        VALUES (:OLD.department_id, :OLD.department_name, SYSDATE, v_manager_first_name || ' ' || v_manager_last_name);
    END archiwum_departamentow_trigger;
    
    SEQUENCE zlodziej_seq;
    
    PROCEDURE employees_salary_check_trigger AS
    BEGIN
        IF :NEW.salary < 2000 OR :NEW.salary > 26000 THEN
            INSERT INTO zlodziej (id, "USER", czas_zmiany)
            VALUES (zlodziej_seq.NEXTVAL, USER, SYSTIMESTAMP);

            RAISE_APPLICATION_ERROR(-20001, 'Wynagrodzenie musi być w zakresie 2000 - 26000');
        END IF;
    END employees_salary_check_trigger;
    
    SEQUENCE employees_seq;
    
    PROCEDURE employees_auto_increment_trigger AS
    BEGIN
        IF :NEW.employee_id IS NULL THEN
            SELECT employees_seq.NEXTVAL INTO :NEW.employee_id FROM DUAL;
        END IF;
    END employees_auto_increment_trigger;
    
    PROCEDURE job_grades_restrict_trigger AS
    BEGIN
        RAISE_APPLICATION_ERROR(-20001, 'Operacje INSERT, UPDATE i DELETE na tabeli JOB_GRADES są zabronione.');
    END job_grades_restrict_trigger;
    
    TRIGGER jobs_restrict_salaries_trigger
        BEFORE UPDATE ON jobs
        FOR EACH ROW
    BEGIN
        IF :NEW.max_salary IS NOT NULL AND :OLD.max_salary IS NOT NULL THEN
            :NEW.max_salary := :OLD.max_salary;
        END IF;

        IF :NEW.min_salary IS NOT NULL AND :OLD.min_salary IS NOT NULL THEN
            :NEW.min_salary := :OLD.min_salary;
        END IF;
    END jobs_restrict_salaries_trigger;
END MY_PACKAGE;


-- PACZKI 2
-- DEKLARACJA PACZKI
CREATE OR REPLACE PACKAGE RegionsPackage AS
    FUNCTION getAllRegions RETURN SYS_REFCURSOR;
    FUNCTION getRegionById(region_id_param IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION getRegionsByName(region_name_param IN VARCHAR2) RETURN SYS_REFCURSOR;
    PROCEDURE addRegion(region_id_param IN NUMBER, region_name_param IN VARCHAR2);
    PROCEDURE updateRegionName(region_id_param IN NUMBER, new_region_name_param IN VARCHAR2);
    PROCEDURE deleteRegion(region_id_param IN NUMBER);
END RegionsPackage;
-- UUZPEŁNIENIE FUNKCJI
CREATE OR REPLACE PACKAGE BODY RegionsPackage AS
    FUNCTION getAllRegions RETURN SYS_REFCURSOR IS
        result_cursor SYS_REFCURSOR;
    BEGIN
        OPEN result_cursor FOR
        SELECT * FROM regions;

        RETURN result_cursor;
    END getAllRegions;

    FUNCTION getRegionById(region_id_param IN NUMBER) RETURN SYS_REFCURSOR IS
        result_cursor SYS_REFCURSOR;
    BEGIN
        OPEN result_cursor FOR
        SELECT * FROM regions WHERE region_id = region_id_param;

        RETURN result_cursor;
    END getRegionById;

    FUNCTION getRegionsByName(region_name_param IN VARCHAR2) RETURN SYS_REFCURSOR IS
        result_cursor SYS_REFCURSOR;
    BEGIN
        OPEN result_cursor FOR
        SELECT * FROM regions WHERE UPPER(region_name) = UPPER(region_name_param);

        RETURN result_cursor;
    END getRegionsByName;

    PROCEDURE addRegion(region_id_param IN NUMBER, region_name_param IN VARCHAR2) IS
    BEGIN
        INSERT INTO regions (region_id, region_name) VALUES (region_id_param, region_name_param);
        COMMIT;
    END addRegion;

    PROCEDURE updateRegionName(region_id_param IN NUMBER, new_region_name_param IN VARCHAR2) IS
    BEGIN
        UPDATE regions SET region_name = new_region_name_param WHERE region_id = region_id_param;
        COMMIT;
    END updateRegionName;

    PROCEDURE deleteRegion(region_id_param IN NUMBER) IS
    BEGIN
        DELETE FROM regions WHERE region_id = region_id_param;
        COMMIT;
    END deleteRegion;
END RegionsPackage;