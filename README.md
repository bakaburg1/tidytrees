
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidytrees

<!-- badges: start -->
<!-- badges: end -->

Regression and classification trees (e.g. from packages like `partykit`
or `rpart`) are a very powerful set of statistical learning algorithms.

Nevertheless each tree package has its own way of representing and
storing the trees, usually as a nested recursive list with attributes.
This makes it very hard to interact with them.

This package provides an interface to convert tree objects from various
packages into a “tidy” data frame, with a row for each node showing its
defining set of rules and its characteristics.

## Installation

You can install the last version of `tidytrees` with
<!-- [CRAN](https://CRAN.R-project.org) with: -->

<!-- ``` r -->
<!-- install.packages("tidytrees") -->
<!-- ``` -->
<!-- And the development version from [GitHub](https://github.com/) with: -->

    # install.packages("devtools")
    devtools::install_github("bakaburg1/tidytrees")

## Simple use

`tidytrees` exposes the generic function `tidy_tree` which has a method
for various tree objects (see `?tidy_tree` for the list supported
methods). The output is a tibble with a row of each tree node. For each
node the relative rules are reported, plus other information like the
node id, the number of observations related to the node in the data from
which the model is derived, the depth of the node in the tree.

``` r
library(tidytrees)
library(partykit)
library(rpart)

# The function works with partykit...
model <- ctree(Sepal.Width ~ Species + Sepal.Length, data = iris)

tidy_tree(model)
#> # A tibble: 12 x 6
#>    rule                                         id n.obs terminal depth estimate
#>    <chr>                                     <int> <int> <lgl>    <dbl>    <dbl>
#>  1 Species in setosa                             2    50 FALSE        1     3.43
#>  2 Sepal.Length <= 5 & Species in setosa         3    28 FALSE        2     3.20
#>  3 Sepal.Length <= 4.9 & Species in setosa       4    20 TRUE         3     3.14
#>  4 Sepal.Length <= 5 & Sepal.Length > 4.9 &…     5     8 TRUE         3     3.36
#>  5 Sepal.Length > 5 & Species in setosa          6    22 FALSE        2     3.71
#>  6 Sepal.Length <= 5.3 & Sepal.Length > 5 &…     7    12 TRUE         3     3.62
#>  7 Sepal.Length > 5.3 & Species in setosa        8    10 TRUE         3     3.82
#>  8 Species in versicolor, virginica              9   100 FALSE        1     2.87
#>  9 Sepal.Length <= 6.3 & Species in versico…    10    58 FALSE        2     2.74
#> 10 Sepal.Length <= 5.5 & Species in versico…    11    12 TRUE         3     2.47
#> 11 Sepal.Length <= 6.3 & Sepal.Length > 5.5…    12    46 TRUE         3     2.81
#> 12 Sepal.Length > 6.3 & Species in versicol…    13    42 TRUE         2     3.05

# ... and with rpart trees (more models to come)
model <- rpart(Sepal.Width ~ Species + Sepal.Length, data = iris)

tidy_tree(model)
#> # A tibble: 8 x 6
#>   rule                                          id n.obs depth terminal estimate
#>   <chr>                                      <dbl> <int> <dbl> <lgl>       <dbl>
#> 1 Species = versicolor,virginica                 2   100     1 FALSE        2.87
#> 2 Species = versicolor,virginica & Sepal.Le…     4    58     2 FALSE        2.74
#> 3 Species = versicolor,virginica & Sepal.Le…     8    12     3 TRUE         2.47
#> 4 Species = versicolor,virginica & Sepal.Le…     9    46     3 TRUE         2.81
#> 5 Species = versicolor,virginica & Sepal.Le…     5    42     2 TRUE         3.05
#> 6 Species = setosa                               3    50     1 FALSE        3.43
#> 7 Species = setosa & Sepal.Length < 5.05         6    28     2 TRUE         3.20
#> 8 Species = setosa & Sepal.Length >= 5.05        7    22     2 TRUE         3.71
```

The rules can optionally be rendered in a R compatible format, for easy
use as data filters, or as list of rules.

``` r
library(tidytrees)
library(dplyr)
library(rpart)

model <- rpart(Sepal.Width ~ Species + Sepal.Length, data = iris)

# Evaluation friendly rules

out <- tidy_tree(model, eval_ready = T)

iris %>% filter(eval(str2expression(out$rule[3]))) %>% str
#> 'data.frame':    12 obs. of  5 variables:
#>  $ Sepal.Length: num  5.5 4.9 5.2 5 5.5 5.5 5.4 5.5 5.5 5 ...
#>  $ Sepal.Width : num  2.3 2.4 2.7 2 2.4 2.4 3 2.5 2.6 2.3 ...
#>  $ Petal.Length: num  4 3.3 3.9 3.5 3.8 3.7 4.5 4 4.4 3.3 ...
#>  $ Petal.Width : num  1.3 1 1.4 1 1.1 1 1.5 1.3 1.2 1 ...
#>  $ Species     : Factor w/ 3 levels "setosa","versicolor",..: 2 2 2 2 2 2 2 2 2 2 ...

# Rules as vectors
out <- tidy_tree(model, rule_as_text = F)

out$rule[3]
#> [[1]]
#> [1] "Species = versicolor,virginica" "Sepal.Length < 6.35"           
#> [3] "Sepal.Length < 5.55"

# Both
out <- tidy_tree(model, rule_as_text = F, eval_ready = T)

out$rule[3]
#> [[1]]
#> [1] "Species %in% c(\"versicolor\", \"virginica\")"
#> [2] "Sepal.Length < 6.35"                          
#> [3] "Sepal.Length < 5.55"
```

Tree models tend to create explicity, nested rules with redundant
components, in order to retain the whole branching information. This is
not necessary for data partition and makes rules harder to read. The
package allow to simplify such rules in order to retain the minimal
necessary set of conditions to identify a partition. The simplified
rules are ordered alphabetically to keep conditions on the same
variables together.

``` r
library(tidytrees)
library(dplyr)
library(rpart)

model <- rpart(Sepal.Length ~ Species + Sepal.Width, data = iris)

# Full rules

tidy_tree(model)$rule[5:9]
#> [1] "Species = versicolor,virginica & Species = versicolor"                                            
#> [2] "Species = versicolor,virginica & Species = versicolor & Sepal.Width < 2.75"                       
#> [3] "Species = versicolor,virginica & Species = versicolor & Sepal.Width >= 2.75"                      
#> [4] "Species = versicolor,virginica & Species = versicolor & Sepal.Width >= 2.75 & Sepal.Width < 3.05" 
#> [5] "Species = versicolor,virginica & Species = versicolor & Sepal.Width >= 2.75 & Sepal.Width >= 3.05"

# Simplified rules
tidy_tree(model, simplify_rules = T)$rule[5:9]
#> [1] "Species = versicolor"                                           
#> [2] "Sepal.Width < 2.75 & Species = versicolor"                      
#> [3] "Sepal.Width >= 2.75 & Species = versicolor"                     
#> [4] "Sepal.Width < 3.05 & Sepal.Width >= 2.75 & Species = versicolor"
#> [5] "Sepal.Width >= 3.05 & Species = versicolor"

# It works also on a list of conditions
tidy_tree(model, rule_as_text = F, simplify_rules = T)$rule[5:9]
#> [[1]]
#> [1] "Species = versicolor"
#> 
#> [[2]]
#> [1] "Sepal.Width < 2.75"   "Species = versicolor"
#> 
#> [[3]]
#> [1] "Sepal.Width >= 2.75"  "Species = versicolor"
#> 
#> [[4]]
#> [1] "Sepal.Width < 3.05"   "Sepal.Width >= 2.75"  "Species = versicolor"
#> 
#> [[5]]
#> [1] "Sepal.Width >= 3.05"  "Species = versicolor"

# Can be applied to previously created rules

rules <- tidy_tree(model)$rule[5:9]

simplify_rules(rules)
#> [1] "Species = versicolor"                                           
#> [2] "Sepal.Width < 2.75 & Species = versicolor"                      
#> [3] "Sepal.Width >= 2.75 & Species = versicolor"                     
#> [4] "Sepal.Width < 3.05 & Sepal.Width >= 2.75 & Species = versicolor"
#> [5] "Sepal.Width >= 3.05 & Species = versicolor"
```

## Node predictions

The output contains optionally the predicted value in the node and
estimation intervals, with the possibility to chose the interval
coverage (default = 95%).

``` r
library(tidytrees)
library(dplyr)
library(rpart)

# Intervals for continuous...
model <- rpart(Sepal.Width ~ Species + Sepal.Length, data = iris)

tidy_tree(model, add_interval = T, interval_level = .89)
#> # A tibble: 8 x 8
#>   rule                       id n.obs depth terminal estimate conf.low conf.high
#>   <chr>                   <dbl> <int> <dbl> <lgl>       <dbl>    <dbl>     <dbl>
#> 1 Species = versicolor,v…     2   100     1 FALSE        2.87     2.83      2.91
#> 2 Species = versicolor,v…     4    58     2 FALSE        2.74     2.69      2.79
#> 3 Species = versicolor,v…     8    12     3 TRUE         2.47     2.38      2.55
#> 4 Species = versicolor,v…     9    46     3 TRUE         2.81     2.76      2.87
#> 5 Species = versicolor,v…     5    42     2 TRUE         3.05     3.00      3.10
#> 6 Species = setosa            3    50     1 FALSE        3.43     3.36      3.49
#> 7 Species = setosa & Sep…     6    28     2 TRUE         3.20     3.14      3.27
#> 8 Species = setosa & Sep…     7    22     2 TRUE         3.71     3.64      3.79

# ... and discrete outcomes
model <- rpart(Species ~ Sepal.Width + Sepal.Length, data = iris)

tidy_tree(model, add_interval = T, interval_level = .89)
#> # A tibble: 24 x 9
#>    rule              id n.obs depth terminal estimate conf.low conf.high y.level
#>    <chr>          <dbl> <int> <dbl> <lgl>       <dbl>    <dbl>     <dbl> <chr>  
#>  1 Sepal.Length …     2    52     1 FALSE      0.865   0.765      0.934  setosa 
#>  2 Sepal.Length …     2    52     1 FALSE      0.115   0.0527     0.212  versic…
#>  3 Sepal.Length …     2    52     1 FALSE      0.0192  0.00109    0.0860 virgin…
#>  4 Sepal.Length …     4    45     2 TRUE       0.978   0.901      0.999  setosa 
#>  5 Sepal.Length …     4    45     2 TRUE       0.0222  0.00126    0.0988 versic…
#>  6 Sepal.Length …     4    45     2 TRUE       0       0          0.0624 virgin…
#>  7 Sepal.Length …     5     7     2 TRUE       0.143   0.00805    0.512  setosa 
#>  8 Sepal.Length …     5     7     2 TRUE       0.714   0.349      0.944  versic…
#>  9 Sepal.Length …     5     7     2 TRUE       0.143   0.00805    0.512  virgin…
#> 10 Sepal.Length …     3    98     1 FALSE      0.0510  0.0209     0.103  setosa 
#> # … with 14 more rows
```

The default intervals are based on the normal approximation for
continuous values and on `binom.test()` for discrete ones. But the
estimation function is pluggable, so users can provide their own.

``` r
library(tidytrees)
library(dplyr)
library(rpart)

# Quantile intervals for continuous outcomes
model <- rpart(Sepal.Width ~ Species + Sepal.Length, data = iris)

tidy_tree(model, add_interval = T, est_fun = function(values, add_interval, interval_level) {
    data.frame(
        estimate = median(values),
        conf.low = quantile(values, (1 - interval_level) / 2),
        conf.high = quantile(values, .5 + interval_level/2)
    )
})
#> # A tibble: 8 x 8
#>   rule                       id n.obs depth terminal estimate conf.low conf.high
#>   <chr>                   <dbl> <int> <dbl> <lgl>       <dbl>    <dbl>     <dbl>
#> 1 Species = versicolor,v…     2   100     1 FALSE        2.9      2.2       3.50
#> 2 Species = versicolor,v…     4    58     2 FALSE        2.75     2.2       3.4 
#> 3 Species = versicolor,v…     8    12     3 TRUE         2.45     2.08      2.92
#> 4 Species = versicolor,v…     9    46     3 TRUE         2.8      2.2       3.4 
#> 5 Species = versicolor,v…     5    42     2 TRUE         3        2.60      3.80
#> 6 Species = setosa            3    50     1 FALSE        3.4      2.92      4.18
#> 7 Species = setosa & Sep…     6    28     2 TRUE         3.2      2.70      3.6 
#> 8 Species = setosa & Sep…     7    22     2 TRUE         3.7      3.35      4.30

# Bayesian regularized credibility intervals for discrete outcomes
model <- rpart(Species ~ Sepal.Width + Sepal.Length, data = iris)

tidy_tree(model, add_interval = T, est_fun = function(values, add_interval, interval_level) {
    table(values) %>%
        lapply(function(cases) {
            qbeta(
                c(.5, (1 - interval_level) / 2, .5 + interval_level/2),
                cases + 1.1,
                length(values) - cases + 1.1
            ) %>% matrix(nrow = 1) %>% as.data.frame() %>% 
                setNames(c('estimate', 'cred.low', 'cred.high'))
        }) %>% bind_rows()
})
#> # A tibble: 24 x 8
#>    rule                      id n.obs depth terminal estimate cred.low cred.high
#>    <chr>                  <dbl> <int> <dbl> <lgl>       <dbl>    <dbl>     <dbl>
#>  1 Sepal.Length < 5.45        2    52     1 FALSE      0.855  0.745       0.931 
#>  2 Sepal.Length < 5.45        2    52     1 FALSE      0.126  0.0558      0.232 
#>  3 Sepal.Length < 5.45        2    52     1 FALSE      0.0332 0.00519     0.103 
#>  4 Sepal.Length < 5.45 &…     4    45     2 TRUE       0.962  0.882       0.994 
#>  5 Sepal.Length < 5.45 &…     4    45     2 TRUE       0.0382 0.00599     0.118 
#>  6 Sepal.Length < 5.45 &…     4    45     2 TRUE       0.0170 0.000803    0.0810
#>  7 Sepal.Length < 5.45 &…     5     7     2 TRUE       0.208  0.0353      0.531 
#>  8 Sepal.Length < 5.45 &…     5     7     2 TRUE       0.675  0.349       0.911 
#>  9 Sepal.Length < 5.45 &…     5     7     2 TRUE       0.208  0.0353      0.531 
#> 10 Sepal.Length >= 5.45       3    98     1 FALSE      0.0580 0.0231      0.115 
#> # … with 14 more rows
```
