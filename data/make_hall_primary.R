# Build the trimmed Hall (2015) primary-election dataset used by the
# limits-and-continuity chapter's motivating figure (@fig-hall-rdd).
#
# Source: replication archive for
#   Andrew B. Hall (2015), "What Happens When Extremists Win Primaries?",
#   American Political Science Review 109(1): 18-42.
# The archive (Hall_Extremist_Primaries_APSR_Replication.zip) ships
# primary_analysis.dta; we keep only the four columns the figure needs and
# commit the result as a small CSV so the book renders deterministically in CI
# with no network dependency (mirrors data/make_synthetic_county_pres.R).
#
# Columns kept:
#   rv      relatively extreme candidate's winning margin in the primary
#           (running variable; > 0 means the extremist won the primary)
#   dv      the party's general-election vote share (outcome)
#   margin  |rv|, the absolute primary margin
#   absdist ideological distance between the two primary candidates
#
# Re-generate with:  Rscript data/make_hall_primary.R
# Output:            data/hall_primary.csv  (committed)

library("archive")
library("haven")
library("dplyr")

url_hall <- "https://www.dropbox.com/s/1o0lrqemdlyh7ha/Hall_Extremist_Primaries_APSR_Replication.zip?dl=1"
con <- archive_read(url_hall, file = "primary_analysis.dta")
raw <- read_dta(con)

hall <- raw |>
  transmute(rv, dv, margin, absdist)

dir.create("data", showWarnings = FALSE)
write.csv(hall, "data/hall_primary.csv", row.names = FALSE)
cat("wrote data/hall_primary.csv:", nrow(hall), "rows\n")
