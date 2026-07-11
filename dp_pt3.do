capture log close
log using dp_pt3.txt, replace text
clear

/*

ECON 388 Data Project Pt. 3

NAME: Spencer Spendlove

*/

************************************
cd "C:\Users\sjs2nps3\Box\Econ 388\Data Project 3"

*** Load and clean datasets ***

** Load and clean hpi data **
clear
import excel using "hpi_at_zip3.xlsx", sheet("ZIP3") cellrange(A7)
rename A zip3
rename B year
rename D hpi
keep if year==2020 | year==2021 // Only years we care about
drop G // This gets rid of empty column 
drop C // This gets rid of annual change variable
drop E // This gets rid of hpi_1990base
drop F // This gets rid of hpi_2000base
tostring zip3, replace // Just to stay consistent
replace zip3 = "0" + zip3 if length(zip3) == 2 // Adds leading 0 for consistency
replace zip3 = "00" + zip3 if length(zip3) == 1 // Adds two leading 0's
reshape wide hpi, i(zip3) j(year) // This creates wide dataset
save "hpi_zip3_wide", replace // This saves the new dataset. (Use later).

** Load and clean hospital data **
clear
import delimited using "HIFLD_2020_Hospitals.csv" // Hospital data
gen numhospitals = 1 // The data is on specific hospitals, not hospitals per county
rename countyfips county_fips
drop if county_fips == "NOT AVAILABLE" // We lose 8 hospitals here
collapse (sum) numhospitals, by(county_fips)
save "zip_hos_count", replace // This saves the new dataset. (Use later).

** Load and clean ZIP_COUNTY data **
clear
import excel using "ZIP_COUNTY_122020.xlsx", firstrow // Data from 2020 Q4
rename ZIP zip5
rename COUNTY county_fips
gen zip3 = substr(zip5, 1, 3) // This keeps first 3 digits as a string
keep zip3 county_fips // These variables will help us merge to county level

** Merge and collapse data to find aggregate hpi for residents on the county level **
merge m:1 zip3 using "hpi_zip3_wide"
keep if _merge==3 // Missing 147 matches but got 6,761 perfect matches.
// Those missing matches simply didn't have hpi data in raw dataset.
drop _merge
collapse (mean) hpi2020 hpi2021, by (county_fips)
// This makes the county-level hpi the average hpi at each county fips.
rename hpi2020 county_hpi2020
rename hpi2021 county_hpi2021
// Collapse to county level
gen hpipcinc = ((county_hpi2021-county_hpi2020)/county_hpi2020)*100 
// Percent change in hpi for regression
merge 1:1 county_fips using "zip_hos_count"
replace numhospitals = 0 if _merge==1 // counties with no hospitals
drop if _merge==2 // Missing 30 observations
drop _merge
save "county_level_hpi_hos", replace
// USE THIS LATER in final merge.

** Load and clean land data **
clear
import delimited "county_landmass.csv" // This is the landmass datasets
rename fips county_fips
tostring county_fips, replace // Just to stay consistent
replace county_fips = "0" + county_fips if length(county_fips) == 4
keep county_fips land_sq_mi
save "county_size", replace
// USE THIS LATER in final merge.

** Load and Collapse COVID Data **
clear
import delimited "us-counties-2020.csv" // This is the dataset of COVID cases
rename fips county_fips
/* Note: New York City and Unkown, Rhode Island are missing county_fips and thus cannot
be used in the final dataset. This will offset the final regression slightly, but our
sample size is already large enough and there's nothing I can do to recover this lost 
data.
*/
drop if county_fips == .
gen geo_area = county + ", " + state
replace geo_area = "Doña Ana, New Mexico" in 5614 // This causes a mismatch without fix
collapse (max) cases deaths (first) geo_area, by(county_fips)
save "county_covid_cases", replace

** Load and clean merge population data **
clear
import excel using "co-est2025-pop.xlsx", sheet("CO-EST2025-POP") cellrange(A4)
rename A geo_area
rename B base_pop_2020
drop if base_pop_2020 == . // This gets rid of cells explaining dataset
drop if geo_area == "United States" // This gets rid of aggregate data I don't need
replace geo_area = substr(geo_area, 2, .) // This gets rid of  the leading .
replace geo_area = subinstr(geo_area, " County", "", .)
replace geo_area = subinstr(geo_area, " Planning Region", "", .)
replace geo_area = subinstr(geo_area, " Parish", "", .)
// Those got rid of additional labels that aren't found in the COVID Dataset
replace geo_area = "Bristol Bay plus Lake and Peninsula, Alaska" in 72
replace base_pop = 2313 in 72
replace geo_area = "Yakutat plus Hoonah-Angoon, Alaska" in 79
replace base_pop = 3023 in 72
// Those fix some mismatches that would come up later.
keep geo_area base_pop_2020 
/* I will use the base_2020 variable since it was the earliest population estimate 
in 2020, in the beginning stages of COVID.*/

*** Merge cleaned datasets ***
merge 1:1 geo_area using "county_covid_cases"
// Unfortunately 112 observations didn't match, but there's nothing we can do about it.
keep if _merge==3
drop _merge
tostring county_fips, replace // Just to stay consistent
replace county_fips = "0" + county_fips if length(county_fips) == 4
merge 1:1 county_fips using "county_level_hpi_hos"
// 22 observations from the hpi_hos didn't merge, 5 mismatches from master
keep if _merge==3
drop _merge
merge 1:1 county_fips using "county_size"
// 26 observations from the county_size did not merge, 0 mismatches from master
keep if _merge==3
drop _merge
// We now have 3120 observations or data for 3120 counties

** Generate variables for regression **
gen dp1000 = deaths/base_pop_2020 * 1000 // main independent variable
gen cp1000 = cases/base_pop_2020 * 1000 // control variable
gen popdensity = base_pop_2020/land_sq_mi // control variable
order geo_area county_fips hpipcinc dp1000 cp1000 popdensity numhospitals // Just to order for regression
save "master_county_data", replace

*** Data Analysis ***

** Summary Table **
summarize hpipcinc dp1000 cp1000 popdensity numhospitals

** Correlation coefficients **
correlate hpipcinc cp1000
correlate hpipcinc popdensity
correlate hpipcinc numhospitals
correlate dp1000 cp1000
correlate dp1000 popdensity
correlate dp1000 numhospitals

** Bar Graphs for distributions of important variables **
histogram hpipcinc, width(1) ///
	color(green%80) ///
	title("Distribution of HPI Percent Increase") ///
	ytitle("Number of Counties") ///
	xtitle("HPI Percent Increase")
graph export "hpi_distribution.png", replace
// This creates a bar graph for the distibution of HPI Percent Increases.
histogram dp1000, width(.5) ///
	color(cranberry%90) ///
	title("Distribution of Deaths per 1,000 People") ///
	ytitle("Number of Counties") ///
	xtitle("Deaths per 1,000 People")
graph export "deaths_distribution.png", replace
// This creates a bar graph for the distribution of Deaths per 1000 People

** Bivariate regression **
reg hpipcinc dp1000

** Multiple regression **
reg hpipcinc dp1000 cp1000 popdensity numhospitals


log close
