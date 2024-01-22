-- zadanie 1
CREATE OR REPLACE FUNCTION obfuscated_function(identifier IN VARCHAR2)
    RETURN VARCHAR2
IS
    v_result jobs.job_title%TYPE;
BEGIN
    SELECT job_title
    INTO v_result
    FROM jobs
    WHERE job_id = identifier;

    RETURN v_result;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Błąd: Nie znaleziono pasującej pozycji');
END;

DECLARE
    v_output VARCHAR2(100);
BEGIN
    v_output := obfuscated_function('IT_PROG');
    DBMS_OUTPUT.PUT_LINE('Rezultat: ' || v_output);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
END;

-- zadanie 2

CREATE OR REPLACE FUNCTION calculate_annual_earnings(employee_id_param IN NUMBER)
    RETURN NUMBER
IS
    v_salary employees.salary%TYPE;
    v_commission_pct employees.commission_pct%TYPE;
    v_annual_earnings NUMBER;
BEGIN
    -- Pobieramy wynagrodzenie i premię pracownika na podstawie ID
    SELECT salary, commission_pct
    INTO v_salary, v_commission_pct
    FROM employees
    WHERE employee_id = employee_id_param;

    -- Obliczamy roczne zarobki (wynagrodzenie 12-miesięczne plus premia)
    v_annual_earnings := v_salary * 12 + (v_salary * v_commission_pct);

    RETURN v_annual_earnings;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Błąd: Pracownik o podanym ID nie istnieje');
END;


-- zadanie 3
CREATE OR REPLACE FUNCTION extract_area_code(phone_number IN VARCHAR2)
    RETURN VARCHAR2
IS
    v_area_code VARCHAR2(10);
BEGIN
    -- Sprawdzamy, czy numer telefonu ma odpowiednią długość i format
    IF LENGTH(phone_number) >= 9 AND REGEXP_LIKE(phone_number, '^\+\d{1,4}-\d{2,8}$') THEN
        -- Wyodrębniamy numer kierunkowy z numeru telefonu
        v_area_code := SUBSTR(phone_number, 2, INSTR(phone_number, '-') - 2);
        RETURN v_area_code;
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Błąd: Nieprawidłowy format numeru telefonu');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Błąd: Nie udało się wyodrębnić numeru kierunkowego');
END;
/

-- zadanie 4
CREATE OR REPLACE FUNCTION format_name_case(input_string IN VARCHAR2)
    RETURN VARCHAR2
IS
    v_result VARCHAR2(255);
BEGIN
    -- Sprawdzamy, czy podany ciąg znaków jest niepusty
    IF input_string IS NOT NULL THEN
        -- Konwertujemy wszystkie litery na małe
        v_result := LOWER(input_string);

        -- Zmieniamy pierwszą i ostatnią literę na wielkie
        v_result := INITCAP(v_result);

        RETURN v_result;
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Błąd: Podany ciąg znaków jest pusty');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Błąd: Nie udało się przekształcić ciągu znaków');
END;

-- zadanie 5
CREATE OR REPLACE FUNCTION pesel_to_birthdate(pesel IN VARCHAR2)
    RETURN VARCHAR2
IS
    v_year VARCHAR2(4);
    v_month VARCHAR2(2);
    v_day VARCHAR2(2);
    v_birthdate VARCHAR2(10);
BEGIN
    -- Sprawdzamy, czy PESEL ma poprawną długość
    IF LENGTH(pesel) = 11 THEN
        -- Wyodrębniamy rok, miesiąc i dzień z PESEL
        v_year := SUBSTR(pesel, 1, 2);
        v_month := SUBSTR(pesel, 3, 2);
        v_day := SUBSTR(pesel, 5, 2);

        -- Dodajemy "19" lub "20" na początku roku w zależności od cyfry miesiąca
        IF TO_NUMBER(v_month) <= 12 THEN
            v_year := '19' || v_year;
        ELSE
            v_year := '20' || v_year;
        END IF;

        -- Tworzymy datę urodzenia w formacie 'yyyy-mm-dd'
        v_birthdate := v_year || '-' || v_month || '-' || v_day;

        RETURN v_birthdate;
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Błąd: Nieprawidłowa długość numeru PESEL');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Błąd: Nie udało się przekształcić numeru PESEL na datę urodzenia');
END;
/

-- zadanie 6
CREATE OR REPLACE FUNCTION count_employees_and_departments_in_country(country_name IN VARCHAR2)
    RETURN VARCHAR2
IS
    v_employee_count NUMBER;
    v_department_count NUMBER;
BEGIN
    -- Liczymy liczbę pracowników w danym kraju
    SELECT COUNT(*) INTO v_employee_count
    FROM employees e
    WHERE e.department_id IN (SELECT d.department_id FROM departments d WHERE d.location_id IN (SELECT l.location_id FROM locations l WHERE l.country_name = country_name));

    -- Liczymy liczbę departamentów w danym kraju
    SELECT COUNT(*) INTO v_department_count
    FROM departments d
    WHERE d.location_id IN (SELECT l.location_id FROM locations l WHERE l.country_name = country_name);

    IF v_employee_count = 0 AND v_department_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Błąd: Brak pracowników i departamentów w podanym kraju');
    ELSE
        RETURN 'Liczba pracowników: ' || v_employee_count || ', Liczba departamentów: ' || v_department_count;
    END IF;
END;
/


-- Wyzwalacze
-- zadanie 1

CREATE TABLE archiwum_departamentow (
    id NUMBER,
    nazwa VARCHAR2(255),
    data_zamkniecia DATE,
    ostatni_manager VARCHAR2(255)
);

CREATE OR REPLACE TRIGGER archiwizacja_departamentow
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
    INSERT INTO archiwum_departamentow (id, nazwa, data_zamknięcia, ostatni_manager)
    VALUES (:OLD.department_id, :OLD.department_name, SYSDATE, v_manager_first_name || ' ' || v_manager_last_name);
END;

-- zadanie 2
CREATE TABLE zlodziej (
    id NUMBER,
    username VARCHAR2(255),
    czas_zmiany TIMESTAMP
);

CREATE OR REPLACE PROCEDURE log_zdarzenie(p_user VARCHAR2, p_time TIMESTAMP)
AS
BEGIN
    INSERT INTO zlodziej (id, username, czas_zmiany)
    VALUES (seq_zlodziej.nextval, p_user, p_time);
END;

CREATE OR REPLACE TRIGGER ograniczenie_zarobkow
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
DECLARE
    v_user VARCHAR2(255);
BEGIN
    IF :NEW.salary < 2000 OR :NEW.salary > 26000 THEN
        -- Logowanie próby zmiany wynagrodzenia poza widełkami
        v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');
        log_zdarzenie(v_user, SYSTIMESTAMP);
        -- Rzucenie błędu, aby przerwać operację
        RAISE_APPLICATION_ERROR(-20001, 'Wynagrodzenie poza dozwolonymi widełkami (2000 - 26000).');
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