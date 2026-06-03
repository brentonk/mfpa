# Generate a synthetic, countypres-shaped dataset used as an offline placeholder
# for the derivatives chapter's lottery example. This replaces a Harvard
# Dataverse download so the book renders deterministically in CI with no network
# dependency. The numbers are fabricated (NOT real election returns) but mimic
# the shape the chapter expects: one DEMOCRAT and one REPUBLICAN row per county
# for year 2024, with a left-skewed two-party Trump share (mean slightly below
# median, as in the real data).
#
# Re-generate with:  Rscript data/make_synthetic_county_pres.R
# Output:            data/synthetic_county_pres.csv  (committed)

set.seed(8350)

n_counties <- 3188

# Left-skewed two-party Republican share in [0, 100]; Beta(7, 4) has its mean
# (~63.6) a touch below its median (~64.8), matching the chapter's narrative.
pct_trump <- 100 * rbeta(n_counties, 7, 4)

# Plausible county turnout: lognormal, a few hundred to a few hundred thousand.
votes_total <- round(exp(rnorm(n_counties, mean = 9, sd = 1.3))) + 200L
votes_trump <- round(votes_total * pct_trump / 100)
votes_dem   <- votes_total - votes_trump

# Unique (state, county_name) pairs so group_by(state, county_name) yields
# exactly n_counties groups.
states <- state.name
state  <- states[((seq_len(n_counties) - 1L) %% length(states)) + 1L]
county_name <- sprintf("County %04d", seq_len(n_counties))

long <- data.frame(
  year = 2024L,
  state = rep(state, each = 2L),
  county_name = rep(county_name, each = 2L),
  party = rep(c("REPUBLICAN", "DEMOCRAT"), times = n_counties),
  candidatevotes = as.integer(c(rbind(votes_trump, votes_dem)))
)

dir.create("data", showWarnings = FALSE)
write.csv(long, "data/synthetic_county_pres.csv", row.names = FALSE)
cat("wrote data/synthetic_county_pres.csv:", nrow(long), "rows,",
    n_counties, "counties\n")
