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