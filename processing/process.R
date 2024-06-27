##############
# Parameters #
##############

library(optparse)

logger = function(..., sep = ""){
  cat("\n", format(Sys.time(), format = '%Y-%m-%d %H:%M:%S'), " ", ..., sep = sep)}

strwrap2 = function(x, lw = 80){
  gsub("\\s{2,}", " ", x) |>
  strwrap(width = lw, simplify = T) |>
  paste(collapse = "\n")}

parser = OptionParser(
  option_list = list(
    
    make_option(
      opt_str = c("-i", "--input"),
      help = strwrap2(
        "Input file, in CSV format containing at minimum columns: sampleDate,
        siteName, mN1, mN2, mFluA, mFluB, and mBiomarker."),
      type = "character",
      default = ""),

    make_option(
      opt_str = c("-w", "--weights"),
      help = strwrap2(
        "Input file, in CSV format with columns: Site, and Weight. The site 
        column corresponds to siteName values in the input file. Weights
        represents factor used for combing site-specific trends into a single 
        regional trend. Weights are decimal numbers and should sum to 1.
        The weights may be set to be equal, or correspond to population
        weighting, sampling frequency, or any other user-determined criteria."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-p", "--patch"),
      help = strwrap2(
        "Input file, in CSV format with columns: Date, Site, and one or more of 
        mN1, mN2, mFluA, mFluB, mBiomarker. Values in the patch file will add or
        overide any existing values in the primary input file."),
      type = "character",
      default = ""),
  
    make_option(
      opt_str = c("-C", "--output_region_covid"),
      help = strwrap2(
        "Output location for CSV file containing regional summary for 
        SARS-CoV-2. No output will be generated if left blank."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-A", "--output_region_flu_a"),
      help = strwrap2(
        "Output location for CSV file containing regional summary for 
        Influenza A. No output will be generated if left blank."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-B", "--output_region_flu_b"),
      help = strwrap2(
        "Output location for CSV file containing regional summary for 
        Influenza B. No output will be generated if left blank."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-c", "--output_covid"),
      help = strwrap2(
        "Output location for CSV file containing site-specific SARS-CoV-2 data.
        No output will be generated if left blank."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-a", "--output_flu_a"),
      help = strwrap2(
        "Output location for CSV file containing site-specific Influenza A data.
        No output will be generated if left blank."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-b", "--output_flu_b"),
      help = strwrap2(
        "Output location for CSV file containing site-specific Influenza B data.
        No output will be generated if left blank."),
      type = "character",
      default = ""),
    
    make_option(
      opt_str = c("-v", "--verbose"),
      help = strwrap2(
        "Print additional diagnostic information."),
      action = "store_true",
      default = FALSE)
    )
  )

# Parse arguments
args = parse_args(parser)

# Verbose argument
if(args$verbose){
  logger("The following arguments have been passed to R:",
    commandArgs(trailingOnly = TRUE))
  }


###################
# Data processing #
###################

# Warn of package conflicts only in verbose mode
options(conflicts.policy = list("warn" = args$verbose))

library(readr)
library(dplyr)

# Note on variable prefixes:
# n: biomarker-normalized
# r: relative
# s: kernel-smoothed
# d: derivative/slope (with respect to date)

ww = read_csv(
  file = args$input,
  show_col_types = F,
  progress = F,
  col_types = cols_only(
    sampleDate = col_date(format = "%m/%d/%Y"),
    siteName   = col_character(),
    mN1        = col_double(),
    mN2        = col_double(),
    mFluA      = col_double(),
    mFluB      = col_double(),
    mBiomarker = col_double())) |>
  suppressMessages() |>
  rename(
    "Date"  = sampleDate,
    "Site"  = siteName)

# Patch file application
if(args$patch != ""){
  logger("Applying patch file")
  
  ww = merge(
    x = ww,
    y = read_csv(
      file = args$patch,
      show_col_types = F,
      progress = F), 
    all = T,
    by = c("Site", "Date"),
    suffixes = c("", ".patch")) |>
    
    mutate(
      across(
        .cols = ends_with(".patch"),
        .fns = \(x) coalesce(get(sub(".patch$", "", cur_column())), x),
        .names = "{sub('.patch$', '', .col)}")) |>
    select(-ends_with(".patch"))
  }

  # Biomarker-normalize values
  ww = ww |>
  mutate(
    across(
      .cols = c(mN1, mN2, mFluA, mFluB),
      .names = "n{.col}",
      .fns = \(x){x / mBiomarker}
    )
  ) |>
  
  # Scale N1 and N2 to max values within each sewershed,
  # representing signal between 0 and 1.
  group_by(Site) |>
  mutate(
    
    # Cap values at 95th percentile
    across(
      .cols = where(is.numeric),
      .fns = \(x) {
        DescTools::Winsorize(x, probs = c(0, 0.95), na.rm = T)}),
    
    # Scale values [0, 1]
    across(
      .cols = where(is.numeric),
      .fns = \(x) {x/max(x, na.rm = T)})) |>
  ungroup() |>
  
  # Rename to reflected scaled (relative) values
  rename(
    "rN1"        = "mN1",
    "rN2"        = "mN2",
    "rFluA"      = "mFluA",
    "rFluB"      = "mFluB",
    "rnN1"       = "nmN1",
    "rnN2"       = "nmN2",
    "rnFluA"     = "nmFluA",
    "rnFluB"     = "nmFluB",
    "rBiomarker" = "mBiomarker") |>
  
  # Combine N1 and N2 data for SARS-CoV-2
  rowwise() |>
  mutate(
    rN1N2 = mean(c(rN1, rN2), na.rm = T),
    rnN1N2 = mean(c(rnN1, rnN2), na.rm = T),) |>
  ungroup()


###############
# Site Trends #
###############

# Create a tidier `ksmooth()`
ksmooth2 = function(date, y, kernel, bandwidth){
  # Data must be sorted and free of NAs to ksmooth
  data = data.frame(date, y) |>
    arrange(date) |>
    na.omit()
  
  # Use complete `Date` for fitted values
  ksmooth(
    x = data$date, y = data$y,
    kernel = kernel,
    bandwidth = bandwidth,
    x.points = date) |>
    magrittr::use_series(y)
  }

ww_ks = ww |>
  
  # Ensure coverage of all dates
  right_join(
    expand.grid(
      "Date" = seq.Date(
        from = min(ww$Date, na.rm = T),
        to = max(ww$Date, na.rm = T),
        by = "1 day"),
      "Site" = unique(ww$Site)),
    by = c("Date", "Site"),
    relationship = "one-to-one",
    unmatched = "error") |>
  
  # Site specific trends
  group_by(Site) |>
  arrange(Date) |>
  mutate(
    across(
      .cols = c(
        rN1N2, rFluA, rFluB,
        rnN1N2, rnFluA, rnFluB),
      .names = "s{.col}",
      .fns = \(x) ksmooth2(
        date = Date,
        y = x,
        kernel = "normal",
        bandwidth = 21)
      )
    ) |>
  ungroup()


##############
# Site Files # 
##############

# COVID
if(args$output_covid != "") {
  logger("Preparing sewershed-specific COVID output")
  
  ww_ks |>
    select(Date, Site, ends_with("N1N2")) |> 
    filter(!is.na(srN1N2)) |>
    write_csv(file = args$output_covid)}

# Influenza A
if(args$output_flu_a != "") {
  logger("Preparing sewershed-specific Influenza A output")
  
  ww_ks |>
    select(Date, Site, ends_with("FluA")) |> 
    filter(!is.na(srFluA)) |>
    write_csv(file = args$output_flu_a)}

# Influenza B
if(args$output_flu_b != "") {
  logger("Preparing sewershed-specific Influenza B output")
  
  ww_ks |>
    select(Date, Site, ends_with("FluB")) |> 
    filter(!is.na(srFluB)) |>
    write_csv(file = args$output_flu_b)}

##################S
# Regional Trend #
##################

# Read in weights file
weights = read_csv(
  file = args$weights,
  show_col_types = F,
  progress = F,
  col_types = cols_only(
    Site = col_character(),
    Weight = col_double()))

  ww_regional = ww_ks |>
  select(
    Date,
    Site,
    # Kernel Smoothed, Relative measurements
    starts_with("sr")) |>

  # Add site weights
  inner_join(
    y = weights,
    by = c("Site"),
    relationship = "many-to-one",
    unmatched = "error") |>
  
  # Apply weights
  mutate(
    across(
      .cols = starts_with("sr"),
      .fns = \(x){x * Weight})) |>

  # Combine signals
  group_by(Date) |>
  summarize(across(
    .cols = starts_with("sr"),
    .fns = \(x) sum(x, na.rm = F)),
    .groups = "drop")


##################
# Regional Files #
##################

# COVID
if(args$output_region_covid != "") {
  logger("Preparing regional COVID output")
  
  ww_regional |>
    select(Date, ends_with("N1N2")) |>
    filter(!is.na(srN1N2)) |>
    write_csv(file = args$output_region_covid)}

# Influenza A
if(args$output_region_flu_a != "") {
  logger("Preparing regional Influenza A output")
  
  ww_regional |>
    select(Date, ends_with("FluA")) |>
    filter(!is.na(srFluA)) |>
    write_csv(file = args$output_region_flu_a)}

# Influenza B
if(args$output_region_flu_b != "") {
  logger("Preparing regional Influenza B output")
  
  ww_regional |>
    select(Date, ends_with("FluB")) |>
    filter(!is.na(srFluB)) |>
    write_csv(file = args$output_region_flu_b)}
    
logger("Done!")