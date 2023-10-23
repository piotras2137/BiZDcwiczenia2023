CREATE TABLE Regions (
    Region_ID int NOT NULL,
    Region_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (Region_id)
);

CREATE TABLE Countries (
    Country_ID int NOT NULL,
    Country_name VARCHAR(100),
    Region_ID int,
    PRIMARY KEY (Country_ID),
    FOREIGN KEY (Region_ID) REFERENCES Regions(Region_ID)
);

CREATE TABLE Locations (
    Location_ID int NOT NULL,
    Street_address VARCHAR(255),
    Postal_code VARCHAR(20),
    City VARCHAR(100),
    State_province VARCHAR(100),
    Country_ID int,
    PRIMARY KEY (Location_ID),
    FOREIGN KEY (Country_ID) REFERENCES Countries(Country_ID)
);

CREATE TABLE Jobs (
    Job_ID int NOT NULL,
    Job_title VARCHAR(50),
    Min_salary DECIMAL(10,2),
    Max_salary DECIMAL(10,2),
    CHECK(Max_salary - Min_salary >= 2000),
    PRIMARY KEY (Job_ID)
);

CREATE TABLE Departaments (
    Department_ID int NOT NULL,
    Department_name VARCHAR(255),
    Manager_ID int,
    Location_ID int,
    PRIMARY KEY (Department_ID),
    FOREIGN KEY (Location_ID) REFERENCES Locations(Location_ID)
);

CREATE TABLE Employees(
    Employee_ID int NOT NULL,
    First_name VARCHAR(50),
    Last_name VARCHAR(50),
    Email VARCHAR(100),
    Phone_number VARCHAR(20),
    Hire_date DATE,
    Job_id int,
    Salary DECIMAL(10,2),
    Commission_pct VARCHAR(255),
    Manager_ID int,
    Department_ID int,
    PRIMARY KEY (Employee_ID),
    FOREIGN KEY (Job_ID) REFERENCES Jobs(Job_ID)
);

CREATE TABLE Job_history (
    Employee_ID int NOT NULL,
    Start_date DATE NOT NULL,
    End_date DATE,
    Job_ID int,
    Department_ID int,
    FOREIGN KEY (Department_ID) REFERENCES Departaments(Department_ID),
    FOREIGN KEY (Employee_ID) REFERENCES Employees(Employee_ID),
    FOREIGN KEY (Job_ID) REFERENCES Jobs(Job_ID),
    CONSTRAINT PK_job_history PRIMARY KEY (Employee_ID,Start_date)
);

ALTER TABLE Departaments ADD FOREIGN KEY (Manager_ID) REFERENCES Employees(Employee_ID);
ALTER TABLE Employees ADD FOREIGN KEY (Manager_ID) REFERENCES Employees(Employee_ID);
ALTER TABLE Employees ADD FOREIGN KEY (Department_ID) REFERENCES Departaments(Department_ID);
