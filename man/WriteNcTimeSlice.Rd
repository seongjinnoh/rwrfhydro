% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/usgs_to_ncdf.R
\name{WriteNcTimeSlice}
\alias{WriteNcTimeSlice}
\title{Write a USGS discharge timeslice to a netcdf file.}
\usage{
WriteNcTimeSlice(dfByPosix, outPath, sliceResolution)
}
\arguments{
\item{dfByPosix}{Dataframe, a data frame with the following columns:
\code{site_no}, \code{dateTime}, \code{dateTimeRound},
\code{queryTime}, \code{discharge.cms}, and \code{discharge.quality} where dateTimeRound
is the same for the entire dataframe.}

\item{outPath}{Character, the path for the output netcdf file.}

\item{sliceResolution}{The Temporal resolution.}
}
\description{
Write a USGS discharge timeslice to a netcdf file.
}
\examples{

library(rwrfhydro)
library(data.table); library(plyr); library(lubridate)

rlFile <- '/glade/p/work/jamesmcc/TEST_DOMAINS/v5_community/croton_NY/NWM/DOMAIN/RouteLink.nc'
rl <- GetNcdfFile(rlFile, q=TRUE)
siteNumbers <- setdiff(trimws(unique(rl$gages)),'')
parameterCd <- "00060"  # Discharge
# NWIS is local time. Pad time at least enough to account
# for the 5hr offset in this domain.
startDate <- "2011-08-25"
endDate <- "2011-09-03"
obsDischarge <- dataRetrieval::readNWISuv(siteNumbers, parameterCd, startDate, endDate)

obsDischarge <- as.data.table(obsDischarge)
cfsToCms <- 1/35.31466621266132
obsDischarge[, `:=`(discharge.cms=X_00060_00000*cfsToCms)]
# reformat the name of th gauge to 15 character
obsDischarge$site_no <- formatC(obsDischarge$site_no, width=15)
obsDischarge$dateTimeRound <-
  format(RoundMinutes(obsDischarge$dateTime,nearest=15),
         '\%Y-\%m-\%d_\%H:\%M:\%S')
obsDischarge$dateTimeRound <-
  as.POSIXct(obsDischarge$dateTimeRound, "\%Y-\%m-\%d_\%H:\%M:\%S",
             tz='UTC')
obsDischarge$queryTime <- Sys.time()
# quality control procedures...
obsDischarge$discharge.quality <- 100

system("mkdir nudgingTimeSliceObs")
outPath <- "nudgingTimeSliceObs/"
for (i in sort(unique(obsDischarge$dateTimeRound))) {
  print(i)
  WriteNcTimeSlice(subset(obsDischarge,dateTimeRound == i),
                   outPath=outPath,
                   sliceResolution = 15)
}
}
