-- 1. Create Database
CREATE DATABASE IF NOT EXISTS HealthcareDB;

-- 2.Activate database
USE HealthcareDB;
CREATE TABLE IF NOT EXISTS Healthcare_Data (
    Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(20),
    Blood_Type VARCHAR(10),
    Medical_Condition VARCHAR(100),
    Date_of_Admission DATE,
    Doctor VARCHAR(100),
    Hospital VARCHAR(150),
    Insurance_Provider VARCHAR(100),
    Billing_Amount DECIMAL(12, 2),
    Room_Number INT,
    Admission_Type VARCHAR(50),
    Discharge_Date DATE,
    Medication VARCHAR(100),
    Test_Results VARCHAR(50)
);

USE HealthcareDB;

TRUNCATE TABLE Healthcare_Data;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'D:/Desktop/healthcare_dataset.csv'
INTO TABLE Healthcare_Data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Name, Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission, Doctor, Hospital, Insurance_Provider, Billing_Amount, Room_Number, Admission_Type, Discharge_Date, Medication, Test_Results);

SELECT COUNT(*) FROM Healthcare_Data;

USE HealthcareDB;

-- View 1: Length of Stay (LOS) & Patient Level Metrics
CREATE OR REPLACE VIEW View_PatientAdmissionAnalytics AS
WITH PatientCalculations AS (
    SELECT 
        Name,
        Age,
        Gender,
        Medical_Condition,
        Date_of_Admission,
        Discharge_Date,
        DATEDIFF(Discharge_Date, Date_of_Admission) AS LengthOfStayDays,
        Billing_Amount,
        Doctor,
        Hospital,
        Admission_Type,
        Test_Results,
        Medication,
        Insurance_Provider,
        
        -- Window Function 1: Avg LOS per Medical Condition
        AVG(DATEDIFF(Discharge_Date, Date_of_Admission)) OVER(PARTITION BY Medical_Condition) AS AvgLOS_By_Condition,
        
        -- Window Function 2: Avg Billing Amount per Medical Condition
        AVG(Billing_Amount) OVER(PARTITION BY Medical_Condition) AS AvgBilling_By_Condition
    FROM Healthcare_Data
)
SELECT *,
    CASE 
        WHEN LengthOfStayDays > AvgLOS_By_Condition THEN 'Above Avg Stay'
        ELSE 'Normal Stay'
    END AS StayDurationCategory
FROM PatientCalculations;


-- View 2: Medical Condition Summary Aggregations
CREATE OR REPLACE VIEW View_Condition_Summary AS
SELECT 
    Medical_Condition,
    COUNT(*) AS TotalPatients,
    ROUND(AVG(DATEDIFF(Discharge_Date, Date_of_Admission)), 2) AS AvgLengthOfStay,
    ROUND(AVG(Billing_Amount), 2) AS AvgBillingAmount,
    SUM(CASE WHEN Test_Results = 'Abnormal' THEN 1 ELSE 0 END) AS AbnormalTestCount,
    ROUND((SUM(CASE WHEN Test_Results = 'Abnormal' THEN 1.0 ELSE 0 END) / COUNT(*)) * 100, 2) AS AbnormalRatePercent
FROM Healthcare_Data
GROUP BY Medical_Condition;