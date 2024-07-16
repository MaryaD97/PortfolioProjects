-- Selecting all records from CovidDeaths table where continent information is available
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LEN(TRIM(continent)) > 0
ORDER BY 3, 4;

-- Selecting all records from CovidVaccinations table
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4;

-- Selecting relevant data for analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;

-- Calculating death percentage for the United States
SELECT location, date, total_cases, total_deaths, 
    (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Calculating percentage of population that contracted Covid in the United States
SELECT location, date, population, total_cases, 
    (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS InfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Identifying countries with the highest infection rates relative to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
    MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Identifying countries with the highest death counts
SELECT location, SUM(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LEN(TRIM(continent)) > 0
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Identifying countries with the highest death counts excluding global aggregations
SELECT location, SUM(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL OR LEN(TRIM(continent)) = 0
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Aggregating global new cases and death percentages over time
SELECT date, SUM(CONVERT(float, new_cases)) AS TotalNewCases, 
    (SUM(CONVERT(float, total_deaths)) / NULLIF(SUM(CONVERT(float, total_cases)), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LEN(TRIM(continent)) > 0
GROUP BY date
ORDER BY 1, 2;

-- Aggregating global new cases and death percentages
SELECT 
    SUM(CONVERT(float, new_cases)) AS TotalCases,
    SUM(CONVERT(float, new_deaths)) AS TotalDeaths,
    (SUM(CONVERT(float, new_deaths)) / NULLIF(SUM(CONVERT(float, new_cases)), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND LEN(TRIM(continent)) > 0
ORDER BY 1, 2;

-- Joining CovidDeaths and CovidVaccinations tables to analyze vaccination data
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Calculating rolling sum of vaccinations by country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND LEN(TRIM(dea.continent)) > 0
ORDER BY 2, 3;

-- Using CTE to calculate rolling sum of vaccinations by country
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL AND LEN(TRIM(dea.continent)) > 0
    AND dea.population IS NOT NULL AND LEN(TRIM(dea.population)) > 0
)
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- Dropping the temporary table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

-- Creating the temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_Vaccination numeric,
    RollingPeopleVaccinated numeric
);

-- Inserting data into the temporary table with conversion handling
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(datetime, dea.date) AS Date, 
    TRY_CONVERT(numeric, dea.population) AS Population, 
    TRY_CONVERT(numeric, vac.new_vaccinations) AS New_Vaccinations,
    SUM(TRY_CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
    AND LEN(TRIM(dea.continent)) > 0
    AND TRY_CONVERT(datetime, dea.date) IS NOT NULL
    AND TRY_CONVERT(numeric, dea.population) IS NOT NULL
    AND TRY_CONVERT(numeric, vac.new_vaccinations) IS NOT NULL;

-- Selecting data from the temporary table and calculating percentage of population vaccinated
SELECT *, 
    (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Setting the context to the PortfolioProject database
USE PortfolioProject;
GO

-- Dropping the existing view if it exists
IF OBJECT_ID('PercentPopulationVaccinated', 'V') IS NOT NULL
BEGIN
    DROP VIEW PercentPopulationVaccinated;
END
GO

-- Creating the view PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CONVERT(datetime, dea.date) AS Date, 
    TRY_CONVERT(numeric, dea.population) AS Population, 
    TRY_CONVERT(numeric, vac.new_vaccinations) AS New_Vaccinations,
    SUM(TRY_CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY TRY_CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
    AND LEN(TRIM(dea.continent)) > 0
    AND TRY_CONVERT(datetime, dea.date) IS NOT NULL
    AND TRY_CONVERT(numeric, dea.population) IS NOT NULL
    AND TRY_CONVERT(numeric, vac.new_vaccinations) IS NOT NULL;
GO

-- Selecting data from the view and calculating percentage of population vaccinated
SELECT *, 
    (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;
