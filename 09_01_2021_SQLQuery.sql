--SELECTING and Exploring DATA
SELECT location, date, TOTAL_CASES,NEW_CASES,total_deaths,population
FROM PortfolioProject..Covid_Deaths
ORDER BY 1,2

-- Total Cases Vs. Total Deaths

SELECT location, date, TOTAL_CASES,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..Covid_Deaths
WHERE location = 'Canada'
ORDER BY 1,2


--Total Cases Vs. Population
SELECT location, date, total_cases, Population, (total_cases/population)*100 AS InfectionRate
FROM PortfolioProject..Covid_Deaths
WHERE location = 'CANADA'
ORDER BY 5

--COUNTRIES WITH HIGHEST INFECTION RATE
SELECT location, population, MAX(total_cases) as TopInfectionCount, MAX((total_cases/population))*100 as 
		TopInfectionRate
FROM PortfolioProject..Covid_Deaths
GROUP BY location, population
ORDER BY TopInfectionRate DESC

--COUNTRIES WITH HIGHEST DEATH COUNT PER CAPITA
SELECT location, population, MAX(cast(total_deaths as int)) as TopDeathCount, MAX(cast(total_deaths as int)/population)*100 as 
		TopDeathPerCapita
FROM PortfolioProject..Covid_Deaths
WHERE total_deaths is not Null
GROUP BY location, population
ORDER BY TopDeathCount, TopDeathPerCapita 

-- Details in lOCATIONS

SELECT location, MAX(cast(total_deaths as int)) as TopDeathCount, MAX(cast(total_deaths as int)/population)*100 as 
		TopDeathPerCapita
FROM PortfolioProject..Covid_Deaths
WHERE continent is Null
GROUP BY location
ORDER BY TopDeathCount, TopDeathPerCapita DESC  

-- Details in Continent

SELECT continent, MAX(cast(total_deaths as int)) as TopDeathCount, MAX(cast(total_deaths as int)/population)*100 as 
		TopDeathPerCapita
FROM PortfolioProject..Covid_Deaths
WHERE continent is nOT Null
GROUP BY continent
ORDER BY TopDeathCount, TopDeathPerCapita DESC  

--Global Numbers

/* Total Cases and Deaths*/
SELECT SUM(new_cases) as GlobalCases, SUM(cast(new_deaths as int)) as GlobalDeath, 
		SUM(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathRate
FROM PortfolioProject..Covid_Deaths
WHERE continent is not Null

/* GlobalDeathRate Each Day*/

SELECT CAST(date as date), SUM(new_cases) as GlobalCases, SUM(cast(new_deaths as int)) as GlobalDeath, 
		SUM(cast(new_deaths as int))/SUM(new_cases)*100 as GlobalDeathRate
FROM PortfolioProject..Covid_Deaths
WHERE continent is not Null
Group by CAST(date as date)
ORDER BY 1,2 DESC

/*Total Population vs Vaccination*/
SELECT DEATH.continent, DEATH.location, CAST(DEATH.date AS date) date, DEATH.population, VACC.new_vaccinations,
		SUM(convert(int,VACC.new_vaccinations)) OVER (PARTITION BY DEATH.location 
		order by 
		DEATH.location, DEATH.date) as RollingPeopleVaccinated, 
		/*     (RollingPeopleVaccinated/population)*100    */
FROM PortfolioProject..Covid_Deaths DEATH
JOIN PortfolioProject..Covid_Vaccinations VACC
	ON  DEATH.location = VACC.location 
	AND
		DEATH.date = VACC.date
WHERE DEATH.continent IS NOT NULL
ORDER BY 2,3

/*Plug in (RollingPeopleVaccinated/population)*100      */
-- #1 CTE 
with POPvsVac (continent, location, date,population,new_vaccinations,RollingPeopleVaccinated)
as
(
SELECT DEATH.continent, DEATH.location, CAST(DEATH.date AS date) date, DEATH.population, VACC.new_vaccinations,
		SUM(convert(int,VACC.new_vaccinations)) OVER (PARTITION BY DEATH.location 
		order by 
		DEATH.location, DEATH.date) as RollingPeopleVaccinated
	--	(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..Covid_Deaths DEATH
JOIN PortfolioProject..Covid_Vaccinations VACC
	ON  DEATH.location = VACC.location 
	AND
		DEATH.date = VACC.date
WHERE DEATH.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100 as RollingVaccinationRate
FROM POPvsVac

--#2 Temtable 
Drop Table if exists #Population_Vaccinated_Rate
CREATE TABLE #Population_Vaccinated_Rate
(
	Continent nvarchar (255),
	Location nvarchar (255),
	Date date,
	Population numeric,
	New_vaccinations Numeric,
	RollingPeopleVaccinated Numeric
	)
INSERT INTO #Population_Vaccinated_Rate
SELECT DEATH.continent, DEATH.location, CAST(DEATH.date AS date) date, DEATH.population, VACC.new_vaccinations,
		SUM(convert(int,VACC.new_vaccinations)) OVER (PARTITION BY DEATH.location 
		order by 
		DEATH.location, DEATH.date) as RollingPeopleVaccinated
	--	(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..Covid_Deaths DEATH
JOIN PortfolioProject..Covid_Vaccinations VACC
	ON  DEATH.location = VACC.location 
	AND
		DEATH.date = VACC.date
WHERE DEATH.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 as RollingVaccinationRate
FROM #Population_Vaccinated_Rate


-- Creating View to store data for later visualization

CREATE VIEW PopulationVaccinatedPerCapita as
SELECT DEATH.continent, DEATH.location, CAST(DEATH.date AS date) date, DEATH.population, VACC.new_vaccinations,
		SUM(convert(int,VACC.new_vaccinations)) OVER (PARTITION BY DEATH.location 
		order by 
		DEATH.location, DEATH.date) as RollingPeopleVaccinated
		/*     (RollingPeopleVaccinated/population)*100    */
FROM PortfolioProject..Covid_Deaths DEATH
JOIN PortfolioProject..Covid_Vaccinations VACC
	ON  DEATH.location = VACC.location 
	AND
		DEATH.date = VACC.date
WHERE DEATH.continent IS NOT NULL

SELECT *
FROM PopulationVaccinatedPerCapita
