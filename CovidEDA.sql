SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--WHERE continent IS NOT NULL
--ORDER BY 3,4;

-- SELECT THE DATA WE WILL BE USING --

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths -- 
-- The Below shows the likelihood of dying from the Virus in your country --

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE date like '2022%'
ORDER BY 1,2;

-- Looking at Total Cases vs Population --

SELECT location, date, population, total_cases, (total_cases/population)*100 AS ContractionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Africa'
ORDER BY 1,2;

-- Looking at Countries with Highest Infection rates compared to Population --

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS ContractionPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;


-- Showing Countries with highest DeathCount per LOCATION--

SELECT location,MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;


-- THE BELOW WILL BE FOR PER CONTINENT --
-- Below showing Continents with Highest Death Count Version 1--

SELECT location,MAX(CAST(total_deaths AS INT)) AS HighestDeathCount  
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT LIKE 'Upper middle income'
AND location NOT LIKE 'Lower middle income'
AND location NOT LIKE 'Low income'
AND location NOT LIKE 'High income'
AND location NOT LIKE 'International'
AND location NOT LIKE 'European Union'
AND location NOT LIKE 'Oceania'
GROUP BY location
ORDER BY 2 DESC;

-- NOTE that the for the total death counts, the RAW DATA used the LOACTION column especially for the 
-- ... continents. However, if you want a 'drill down' effect. i.e. for viewing from Continet to country
-- ... you will need to do the below QUERY -- 

-- Below showing Continents with Highest Death Count Version 2 forDrill Down --

SELECT continent,MAX(CAST(total_deaths AS INT)) AS HighestDeathCount  
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;

-- GLOBAL NUMBERS --


-- Way to find the TOTAL GLOBAL CASES, DEATHS, and Death Percentage --

WITH cte(location, global_cases, global_deaths, DeathPercentage) AS(
		SELECT location, MAX(CAST(total_cases AS BIGINT)) AS global_cases, 
		MAX(CAST(total_deaths AS BIGINT)) AS global_deaths, 
		MAX(CAST(total_deaths AS BIGINT))/MAX(CAST(total_cases AS BIGINT))
		FROM PortfolioProject..CovidDeaths
		WHERE continent IS NULL
		AND location NOT LIKE 'Upper middle income'
		AND location NOT LIKE 'Lower middle income'
		AND location NOT LIKE 'Low income'
		AND location NOT LIKE 'High income'
		AND location NOT LIKE 'International'
		AND location NOT LIKE 'European Union'
		AND location NOT LIKE 'World'
		GROUP BY location)
SELECT SUM(cte.global_cases) AS Total_Global_Cases,
	   SUM(cte.global_deaths) AS Total_Global_Deaths,
	   (SUM(cte.global_deaths)/SUM(cte.global_cases)) AS Global_Death_Percentage
FROM cte;

		SELECT location, MAX(CAST(total_cases AS BIGINT)) AS global_cases, 
		MAX(CAST(total_deaths AS BIGINT)) AS global_deaths, 
		MAX(CAST(total_deaths AS BIGINT))/MAX(CAST(total_cases AS BIGINT))
		FROM PortfolioProject..CovidDeaths
		WHERE continent IS NULL
		AND location NOT LIKE 'Upper middle income'
		AND location NOT LIKE 'Lower middle income'
		AND location NOT LIKE 'Low income'
		AND location NOT LIKE 'High income'
		AND location NOT LIKE 'International'
		AND location NOT LIKE 'European Union'
		AND location NOT LIKE 'World'
		GROUP BY location

-- WORLD = 514 918 067



-- We shall Join the Death and Vaccination Tables Below --

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date;


-- Looking AT Total Population vs Total Vaccination Globally -- 

--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
--SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
--FROM PortfolioProject..CovidDeaths dea
--JOIN PortfolioProject..CovidVaccinations vac
--	ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;

--USING CTE to find the Total Population vs Total Vaccination Per Country --  

WITH cte(continent, location, date, population, newvacs,RollingPeopleVaccinated) AS(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL)
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingVaccinationPercentage
FROM cte;

-- USING A TEMP TABLE TO find the Total Population vs Total Vaccination Per Country --


DROP TABLE IF EXISTS #PercentagePopulationVaccinated 
CREATE TABLE #PercentagePopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentagePopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;

SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingVaccinationPercentage
FROM #PercentagePopulationVaccinated;


-- FIND THE CURRENT VACCINATED POPULATION PER COUNTRY --

SELECT  dea.location, MAX(vac.new_vaccinations/dea.population)*100 AS VaccinatedPopulationPercentage
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location
ORDER BY 2 DESC;

-- Creating View to store data for later visualizations --


-- DROP VIEW IF EXISTS PercentagePopulationVaccinated;

CREATE VIEW PercentagePopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccination
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
-- ORDER BY 2,3

