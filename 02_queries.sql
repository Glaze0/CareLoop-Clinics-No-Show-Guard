# Creating the Database 
create database noshowguard;
Use noshowguard;

# Creating clinics Table
CREATE TABLE clinics (
  clinic_id VARCHAR(5) PRIMARY KEY, clinic_name VARCHAR(40) NOT NULL, city VARCHAR(20) NOT NULL,
  tier VARCHAR(10), latitude DECIMAL(8,4), longitude DECIMAL(8,4), temp_c DECIMAL(5,1));

# Creating appointments Table
CREATE TABLE appointments (
  appointment_id VARCHAR(8) PRIMARY KEY, patient_id VARCHAR(8) NOT NULL, clinic_id VARCHAR(5) NOT NULL,
  booked_on DATE, appt_date DATE, age INT, gender VARCHAR(1), distance_km DECIMAL(5,1), fee_inr INT,
  booking_channel VARCHAR(10), visit_type VARCHAR(12), reminder_sent VARCHAR(3), prior_no_shows INT,
  status VARCHAR(10), lead_days INT, no_show INT,
  FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id));

# Testing if the clinics table is inserted properly
select *
from clinics;

#Testing if appointments table is inserted properly
select sum(no_show)
from appointments;

# Trying to insert a duplicate row to test
INSERT INTO appointments VALUES ('A0001','P509','C05','2025-01-24','2025-01-25',60,'F',18.0,850,'Phone','Consultation','Yes',1,'No-Show',1,1);
#After Running this command we get an Error with Error Code:1062, Dupliacte entry 'A0001' for key 'appointments.PRIMARY'


# No-show rate by clinic with appointments greater than 95
SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c
    ON a.clinic_id = c.clinic_id
GROUP BY
    c.clinic_id,
    c.clinic_name,
    c.city
HAVING COUNT(*) >= 95
ORDER BY no_show_pct DESC;


# No-show rate by clinic 
SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments a
JOIN clinics c
    ON a.clinic_id = c.clinic_id
GROUP BY
    c.clinic_id,
    c.clinic_name,
    c.city
ORDER BY no_show_pct DESC;


#Does booking far ahead matter? 
SELECT
    CASE
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
        ELSE '31+'
    END AS lead_band,
    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
FROM appointments
GROUP BY
    CASE
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
        ELSE '31+'
    END
ORDER BY MIN(lead_days);


# Month-by-month trend
WITH monthly AS (
    SELECT
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT
    month,
    appointments,
    no_show_pct,
    ROUND(
        no_show_pct - LAG(no_show_pct) OVER (ORDER BY month),
        1
    ) AS pct_point_change
FROM monthly
ORDER BY month;


# Rank clinics inside each city
WITH clinic_rates AS (
    SELECT
        c.clinic_name,
        c.city,
        ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct
    FROM clinics c
    JOIN appointments a
        ON c.clinic_id = a.clinic_id
    GROUP BY
        c.clinic_name,
        c.city
)
SELECT
    clinic_name,
    city,
    no_show_pct,
    RANK() OVER (
        PARTITION BY city
        ORDER BY no_show_pct DESC
    ) AS rank_in_city,
    CASE
        WHEN no_show_pct >
             (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1)
              FROM appointments)
        THEN 'above'
        WHEN no_show_pct <
             (SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 1)
              FROM appointments)
        THEN 'below'
        ELSE 'equal'
    END AS vs_overall
FROM clinic_rates
ORDER BY
    city,
    rank_in_city;