---Looking at Total Cases

SELECT COUNT(*) AS Total_Number_of_Cases_Reported
FROM PreControl;


---Looking at Total Cases With Casualties

SELECT COUNT(*) AS Total_Number_of_Cases_With_Casualties
FROM PostControl
WHERE Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL;


---Looking at Total Deaths

Select SUM(Civilian_Casualties) AS Total_Deaths_Reported
FROM PostControl;


---Percentage of cases with death

SELECT (COUNT(CASE WHEN Civilian_Casualties > 0 THEN 1 END) * 100  / COUNT(*)) AS Percentage_of_Cases_with_Civilian_Casualties
FROM PostControl;


--TOTAL NUMBER OF CASES REPORTED BY AREAS

SELECT Intersection, COUNT(Intersection) AS TotalCases
FROM PreControl
WHERE Intersection IS NOT NULL 
GROUP BY Intersection
ORDER BY TotalCases DESC;


--TOTAL NUMBER OF CASES WITH CASUALTIES BY AREAS

SELECT Pr.Intersection,
       COUNT(Pr.Intersection) AS TotalCases, 
	   SUM(Po.Civilian_Casualties) AS TotalCasualties
FROM PreControl Pr
INNER JOIN PostControl Po  ON Pr.id = Po.id
WHERE Po.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY Pr.Intersection
ORDER BY TotalCasualties DESC;

-- Intersections, Cases, Casualties

SELECT Pr.Intersection,
       COUNT(Pr.Intersection) OVER (PARTITION BY Pr.Intersection) AS Total_Cases_Reported_in_Area, 
	   Pr.id AS Case_id,
	   --ROW_NUMBER() OVER (PARTITION BY Pr.id ORDER BY Pr.Intersection) AS Case_Number ,
	   SUM(Po.Civilian_Casualties) OVER (PARTITION BY Pr.id) AS Casualties
FROM PreControl Pr
INNER JOIN PostControl Po  ON Pr.id = Po.id
WHERE Po.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
ORDER BY Pr.Intersection, Pr.id, Casualties;




--TOTAL NUMBER OF CASES WITH CASUALTIES REPORTED BY Year

SELECT YEAR(TFS_Alarm_Time) AS Year, COUNT(YEAR(TFS_Alarm_Time)) AS Number_of_Cases, SUM(Po.Civilian_Casualties) AS TotalCasualties
FROM PreControl Pr
INNER JOIN PostControl Po  ON Pr.id = Po.id
WHERE Po.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY YEAR(TFS_Alarm_Time)
ORDER BY TotalCasualties DESC;


--TOTAL NUMBER OF CASES WITH CASUALTIES REPORTED BY Month

SELECT FORMAT(TFS_Alarm_Time, 'MM') AS Month, COUNT(FORMAT(TFS_Alarm_Time, 'MM')) AS NumberofCases,SUM(Po.Civilian_Casualties) AS TotalCasualties
FROM PreControl Pr
INNER JOIN PostControl Po  ON Pr.id = Po.id
WHERE Po.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY FORMAT(TFS_Alarm_Time, 'MM')
ORDER BY TotalCasualties DESC;



--TOTAL NUMBER OF CASES WITH CASUALTIES REPORTED BY Day of the Week 

SELECT FORMAT(TFS_Alarm_Time, 'dddd') AS Day, COUNT(FORMAT(TFS_Alarm_Time, 'dddd')) AS NumberofCases,SUM(Po.Civilian_Casualties) AS TotalCasualties
FROM PreControl Pr
INNER JOIN PostControl Po  ON Pr.id = Po.id
WHERE Po.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY FORMAT(TFS_Alarm_Time, 'dddd')
ORDER BY TotalCasualties DESC;


--TOTAL NUMBER OF CASES WITH CASUALTIES REPORTED BY Hour of the Day

SELECT FORMAT(TFS_Alarm_Time, 'HH') AS Hour, COUNT(FORMAT(TFS_Alarm_Time, 'HH')) AS NumberofCases,SUM(Po.Civilian_Casualties) AS TotalCasualties
FROM PreControl Pr
INNER JOIN PostControl Po  ON Pr.id = Po.id
WHERE Po.Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY FORMAT(TFS_Alarm_Time, 'HH')
ORDER BY TotalCasualties DESC;


-- Area of Origin of Fire

SELECT  Area_of_Origin, COUNT(Area_of_Origin) AS Number_Of_Cases_Reported
FROM PostControl
WHERE Area_of_Origin IS NOT NULL AND Civilian_Casualties IS NOT NULL AND Civilian_Casualties > 0
GROUP BY Area_of_Origin
ORDER BY COUNT(Area_of_Origin) DESC;

-- Area of Origin of Fire2
SELECT  Area_of_Origin, SUM(Civilian_Casualties) AS Number_Of_Deaths
FROM PostControl
WHERE Area_of_Origin IS NOT NULL AND Civilian_Casualties IS NOT NULL 
GROUP BY Area_of_Origin
ORDER BY SUM(Civilian_Casualties) DESC


--Material that first caught fire

SELECT  Material_First_Ignited, SUM(Civilian_Casualties) AS Total_Cases
FROM PostControl
WHERE Material_First_Ignited IS NOT NULL AND Civilian_Casualties > 0 
GROUP BY Material_First_Ignited
ORDER BY SUM(Civilian_Casualties) DESC


--Property Use in the cases reported

SELECT Property_Use, COUNT(Property_Use) AS Total_Cases
FROM PostControl
WHERE Property_Use IS NOT NULL
GROUP BY Property_Use
ORDER BY COUNT(Property_Use) DESC

-- Property Use in the cases wherein casualties happened

SELECT Property_Use, SUM(Civilian_Casualties) AS Total_Cases
FROM PostControl
WHERE Property_Use IS NOT NULL AND Civilian_Casualties > 0 AND Civilian_Casualties IS NOT NULL
GROUP BY Property_Use
ORDER BY SUM(Civilian_Casualties) DESC
*/