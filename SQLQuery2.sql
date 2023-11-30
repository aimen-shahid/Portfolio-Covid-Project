SELECT *
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM [Portfolio Project]..covid_vaccinations
ORDER BY 3,4

--sELECT DATA THAT WE'RE GOING TO BE USING

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
order by 1,2  

-- Looking at Total Cases Vs Total Deaths
-- Needed to convert data type from nvarchar to perform calculation.

SELECT location, date, total_cases, total_deaths, CONVERT(float, total_deaths)/ NULLIF(CONVERT(float, total_cases), 0)*100 as DeathPercentage
FROM [Portfolio Project].dbo.covid_deaths
WHERE location like '%states%'
and continent is not null
ORDER BY 1,2 

-- Looking at Total Cases Vs Population

SELECT location, date, total_cases, population, total_cases/population*100 as PercentagePopulationInfected
FROM [Portfolio Project].dbo.covid_deaths
WHERE location like '%Netherlands%'
and continent is not null
ORDER BY 1,2 

-- Looking at Countries with Highest Infection Rates per Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc

-- Countries with Highest Death Count per Poplation by Country
-- needed to add where clause bcuz in some records ASIA is included in location and in some records in continent. 

SELECT location, population, MAX(CAST(total_deaths AS int)) as HighestDeathCount
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
GROUP BY location, population
order by HighestDeathCount desc

-- highest death count by Continent

SELECT continent, MAX(CAST(total_deaths AS int)) as HighestDeathCount
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
GROUP BY continent
order by continent, HighestDeathCount desc

--Results from this query seem inaccurate; 
-- Try this query instead.

SELECT continent, location, MAX(CAST(total_deaths AS int)) as HighestDeathCount
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
GROUP BY continent, location
order by continent, HighestDeathCount desc

-- Global Numbers
--query01

SELECT location, date, total_cases, total_deaths, CONVERT(float, total_deaths)/ NULLIF(CONVERT(float, total_cases), 0)*100 as DeathPercentage
FROM [Portfolio Project].dbo.covid_deaths
WHERE continent is not null
ORDER BY 1,2 

--query02

SELECT SUM(new_cases) as totalCases, SUM(CAST(new_deaths as int)) as totalDeaths,  SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [Portfolio Project].dbo.covid_deaths
where continent is not null 
order by 1,2 

SELECT SUM(CAST(total_cases as int)) as totalCases, SUM(CAST(total_deaths as int)) as totalDeaths  --SUM(CAST(total_deaths as int))/SUM(CAST(total_cases as int))*100 as DeathPercentage
FROM [Portfolio Project].dbo.covid_deaths
where continent is not null 
order by 1,2 --not working

SELECT SUM(total_cases) as totalCases, SUM(total_deaths) as totalDeaths  --SUM(CAST(total_deaths as int))/SUM(CAST(total_cases as int))*100 as DeathPercentage
FROM [Portfolio Project].dbo.covid_deaths
where continent is not null 
order by 1,2 --not working


-- QUERIES ON COVID VACCINATION

-- Join both tables by location & date

SELECT *
FROM [Portfolio Project]..covid_deaths AS deaths
JOIN [Portfolio Project]..covid_vaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location
	and deaths.date = Vaccinations.date

-- Total polulation vs vaccinations

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS bigint)) over (partition by deaths.location ORDER BY deaths.location, deaths.date) as PeopleVaccinated-- USE PARTITION BY TO BREAKING THE CALC. UP BY DESIRED COLUMN. 
FROM [Portfolio Project]..covid_deaths AS deaths
JOIN [Portfolio Project]..covid_vaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location
	and deaths.date = Vaccinations.date
WHERE deaths.continent is not null
order by 2,3 

--01: USE CTE; if the no. of columns in the CTE is different than the columns in the query, then it will give errors.
With PopulationVsVaccination (continent, location, date, population, new_vaccinations, PeopleVaccinated)
as
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS bigint)) over (partition by deaths.location ORDER BY deaths.location, deaths.date) as PeopleVaccinated-- USE PARTITION BY TO BREAKING THE CALC. UP BY DESIRED COLUMN. 
FROM [Portfolio Project]..covid_deaths AS deaths
JOIN [Portfolio Project]..covid_vaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location
	and deaths.date = Vaccinations.date
WHERE deaths.continent is not null
)
SELECT *, (PeopleVaccinated/population)*100 AS PERCENTAGE
FROM PopulationVsVaccination

--02: USE TEMP TABLE
-- To add or alter some columns, use this statement to encounter possible errors
DROP TABLE if exists PercentPopulationVaccinated 
CREATE TABLE PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
PeopleVaccinated numeric
)
INSERT into PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS bigint)) over (partition by deaths.location ORDER BY deaths.location, deaths.date) as PeopleVaccinated-- USE PARTITION BY TO BREAKING THE CALC. UP BY DESIRED COLUMN. 
FROM [Portfolio Project]..covid_deaths AS deaths
JOIN [Portfolio Project]..covid_vaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location
	and deaths.date = Vaccinations.date
--WHERE deaths.continent is not null

SELECT *, (PeopleVaccinated/population)*100 AS PERCENTAGE
FROM PercentPopulationVaccinated

--Create Views to store data for Visualizations.

CREATE VIEW PercentPopulationsVaccinated as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, Vaccinations.new_vaccinations,
SUM(CAST(Vaccinations.new_vaccinations AS bigint)) over (partition by deaths.location ORDER BY deaths.location, deaths.date) as PeopleVaccinated-- USE PARTITION BY TO BREAKING THE CALC. UP BY DESIRED COLUMN. 
FROM [Portfolio Project]..covid_deaths AS deaths
JOIN [Portfolio Project]..covid_vaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location
	and deaths.date = Vaccinations.date
WHERE deaths.continent is not null

SELECT *
FROM PercentPopulationsVaccinated
