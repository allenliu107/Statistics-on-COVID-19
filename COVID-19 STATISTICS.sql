--Statistics on Covid Deaths and Cases

--Total Cases vs Total Deaths
SELECT
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(CAST(total_deaths as numeric))/(Cast(total_cases as numeric))*100 as DeathPercentage
FROM 
	CovidProject..CovidDeaths
WHERE 
	location like '%states%'
ORDER BY 
	1,2

-- Showing Countries with Highest Death Count per Population

Select 
	Location, 
	MAX(CAST(total_deaths as numeric)) AS TotalDeathCount
FROM 
	CovidProject..CovidDeaths
Where 
	continent is not null
GROUP BY 
	Location
ORDER BY 
	TotalDeathCount DESC

--Break things down by continent(showing continents with toal death count)
Select 
	location, 
	MAX(CAST(total_deaths as numeric)) AS TotalDeathCount
FROM 
	CovidProject..CovidDeaths
Where 
	continent is null
GROUP BY 
	location
ORDER BY 
	TotalDeathCount DESC

----GLOBAL NUMBERS

SELECT 
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS int)) AS total_deaths, 
	SUM(CAST(new_deaths AS int))/ NULLIF(SUM(New_Cases), 0)*100 AS GlobalDeathPercentage
FROM 
	CovidProject..CovidDeaths
WHERE 
	continent is not null
Group By 
	date
ORDER BY 
	1,2


-- Calculate Total New Cases for the Entire Month based on First Day of Each Month
SELECT
    SUM(new_cases) AS new_cases_month,
    location,
    MONTH(date) AS month,
    YEAR(date) AS year
FROM 
	CovidProject..CovidDeaths
WHERE
    total_cases IS NOT NULL
    AND new_cases IS NOT NULL
GROUP BY
    location, MONTH(date), YEAR(date)
HAVING
    DAY(MIN(date)) = 1
ORDER BY  
	location,
	year,
	month

--Statistics on Cases over times

--Shows what percent of United States contracted Covid over time
SELECT 
	location, 
	date, 
	total_cases, 
	((CAST(total_cases AS numeric))/population)*100 AS PercentageOfCountryAffected
FROM 
	CovidProject..CovidDeaths
WHERE 
	location = 'United States'
ORDER BY 
	2

--Looking at Countries with Highest Infection Rate compared to Population
SELECT 
	location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX(((CAST(total_cases AS numeric))/population)*100) AS PercentofCountryAffected
FROM 
	CovidProject..CovidDeaths
GROUP BY 
	Location, 
	Population
ORDER BY 
	4 DESC

--Statistics on Vaccinations

--Percent Fully Vaccinated
SELECT
    subquery.location,
    subquery.total_vaccinations,
    subquery.population,
    subquery.people_vaccinated,
    subquery.people_fully_vaccinated,
    ROUND((CAST(subquery.people_fully_vaccinated AS numeric) / CAST(subquery.people_vaccinated AS numeric)) * 100, 2) AS PercentFullyVaccinated
FROM (
    SELECT
        VAC.location,
        VAC.total_vaccinations,
        DEA.population,
        VAC.people_vaccinated,
        VAC.people_fully_vaccinated,
        ROW_NUMBER() OVER (PARTITION BY VAC.location ORDER BY VAC.total_vaccinations DESC) AS rn
    FROM
        CovidProject..CovidVaccinations AS VAC
        JOIN CovidProject..CovidDeaths AS DEA
        ON DEA.location = VAC.location
        AND DEA.date = VAC.date
    WHERE
        VAC.total_vaccinations IS NOT NULL
) AS subquery
WHERE
    subquery.rn = 1;

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM
	CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE 
	dea.continent is not null 
ORDER BY 
	2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM
	CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT
	*, 
	(RollingPeopleVaccinated/Population)*100
FROM 
	PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF 
	exists #PercentPopulationVaccinated
CREATE TABLE 
	#PercentPopulationVaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
	)

INSERT INTO 
	#PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
	CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
	where dea.continent is not null 

SELECT 
	*, 
	(RollingPeopleVaccinated/Population)*100
FROM 
	#PercentPopulationVaccinated

