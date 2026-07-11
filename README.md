# 2020-COVID-Mortality-on-2021-HPI-Growth-Rate
The files in this repository seek to answer the question: what effect did county-level per-capita COVID-19 mortality rates in 2020 have on housing prices in 2021 in the United States?

Raw Data File Sources:

- co-est2025-pop.xslx, from the U.S. Census Bureau: https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-total.html

- county_landmass.csv, from Brian Dill: https://www.kaggle.com/datasets/wbdill/us-county-landmass

- HIFLD_2020_Hospitals.csv, from 543rd GPC Hub (Homeland Infrastructure Foundation-Level Data): https://543rd-gpc-hub-543rd.hub.arcgis.com/datasets/hifld-2020-hospitals/explore?location=28.503742%2C-15.457895%2C1

- hpi_at_zip3.xlsx, from The Federal Finance Housing Agency: https://www.fhfa.gov/data/hpi/datasets?tab=annual-data

- us-counties-2020.csv, from The New York Times: https://www.nytimes.com/article/coronavirus-county-data-us.html
  - Note: I attached a sample of this dataset containing the observations for the first 3 months of 2020 since the original file was too big to upload to github.

- ZIP_COUNTY_122020, from the Office of Policy Development and Research: https://www.huduser.gov/portal/datasets/usps_crosswalk.html

Other files:

- covid_hpi.do, this file runs the commands to clean, merge, and analyze the data results in Stata to answer the research question.

- Covid_hpi_Write_Up.pdf, this file provides the write up of the empirical analysis I conducted to answer the quesion listed at the top of this page.
