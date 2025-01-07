-- Aim: To explore and assess cases with casualties.
 


-- Looking at Total Cases

SELECT COUNT(*) AS Total_Number_of_Cases_Reported
FROM Table1;


-- Looking at Total Cases With Casualties

SELECT COUNT(*) AS Total_Number_of_Cases_With_Casualties
FROM Table2
WHERE Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL;


-- Looking at Total Casualties

Select SUM(Civilian_Casualties) AS Total_Casualties_Reported
FROM Table2;


-- Percentage of cases with Casualties

SELECT (COUNT(CASE WHEN Civilian_Casualties > 0 THEN 1 END) * 100  / COUNT(*)) AS Percentage_of_Cases_with_Civilian_Casualties
FROM Table2;


-- Total Number of cases reported in different areas/intersection.

SELECT Intersection, 
       COUNT(Intersection) AS TotalCases
FROM Table1
WHERE Intersection IS NOT NULL 
GROUP BY Intersection
ORDER BY TotalCases DESC;


-- Total number of cases with casualties and total casualties recorded in different areas.

SELECT T1.Intersection,
       COUNT(T1.Intersection) AS TotalCases, 
	   SUM(T2.Civilian_Casualties) AS TotalCasualties
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE T2.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY T1.Intersection
ORDER BY TotalCasualties DESC;


-- Total casualties by individual cases recorded in different areas.

SELECT T1.Intersection,
       COUNT(T1.Intersection) OVER (PARTITION BY T1.Intersection) AS Total_Cases_Reported_in_Area, 
	   T1.id AS Case_id,
	   SUM(T2.Civilian_Casualties) OVER (PARTITION BY T1.id) AS Total_Casualties
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE T2.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
ORDER BY T1.Intersection, T1.id, Total_Casualties;



-- Total cases recorded by year.

SELECT YEAR(TFS_Alarm_Time) AS _Year_, 
       COUNT(*) AS Number_of_Cases 
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
GROUP BY YEAR(TFS_Alarm_Time)
ORDER BY YEAR(TFS_Alarm_Time);


-- Total cases with casualties and total casualties recorded by year.

SELECT YEAR(TFS_Alarm_Time) AS _Year_, 
       COUNT(YEAR(TFS_Alarm_Time)) AS Number_of_Cases, 
	   SUM(T2.Civilian_Casualties) AS Total_Casualties
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE T2.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY YEAR(TFS_Alarm_Time)
ORDER BY YEAR(TFS_Alarm_Time);


-- Cases recorded by month through out years.

SELECT FORMAT(TFS_Alarm_Time, 'MM') AS _Month_, 
       COUNT(FORMAT(TFS_Alarm_Time, 'MM')) AS NumberofCases
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE FORMAT(TFS_Alarm_Time, 'MM') IS NOT NULL 
GROUP BY FORMAT(TFS_Alarm_Time, 'MM')
ORDER BY FORMAT(TFS_Alarm_Time, 'MM')


-- Cases with casualties recorded by month through out years and total casualties by year.

SELECT FORMAT(TFS_Alarm_Time, 'MM') AS _Month_, 
       COUNT(FORMAT(TFS_Alarm_Time, 'MM')) AS NumberofCases,
	   SUM(T2.Civilian_Casualties) AS TotalCasualties
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE T2.Civilian_Casualties > 0
GROUP BY FORMAT(TFS_Alarm_Time, 'MM')
ORDER BY FORMAT(TFS_Alarm_Time, 'MM');



-- Cases recorded by days of the week through out years.

SELECT FORMAT(TFS_Alarm_Time, 'dddd') AS _Day_, 
       COUNT(FORMAT(TFS_Alarm_Time, 'dddd')) AS NumberofCases
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
GROUP BY FORMAT(TFS_Alarm_Time, 'dddd')
ORDER BY 
     CASE
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Sunday' THEN 1
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Monday' THEN 2
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Tuesday' THEN 3
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Wednesday' THEN 4
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Thursday' THEN 5
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Friday' THEN 6
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Saturday' THEN 7
     END ASC;


