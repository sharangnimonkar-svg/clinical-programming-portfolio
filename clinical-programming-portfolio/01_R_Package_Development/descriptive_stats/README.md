# descriptiveStats
An R package designed to execute core descriptive statistical measurements on numeric vectors.

## Installation
You can install this local package variant using `devtools`. This assumes you have opened the `project_root.Rproj` (so that `here()` resolves correctly regardless of your machine or working directory):
```r
devtools::install(here::here("01_R_Package_Development", "descriptive_stats"))
library(descriptiveStats)
```

## Features & Edge Case Protections
- **Missing Data**: Automatically filters out `NA` items before computation.
- **Robust Errors**: Rejects non-numeric, `NULL`, or entirely empty data vectors.
- **All-NA Vectors**: Triggers a safety error since no mathematical operations can be performed.
- **Tied / No Mode**: Returns all tied numerical constants, or prints a message and returns `NA` if frequencies are completely flat.

## Example Usage
```r
# Load the installed package
library(descriptiveStats)

# Example data
data <- c(1, 2, 2, 3, 4, 5, 5, 5, 6, 10)

# Run calculation functions
calc_mean(data)   
calc_median(data) 
calc_mode(data)   
calc_q1(data)     
calc_q3(data)     
calc_iqr(data)    
```
