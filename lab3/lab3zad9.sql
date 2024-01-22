CREATE OR REPLACE PROCEDURE AddJob(
p_job_id IN Jobs.Job_id%TYPE,
p_job_title IN Jobs.Job_title%TYPE) AS
BEGIN
    INSERT INTO Jobs (Job_id, Job_title)
    VALUES (p_job_id, p_job_title);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd podczas dodawania wiersza do tabeli Jobs.');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END AddJob;

BEGIN
    AddJob('IT_PROG_JU', 'Programmer Junior');
    commit;
end;

CREATE OR REPLACE PROCEDURE ModifyJobTitle(
p_job_id IN Jobs.Job_id%TYPE,
p_new_job_title IN Jobs.Job_title%TYPE) AS
BEGIN
	UPDATE Jobs
	SET Job_title = p_new_job_title WHERE Job_id = p_job_id;
	IF SQL%ROWCOUNT = 0 
	THEN RAISE_APPLICATION_ERROR(-20001, 'No Jobs updated');
	END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd podczas modyfikacji tytułu pracy.');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END ModifyJobTitle;

BEGIN
	MODIFYJOBTITLE('IT_PROG_', 'Junior programmer');
	commit;
end;

CREATE OR REPLACE PROCEDURE DeleteJob(p_job_id IN Jobs.Job%TYPE) AS
BEGIN
	DELETE FROM Jobs
	WHERE Job_id = p_job_id;

	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20002, 'No Jobs deleted');
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Wystąpił błąd podczas usuwania wiersza z tabeli Jobs.');
		DBMS_OUTPUT.PUT_LINE(SQLERRM);
END DeleteJob;

BEGIN
    DeleteJob('IT_PROG_JU');
    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetSalaryAndName(p_employee_id IN Employees.Employee_id%TYPE,p_salary OUT Employees.Salary%TYPE,p_last_name OUT Employees.Last_name%TYPE) AS
BEGIN
    SELECT Salary, Last_name
    INTO p_salary, p_last_name
    FROM Employees
    WHERE Employee_id = p_employee_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Pracownik o podanym ID nie istnieje.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd podczas pobierania danych pracownika.');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END  GetSalaryAndName;

DECLARE
    v_salary Employees.Salary%TYPE;
    v_last_name Employees.Last_name%TYPE;
BEGIN
    GetSalaryAndName(101, v_salary, v_last_name);
    DBMS_OUTPUT.PUT_LINE('Zarobki pracownika: ' || v_salary);
    DBMS_OUTPUT.PUT_LINE('Nazwisko pracownika: ' || v_last_name);
END;

CREATE OR REPLACE PROCEDURE AddEmployee(p_first_name IN Employees.First_name%TYPE,p_salary IN NUMBER) AS v_next_id NUMBER;
BEGIN
    IF p_salary > 20000 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Wynagrodzenie nie może być wyższe niż 20000.');
    ELSE
        SELECT MAX(Employee_id) + 1 INTO v_next_id
        FROM Employees;
        DBMS_OUTPUT.PUT_LINE(v_next_id);

        INSERT INTO Employees (Employee_id, First_name, Salary, HIRE_DATE, EMAIL, JOB_ID, LAST_NAME)
        VALUES (v_next_id, p_first_name, p_salary, sysdate, 'M'||p_first_name, 'IT_PROG', 'Nowak');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wystąpił błąd podczas dodawania pracownika.');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END AddEmployee;

BEGIN
    AddEmployee('Adam', 1000);
    commit;
end;