-- Cases with casulaties and total casualties by day of the week through out years.

SELECT FORMAT(TFS_Alarm_Time, 'dddd') AS _Day_, 
       COUNT(FORMAT(TFS_Alarm_Time, 'dddd')) AS NumberofCases,
	   SUM(T2.Civilian_Casualties) AS TotalCasualties
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE T2.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY FORMAT(TFS_Alarm_Time, 'dddd')
ORDER BY 
         CASE
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Sunday' THEN 1
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Monday' THEN 2
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Tuesday' THEN 3
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Wednesday' THEN 4
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Thursday' THEN 5
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Friday' THEN 6
          WHEN FORMAT(TFS_Alarm_Time, 'dddd') = 'Saturday' THEN 7
     END ASC;


-- Total number of cases recorded by hour of the day through out years.

SELECT FORMAT(TFS_Alarm_Time, 'HH') AS _Hour_, 
       COUNT(FORMAT(TFS_Alarm_Time, 'HH')) AS NumberofCases
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE TFS_Alarm_Time IS NOT NULL
GROUP BY FORMAT(TFS_Alarm_Time, 'HH')
ORDER BY FORMAT(TFS_Alarm_Time, 'HH');



-- Total number of cases with casualties and total casualties recorded by hour of the day through out years.

SELECT FORMAT(TFS_Alarm_Time, 'HH') AS _Hour_, 
       COUNT(FORMAT(TFS_Alarm_Time, 'HH')) AS NumberofCases,
       SUM(Civilian_Casualties) AS Total_Casualties
FROM Table1 T1
INNER JOIN Table2 T2  ON T1.id = T2.id
WHERE TFS_Alarm_Time IS NOT NULL AND Civilian_Casualties > 0 
GROUP BY FORMAT(TFS_Alarm_Time, 'HH')
ORDER BY FORMAT(TFS_Alarm_Time, 'HH');



-- Area of origin of fire in cases recorded.

SELECT  Area_of_Origin, 
        COUNT(Area_of_Origin) AS Number_Of_Cases_Reported
FROM Table2
WHERE Area_of_Origin IS NOT NULL
GROUP BY Area_of_Origin
ORDER BY Number_Of_Cases_Reported DESC;

-- Area of origin of fire in cases with casualties recorded and total casualties.

SELECT  Area_of_Origin, 
        COUNT(Area_of_Origin) AS Number_Of_Cases_Reported, 
		SUM(Civilian_Casualties) AS Total_Casualties
FROM Table2
WHERE Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL AND Area_of_Origin IS NOT NULL
GROUP BY Area_of_Origin
ORDER BY Total_Casualties DESC, Number_Of_Cases_Reported DESC;




-- Material that first caught fire in cases recorded.

SELECT  Material_First_Ignited, COUNT(*) AS Total_Cases
FROM Table2
WHERE Material_First_Ignited IS NOT NULL
GROUP BY Material_First_Ignited
ORDER BY Total_Cases DESC;


-- Material that first caught fire in cases with casualties and total casualties.

SELECT  Material_First_Ignited, 
        COUNT(*) AS Total_Cases, 
		SUM(Civilian_Casualties) AS Total_Casualties
FROM Table2
WHERE Material_First_Ignited IS NOT NULL AND Civilian_Casualties > 0 
GROUP BY Material_First_Ignited
ORDER BY Total_Casualties DESC;


--Property use in the cases recorded.

SELECT Property_Use, 
       COUNT(Property_Use) AS Total_Cases
FROM Table2
WHERE Property_Use IS NOT NULL
GROUP BY Property_Use
ORDER BY Total_Cases DESC

-- Property use in the cases with casualties and total casualties.

SELECT Property_Use, 
       COUNT(Property_Use) AS Total_Cases,
	   SUM(Civilian_Casualties) AS Total_Casualties
FROM Table2
WHERE Property_Use IS NOT NULL AND Civilian_Casualties > 0 
GROUP BY Property_Use
ORDER BY SUM(Civilian_Casualties) DESC;
