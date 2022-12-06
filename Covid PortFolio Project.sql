SELECT * 
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 3,4;

SELECT * 
FROM PortfolioProject..CovidVaccinations
order by 3,4;

--Select data that we are going to using


select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths 
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths 
where location like '%states%'
order by 1,2


--Looking at Total Cases vs Population
--Shows what percentage of people got covid 
select location, date, total_cases,population, (total_cases/population)*100 as PercentageOfPopulationInfected
from PortfolioProject..CovidDeaths 
--where location like '%india%'
order by 1,2

--Looking at countries with Highest Infection rate compared to population
select location, population, MAX(total_cases) as HighestInfectionCOunt, MAX((total_cases/population))*100 as PercentageOfPopulationInfected
from PortfolioProject..CovidDeaths 
--where location like '%india%'
Group by location, population
order by PercentageOfPopulationInfected desc

--Showing Countries with the highest death count per population
select location, MAX(cast(total_deaths as int)) as TotalDeaths
from PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null
group by location
order by TotalDeaths desc


--LETS BREAK THIS THINGS DOWN BY CONTINENTS

--Showing Continents with the Highest Death Count per Population
select continent, MAX(cast(total_deaths as int)) as TotalDeaths
from PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null
group by continent
order by TotalDeaths desc


--GLOBAL NUMBERS
select  SUM(new_cases) as totalcases,SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths 
--where location like '%states%'
where continent is not null
--group by date
order by 1,2


--Looking at Total Population vs Vaccination
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(cast(v.new_vaccinations as bigint)) OVER(Partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where d.continent is not null
order by 2,3


--USE CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(cast(v.new_vaccinations as bigint)) OVER(Partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
where d.continent is not null
--order by 2,3
)
select *,(RollingPeopleVaccinated/population)*100 
from PopvsVac


--TEMP TABLE
-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(cast(v.new_vaccinations as bigint)) OVER(Partition by d.location order by d.location,d.date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
ON d.location = v.location
and d.date = v.date
--where d.continent is not null
--order by 2,3

select *,(RollingPeopleVaccinated/population)*100 
from #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

select * 
from PercentPopulationVaccinated