--Zad 9
--a
CREATE OR REPLACE PROCEDURE DodajJob(
  p_Job_id Jobs.Job_id%TYPE,
  p_Job_title Jobs.Job_title%TYPE
)
AS
BEGIN
  INSERT INTO Jobs (Job_id, Job_title)
  VALUES (p_Job_id, p_Job_title);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Blad podczas dodawania wiersza do tabeli Jobs: ' || SQLERRM);
END DodajJob;


CALL DodajJob('T_TST', 'TESTER');
CALL DodajJob('IT_PROG', 'Programmer');
--b
SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE EdytujTytulJob(
    p_JOB_id JOBS.job_id%TYPE,
    p_JOB_title JOBS.job_title%TYPE
)
AS
    no_jobs_updated EXCEPTION;
    PRAGMA EXCEPTION_INIT(no_jobs_updated, -20000);
BEGIN
    UPDATE JOBS SET job_title = p_JOB_title WHERE job_id = p_job_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE no_jobs_updated;
    END IF;
    COMMIT;
EXCEPTION
    WHEN no_jobs_updated THEN
        DBMS_OUTPUT.PUT_LINE('Brak zaktualizowanych wierszy w tabeli Jobs.');
END EdytujTytulJob;
/
CALL edytujtytuljob('IT_PROG','Programista');
CALL edytujtytuljob('N_NIEMO', 'Nie ma');
--c
SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE UsunJob(
    p_job_id JOBS.job_id%TYPE
)
AS
    no_jobs_deleted EXCEPTION;
    PRAGMA EXCEPTION_INIT(no_jobs_deleted, -20001);
BEGIN
    DELETE FROM Jobs WHERE job_id = p_job_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE no_jobs_deleted;
    END IF;
    COMMIT;
EXCEPTION
    WHEN no_jobs_deleted THEN
        DBMS_OUTPUT.PUT_LINE('Brak usunietych wierszy w tabeli Jobs.');
END UsunJob;
/
CALL usunjob('T_TST');
CALL usunjob('T_TST');
--d
SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE ZarobkiPracownika(
    p_employee_id Employees.employee_id%TYPE,
    o_Zarobki OUT employees.salary%TYPE,
    o_Nazwisko OUT employees.last_name%TYPE
)
AS
BEGIN
    SELECT salary, last_name INTO o_zarobki, o_nazwisko FROM employees
    WHERE employees.employee_id = p_employee_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Brak pracownika o podanym ID.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Blad podczas pobierania danych pracownika: ' || SQLERRM);
END ZarobkiPracownika;
/
SET SERVEROUTPUT ON;
DECLARE
  v_Zarobki NUMBER;
  v_Nazwisko VARCHAR2(50);
BEGIN
    ZarobkiPracownika(101, v_Zarobki, v_Nazwisko);
    IF v_Zarobki IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Zarobki pracownika: ' || v_Zarobki);
        DBMS_OUTPUT.PUT_LINE('Nazwisko pracownika: ' || v_Nazwisko);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Brak pracownika o podanym ID lub wystapil blad: ' || v_Nazwisko);
    END IF;
END;
/
DECLARE
  v_Zarobki NUMBER;
  v_Nazwisko VARCHAR2(50);
BEGIN
    ZarobkiPracownika(1010, v_Zarobki, v_Nazwisko);
    IF v_Zarobki IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Zarobki pracownika: ' || v_Zarobki);
        DBMS_OUTPUT.PUT_LINE('Nazwisko pracownika: ' || v_Nazwisko);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Brak pracownika o podanym ID lub wystapil blad: ' || v_Nazwisko);
    END IF;
END;
/
--e
CREATE OR REPLACE PROCEDURE DodajEmployee(
    p_First_name employees.first_name%TYPE,
    p_Last_name employees.last_name%TYPE,
    p_Salary employees.salary%TYPE DEFAULT 1000,
    p_email employees.email%TYPE DEFAULT 'example@mail.com',
    p_phone_number employees.phone_number%TYPE DEFAULT NULL,
    p_hire_date employees.hire_date%TYPE DEFAULT SYSDATE,
    p_job_id employees.job_id%TYPE DEFAULT 'IT_PROG',
    p_commission_pct employees.commission_pct%TYPE DEFAULT NULL,
    p_manager_id employees.manager_id%TYPE DEFAULT NULL,
    p_department_id employees.department_id%TYPE DEFAULT 60
)
AS
    salary_too_high EXCEPTION;
    PRAGMA EXCEPTION_INIT(salary_too_high, -20002);
    v_Employee_id NUMBER;
BEGIN
    SELECT (MAX(employee_id)+1) INTO v_Employee_id FROM employees;
    IF p_Salary > 20000 THEN
        RAISE salary_too_high;
    ELSE
        INSERT INTO employees
        VALUES (v_Employee_id, p_First_name, p_Last_name, p_email, p_phone_number,
        p_hire_date, p_job_id, p_salary, p_commission_pct, p_manager_id, p_department_id);
        COMMIT;
    END IF;
EXCEPTION
    WHEN salary_too_high THEN
        DBMS_OUTPUT.PUT_LINE('Wynagrodzenie przekracza 20000, nie mozna dodac pracownika.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('B³¹d podczas dodawania pracownika: ' || SQLERRM);
END DodajEmployee;
/
CALL dodajemployee('Zbyszek', 'Kieliszek', 3000);
CALL dodajemployee('Marek', 'Towarek', 30000);
CALL dodajemployee('Romek', 'Cyganowicz', 5000, 'rrrroman@gmail.com')