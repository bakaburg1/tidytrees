The package is modular, so it would be great for contributors to provide new methods for other tree objects.

There are not many requirements to match.

## Code file name
The code for methods related to a tree object needs to be called *<tree class name>.R* and go in the *R* folder, e.g. for the rpart tree class: *rpart.R*.
Code for node predictions algorithms will be added to the *R/node_prediction.R* file at the moment. Probably more files and a proper function name template will be needed in the future.

## Method guidelines
 * **Naming convention**: The package uses S3 methods for the `tidy_tree()` generic function. So new methods will have follow the tidy_tree.<tree class name> naming convention.
 * **Arguments**: The methods will have at minimum the following arguments with the same defaults:
   - **tree**: the tree object to tidy;
   - **rule_as_text** (logical, TRUE): whether to expose the node rules as one string (TRUE) e.g.: "Species in setosa & Sepal.Length <= 5", or as a character vector (FALS) e.g.: c("Species in setosa", "Sepal.Length <= 5");
   - **eval_ready** (logical, FALSE): whether to format rules in a eval-ready format (interpretable by R) or in the tree object default representation. e.g.: eval_ready = FALSE -> Species in setosa, versicolor, eval_ready = TRUE -> Species %in% c(setosa, versicolor);
   - **add_estimates** (logical, TRUE): if TRUE node level estimates will be added to the output. Adding estimates may change the number of rows for multinomial outcomes (see output guidelines);
   - **add_interval** (logical, FALSE): if TRUE and also `add_estimates == TRUE`, node level estimates will be added to the output. if `add_interval == TRUE` but `add_estimates == FALSE`, no intervals will be added and a warning is issued. I used add_interval instead of broom::tidy conf.int becuase confidence interval is only one of the possible estimation interval one would want to use;
   - **interval_level** (numeric, .95): it has different meaning, based on the kind of interval is used. The default is taken from the broom:tidy default for confidence intervals;
   - **est_fun** (function, get_pred_estimates): the pluggable function for estimating node predictions and intervals; the default is get_pred_estimates() which provides mean and normal approximation intervals (mean ± Z_(alpha) SE) for continuous outcomes and percentage and exact binomial intervals (from `binom.test()`) for discrete ones. More on this later;
   
     Each method may have other specific arguments, but in general I'd prefer consistency.
 * **General Output**: Based on the arguments the output will have different characteristics. The base output is a `tibble()` with **one row for each node** (*excluding the root*), **no rownames**, and the following columns:
   - **rule**: the rule of the node, that is the list of splits that defines it, separated by *&*. As said before, if `eval_ready == TRUE` it needs to be formatted in a way that makes it R interpretable, for example using `eval(str2expression(rule))`. If `rule_as_text == FALSE` the rule colums should not be a vector of string but must be a list of vectors, with each vector component being a split (see example in the readme).  
   To access this information one has to meddle into the tree object package methods (often the non-exposed ones). An agnostic way is to capture the object print output with regular expressions, but it's not very efficient.
   - **id**: the id of the node, as stored in the original tree object. If the tree object has no node id (never saw a case of this, but who knows!), a progressive integer. It must allow the indentification of the nodes in the original tree object. The final output should be sorted by this column.
   - **n.obs**: the number of observation related the node in the tree object training data; the safest way to get this is by using the eval_ready rules on the original dataset, but it's not very efficient since usually the tree object has this information already somewhere. Nevertheless, the first method can be used to test if your algorithm is correct.
   - **terminal**: a logical stating whether the node is a terminal one (i.e.: a leaf of the tree). No general suggestions here, the way to do it it's very tree object specific.

     If the tree is of depth zero (i.e. a stump) a zero rows dataframe should be returned, with the afore mentioned columns, plus a warning.

 * **Estimation Output**: The afore mentioned columns are mandatory. If `add_estimates == TRUE` the *estimate* column must be added: it contains a point estimate for each node, whose value is determined by the function passed to the `est_fun` argument.  
     This function must take three arguments: `values` the values in the node (I suggest remove missings, even if there shouldn't be any), `add_interval` (default: FALSE), and `interval_level` (default: .95), with the last two arguments inherited from the `tidy_tree()` call.  
     The output will be a data.frame/tibble with an *estimate* column and (if `add_interval == TRUE`) two columns for the lower and upper estimation interval. The beginning of the name for these last two colum is free to chose (I may change idea in the future) but it must be followed by a dot and then "low" and "high" (in this order), e.g.: *conf.low*, *conf.high* or *int.low*, *int.high*. The output should have one row per node, but in the case for example of multinomial outcomes (more than 2 levels), there is a row for each node/outcome level combination, with the outcome level reported in the *y.level* column. Also remove any rownames and transform named vector columns in clean one (e.g. `broom::tidy()` applied to `binom.test()` results creates named vector columns...). These guidelines are chosen to be compatible with the `broom` package specification.  
     Finally the output should be `cbind()`ed (or similar function like data.frame or dplyr::) to the rest of the tidy output. Be careful here, especially with multinomial outcomes, since R functions take many liberties when joining `data.frames` horizontally, so the final result may be messed up; for multinomial models I suggest you either join node by node in a loop (safest) or first expand the original output with `rep()` indexing (most efficient). Also, be careful with rownames when joining, it's safer to remove them first or use a `row.names = NULL` argument if present in the bind function.

## Testing

It's wise to add unit testing for each method using the `testthat` infrastructure. I tried to add the most logical tests to the package, connected to the various problems I encountered during the development; some tests may seem silly but one is never safe enough. Some test should work independently from the original tree object, therefore I added a set of general testing function in the *tests/testthat/helpers.R* file. These tests should be placed in a file in the *tests/testthat/* folder with the *test-<tree class name>.R* convention (to work with `devtools::test()`), where class specific test can be added too. In general I added the following tests:
 * **Method tests**: check if the correct method is called given a input tree and in the method arguments follow the specification. Defined in the `perform_method_tests()` function.
 * **Rules test**: check if the rules are as expected from the original tree class. This is class specific so there's not general function. The idea is either to see if the rule editing in the method break something, or if an update in the tree package break something, or to check compatibility if you develop a rule extraction method which is faster than those exposed in the tree package.
 * **Nodes test**: check if all the nodes of the trees are included. Class specific function.
 * **Stump test**: check that a zero rows tibble and a warning are returned. Defined in the `perform_stump_test()` function.
 * **Output tests**: These tests are grouped based on the kind of outcome (continuous or discrete) and need an ideal result to compare the output to. This template result can be created using `dput()` on the outcome of your method once you are satisfied with it, to test if new changes break something unexpected. Performed by the `perform_output_tests()` function.
   - Number of rows test: test if there is one row per node or one row per node/y.level for multinomial trees.
   - Column names test: test if the column names are as expected give the ideal template and the various arguments.
   - Content test: test if the output is coherent in content with the ideal template.
 * **Number of observations per node test**: test if the number of observation in n.obs is as expected. This test in class specific, but since it must be repeated for every outcome type, I put it into a class specific function `perform_n.obs_test()`
 * **Prediction test**: test the estimations made by the default estimation function with the expected values obtained after filtering the training data with the *eval_ready* rules. As a bonus it also test whether the filtering produce a consistent n.obs with the original tree.
