--- zad 1 

DECLARE
    numer_max departments.department_id%TYPE;
    new_departament_number departments.department_id%TYPE;
    new_departament_name departments.department_name%TYPE := 'EDUCATION';
BEGIN
    SELECT MAX(department_id) INTO numer_max FROM departments;
    new_departament_number := numer_max + 10;
    INSERT INTO departments (department_id, department_name)
    VALUES (new_departament_number, new_departament_name);
END;

--- zad 2 

DECLARE
    numer_max NUMBER(5);
BEGIN
   SELECT max(department_id) INTO numer_max FROM DEPARTMENTS;
   DBMS_OUTPUT.PUT_LINE('Wartosc zmiennej: ' || numer_max);
   INSERT INTO departments(department_id, department_name) VALUES ((numer_max+10), 'EDUCATION');
   UPDATE departments SET location_id = 3000 WHERE department_id = (numer_max+10);
EXCEPTION
   WHEN no_data_found THEN
        numer_max := 0;
END;

--- zad 3


CREATE TABLE NOWA (
    wartosc VARCHAR(60)
);

DECLARE
    i NUMBER := 1;
BEGIN
    WHILE i <= 10 LOOP
        IF i <> 4 AND i <> 6 THEN
            INSERT INTO NOWA(wartosc) VALUES (TO_CHAR(i));
        end if;
        i := i +1;
        end LOOP;
    COMMIT;
end;



--- zad 4

DECLARE
  v_country countries%ROWTYPE;
BEGIN
  SELECT * INTO v_country FROM countries WHERE country_id = 'CA';
  DBMS_OUTPUT.PUT_LINE('Nazwa kraju: ' || v_country.country_name);
  DBMS_OUTPUT.PUT_LINE('ID regionu: ' || v_country.region_id);
END;





--- zad 5

DECLARE
    TYPE DepartmentIndex IS TABLE OF departments.department_name%TYPE INDEX BY BINARY_INTEGER;
    v_departments DepartmentIndex;
BEGIN
    FOR i IN 1..10 LOOP
        v_departments(i * 10) := NULL;
        SELECT department_name INTO v_departments(i * 10)
        FROM departments
        WHERE department_id = i * 10;
    END LOOP;
    FOR i IN 1..10 LOOP
        DBMS_OUTPUT.PUT_LINE('Numer departamentu: ' || i * 10 || ', Nazwa departamentu: ' || v_departments(i * 10));
    END LOOP;
END;


--- zad 6 


DECLARE
  v_department departments%ROWTYPE;
BEGIN
  FOR i IN 1..10 LOOP
    SELECT * INTO v_department
    FROM departments
    WHERE department_id = i * 10;
    DBMS_OUTPUT.PUT_LINE('Informacje o departamencie o ID ' || v_department.department_id);
    DBMS_OUTPUT.PUT_LINE('Nazwa departamentu: ' || v_department.department_name);
    DBMS_OUTPUT.PUT_LINE('ID mened¿era: ' || v_department.manager_id);
    DBMS_OUTPUT.PUT_LINE('ID lokalizacji: ' || v_department.location_id);
    DBMS_OUTPUT.NEW_LINE; -- Nowa linia miêdzy departamentami
  END LOOP;
END;


--- zad 7 


DECLARE
    CURSOR c_employees IS SELECT last_name, salary FROM employees WHERE department_id = 50;
    v_last_name employees.last_name%TYPE;
    v_salary employees.salary%TYPE;
BEGIN
    FOR emp_rec IN c_employees LOOP
        v_last_name := emp_rec.last_name;
        v_salary := emp_rec.salary;
        IF v_salary > 3100 THEN
            DBMS_OUTPUT.PUT_LINE(v_last_name || ' nie dawal podwyzki');
        ELSE
            DBMS_OUTPUT.PUT_LINE(v_last_name || ' dal podwyzke');
        END IF;
    END LOOP;
END;


--- zad 8 

DECLARE
  CURSOR wynagrodzenie_crs (p_min_salary NUMBER, p_max_salary NUMBER, p_first_name_part VARCHAR2) IS
    SELECT salary, first_name, last_name
    FROM employees
    WHERE salary BETWEEN p_min_salary AND p_max_salary
    AND UPPER(first_name) LIKE '%' || UPPER(p_first_name_part) || '%';
  v_SALARY employees.salary%TYPE;
  v_FIRST_NAME employees.first_name%TYPE;
  v_LAST_NAME employees.last_name%TYPE;
BEGIN
  OPEN wynagrodzenie_crs(1000, 5000, 'a');
  DBMS_OUTPUT.PUT_LINE('Pracownicy z widełkami 1000-5000 i częścią imienia "A" lub "a":');
  LOOP
    FETCH wynagrodzenie_crs INTO v_SALARY, v_FIRST_NAME, v_LAST_NAME;
    EXIT WHEN wynagrodzenie_crs%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_FIRST_NAME || ' ' || v_LAST_NAME || ', Zarobki: ' || v_SALARY);
  END LOOP;
  CLOSE wynagrodzenie_crs;
  OPEN wynagrodzenie_crs(5000, 20000, 'u');
  DBMS_OUTPUT.PUT_LINE('Pracownicy z widełkami 5000-20000 i częścią imienia "U" lub "u":');
  LOOP
    FETCH wynagrodzenie_crs INTO v_SALARY, v_FIRST_NAME, v_LAST_NAME;
    EXIT WHEN wynagrodzenie_crs%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_FIRST_NAME || ' ' || v_LAST_NAME || ', Zarobki: ' || v_SALARY);
  END LOOP;
  CLOSE wynagrodzenie_crs;
END;



--- zad 9 